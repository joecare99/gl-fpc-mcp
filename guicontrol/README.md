# mcpguicontrol

A Lazarus package (`mcpguicontrol.lpk`) that lets an MCP agent inspect and
control a running LCL application. It builds on top of `mcpbase` and `LCL`.

## All code is gated behind `MCP_GUICONTROL`

Every unit in this package compiles to an **empty shell** unless the
`MCP_GUICONTROL` symbol is defined. With the symbol off, the units pull in no
dependencies (not even `fphttpserver`/`Classes`) and contribute no code or
symbols to the host binary. This guarantees a **zero footprint in release
builds by construction** — the GUI-control machinery is simply absent unless a
build explicitly opts in.

The package itself is **define-neutral**: it does *not* bake `-dMCP_GUICONTROL`
into its own compiler options. A Lazarus package compiles its units once and
consumers link the resulting `.ppu`; baking the define in would force the real
code into every consumer regardless of their own settings. The define is
therefore always supplied by the **consumer's** build, which recompiles the
units in its own context.

### Supplying the define in a host app

Add `-dMCP_GUICONTROL` to the consuming project, not to this package. In a host
`.lpi` (e.g. via a dedicated build mode), set it under the project's compiler
options:

```xml
<CompilerOptions>
  <Other>
    <CustomOptions Value="-dMCP_GUICONTROL"/>
  </Other>
</CompilerOptions>
```

(`lazbuild` has no command-line `-d`/`--define` flag and packages have no
command-line build modes, so the define must live in the project's
`CustomOptions`.)

## Unix host requirement: `cthreads` must be first

The server runs the embedded HTTP listener on a worker thread. On **Unix**, a
host program that embeds the server thread **MUST list `cthreads` as the *first*
unit in its program `uses` clause**, or thread creation fails at runtime with
RTE 232 (`No thread support`):

```pascal
program myhost;

uses
  {$IFDEF UNIX}
  cthreads, // must be first: enables thread support on Unix
  {$ENDIF}
  Interfaces, Forms, ...;
```

IDE-managed LCL applications get this automatically. Hand-written `.lpr` hosts
must add it explicitly — see `tests/g1modalspike.lpr` for a working example.

`cthreads` is a **host program** requirement only: it is intentionally *not*
listed in this package or its units.

## Contents

- `mcp.lcl.mainthread` — main-thread marshalling bridge. Default `RunOnMainThread`
  uses `TThread.Synchronize` with exception recapture; a bounded-timeout overload
  (`RunOnMainThread(aMethod, aTimeoutMs)`) schedules with `TThread.Queue` and waits
  on a `syncobjs.TEvent`, raising `EMCPException` on expiry so a blocked main thread
  cannot hang the server (NFR2). The bridge is deliberately LCL-free so it links
  into the headless test runner.
- `mcp.lcl.serverthread` — `TMCPServerThread`, hosting a single-reader
  `TFPHTTPServer` (`Threaded := False`) on its own thread, via the `TMCPHTTPServer`
  thin descendant (promotes `Address` to public, which is `protected` on FPC 3.2.2).
- `mcp.lcl.control` — host-facing entry points: `StartGUIControlServer(aPort,
  aAllowControl)`, `StopGUIControlServer`, `GUIControlAllowsControl`, and
  `SetGUIControlAllowed` (single source of truth for the gate flag). Read-only
  by default (`aAllowControl = False`). On start/stop it also installs/removes the
  form-event hooks (`mcp.lcl.formevents`, trunk) through a `SetFormEventHooks` proc-var
  indirection, so this unit stays widgetset-free (it never names the visual unit).
- `mcp.lcl.security` — the `AllowControl` security gate: `TMCPControlTool` base
  class for mutating tools. Its `DoExecute` checks `GUIControlAllowsControl` FIRST
  and raises `EMCPException` (`SErrControlDisabled`) before any subclass body runs;
  inspection tools (descending from `TMCPTool`) are unaffected (NFR3).
- `mcp.lcl.locator` — shared dot/bracket control locator (`MainForm.Panel1.OKButton`
  and `MainForm[2][0]`) plus `findControls` resolution.
- `mcp.lcl.serialize` — published-property↔JSON (classic `TypInfo`): `ReadPublishedProperty`
  and `WritePublishedProperty` (the write path validates the JSON value type against the property
  kind first, raising `SErrPropertyType` on mismatch so a rejected write never mutates), plus LFM
  snapshot and `PaintTo`→PNG (the LFM/PNG paths need the widgetset — see the define matrix below).
- `mcp.lcl.accessors` — the non-published accessor registry: `RegisterAccessor` (a host registers a
  `class -> name -> get/set` triple at startup), `ReadAccessor` and `WriteAccessor` (linear scan, first
  registered wins, descendant-class match via `InheritsFrom`), plus `ClearAccessors`. Reaches state
  classic RTTI cannot see (FR3). Headless-safe (keys on `TClass`, operates on `TObject`/`string` only),
  and main-thread-confined: register on the main thread at startup; read only on the main thread inside
  the tools' `*OnMain` methods (that confinement is the guard — no lock).
- `mcp.lcl.osinput` — the OS-level input backend: `OSInputAvailable`, `OSInjectKey`,
  `OSInjectClickAt` and `OSGetCursorPos`. Synthesizes real OS input events that traverse the
  windowing system as a physical device would — `SendInput` on Windows, X11 `XTEST` via
  dynamically-loaded `libX11`/`libXtst` (no FPC `x11`/`xtst` package, no `-lX11` link). All
  platform `{$IFDEF}` code (Windows / Linux-X11 / unsupported-fallback) is isolated here, so the
  tools stay platform-agnostic. Widgetset-free (headless-safe) and main-thread-confined (the
  backend is initialized lazily and used only on the GUI main thread inside the tools' `*OnMain`
  methods; `finalization` closes the display and unloads the libraries). Raises
  `SErrOSInputUnavailable` when no backend is available (other OS, or no `libXtst`/display).
- `mcp.lcl.formevents` — live form open/close event push (an enhancement of FR1):
  installs LCL `Screen` form-added/removed hooks (`InstallFormEventHooks` /
  `RemoveFormEventHooks`) so each open/close is broadcast to every registered MCP
  transport as a `notifications/message` over SSE, identifying the form by name and
  class. Emission reuses `TMCPController.BroadcastDiagnostic` → the transport's existing
  `notifications/message` diagnostic path (no new transport/protocol code). **Trunk-only**:
  the push channel is SSE, gated on `THTTPServerEvent` being declared (FPC 3.3.1) — on FPC
  3.2.2 the feature is compiled out and both procedures are inert no-ops. This is a **visual**
  unit (`uses Forms`/`Screen`). The hooks are installed at `StartGUIControlServer` and removed
  at `StopGUIControlServer` via a proc-var indirection (`SetFormEventHooks`) that keeps the
  headless `mcp.lcl.control` widgetset-free. Best-effort, single-agent push (no lock — main-thread
  confined; the deferred SSE-hardening of architecture gap G3).
- `mcp.lcl.tools.inspect` — read-only inspection tools (`listForms`,
  `listDataModules`, `readProperty`, `snapshotForm`, `screenshot`, `findControls`, `readAccessor`
  (args: `target`, `name`) reads a host-registered named accessor off a located component).
- `mcp.lcl.tools.control` — mutating tools (descend from `TMCPControlTool`, so the security gate
  runs first): `setProperty` (args: `target`, `property`, `value`) writes a published property of
  a located component; `invokeAction` (args: `target`) fires a located control's `OnClick` handler
  or, failing that, its bound `Action` (raising `SErrNotActionable` when the target is neither);
  `injectKey` (args: `target`, `key`) injects a key (down+up) into a located `TWinControl` and
  `injectClick` (arg: `target`) injects a left mouse click (down+up) at a located control's centre,
  both via `LCLMessageGlue` so the real widget event path runs (raising `SErrNotInjectable` when
  the target cannot receive the requested event); and `waitForProperty` (args: `target`,
  `property`, `value`, `timeoutMs`) polls a located component's published property on the main
  thread (via the bounded-timeout bridge) until it equals `value`, returning `ok=true` on a match
  or raising `SErrWaitTimeout` once `timeoutMs` elapses; and `writeAccessor` (args: `target`, `name`,
  `value`) writes a host-registered named accessor (non-published state) on a located component,
  returning `ok=true` (raising `SErrNoAccessor` when the name is unregistered, and — via the inherited
  gate — `SErrControlDisabled` before the setter runs when control is disabled); and `injectOsKey`
  (args: `target`, `key`) and `injectOsClick` (arg: `target`) which inject a key (down+up) / a left
  mouse click (down+up) at a located control through the **OS** input path (`SendInput`/`XTEST` via
  `mcp.lcl.osinput`) — higher fidelity than `injectKey`/`injectClick` (which use `LCLMessageGlue` and
  never leave the process) — raising `SErrOSInputUnavailable` when no OS backend is available.
  Register via `RegisterControlTools`.
- `mcp.lcl.strings` — `SErr*` resource strings shared by the component.

## Visual / headless define matrix

Foundation and serialization code must link into a **headless** (no-widgetset) test
runner, while the tools that touch `Controls`/`Forms`/`Graphics` need the LCL
widgetset. This is reconciled with nested compile gates — all under `MCP_GUICONTROL`:

| Define | Meaning |
|--------|---------|
| `MCP_GUICONTROL` | Master gate. Off ⇒ the whole package is an empty shell. |
| `MCP_LOCATOR_HEADLESS` | Defined by no-widgetset binaries. Suppresses the visual branches. |
| `MCP_LOCATOR_VISUAL` | Auto-defined in `mcp.lcl.locator` *unless* `MCP_LOCATOR_HEADLESS` is set; gates the `Controls[]`/`Forms` walk. |
| `MCP_SERIALIZE_VISUAL` | Auto-defined in `mcp.lcl.serialize` *unless* `MCP_LOCATOR_HEADLESS` is set; gates the LFM-snapshot and `PaintTo`→PNG paths. |

A consumer only ever sets `MCP_GUICONTROL` (and, for a headless check,
`MCP_LOCATOR_HEADLESS`); the two `*_VISUAL` symbols are derived automatically.

> **Build hazard:** the test/spike projects share one `lib/$(TargetCPU)-$(TargetOS)`
> output dir. A `.ppu` compiled under one define set can be silently reused by a
> project with a different define set. Build verification with **`lazbuild -B`**
> (full rebuild), or use a per-define output dir (the GUI runner uses `...-gui`).

## Build verification

The `tests/` directory contains runnable checks:

- `tests/buildon.lpi` — builds the headless-compatible units (including the accessor
  registry `mcp.lcl.accessors` and the OS-input backend `mcp.lcl.osinput`, whose real code links
  headless via `dynlibs`) with `MCP_GUICONTROL` defined (their real code compiles). It
  deliberately **excludes** the visual `mcp.lcl.formevents` (it `uses Forms`/`Screen`, which would
  force the widgetset and break the headless link).
- `tests/buildoff.lpi` — builds the same units plus the visual ones (`mcp.lcl.osinput`,
  `mcp.lcl.formevents`, the tool units) with the define *off* and runs the binary, proving they
  compile to empty, dependency-free shells.
- `tests/g1modalspike.lpi` — runtime regression for the main-thread bridge under a
  modal dialog.
- `tests/g2servercycle.lpi` — self-checking start → `tools/list` over HTTP → stop →
  re-bind cycle, with a watchdog.
- `tests/mcpguicontroltests.lpi` — **headless** fpcunit runner (bridge, locator,
  serialize, accessor registry, OS-input backend): no widgetset. The OS-input suite is adaptive —
  on a reachable `DISPLAY` with `libX11`/`libXtst` it exercises the supported path (an injected
  pointer move read back via `XQueryPointer`), else it asserts the graceful `SErrOSInputUnavailable`.
- `tests/mcpguicontrolguitests.lpi` — **GUI** fpcunit runner (the inspection and
  control tools, plus the `mcp.lcl.formevents` open/close-event suite): widgetset-linked,
  needs a display, uses a separate `lib/...-gui` output dir. The form-event emission tests
  are active on FPC 3.3.1 (SSE available) and compiled out on 3.2.2 (only the no-op
  callable check runs there).

Each check is expected to build (and where applicable run, exiting `0`) on both
FPC 3.2.2 and FPC 3.3.1. For the 3.3.1 pass, prefix `lazbuild` with
`--pcp=$HOME/.lazarus-trunk`. Use `lazbuild -B` to avoid the shared-`lib/` stale-`.ppu`
hazard noted above.

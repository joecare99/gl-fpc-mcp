# Controlling an LCL application with an MCP agent (guicontrol)

`mcpguicontrol` lets an MCP agent (e.g. Claude) **inspect and drive a running
LCL application** — list its forms, read/write published properties, click
buttons, inject input, take screenshots, and more. The control surface is an
MCP server embedded in your application.

This guide covers both halves you need to make it work:

1. **Adding guicontrol to your application** — the project settings, the `uses`
   clause (with the two easy-to-miss units), and the startup code.
2. **The work cycle** — how to wire an MCP client to it so you can build → run →
   drive → rebuild → restart repeatedly, using the `mcpsupervisor` proxy to get
   around the fact that the server only exists while your app is running.

A complete, working example of everything below lives in **`demo/todo`** (a tiny
login-gated TODO app), and the proxy lives in **`Src/proxy/mcpsupervisor`**.

---

## Architecture at a glance

```
  MCP client (Claude)                your machine
  ───────────────────                ────────────
        │  stdio                     ┌───────────────────────────┐
        ▼                            │  Your LCL application      │
   mcpsupervisor  ──── HTTP ───────► │   embedded MCP server      │
   (start/stop/restart/status/       │   (loopback :18900/MCP)    │
    setBinary                        │   listForms, setProperty,  │
                                     │   invokeAction, …          │
                                     └───────────────────────────┘
```

The server is **read-only by default**; mutating tools (`setProperty`,
`invokeAction`, `injectClick`, …) only run when you start it read-write.

---

## Part 1 — Add guicontrol to your application

`mcpguicontrol` compiles to an **empty shell** unless the symbol `MCP_GUICONTROL`
is defined, so it adds nothing to a normal release build. The package itself is
**define-neutral**: you do *not* add the `mcpguicontrol` package as a dependency
and link its `.ppu`s (those were compiled without the symbol and would be empty).
Instead your project **recompiles the units in its own context** with the symbol
on. Concretely:

### 1.1 Project settings (`.lpi`)

- **Required packages:** `LCL` and `mcpbase` (not `mcpguicontrol`).
- **Other unit files:** add the path to the `guicontrol` source directory, e.g.
  `../../guicontrol`, so the compiler can find and rebuild `mcp.lcl.*`.
- **Custom compiler options:** add `-dMCP_GUICONTROL`.

  > `lazbuild` has no command-line `-d`/`--define` flag and packages have no
  > command-line build modes, so the define must live in the project's
  > `CustomOptions` (Project Options → Compiler Options → Custom Options), e.g.:
  > ```xml
  > <Other>
  >   <CustomOptions Value="-dMCP_GUICONTROL"/>
  > </Other>
  > ```

### 1.2 The program `uses` clause — two units that are easy to miss

```pascal
program myapp;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,      // (1) MUST be first on Unix
  {$ENDIF}
  Interfaces, Forms,
  jsonparser,    // (2) MUST be present
  mcp.lcl.control,
  mcp.lcl.tools.inspect,
  mcp.lcl.tools.control,
  mcp.lcl.formevents,   // optional: live form open/close events (trunk only)
  myMainForm;
```

Two requirements bite hard if forgotten — both fail at *runtime*, not compile
time:

1. **`cthreads` must be the FIRST unit in the program `uses` clause** (Unix).
   The MCP server runs its HTTP listener on a worker thread; without `cthreads`
   first, thread creation fails with **RTE 232 (`No thread support`)**.
   IDE-generated LCL programs get this automatically; hand-written `.lpr` hosts
   must add it.

2. **`jsonparser` must be in the program `uses` clause.** The MCP transport
   parses incoming JSON with `GetJSON`, which needs the `fpjson` parser handler
   that the `jsonparser` unit installs in its `initialization`. Without it, the
   server raises `EJSON: No JSON parser handler installed` on the **first
   request** and the connection is dropped — the symptom a client sees is a
   bewildering **"empty reply from server"** with no error. Add `jsonparser` and
   it works.

### 1.3 Start the server

Register the tools, then start the server — once, on the main thread (the
program body, or your main form's `OnCreate`):

```pascal
const
  ServerPort = 18900;

begin
  Application.Initialize;

  RegisterInspectionTools;            // listForms, readProperty, screenshot, …
  RegisterControlTools;               // setProperty, invokeAction, injectClick, …

  // Second arg = AllowControl. False (the default) = read-only inspection.
  // Pass True only when you want the agent to perform mutating actions.
  StartGUIControlServer(ServerPort, True);
  try
    Application.CreateForm(TMainForm, MainForm);
    Application.Run;
  finally
    StopGUIControlServer;             // stop on shutdown
  end;
end.
```

- `StartGUIControlServer(aPort, aAllowControl = False)` binds on **loopback**
  only, so the endpoint is never exposed on other interfaces.
- The security gate is enforced for you: mutating tools refuse to run (raising
  `SErrControlDisabled`) unless the server was started with `AllowControl = True`
  (or you call `SetGUIControlAllowed(True)`). Inspection tools are unaffected.
- `RegisterInspectionTools` / `RegisterControlTools` register into a global
  registry; call each once before `StartGUIControlServer`.

### 1.4 Make controls addressable

The agent locates controls with a dotted path, e.g. `MainForm.Panel1.OkButton`
or `LoginForm.UserNameEdit`. For that to work, **give every control you want to
drive an explicit `Name`** (controls placed in the form designer already have
names; controls created in code must have `Name` assigned and be owned by the
form). Bracket indexing (`MainForm[2][0]`) is also supported.

### 1.5 Build (both FPC versions)

Every story in this project must build on **FPC 3.2.2 and 3.3.1**. Always use
`lazbuild -B` (full rebuild):

```sh
lazbuild -B myapp.lpi                              # FPC 3.2.2
lazbuild --pcp=$HOME/.lazarus-trunk -B myapp.lpi   # FPC 3.3.1 (trunk)
```

> **Build hazard:** projects that share one `lib/$(TargetCPU)-$(TargetOS)`
> output dir can silently reuse a `.ppu` compiled under a *different* define set.
> `-B` avoids it. On trunk you additionally get the live form-events SSE channel
> (`mcp.lcl.formevents`); on 3.2.2 that unit is an inert no-op.

---

## Part 2 — The work cycle (wiring an MCP client)

### 2.1 The problem

The MCP server lives **inside your application**, so it only exists while the app
runs. But an MCP client (Claude Code/Desktop) connects to its configured servers
at **its own** startup — when your app is usually *not* running. And in a normal
dev loop you stop the app, recompile, and start it again many times. A plain
HTTP MCP entry pointed straight at `:18900` would be dead at client startup and
would need a manual reconnect after every rebuild.

### 2.2 The solution: the `mcpsupervisor` proxy

`Src/proxy/mcpsupervisor` is a tiny **headless stdio MCP server** that the client
spawns at *its* startup (so it is always present — it needs neither your app nor
a display to exist). It adds five lifecycle tools and forwards everything else to
your app over HTTP:

| Tool | What it does |
|------|--------------|
| `start` | Launches your app binary, waits until its MCP endpoint answers. Idempotent. |
| `stop` | Terminates the app. |
| `restart` | `stop` then `start` — run this after a rebuild. |
| `status` | Reports `running`/`pid`/`url`, plus the selected `binary`, whether it is `locked` (fixed by `--target`), and whether it exists on disk (`binaryExists`). |
| `setBinary` | Chooses which binary `start` launches, at runtime. Only when `--target` was *not* given, and only for whitelisted paths — see 2.4 below. |

Everything else (`listForms`, `setProperty`, …) is forwarded to the app. The
supervisor does **not** hardcode your tool set: `tools/list` returns the four
lifecycle tools plus, *when the app is running*, the app's own live `tools/list`
fetched over HTTP — so new tools you add to your app appear automatically. It
emits `notifications/tools/list_changed` on start/stop so the client refreshes.
When the supervisor exits, it kills the app, so a disconnect never orphans it.

Build it (headless; no `MCP_GUICONTROL`, no widgetset):

```sh
lazbuild -B Src/proxy/mcpsupervisor.lpi
lazbuild --pcp=$HOME/.lazarus-trunk -B Src/proxy/mcpsupervisor.lpi
```

### 2.3 Register it with Claude Code

Register the **supervisor** as a stdio server, pointed at your app binary:

```sh
claude mcp add guictl -- \
  /abs/path/Src/proxy/mcpsupervisor \
  --target /abs/path/to/your/app \
  --url http://127.0.0.1:18900/MCP      # optional; this is the default
```

(`--url`/`--target` accept both `--opt value` and `--opt=value`.) Verify with
`claude mcp list`; check live status inside a session with `/mcp`; remove with
`claude mcp remove guictl`.

`--target` is **optional**. Leave it off and the agent picks the binary at
runtime with `setBinary` — see the next section for the trade-off.

> The launched app inherits the environment, so a GUI app needs `DISPLAY` set in
> the session that runs Claude.

### 2.4 Choosing the binary — `--target` vs `setBinary`

One supervisor registration drives one app at a time, but there are two ways to
say *which* app. They are mutually exclusive, decided at supervisor startup:

| | `--target /path/app` | no `--target` |
|---|---|---|
| Binary chosen | at registration, fixed for the session | at runtime, by the agent |
| `setBinary` | **refused** (`status` reports `"locked":true`) | required before the first `start` |
| Whitelist config | not read at all | **must** permit the path |
| Use it when | you always drive the same app | one registration serves several apps |

Pick `--target` for a single-app project: it is the simplest and needs no config
file. Drop it when you want one `guictl` registration to drive whichever demo or
test app you are working on, without re-registering the server and restarting
Claude each time.

#### The `setBinary` call

```jsonc
{"name":"setBinary","arguments":{"path":"/abs/path/to/your/app"}}
// -> {"ok":true,"binary":"/abs/path/to/your/app"}
```

It only records the choice — it does not launch anything; follow it with
`start`. The choice persists until the supervisor exits or you call `setBinary`
again, so a `stop`/`start` (or `restart`) cycle keeps the same binary. Calling
`start` with no binary set fails with
`{"ok":false,"error":"no binary set - call setBinary first"}`.

A path is accepted only if it passes **all** of these, checked in order — on any
failure the call returns `isError` with the reason, and the previously selected
binary is left untouched:

1. the supervisor was started **without** `--target`;
2. the path is **non-empty** and **absolute** (starts with `/`);
3. it contains **no `..` segment** (which could otherwise step out of a
   whitelisted folder);
4. the file **exists**;
5. it is **permitted by the whitelist**.

#### Configuring the allowed binaries

The whitelist is a JSON file, read once at supervisor startup, from the **first**
of these that exists — first hit wins, the two are never merged:

1. `~/.config/mcpsupervisor.conf` (per user)
2. `/etc/mcpsupervisor.conf` (system-wide)

```json
{
  "allow": [
    "/home/me/projects/fresnel/demo/Grid/GridRemoteControl",
    "/home/me/projects/myapp/bin/*",
    "/home/me/projects/fresnel/demo/**"
  ]
}
```

The three entries above show the three supported forms:

| Entry form | Matches |
|---|---|
| `/dir/app` | that exact path, nothing else |
| `/dir/*` | files whose directory is exactly `/dir` — **not** subdirectories |
| `/dir/**` | anything at any depth under `/dir/` |

> **Strict JSON — no comments.** The file is parsed with `GetJSON` at its
> defaults, which do not enable `joComments`, so a `//` or `/* */` comment makes
> the whole file invalid — and an invalid file means an empty whitelist (see
> below), not a partially applied one.

> **There is no default whitelist.** If the file is missing, unreadable,
> malformed, or has no `allow` array, the whitelist is **empty and every
> `setBinary` is refused** — so without `--target` the supervisor can launch
> nothing at all. This is deliberate: an agent must never be able to talk the
> supervisor into running an arbitrary executable. A malformed file is reported
> on the supervisor's stderr and otherwise ignored (it is never treated as
> "allow everything"). Note that the file is only read when `--target` is
> absent; with `--target` the whitelist is irrelevant and need not exist.

> **The config file is the trust boundary.** Matching is purely lexical:
> symlinks and `.` segments are **not** resolved, so a symlink inside a
> whitelisted directory pointing anywhere on the system will match. Keep the
> file writable only by trusted administrators, and prefer exact paths or a
> narrow `/dir/*` over a broad `/dir/**` over a directory whose contents you do
> not control.

### 2.5 The loop

In one Claude session, with no reconnects:

1. **`setBinary`** — only when the supervisor runs without `--target`, and only
   once per app: the choice survives `restart`.
2. **`start`** — launches the freshly built app; its tools now appear.
3. **Drive it** — `listForms`, `setProperty`, `invokeAction`, etc.
4. Edit code → `lazbuild -B …` → **`restart`** — runs the new binary.
5. Repeat. **`stop`** when done; **`status`** any time.

Because the supervisor stays connected for the whole session, the build/debug
loop never requires restarting Claude or running `/mcp reconnect`.

---

## Part 3 — Driving the app (tool reference)

Inspection (always available): `listForms`, `listDataModules`, `readProperty`,
`snapshotForm`, `screenshot`, `findControls`, `readAccessor`.

Control (only when `AllowControl = True`): `setProperty`, `invokeAction`,
`injectKey`, `injectClick`, `waitForProperty`, `writeAccessor`, `injectOsKey`,
`injectOsClick`.

Common arguments use `target` (a dotted control path). Examples:

```jsonc
// list the visible forms
{"name":"listForms","arguments":{}}

// type into an edit and click a button
{"name":"setProperty","arguments":{"target":"LoginForm.UserNameEdit","property":"Text","value":"admin"}}
{"name":"invokeAction","arguments":{"target":"LoginForm.LoginButton"}}

// read a label back to verify
{"name":"readProperty","arguments":{"target":"TodoMainForm.StatusLabel","property":"Caption"}}
```

A natural-language request to Claude that exercises the whole path:

> "Using the guictl server: start the app, log in with admin/secret, add a task
> 'Buy milk', then read the status label to confirm it was created."

---

## Gotchas checklist

- [ ] `cthreads` is the **first** unit in the program `uses` (Unix) — else RTE 232.
- [ ] `jsonparser` is in the program `uses` — else `EJSON … No JSON parser
      handler` / "empty reply from server".
- [ ] `-dMCP_GUICONTROL` is in the project's **CustomOptions** (not the package).
- [ ] Required packages are `LCL` + `mcpbase`; the `guicontrol` source dir is on
      the unit path (you recompile the units, you don't link the package binary).
- [ ] `StartGUIControlServer(port, True)` if the agent must perform mutating
      actions; otherwise it's read-only.
- [ ] Controls you want to drive have explicit `Name`s.
- [ ] Build with `lazbuild -B` on both FPC 3.2.2 and 3.3.1.
- [ ] `DISPLAY` is available to the process that launches the GUI app.
- [ ] Running **without** `--target`? Then `~/.config/mcpsupervisor.conf` (or
      `/etc/mcpsupervisor.conf`) exists and its `allow` array covers your binary
      — an absent or malformed config means an empty whitelist, and **every**
      `setBinary` is refused.
- [ ] `setBinary` paths are **absolute** and free of `..` segments.
- [ ] `setBinary` refused with "a fixed target is configured"? The supervisor was
      registered with `--target`; drop it from the registration (and restart the
      client) to choose binaries at runtime.

## See also

- `demo/todo/` — a complete worked example (login form + `TBufDataset`), with its
  own `README.md` describing the exact MCP call sequence.
- `Src/proxy/README-mcpsupervisor.md` — the supervisor proxy in detail.
- `guicontrol/README.md` — the package internals and the define matrix.

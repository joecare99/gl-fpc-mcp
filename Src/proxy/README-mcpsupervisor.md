# mcpsupervisor — a launch-and-forward MCP proxy

`mcpsupervisor` solves a lifecycle mismatch: an MCP GUI-control server lives
*inside* the application under test, so its lifetime is the app's — but an MCP
client (Claude Code/Desktop) enumerates its servers at *its own* startup, when
the app is usually not running, and during a build/debug loop the app is
repeatedly stopped, rebuilt and restarted.

`mcpsupervisor` is a tiny, **headless stdio MCP server** that the client spawns
at startup (always available, no display needed for it to exist). It:

- exposes four lifecycle tools — **`start`**, **`stop`**, **`restart`**, **`status`** —
  that launch/terminate the target application binary, and
- **forwards every other MCP request** to the target app's HTTP MCP endpoint.

It does **not** hardcode the app's tools. `tools/list` returns the four
lifecycle tools plus, when the app is running, the app's own live `tools/list`
fetched over HTTP — so it tracks any tools you add to the app with no changes
here. `start`/`stop` emit `notifications/tools/list_changed` so the client
refreshes and the app's tools appear/disappear.

```
client (stdio)  ──►  mcpsupervisor  ──HTTP──►  app's embedded MCP server (:18900)
                       │ start/stop/restart/status handled locally
                       └ everything else forwarded verbatim
```

## Usage

```
mcpsupervisor --target <path-to-app-binary> [--url http://127.0.0.1:18900/MCP]
```

- `--target` (`-t`): the application binary to launch on `start`. Required.
- `--url` (`-u`): the app's MCP HTTP endpoint. Default `http://127.0.0.1:18900/MCP`.

Both `--opt value` and `--opt=value` forms are accepted. The launched process
inherits the environment (so `DISPLAY` is passed through for GUI apps), and is
terminated when the supervisor exits, so the client disconnecting never orphans
the app.

## Register with Claude Code

```sh
claude mcp add guictl -- \
  /abs/path/Src/proxy/mcpsupervisor --target /abs/path/demo/todo/todo
```

Then, in a session: `start` (launches the app), drive it via the forwarded
tools (`listForms`, `setProperty`, `invokeAction`, …), `restart` after a
rebuild, `stop` when done — all without restarting Claude or reconnecting MCP.

## Build

Headless console app; no widgetset, no `MCP_GUICONTROL` define.

```sh
lazbuild -B Src/proxy/mcpsupervisor.lpi                          # FPC 3.2.2
lazbuild --pcp=$HOME/.lazarus-trunk -B Src/proxy/mcpsupervisor.lpi  # FPC 3.3.1
```

## Relation to `mcpproxy`

`mcpproxy` (in this directory) is a *transparent* stdio↔socket bridge — it
forwards everything and manages no lifecycle. `mcpsupervisor` is the
*managing* variant: it forwards over **HTTP** and adds the start/stop lifecycle
tools. Use `mcpsupervisor` when the client must be connected before the target
app exists.

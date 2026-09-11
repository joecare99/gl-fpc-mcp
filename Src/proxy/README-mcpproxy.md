# `mcpproxy` — stdio-to-socket MCP bridge

`mcpproxy` bridges an MCP client's stdio transport to the private MCP socket
transport used by the Lazarus IDE integration.

```text
MCP client (stdio)  ──>  mcpproxy  ──TCP──>  Lazarus IDE MCP server
```

## Usage

```text
mcpproxy --port=10987
```

The default remote port is `9876`. The Lazarus IDE integration listens on
`10987` by default, so pass `--port=10987` when connecting to the IDE server.
Configuration can also be supplied through the proxy `.ini` file; command-line
options override the file.

## Connection lifecycle

- The proxy starts without opening the remote socket. The first request opens
  the connection, so the proxy can be started before Lazarus.
- If the remote server is unavailable, the proxy returns a JSON-RPC error for
  requests with an ID and remains alive for subsequent requests.
- If the remote socket closes or a request fails, the proxy discards that
  transport. A later request creates a fresh socket instead of reusing the
  failed connection.
- Notifications without an ID are not replayed after a failed connection.
  Requests are also not automatically replayed because doing so could repeat a
  side effect after the server processed the request but before its response
  reached the proxy.
- The IDE socket server uses a five-minute idle read timeout by default. Set
  `ConnectionTimeout` to zero to disable it when embedding
  `TMCPServerTCPSocketDispatcher` directly.

Disconnecting or restarting Lazarus therefore requires reconnecting only the
socket transport, not restarting the stdio proxy or the MCP client.

## Validation

The repository's console test runner covers the core types, registries, and
client behavior. It does not currently produce a line-coverage report, and
the socket reconnect path is validated separately with an end-to-end socket
probe covering:

1. request while the remote server is unavailable;
2. a successful request after the server becomes available;
3. a client disconnect during a frame;
4. idle connection expiration; and
5. a successful request after timeout and reconnect.

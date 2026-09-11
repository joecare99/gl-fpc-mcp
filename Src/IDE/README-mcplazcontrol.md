# Lazarus IDE MCP tools

The `mcplazcontrol` package exposes a loopback MCP server on port `10987`.
The server runs IDE operations on Lazarus's main thread and currently provides
the original project actions plus read-only inspection tools.

## Tool permissions

The package adds an **MCP Tools** page to Lazarus's native
**Tools -> Options -> Environment** dialog. Each tool can be set to:

- **Allowed**: execute without prompting.
- **Ask**: show a Lazarus confirmation dialog for every invocation.
- **Disabled**: do not register the tool or expose it through `tools/list`.

The defaults allow the read-only inspection tools and ask before project
changes or compilation. A client cannot grant itself permission. Changes to
tool visibility take effect after restarting the IDE; the approval mode is
checked when a tool is invoked.

## Read-only inspection tools

- `getWorkspaceInfo` returns the active project file, project directory, main
  file, and project file count.
- `listProjectFiles` lists files belonging to the active project.
- `listOpenEditors` lists open source editors and identifies the active editor.
- `getActiveEditor` returns the active editor's file, cursor, selection, and
  modified/read-only state.
- `readEditorText` reads a bounded line range from an open file belonging to
  the active project. The maximum range is 500 lines.
- `getBuildMessages` returns the messages currently shown in the Lazarus
  Messages window, including severity, source location, and view.

These tools do not save, edit, execute, or debug code. File inspection is
restricted to files that belong to the active Lazarus project. The existing
project-action tools (`openproject`, `newproject`, `newnunit`, `addnunit`, and
`compile`) remain available separately.

Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "readEditorText",
    "arguments": {
      "filename": "C:\\work\\demo\\main.pas",
      "startLine": 1,
      "endLine": 40
    }
  }
}
```

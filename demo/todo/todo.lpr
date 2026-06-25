{
  TODO demo - host program.

  A tiny login-gated TODO application that embeds the MCP GUI-control server so
  an MCP agent can drive it (log in, then create a task) as a test scenario.

  The server is started read-WRITE (AllowControl = True) on purpose: the demo's
  whole point is to let an agent perform mutating actions (setProperty / click).
  A real application would default to read-only.
}
program todo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads, // must be first on Unix: enables thread support for the server thread
  {$ENDIF}
  Interfaces, Forms,
  {$IFDEF DEBUG}
  jsonparser, // registers the fpjson parser handler the MCP transport needs
  mcp.lcl.control, mcp.lcl.tools.inspect, mcp.lcl.tools.control, mcp.lcl.formevents,
  {$ENDIF}
  todoAuth, todoLogin, todoMain;

{$IFDEF DEBUG}
const
  ServerPort = 18900;
{$ENDIF}

begin
  Application.Initialize;
  Application.Title := 'TODO Demo';
  {$IFDEF DEBUG}
  RegisterInspectionTools;
  RegisterControlTools;
  StartGUIControlServer(ServerPort, True);
  {$ENDIF}
  try
    // The login form is shown before the main form; the main form only appears
    // once valid credentials (from todo.ini) have been accepted.
    if ExecuteLogin then
      begin
      TodoMainForm := TTodoMainForm.CreateNew(Application);
      TodoMainForm.Show;
      Application.Run;
      end;
  finally
    StopGUIControlServer;
  end;
end.

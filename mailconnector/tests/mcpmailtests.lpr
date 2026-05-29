program mcpmailtests;

{$mode objfpc}{$H+}

uses
  {$ifdef unix}
  cwstring,
  {$endif}
  Classes, consoletestrunner, jsonparser,
  mcpmailtools.test,
  mcpsmtptools.test,
  mcp.logging;

type

  { TMailTestRunner }

  TMailTestRunner = class(TTestRunner)
  protected
  end;

var
  Application: TMailTestRunner;

begin
  mcp.logging.MCPLogger.Enabled := False;
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  Application := TMailTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'Mail MCP Server tests';
  Application.Run;
  Application.Free;
end.

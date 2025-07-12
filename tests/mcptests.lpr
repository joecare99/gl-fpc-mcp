program mcptests;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner,
  mcp.types.test,
  mcp.resources.test,
  mcp.resourceregistry.test,
  mcp.prompts.test,
  mcp.promptregistry.test,
  mcp.tools.test,
  mcp.toolregistry.test;

type

  { TMyTestRunner }

  TMyTestRunner = class(TTestRunner)
  protected
  end;

var
  Application: TMyTestRunner;

begin
  DefaultRunAllTests:=True;
  DefaultFormat:=fPlain;
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'MCP Package tests';
  Application.Run;
  Application.Free;
end.

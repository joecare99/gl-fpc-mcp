{
    This file is part of the Free Component Library

    MCP LCL control - console fpcunit runner for the GUI-control suite
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

program mcpguicontroltests;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads, // must be first: enables thread support on Unix (the suite spawns workers)
  {$ENDIF}
  Classes, consoletestrunner,
  mcp.lcl.mainthread.test, mcp.lcl.locator.test, mcp.lcl.serialize.test,
  mcp.lcl.security.test, mcp.lcl.accessors.test, mcp.lcl.osinput.test;

type

  { TMyTestRunner }

  TMyTestRunner = class(TTestRunner)
  protected
  end;

var
  Application: TMyTestRunner;

begin
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'MCP GUI control tests';
  Application.Run;
  Application.Free;
end.

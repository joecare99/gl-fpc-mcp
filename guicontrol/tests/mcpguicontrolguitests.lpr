{
    This file is part of the Free Component Library

    MCP LCL control - widgetset-linked fpcunit runner for the inspection-tools suite
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

program mcpguicontrolguitests;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads, // must be first: enables thread support on Unix (the marshalled test spawns a worker)
  {$ENDIF}
  Interfaces, // links the widgetset so real TForm/TDataModule fixtures work
  Forms, Classes, consoletestrunner,
  mcp.lcl.tools.inspect.test, mcp.lcl.tools.control.test, mcp.lcl.formevents.test;

type

  { TMyTestRunner }

  TMyTestRunner = class(TTestRunner)
  protected
  end;

var
  Application: TMyTestRunner;

begin
  // consoletestrunner declares its own Application var, so qualify the LCL one.
  Forms.Application.Initialize;
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'MCP GUI control GUI tests';
  Application.Run;
  Application.Free;
end.

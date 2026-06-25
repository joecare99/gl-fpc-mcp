{
    This file is part of the Free Component Library

    MCP LCL control - build check: every unit reduces to an empty shell (no define)
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

program buildoff;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads, // must be first: enables thread support on Unix
  {$ENDIF}
  mcp.lcl.mainthread, mcp.lcl.serverthread, mcp.lcl.strings, mcp.lcl.control, mcp.lcl.security,
  mcp.lcl.locator, mcp.lcl.serialize, mcp.lcl.accessors, mcp.lcl.osinput, mcp.lcl.formevents,
  mcp.lcl.tools.inspect, mcp.lcl.tools.control;

begin
  // Without MCP_GUICONTROL the units are empty, dependency-free shells.
  Halt(0);
end.

{
    This file is part of the Free Component Library

    MCP LCL control - build check: every headless-safe unit compiles with MCP_GUICONTROL on
    (locator built headless via MCP_LOCATOR_HEADLESS - its visual Controls/Forms
    branch needs a widgetset to link and is compile-verified by the package build)
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

program buildon;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads, // must be first: enables thread support on Unix
  {$ENDIF}
  mcp.lcl.mainthread, mcp.lcl.serverthread, mcp.lcl.strings, mcp.lcl.control, mcp.lcl.security,
  mcp.lcl.locator, mcp.lcl.serialize, mcp.lcl.accessors, mcp.lcl.osinput;

begin
  // With -dMCP_GUICONTROL the real code of every listed unit is forced to compile
  // (the locator's always-present headless core; its visual branch is gated off
  // by MCP_LOCATOR_HEADLESS so this console binary links without a widgetset).
  Halt(0);
end.

{
    This file is part of the Free Component Library

    MCP LCL control - security gate and TMCPControlTool base class
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.security;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, mcp.types, mcp.tools;

type

  { TMCPControlTool }

  // Abstract base for mutating (read-write) tools: gates execution on the
  // process-wide control flag and raises before any subclass code runs.
  TMCPControlTool = class(TMCPTool)
  protected
    // Entry point of the DoExecute chain: refuses when control is disabled, then delegates.
    procedure DoExecute(aInput : TJSONObject; var aResult : TMCPToolResultArray); override;
  end;

implementation

uses
  mcp.lcl.control, mcp.lcl.strings;

{ TMCPControlTool }

procedure TMCPControlTool.DoExecute(aInput : TJSONObject; var aResult : TMCPToolResultArray);

begin
  if not GUIControlAllowsControl then
    raise EMCPException.Create(SErrControlDisabled);
  inherited DoExecute(aInput, aResult);
end;

end.

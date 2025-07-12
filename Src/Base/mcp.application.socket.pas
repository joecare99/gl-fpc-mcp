{
    This file is part of the Free Component Library

    MCP Application object with socket transport.
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit mcp.application.socket;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CustApp, fpjson, mcp.controller, mcp.dispatcher.base, mcp.transport.socket, mcp.dispatcher.serversocket;


type

  { TMCPSocketApplication }

  TMCPSocketApplication = Class(TCustomApplication)
  Private
    FServer : TMCPServerTCPSocketDispatcher;
    FController : TMCPController;
    function ParseOptions : Boolean;
  Protected
    Procedure doRun; override;
  public
    procedure Initialize; override;
  end;


implementation

uses mcp.stdhandlers, mcp.logging;

function TMCPSocketApplication.ParseOptions: Boolean;

begin
  if HasOption('p','port') then
    FServer.Port:=StrToIntDef(GetOptionValue('p','port'),DefaultMCPServerPort);
  Result:=True;
end;

procedure TMCPSocketApplication.doRun;


begin
  Terminate;
  if not ParseOptions then
    exit;
  FServer.InitSocket;
  FServer.RunLoop;
end;

procedure TMCPSocketApplication.Initialize;
begin
  inherited Initialize;
  RegisterStandardHandlers;
  FServer:=TMCPServerTCPSocketDispatcher.Create(Self);
  FController:=TMCPController.create(self);
  FServer.Controller:=FController;
end;

end.


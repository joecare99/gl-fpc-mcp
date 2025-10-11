{
    This file is part of the Free Component Library

    MCP class registration
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit regmcp;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  mcp.dispatcher;

procedure Register;

implementation

uses mcp.handler, mcp.dispatcher.serversocket, mcp.dispatcher.clientsocket, mcp.controller, mcp.transport.stdio;

{$R mcp_icons.res}

procedure Register;

begin
  RegisterComponents('AI',[TMCPSocketServer,TMCPClientSocketDispatcher,TMCPSTDIOTransport,TMCPController]);
end;

initialization

end.


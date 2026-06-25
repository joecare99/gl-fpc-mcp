{
    This file is part of the Free Component Library

    MCP LCL control - HTTP server hosted on a worker thread
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.serverthread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpserver, httproute;

type

  { TMCPHTTPServer }

  // TFPHTTPServer with Address promoted to public: on FPC 3.2.2 the bind
  // address lives in a protected section of TFPCustomHttpServer (only 3.3.1+
  // publishes it), so a descendant is needed to set the loopback bind on both.
  TMCPHTTPServer = class(TFPHTTPServer)
  public
    Property Address;
  end;

  { TMCPServerThread }

  // Hosts a TMCPHTTPServer on its own thread so the LCL main thread stays free.
  // Requests are routed through the global HTTPRouter, where the MCP endpoint
  // must already be registered (see mcp.transport.http / TMCPRoute.Init).
  TMCPServerThread = class(TThread)
  private
    FPort : Word;
    FAddress : String;
    FServer : TMCPHTTPServer;
    procedure HandleRequest(aSender: TObject; var aRequest: TFPHTTPConnectionRequest;
                            var aResponse: TFPHTTPConnectionResponse);
  protected
    procedure Execute; override;
  public
    // aPort is the TCP port the server listens on; aAddress is the bind address
    // (defaults to loopback so the endpoint is not exposed on other interfaces).
    constructor Create(aPort : Word; const aAddress : String = '127.0.0.1');
    // Stops the accept loop; the thread terminates shortly after.
    procedure StopServer;
    // Port the server listens on.
    Property Port : Word Read FPort;
    // Address the server binds to (loopback by default).
    Property Address : String Read FAddress;
  end;

implementation

{ TMCPServerThread }

constructor TMCPServerThread.Create(aPort : Word; const aAddress : String = '127.0.0.1');

begin
  FPort := aPort;
  FAddress := aAddress;
  FreeOnTerminate := False;
  inherited Create(False);
end;


procedure TMCPServerThread.HandleRequest(aSender: TObject;
  var aRequest: TFPHTTPConnectionRequest; var aResponse: TFPHTTPConnectionResponse);

begin
  // TFPHTTPConnectionRequest/Response descend from TRequest/TResponse,
  // so the MCP routes registered via TMCPRoute.Init handle them directly.
  HTTPRouter.RouteRequest(aRequest, aResponse);
end;


procedure TMCPServerThread.Execute;

begin
  FServer := TMCPHTTPServer.Create(nil);
  try
    // Serialize requests: keeps the session table and registries single-reader.
    // A single agent driving the app never needs concurrency here.
    FServer.Threaded := False;
    FServer.Address := FAddress; // Bind to loopback (or caller-supplied address) before listening.
    FServer.Port := FPort;
    // Poll the accept loop instead of blocking forever in accept(): StopServer
    // only clears the accepting flag, so without a timeout the thread would stay
    // wedged in accept() and WaitFor would deadlock. The timeout bounds stop latency.
    FServer.AcceptIdleTimeout := 100;
    FServer.OnRequest := @HandleRequest;
    FServer.Active := True; // Blocks here serving until StopServer sets it False.
  finally
    FreeAndNil(FServer);
  end;
end;


procedure TMCPServerThread.StopServer;

begin
  if Assigned(FServer) then
    FServer.Active := False;
end;


end.

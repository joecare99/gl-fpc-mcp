{
    This file is part of the Free Component Library

    MCP LCL control - server lifecycle and configuration
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.control;

{$mode objfpc}{$H+}

interface

// Wires up the standard handlers, the MCP route and starts the server thread on
// loopback. Call ONCE from the main thread (e.g. main form OnCreate). aAllowControl
// defaults to False, so the server starts read-only 
procedure StartGUIControlServer(aPort : Word; aAllowControl : Boolean = False);

// Stops, joins and frees the server thread. Call from the main thread on shutdown.
// Safe to call when the server was never started (no-op).
procedure StopGUIControlServer;

// Returns whether control (read-write) operations are currently allowed.
function GUIControlAllowsControl : Boolean;

// Sets the read-write control gate; used at startup and by tests to flip the gate without a live server.
procedure SetGUIControlAllowed(aValue : Boolean);

// Lets the visual form-events unit register its start/stop hooks without
// creating a compile-time dependency (keeps this unit widgetset-free for buildon).
// System-qualified: SysUtils (impl uses) declares its own distinct TProcedure,
// so an unqualified name would mismatch the interface and not resolve.
procedure SetFormEventHooks(aOnStart, aOnStop: System.TProcedure);

implementation

uses
  SysUtils,
  mcp.transport.http, mcp.stdhandlers, mcp.lcl.serverthread;

var
  GServerThread : TMCPServerThread;
  GAllowControl : Boolean;
  GOnServerStart : System.TProcedure = nil;
  GOnServerStop : System.TProcedure = nil;


procedure StartGUIControlServer(aPort : Word; aAllowControl : Boolean = False);

begin
  // Double-start is a no-op: the server is already wired and listening.
  if Assigned(GServerThread) then
    Exit;
  SetGUIControlAllowed(aAllowControl);
  // The standard handlers and the MCP route register into process-global
  // singletons that outlive a StopGUIControlServer, and re-registering raises
  // (RegisterStandardHandlers -> EJSONRPC duplicate; TMCPRoute.Init -> EMCPHTTP).
  // Wire them once, so a stop->start cycle within one process is safe.
  if not Assigned(TMCPRoute.Instance) then
    begin
    RegisterStandardHandlers;
    TMCPRoute.Init('/MCP');
    // A bare tools/list POST carries no session id; non-initialize methods would
    // otherwise be rejected with HTTP 400 by CheckSession.
    TMCPRoute.Instance.RequireSessionID := False;
    end;
  GServerThread := TMCPServerThread.Create(aPort);
  // Install the form-event hooks now the server is up (trunk-only; nil on 3.2.2).
  if Assigned(GOnServerStart) then
    GOnServerStart();
end;


procedure StopGUIControlServer;

begin
  // Remove the form-event hooks the moment teardown begins (trunk-only; nil on 3.2.2).
  if Assigned(GOnServerStop) then
    GOnServerStop();
  if Assigned(GServerThread) then
    begin
    GServerThread.StopServer;   // Active := False -> accept loop exits
    GServerThread.WaitFor;      // join: block until Execute returns
    FreeAndNil(GServerThread);  // FServer was already freed in Execute's finally
    end;
end;


function GUIControlAllowsControl : Boolean;

begin
  Result := GAllowControl;
end;


procedure SetGUIControlAllowed(aValue : Boolean);

begin
  GAllowControl := aValue;
end;


procedure SetFormEventHooks(aOnStart, aOnStop: System.TProcedure);

begin
  GOnServerStart := aOnStart;
  GOnServerStop := aOnStop;
end;

end.

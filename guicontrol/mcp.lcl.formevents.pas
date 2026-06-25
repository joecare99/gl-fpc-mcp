{
    This file is part of the Free Component Library

    MCP LCL control - live form open/close event push over SSE (trunk only)
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{ Live form open/close event push: 
  installs LCL Screen form-added/removed hooks so each open/close is broadcast 
  to every registered  MCP transport as a notifications/message 
  (the human-readable text identifies the form by name and class). 
  
  The envelope is built by the transport's existing DoSendDiagnostic path; 
  this unit only produces the data text.

  Trunk-only: 
  the push channel is SSE, this is checked by verifying THTTPServerEvent 
  is declared (httpdefs, present on FPC 3.3.1, absent on 3.2.2) - 
  
  With SSE unavailable (FPC 3.2.2) InstallFormEventHooks / RemoveFormEventHooks are inert no-ops; 

  Visual unit: 
  it uses Forms/Screen, so it lives in the package, the buildoff check and the 
  GUI runner only - NOT in the headless buildon / headless runner.
  mcp.lcl.control drives Install/Remove through a proc-var indirection
  (SetFormEventHooks) so the headless control unit never names this visual unit.

  Threading is used in the http server:
  Screen form-added/removed handlers fire on the GUI main thread (LCL invariant),
  so BroadcastDiagnostic runs on the main thread and writes to SSE Response objects
  owned by the server thread. 
  
  The server is Threaded := False (serves one request at a time, sits in the 
  accept loop between requests), so a collision is unlikely
  under the single-agent model but is NOT formally synchronized. 
}

unit mcp.lcl.formevents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, httpdefs, Forms;

{$IF DECLARED(THTTPServerEvent)}
{$DEFINE USE_EVENTS}
{$ENDIF}

// Installs the Screen form open/close hooks so opens/closes are pushed as MCP
// notifications/message to registered SSE transports. Call on the GUI main thread
// (StartGUIControlServer does this). No-op when SSE is unavailable (FPC 3.2.2).
procedure InstallFormEventHooks;
// Removes the Screen hooks installed by InstallFormEventHooks; no dangling handler
// references remain. Call on the GUI main thread (StopGUIControlServer does this).
// No-op when SSE is unavailable (FPC 3.2.2) or when hooks were never installed.
procedure RemoveFormEventHooks;

implementation

{$IFDEF USE_EVENTS}

uses
  mcp.controller, mcp.lcl.strings, mcp.lcl.control;

type
  TMCPFormEventNotifier = class
    procedure HandleFormAdded(Sender: TObject; aForm: TCustomForm);
    procedure HandleRemoveForm(Sender: TObject; aForm: TCustomForm);
  end;

var
  GNotifier : TMCPFormEventNotifier = nil;
  GInstalled : Boolean = False;


function FormIdentity(aForm: TCustomForm): string;

begin
  Result := aForm.Name;
  if Result = '' then
    Result := aForm.ClassName;
end;


procedure TMCPFormEventNotifier.HandleFormAdded(Sender: TObject; aForm: TCustomForm);

begin
  if aForm = nil then
    Exit;
  TMCPController.Instance.BroadcastDiagnostic(Format(SFormOpened, [FormIdentity(aForm), aForm.ClassName]));
end;


procedure TMCPFormEventNotifier.HandleRemoveForm(Sender: TObject; aForm: TCustomForm);

begin
  if aForm = nil then
    Exit;
  TMCPController.Instance.BroadcastDiagnostic(Format(SFormClosed, [FormIdentity(aForm), aForm.ClassName]));
end;


procedure InstallFormEventHooks;

begin
  if GInstalled then
    Exit;
  if not Assigned(GNotifier) then
    GNotifier := TMCPFormEventNotifier.Create;
  Screen.AddHandlerFormAdded(@GNotifier.HandleFormAdded);
  Screen.AddHandlerRemoveForm(@GNotifier.HandleRemoveForm);
  GInstalled := True;
end;


procedure RemoveFormEventHooks;

begin
  if not GInstalled then
    Exit;
  // Removes both handlers in one call (every handler owned by GNotifier),
  // guaranteeing no dangling references remain.
  Screen.RemoveAllHandlersOfObject(GNotifier);
  GInstalled := False;
end;

{$ELSE USE_EVENTS}

procedure InstallFormEventHooks;

begin
  // SSE unavailable (FPC 3.2.2): event-push is compiled out - inert no-op.
end;


procedure RemoveFormEventHooks;

begin
  // SSE unavailable (FPC 3.2.2): event-push is compiled out - inert no-op.
end;

{$ENDIF USE_EVENTS}

{$IFDEF USE_EVENTS}
initialization
  // Self-wire the start/stop hooks into the (headless-safe) control unit without
  // making it depend on this visual unit. Trunk-only: on 3.2.2 this never runs,
  // so control's proc-vars stay nil and start/stop call nothing (AC #4 no-op).
  mcp.lcl.control.SetFormEventHooks(@InstallFormEventHooks, @RemoveFormEventHooks);
finalization
  RemoveFormEventHooks;
  FreeAndNil(GNotifier);
{$ENDIF USE_EVENTS}


end.

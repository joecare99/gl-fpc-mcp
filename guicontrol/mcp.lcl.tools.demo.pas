{
    This file is part of the Free Component Library

    MCP LCL control - demo inspection tools proving the threading bridge
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.tools.demo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, mcp.tools;

// Wires up the standard handlers, the MCP route, the demo tools and starts
// the server thread. Call this ONCE from the main thread (e.g. main form OnCreate).
procedure StartMCPControlServer(aPort : Word);

// Stops and frees the server thread. Call from the main thread on shutdown.
procedure StopMCPControlServer;

implementation

uses
  TypInfo, Variants, Forms, Controls, mcp.types, mcp.strings,
  mcp.transport.http, mcp.stdhandlers,
  mcp.lcl.mainthread, mcp.lcl.serverthread;

type

  { TListFormsTool }

  // Inspection tool: lists every active form known to the LCL Screen object.
  TListFormsTool = class(TMCPTool)
  private
    FResult : TJSONObject;
    procedure CollectForms; // runs on the main thread
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TReadPropertyTool }

  // Inspection tool: reads one published property of a form (or a child
  // component), demonstrating RTTI access marshalled to the main thread.
  TReadPropertyTool = class(TMCPTool)
  private
    FFormName : String;
    FComponentName : String;
    FPropName : String;
    FResult : TJSONObject;
    procedure ReadValue; // runs on the main thread
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    constructor Create(const aName: string; const aDescription: string); override;
  end;

var
  GServerThread : TMCPServerThread;


{ TListFormsTool }

procedure TListFormsTool.CollectForms;

var
  I : Integer;
  lForms : TJSONArray;
  lForm : TCustomForm;

begin
  lForms := TJSONArray.Create;
  for I := 0 to Screen.CustomFormCount - 1 do
    begin
    lForm := Screen.CustomForms[I];
    lForms.Add(TJSONObject.Create([
      'name', lForm.Name,
      'class', lForm.ClassName,
      'caption', lForm.Caption,
      'visible', lForm.Visible
    ]));
    end;
  FResult.Add('forms', lForms);
end;


procedure TListFormsTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the HTTP server thread: marshal all LCL access to the main thread.

begin
  FResult := aResult;
  RunOnMainThread(@CollectForms);
end;


{ TReadPropertyTool }

constructor TReadPropertyTool.Create(const aName: string; const aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('form', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('component', TJSONObject.Create(['type', 'string']), False);
  InputSchema.AddArgument('property', TJSONObject.Create(['type', 'string']), True);
end;


procedure TReadPropertyTool.ReadValue;

var
  lForm : TCustomForm;
  lTarget : TComponent;
  I : Integer;
  lValue : Variant;

begin
  lForm := nil;
  for I := 0 to Screen.CustomFormCount - 1 do
    if SameText(Screen.CustomForms[I].Name, FFormName) then
      begin
      lForm := Screen.CustomForms[I];
      Break;
      end;
  if lForm = nil then
    Raise EMCPException.CreateFmt('No such form: %s', [FFormName]);
  lTarget := lForm;
  if FComponentName <> '' then
    begin
    lTarget := lForm.FindComponent(FComponentName);
    if lTarget = nil then
      Raise EMCPException.CreateFmt('No such component: %s', [FComponentName]);
    end;
  if GetPropInfo(lTarget, FPropName) = nil then
    Raise EMCPException.CreateFmt('No published property: %s', [FPropName]);
  lValue := GetPropValue(lTarget, FPropName);
  FResult.Add('value', VarToStr(lValue));
end;


procedure TReadPropertyTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the HTTP server thread: read input, then marshal RTTI access.

begin
  FFormName := aInput.Get('form', '');
  FComponentName := aInput.Get('component', '');
  FPropName := aInput.Get('property', '');
  FResult := aResult;
  RunOnMainThread(@ReadValue);
end;


procedure StartMCPControlServer(aPort : Word);

begin
  RegisterStandardHandlers;
  TMCPRoute.Init('/MCP');
  // Prototype: no session handshake required, so a plain HTTP client works.
  TMCPRoute.Instance.RequireSessionID := False;
  With TListFormsTool.Create('listForms', 'List the active forms in the application') do
    Register;
  With TReadPropertyTool.Create('readProperty', 'Read a published property of a form or component') do
    Register;
  GServerThread := TMCPServerThread.Create(aPort);
end;


procedure StopMCPControlServer;

begin
  if Assigned(GServerThread) then
    begin
    GServerThread.StopServer;
    GServerThread.WaitFor;
    FreeAndNil(GServerThread);
    end;
end;


end.

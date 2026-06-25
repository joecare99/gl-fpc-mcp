{
    This file is part of the Free Component Library

    MCP LCL control - read-only inspection tools (listForms / listDataModules / readProperty /
    snapshotForm / screenshot / findControls / readAccessor)
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.tools.inspect;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, mcp.types, mcp.tools;

type

  { TListFormsTool }

  // Inspection tool: lists every active form known to the LCL Screen object.
  TListFormsTool = class(TMCPTool)
  private
    FResult : TJSONObject;
  protected
    // Enumerates Screen.CustomForms into FResult. Always runs on the main thread
    // (reached only via RunOnMainThread); virtual so tests can observe it.
    procedure CollectForms; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TListDataModulesTool }

  // Inspection tool: lists every datamodule known to the LCL Screen object.
  TListDataModulesTool = class(TMCPTool)
  private
    FResult : TJSONObject;
  protected
    // Enumerates Screen.DataModules into FResult. Always runs on the main thread
    // (reached only via RunOnMainThread); virtual so tests can observe it.
    procedure CollectDataModules; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TReadPropertyTool }

  // Inspection tool: reads one published property of a component addressed by a locator.
  TReadPropertyTool = class(TMCPTool)
  private
    FResult   : TJSONObject;
    FTarget   : string;
    FProperty : string;
  protected
    // Resolves FTarget via the shared locator and reads FProperty into FResult. Always
    // runs on the main thread (reached only via RunOnMainThread); virtual so tests can observe it.
    procedure ReadValue; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    constructor Create(const aName, aDescription: string); override;
  end;

  { TSnapshotFormTool }

  // Inspection tool: snapshots a located component's tree as LFM text.
  TSnapshotFormTool = class(TMCPTool)
  private
    FResult : TJSONObject;
    FTarget : string;
  protected
    // Resolves FTarget via the shared locator and writes its LFM snapshot into FResult.
    // Always runs on the main thread (reached only via RunOnMainThread); virtual so tests
    // can observe the main-thread hop.
    procedure BuildSnapshot; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    constructor Create(const aName, aDescription: string); override;
  end;

  { TScreenshotTool }

  // Inspection tool: renders a located TWinControl to a PNG image tool-result.
  TScreenshotTool = class(TMCPTool)
  private
    FTarget : string;
    FPng    : TBytes;
  protected
    // Resolves FTarget via the shared locator, guards it is a TWinControl, and renders it
    // into FPng. Always runs on the main thread (reached only via RunOnMainThread); virtual
    // so tests can observe the main-thread hop.
    procedure BuildScreenshot; virtual;
    procedure DoExecute(aInput: TJSONObject; out aResult: TMCPToolResult); override;
  public
    constructor Create(const aName, aDescription: string); override;
  end;

  { TFindControlsTool }

  // Inspection tool: finds controls across all forms by className / caption substring /
  // enabled state, returning each match with a round-trippable locator path.
  TFindControlsTool = class(TMCPTool)
  private
    FResult     : TJSONObject;
    FClassName  : string;
    FCaption    : string;
    FHasEnabled : Boolean;
    FEnabled    : Boolean;
  protected
    // Builds the query from the fields, runs FindControls (locator unit) and fills FResult
    // with the 'controls' array. Always runs on the main thread (reached only via
    // RunOnMainThread); virtual so tests can observe the main-thread hop.
    procedure BuildMatches; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    constructor Create(const aName, aDescription: string); override;
  end;

  { TReadAccessorTool }

  // Inspection tool: reads a host-registered named accessor (non-published state) off a
  // component addressed by a locator.
  TReadAccessorTool = class(TMCPTool)
  private
    FResult : TJSONObject;
    FTarget : string;
    FName   : string;
  protected
    // Resolves FTarget via the shared locator and reads the named accessor into FResult. Always
    // runs on the main thread (reached only via RunOnMainThread); virtual so tests can observe the hop.
    procedure ReadOnMain; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    // Declares the readAccessor schema (target, name - both required).
    constructor Create(const aName, aDescription: string); override;
  end;

// Registers the read-only inspection tools (listForms, listDataModules, readProperty,
// snapshotForm, screenshot, findControls, readAccessor) into the global tool registry. Call ONCE
// from the host app (e.g. before StartGUIControlServer).
procedure RegisterInspectionTools;

implementation

uses
  Controls, Forms, mcp.lcl.mainthread, mcp.lcl.locator, mcp.lcl.serialize, mcp.lcl.strings,
  mcp.lcl.accessors;

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
  FResult.Add('forms', lForms); // ownership of lForms transfers into FResult
end;


procedure TListFormsTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: marshal all LCL access to the main thread.

begin
  FResult := aResult;
  RunOnMainThread(@CollectForms);
end;


{ TListDataModulesTool }

procedure TListDataModulesTool.CollectDataModules;

var
  I : Integer;
  lModules : TJSONArray;
  lModule : TDataModule;

begin
  lModules := TJSONArray.Create;
  for I := 0 to Screen.DataModuleCount - 1 do
    begin
    lModule := Screen.DataModules[I];
    lModules.Add(TJSONObject.Create([
      'name', lModule.Name,
      'class', lModule.ClassName
    ]));
    end;
  FResult.Add('dataModules', lModules); // ownership of lModules transfers into FResult
end;


procedure TListDataModulesTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: marshal all LCL access to the main thread.

begin
  FResult := aResult;
  RunOnMainThread(@CollectDataModules);
end;


{ TReadPropertyTool }

constructor TReadPropertyTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('property', TJSONObject.Create(['type', 'string']), True);
end;


procedure TReadPropertyTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: marshal all LCL access to the main thread.

begin
  FTarget   := aInput.Get('target', '');
  FProperty := aInput.Get('property', '');
  FResult   := aResult;
  RunOnMainThread(@ReadValue);
end;


procedure TReadPropertyTool.ReadValue;   // runs on the GUI main thread

var
  lComp : TComponent;

begin
  lComp := ResolveTarget(FTarget);                               // raises SErrLocatorNotFound
  FResult.Add('value', ReadPublishedProperty(lComp, FProperty)); // raises SErrNoProperty
end;


{ TSnapshotFormTool }

constructor TSnapshotFormTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
end;


procedure TSnapshotFormTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: marshal all LCL access to the main thread.

begin
  FTarget := aInput.Get('target', '');
  FResult := aResult;
  RunOnMainThread(@BuildSnapshot);
end;


procedure TSnapshotFormTool.BuildSnapshot;   // runs on the GUI main thread

var
  lComp : TComponent;

begin
  lComp := ResolveTarget(FTarget);                              // raises SErrLocatorNotFound
  FResult.Add('lfm', SnapshotComponentAsLFM(lComp));
end;


{ TScreenshotTool }

constructor TScreenshotTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
end;


procedure TScreenshotTool.DoExecute(aInput: TJSONObject; out aResult: TMCPToolResult);
// Runs on the server thread: marshal the LCL access to the main thread, then wrap the bytes.

begin
  FTarget := aInput.Get('target', '');
  RunOnMainThread(@BuildScreenshot);                  // fills FPng on the main thread
  aResult := TMCPToolResult.CreateImage('image/png', FPng);  // pure-data base64; no LCL access
end;


procedure TScreenshotTool.BuildScreenshot;   // runs on the GUI main thread

var
  lComp : TComponent;

begin
  lComp := ResolveTarget(FTarget);                            // raises SErrLocatorNotFound
  if not (lComp is TWinControl) then
    raise EMCPException.CreateFmt(SErrNotAControl, [FTarget]); // AC #4 guard
  FPng := ScreenshotControlAsPNG(TWinControl(lComp));
end;


{ TFindControlsTool }

constructor TFindControlsTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('className', TJSONObject.Create(['type', 'string']), False);
  InputSchema.AddArgument('caption', TJSONObject.Create(['type', 'string']), False);
  InputSchema.AddArgument('enabled', TJSONObject.Create(['type', 'boolean']), False);
end;


procedure TFindControlsTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: read the query fields, then marshal the LCL walk to the main thread.

var
  lEnabled : TJSONData;

begin
  FClassName  := aInput.Get('className', '');
  FCaption    := aInput.Get('caption', '');
  lEnabled    := aInput.Find('enabled');     // distinguish "absent" (wildcard) from present
  FHasEnabled := lEnabled <> nil;
  if FHasEnabled then
    FEnabled := lEnabled.AsBoolean;
  FResult := aResult;
  RunOnMainThread(@BuildMatches);
end;


procedure TFindControlsTool.BuildMatches;   // runs on the GUI main thread

var
  lQuery : TControlQuery;
  lFound : TFoundControlArray;
  lControls : TJSONArray;
  lIndex : Integer;

begin
  lQuery.ClassName    := FClassName;
  lQuery.Caption      := FCaption;
  lQuery.HasEnabled   := FHasEnabled;
  lQuery.EnabledValue := FEnabled;
  lFound := FindControls(lQuery);                     // the only LCL access - locator unit
  lControls := TJSONArray.Create;
  for lIndex := 0 to High(lFound) do
    lControls.Add(TJSONObject.Create([
      'locator', lFound[lIndex].Locator,
      'name', lFound[lIndex].Name,
      'class', lFound[lIndex].ClassName,
      'caption', lFound[lIndex].Caption,
      'enabled', lFound[lIndex].Enabled
    ]));
  FResult.Add('controls', lControls);                 // ownership transfers into FResult
end;


{ TReadAccessorTool }

constructor TReadAccessorTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('name', TJSONObject.Create(['type', 'string']), True);
end;


procedure TReadAccessorTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: marshal all LCL/registry access to the main thread.

begin
  FTarget := aInput.Get('target', '');
  FName   := aInput.Get('name', '');
  FResult := aResult;
  RunOnMainThread(@ReadOnMain);
end;


procedure TReadAccessorTool.ReadOnMain;   // runs on the GUI main thread

var
  lComp : TComponent;

begin
  lComp := ResolveTarget(FTarget);                       // raises SErrLocatorNotFound
  FResult.Add('value', ReadAccessor(lComp, FName));      // raises SErrNoAccessor
end;


procedure RegisterInspectionTools;

begin
  With TListFormsTool.Create('listForms', 'List the active forms in the running application') do
    Register;
  With TListDataModulesTool.Create('listDataModules', 'List the datamodules in the running application') do
    Register;
  With TReadPropertyTool.Create('readProperty',
    'Read a published property of a located component (args: target, property)') do
    Register;
  With TSnapshotFormTool.Create('snapshotForm',
    'Snapshot a located form/component tree as LFM text (arg: target)') do
    Register;
  With TScreenshotTool.Create('screenshot',
    'Screenshot a located control/form as a PNG image (arg: target)') do
    Register;
  With TFindControlsTool.Create('findControls',
    'Find controls by className / caption substring / enabled state (args: className, caption, enabled)') do
    Register;
  With TReadAccessorTool.Create('readAccessor',
    'Read a host-registered named accessor (non-published state) off a located component (args: target, name)') do
    Register;
end;

end.

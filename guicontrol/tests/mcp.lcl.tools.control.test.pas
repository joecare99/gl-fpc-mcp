{
    This file is part of the Free Component Library

    MCP LCL control - mutating tools tests (setProperty)
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.tools.control.test;

{$mode objfpc}{$H+}

interface

{$IFDEF MCP_GUICONTROL}
uses
  TestRegistry, Classes, SysUtils, fpjson, jsonparser, fpcunit,
  Forms, Controls, StdCtrls, ActnList, LCLType, mcp.types, mcp.tools, mcp.lcl.strings,
  mcp.lcl.control, mcp.lcl.tools.control, mcp.lcl.tools.inspect, mcp.lcl.accessors,
  mcp.lcl.osinput;

type

  { TMCPControlToolsTest }

  TMCPControlToolsTest = class(TTestCase)
  private
    FFormA  : TForm;
    FButton : TButton;
    FLabel  : TLabel;
    FAction : TAction;
    FClicked : Boolean;
    FActionFired : Boolean;
    FKeyDownFired : Boolean;
    FKeyDownCode : Word;
    FMouseDownFired : Boolean;
    FMouseButton : TMouseButton;
    // OnClick handler used by the invokeAction tests; records that the click fired.
    procedure HandleClick(Sender : TObject);
    // TAction.OnExecute handler used by the bound-action test; records that it fired.
    procedure HandleActionExecute(Sender : TObject);
    // OnKeyDown handler used by the injectKey tests; records that it fired and the key code.
    procedure HandleKeyDown(Sender : TObject; var Key : Word; Shift : TShiftState);
    // OnMouseDown handler used by the injectClick tests; records that it fired and the button.
    procedure HandleMouseDown(Sender : TObject; Button : TMouseButton; Shift : TShiftState;
      X, Y : Integer);
    // Drives setProperty with {target, property, value} and returns the parsed inner JSON
    // object (the caller owns and must free it). aValue ownership transfers into the helper.
    function RunSetProperty(const aTarget, aProperty : String; aValue : TJSONData) : TJSONObject;
    // Drives readProperty (an inspection tool, unaffected by the gate) and returns the parsed
    // inner JSON object (the caller owns and must free it). Used to prove observability.
    function RunReadProperty(const aTarget, aProperty : String) : TJSONObject;
    // Drives invokeAction with {target} and returns the parsed inner JSON object (the caller
    // owns and must free it).
    function RunInvokeAction(const aTarget : String) : TJSONObject;
    // Drives injectKey with {target, key} and returns the parsed inner JSON object (the caller
    // owns and must free it).
    function RunInjectKey(const aTarget : String; aKey : Integer) : TJSONObject;
    // Drives injectClick with {target} and returns the parsed inner JSON object (the caller
    // owns and must free it).
    function RunInjectClick(const aTarget : String) : TJSONObject;
    // Drives waitForProperty with {target, property, value, timeoutMs} on the calling thread and
    // returns the parsed inner JSON object (the caller owns and must free it).
    function RunWaitForProperty(const aTarget, aProperty, aValue : String;
      aTimeoutMs : Integer) : TJSONObject;
    // Drives writeAccessor with {target, name, value} and returns the parsed inner JSON object
    // (the caller owns and must free it).
    function RunWriteAccessor(const aTarget, aName, aValue : String) : TJSONObject;
    // Drives injectOsKey with {target, key} and returns the parsed inner JSON object (the caller
    // owns and must free it).
    function RunInjectOsKey(const aTarget : String; aKey : Integer) : TJSONObject;
    // Drives injectOsClick with {target} and returns the parsed inner JSON object (the caller
    // owns and must free it).
    function RunInjectOsClick(const aTarget : String) : TJSONObject;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSetStringObservableViaRead;
    procedure TestSetIntegerObservableViaRead;
    procedure TestSetBooleanObservableViaRead;
    procedure TestSetEnumObservableViaRead;
    procedure TestSetWrongTypeRaisesPropertyType;
    procedure TestSetUnknownEnumRaisesPropertyType;
    procedure TestSetWhenControlDisabledRaises;
    procedure TestSetUnknownTargetRaises;
    procedure TestSetUnknownPropertyRaises;
    procedure TestSetPropertyMarshalsToMainThread;
    procedure TestInvokeOnClickFires;
    procedure TestInvokeBoundActionFires;
    procedure TestInvokeNotActionableRaises;
    procedure TestInvokeWhenControlDisabledRaises;
    procedure TestInvokeUnknownTargetRaises;
    procedure TestInvokeMarshalsToMainThread;
    procedure TestInjectKeyFiresKeyDown;
    procedure TestInjectClickFiresMouseDown;
    procedure TestInjectKeyNotInjectableRaises;
    procedure TestInjectKeyWhenControlDisabledRaises;
    procedure TestInjectClickWhenControlDisabledRaises;
    procedure TestInjectKeyUnknownTargetRaises;
    procedure TestInjectKeyMarshalsToMainThread;
    procedure TestInjectClickMarshalsToMainThread;
    procedure TestWaitForPropertyMatchesAfterDelay;
    procedure TestWaitForPropertyTimesOut;
    procedure TestWaitForPropertyPollsOnMainThread;
    procedure TestWaitForPropertyWhenControlDisabledRaises;
    procedure TestWaitForPropertyUnknownTargetRaises;
    procedure TestWaitForPropertyUnknownPropertyRaises;
    procedure TestWriteAccessorObservable;
    procedure TestWriteAccessorWhenControlDisabledRaises;
    procedure TestWriteAccessorUnknownNameRaises;
    procedure TestWriteAccessorUnknownTargetRaises;
    procedure TestWriteAccessorMarshalsToMainThread;
    procedure TestInjectOsClickDeliversOrUnavailable;
    procedure TestInjectOsKeyDeliversOrUnavailable;
    procedure TestInjectOsKeyWhenControlDisabledRaises;
    procedure TestInjectOsClickWhenControlDisabledRaises;
    procedure TestInjectOsKeyUnknownTargetRaises;
    procedure TestInjectOsKeyMarshalsToMainThread;
    procedure TestInjectOsClickMarshalsToMainThread;
  end;

implementation

type

  { TProbeSetPropertyTool }

  // Test-only subclass that records which thread SetValue ran on, so the marshalled-from-a-worker
  // test can prove the LCL access happened on the main thread.
  TProbeSetPropertyTool = class(TSetPropertyTool)
  private
    FSetThreadId : TThreadID;
  protected
    procedure SetValue; override;
  public
    // Thread id on which SetValue last executed.
    property SetThreadId : TThreadID read FSetThreadId;
  end;

  { TProbeInvokeActionTool }

  // Test-only subclass that records which thread InvokeOnMain ran on, so the marshalled-from-a-
  // worker test can prove the LCL access happened on the main thread.
  TProbeInvokeActionTool = class(TInvokeActionTool)
  private
    FInvokeThreadId : TThreadID;
  protected
    procedure InvokeOnMain; override;
  public
    // Thread id on which InvokeOnMain last executed.
    property InvokeThreadId : TThreadID read FInvokeThreadId;
  end;

  { TProbeInjectKeyTool }

  // Test-only subclass that records which thread InjectOnMain ran on, so the marshalled-from-a-
  // worker test can prove the LCL access happened on the main thread.
  TProbeInjectKeyTool = class(TInjectKeyTool)
  private
    FInjectThreadId : TThreadID;
  protected
    procedure InjectOnMain; override;
  public
    // Thread id on which InjectOnMain last executed.
    property InjectThreadId : TThreadID read FInjectThreadId;
  end;

  { TProbeInjectClickTool }

  // Test-only subclass that records which thread InjectOnMain ran on, so the marshalled-from-a-
  // worker test can prove the LCL access happened on the main thread.
  TProbeInjectClickTool = class(TInjectClickTool)
  private
    FInjectThreadId : TThreadID;
  protected
    procedure InjectOnMain; override;
  public
    // Thread id on which InjectOnMain last executed.
    property InjectThreadId : TThreadID read FInjectThreadId;
  end;

  { TProbeInjectOsKeyTool }

  // Test-only subclass that records which thread InjectOnMain ran on and how many times it ran, so
  // the marshalled-from-a-worker test can prove the OS call happened on the main thread and the
  // disabled-gate test can prove no OS call ran at all. The thread id is recorded BEFORE inherited,
  // so it is captured even when inherited raises SErrOSInputUnavailable/gate.
  TProbeInjectOsKeyTool = class(TInjectOsKeyTool)
  private
    FInjectThreadId : TThreadID;
    FInjectCount    : Integer;
  protected
    procedure InjectOnMain; override;
  public
    // Thread id on which InjectOnMain last executed.
    property InjectThreadId : TThreadID read FInjectThreadId;
    // Number of times InjectOnMain ran (0 proves the gate blocked the body).
    property InjectCount : Integer read FInjectCount;
  end;

  { TProbeInjectOsClickTool }

  // Test-only subclass that records which thread InjectOnMain ran on and how many times it ran, so
  // the marshalled-from-a-worker test can prove the OS call happened on the main thread and the
  // disabled-gate test can prove no OS call ran at all. The thread id is recorded BEFORE inherited,
  // so it is captured even when inherited raises SErrOSInputUnavailable/gate.
  TProbeInjectOsClickTool = class(TInjectOsClickTool)
  private
    FInjectThreadId : TThreadID;
    FInjectCount    : Integer;
  protected
    procedure InjectOnMain; override;
  public
    // Thread id on which InjectOnMain last executed.
    property InjectThreadId : TThreadID read FInjectThreadId;
    // Number of times InjectOnMain ran (0 proves the gate blocked the body).
    property InjectCount : Integer read FInjectCount;
  end;

  { TProbeWaitForPropertyTool }

  // Test-only subclass that records which thread PollOnce ran on and how many times it ran, so
  // the marshalled-from-a-worker test can prove the read happened on the main thread and the
  // disabled-gate test can prove no poll ran at all.
  TProbeWaitForPropertyTool = class(TWaitForPropertyTool)
  private
    FPollThreadId : TThreadID;
    FPollCount    : Integer;
  protected
    procedure PollOnce; override;
  public
    // Thread id on which PollOnce last executed.
    property PollThreadId : TThreadID read FPollThreadId;
    // Number of times PollOnce ran (0 proves the gate blocked the body).
    property PollCount : Integer read FPollCount;
  end;

  { TProbeWriteAccessorTool }

  // Test-only subclass that records which thread WriteOnMain ran on and how many times it ran, so
  // the marshalled-from-a-worker test can prove the write happened on the main thread and the
  // disabled-gate test can prove no write ran at all.
  TProbeWriteAccessorTool = class(TWriteAccessorTool)
  private
    FWriteThreadId : TThreadID;
    FWriteCount    : Integer;
  protected
    procedure WriteOnMain; override;
  public
    // Thread id on which WriteOnMain last executed.
    property WriteThreadId : TThreadID read FWriteThreadId;
    // Number of times WriteOnMain ran (0 proves the gate blocked the body).
    property WriteCount : Integer read FWriteCount;
  end;

  { TControlMarshalWorker }

  // Worker thread that drives a tool's public Execute (which internally hops to the main thread
  // via RunOnMainThread) and recaptures any exception so the main (test) thread can assert on it.
  TControlMarshalWorker = class(TThread)
  private
    FTool   : TMCPTool;
    FInput  : TJSONObject;
    FResult : TJSONObject;
    FReturned : Boolean;
    FErrMsg : String;
  protected
    procedure Execute; override;
  public
    constructor Create(aTool : TMCPTool; aInput, aResult : TJSONObject);
    // True when Execute returned normally (no exception).
    property Returned : Boolean read FReturned;
    // Message of the exception caught from Execute, or '' if none.
    property ErrMsg : String read FErrMsg;
  end;


procedure TProbeSetPropertyTool.SetValue;

begin
  FSetThreadId := GetCurrentThreadID;
  inherited SetValue;
end;


procedure TProbeInvokeActionTool.InvokeOnMain;

begin
  FInvokeThreadId := GetCurrentThreadID;
  inherited InvokeOnMain;
end;


procedure TProbeInjectKeyTool.InjectOnMain;

begin
  FInjectThreadId := GetCurrentThreadID;
  inherited InjectOnMain;
end;


procedure TProbeInjectClickTool.InjectOnMain;

begin
  FInjectThreadId := GetCurrentThreadID;
  inherited InjectOnMain;
end;


procedure TProbeInjectOsKeyTool.InjectOnMain;

begin
  // Record BEFORE inherited so the thread id is captured even when inherited raises
  // (SErrOSInputUnavailable when no backend, or the gate when control is disabled).
  FInjectThreadId := GetCurrentThreadID;
  Inc(FInjectCount);
  inherited InjectOnMain;
end;


procedure TProbeInjectOsClickTool.InjectOnMain;

begin
  FInjectThreadId := GetCurrentThreadID;
  Inc(FInjectCount);
  inherited InjectOnMain;
end;


procedure TProbeWaitForPropertyTool.PollOnce;

begin
  FPollThreadId := GetCurrentThreadID;
  Inc(FPollCount);
  inherited PollOnce;
end;


var
  // Backing store for the test accessor registered against the fixture form's class. The shared
  // fixture forms have no spare non-published field, so the getter/setter read/write these module
  // globals - proving the tool->registry->setter wiring (and the gate's "setter not called"
  // guarantee) end-to-end without touching the fixtures.
  GAccessorState       : string;
  GAccessorSetterCalled : Boolean;

// Module-level getter for the 'probe' accessor: returns the module-global backing store.
function ControlAccessorGet(aInstance: TObject): string;

begin
  Result := GAccessorState;
end;


// Module-level setter for the 'probe' accessor: writes the module-global store and flags that it ran.
procedure ControlAccessorSet(aInstance: TObject; const aValue: string);

begin
  GAccessorState := aValue;
  GAccessorSetterCalled := True;
end;


procedure TProbeWriteAccessorTool.WriteOnMain;

begin
  FWriteThreadId := GetCurrentThreadID;
  Inc(FWriteCount);
  inherited WriteOnMain;
end;


constructor TControlMarshalWorker.Create(aTool : TMCPTool; aInput, aResult : TJSONObject);

begin
  FTool := aTool;
  FInput := aInput;
  FResult := aResult;
  inherited Create(False);
end;


procedure TControlMarshalWorker.Execute;

begin
  try
    FTool.Execute(FInput, FResult);
    FReturned := True;
  except
    on E : Exception do
      FErrMsg := E.Message;
  end;
end;


{ TMCPControlToolsTest }

procedure TMCPControlToolsTest.SetUp;

begin
  inherited SetUp;
  FFormA := TForm.CreateNew(nil);
  FFormA.Name := 'FixtureFormA';
  FFormA.Caption := 'Fixture Form A';
  FFormA.Visible := False;
  FButton := TButton.Create(FFormA);
  FButton.Name := 'OkButton';
  FButton.Parent := FFormA;
  FButton.Caption := 'Ok';
  FButton.SetBounds(0, 0, 75, 25);
  // A TLabel is a TControl but NOT a TWinControl - the injectKey not-injectable fixture. Addressed
  // by name (InfoLabel), so adding it does not disturb the index-free existing tests.
  FLabel := TLabel.Create(FFormA);
  FLabel.Name := 'InfoLabel';
  FLabel.Parent := FFormA;
  FLabel.Caption := 'Info';
  // Leave FButton.OnClick/OnKeyDown/OnMouseDown unassigned so the gate and not-injectable tests
  // start pristine.
  FClicked := False;
  FActionFired := False;
  FKeyDownFired := False;
  FKeyDownCode := 0;
  FMouseDownFired := False;
  // Register a test accessor against the fixture form's class for the writeAccessor tests; reset
  // the registry both ends (it is a process-global - isolate it like the singleton registries).
  ClearAccessors;
  GAccessorState := 'unchanged';
  GAccessorSetterCalled := False;
  RegisterAccessor(TForm, 'probe', @ControlAccessorGet, @ControlAccessorSet);
  // Positive tests need the gate ON; the denied-path test flips it OFF locally.
  SetGUIControlAllowed(True);
end;


procedure TMCPControlToolsTest.HandleClick(Sender : TObject);

begin
  FClicked := True;
end;


procedure TMCPControlToolsTest.HandleActionExecute(Sender : TObject);

begin
  FActionFired := True;
end;


procedure TMCPControlToolsTest.HandleKeyDown(Sender : TObject; var Key : Word; Shift : TShiftState);

begin
  FKeyDownFired := True;
  FKeyDownCode := Key;
end;


procedure TMCPControlToolsTest.HandleMouseDown(Sender : TObject; Button : TMouseButton;
  Shift : TShiftState; X, Y : Integer);

begin
  FMouseDownFired := True;
  FMouseButton := Button;
end;


procedure TMCPControlToolsTest.TearDown;

begin
  // Reset the gate so no test leaks the global into the next (Story 2.1 isolation pattern).
  SetGUIControlAllowed(False);
  ClearAccessors;
  FreeAndNil(FFormA);   // owns FButton
  inherited TearDown;
end;


function TMCPControlToolsTest.RunSetProperty(const aTarget, aProperty : String; aValue : TJSONData) : TJSONObject;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TSetPropertyTool.Create('setProperty', 'x');
  try
    lInput := TJSONObject.Create(['target', aTarget, 'property', aProperty]);
    lInput.Add('value', aValue);   // ownership of aValue transfers into lInput
    lOutput := TJSONObject.Create;
    lTool.Execute(lInput, lOutput);
    lContent := lOutput.FindPath('content[0].text');
    if lContent = Nil then
      Fail('tool result is missing the content[0].text envelope');
    Result := GetJSON(lContent.AsString) as TJSONObject;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


function TMCPControlToolsTest.RunReadProperty(const aTarget, aProperty : String) : TJSONObject;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TReadPropertyTool.Create('readProperty', 'x');
  try
    lInput := TJSONObject.Create(['target', aTarget, 'property', aProperty]);
    lOutput := TJSONObject.Create;
    lTool.Execute(lInput, lOutput);
    lContent := lOutput.FindPath('content[0].text');
    if lContent = Nil then
      Fail('tool result is missing the content[0].text envelope');
    Result := GetJSON(lContent.AsString) as TJSONObject;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


function TMCPControlToolsTest.RunInvokeAction(const aTarget : String) : TJSONObject;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TInvokeActionTool.Create('invokeAction', 'x');
  try
    lInput := TJSONObject.Create(['target', aTarget]);
    lOutput := TJSONObject.Create;
    lTool.Execute(lInput, lOutput);
    lContent := lOutput.FindPath('content[0].text');
    if lContent = Nil then
      Fail('tool result is missing the content[0].text envelope');
    Result := GetJSON(lContent.AsString) as TJSONObject;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


function TMCPControlToolsTest.RunInjectKey(const aTarget : String; aKey : Integer) : TJSONObject;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TInjectKeyTool.Create('injectKey', 'x');
  try
    lInput := TJSONObject.Create(['target', aTarget, 'key', aKey]);
    lOutput := TJSONObject.Create;
    lTool.Execute(lInput, lOutput);
    lContent := lOutput.FindPath('content[0].text');
    if lContent = Nil then
      Fail('tool result is missing the content[0].text envelope');
    Result := GetJSON(lContent.AsString) as TJSONObject;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


function TMCPControlToolsTest.RunInjectClick(const aTarget : String) : TJSONObject;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TInjectClickTool.Create('injectClick', 'x');
  try
    lInput := TJSONObject.Create(['target', aTarget]);
    lOutput := TJSONObject.Create;
    lTool.Execute(lInput, lOutput);
    lContent := lOutput.FindPath('content[0].text');
    if lContent = Nil then
      Fail('tool result is missing the content[0].text envelope');
    Result := GetJSON(lContent.AsString) as TJSONObject;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


function TMCPControlToolsTest.RunWaitForProperty(const aTarget, aProperty, aValue : String;
  aTimeoutMs : Integer) : TJSONObject;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TWaitForPropertyTool.Create('waitForProperty', 'x');
  try
    lInput := TJSONObject.Create(['target', aTarget, 'property', aProperty, 'value', aValue,
      'timeoutMs', aTimeoutMs]);
    lOutput := TJSONObject.Create;
    lTool.Execute(lInput, lOutput);
    lContent := lOutput.FindPath('content[0].text');
    if lContent = Nil then
      Fail('tool result is missing the content[0].text envelope');
    Result := GetJSON(lContent.AsString) as TJSONObject;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestSetStringObservableViaRead;

var
  lParsed, lRead : TJSONObject;

begin
  // AC #1: set a string property; the change is observable via readProperty.
  lParsed := RunSetProperty('FixtureFormA', 'Caption', TJSONString.Create('Changed Caption'));
  try
    AssertEquals('setProperty confirms with ok=true', True, lParsed.Get('ok', False));
  finally
    lParsed.Free;
  end;
  lRead := RunReadProperty('FixtureFormA', 'Caption');
  try
    AssertEquals('Caption reads back the value just set', 'Changed Caption', lRead.Find('value').AsString);
  finally
    lRead.Free;
  end;
end;


procedure TMCPControlToolsTest.TestSetIntegerObservableViaRead;

var
  lParsed, lRead : TJSONObject;

begin
  // AC #2: set an integer property (Width is tkInteger); observable via readProperty.
  lParsed := RunSetProperty('FixtureFormA.OkButton', 'Width', TJSONIntegerNumber.Create(123));
  try
    AssertEquals('setProperty confirms with ok=true', True, lParsed.Get('ok', False));
  finally
    lParsed.Free;
  end;
  lRead := RunReadProperty('FixtureFormA.OkButton', 'Width');
  try
    AssertEquals('Width reads back the value just set', 123, lRead.Find('value').AsInteger);
  finally
    lRead.Free;
  end;
end;


procedure TMCPControlToolsTest.TestSetBooleanObservableViaRead;

var
  lParsed, lRead : TJSONObject;

begin
  // AC #3: set a boolean property; observable via readProperty.
  lParsed := RunSetProperty('FixtureFormA.OkButton', 'Enabled', TJSONBoolean.Create(False));
  try
    AssertEquals('setProperty confirms with ok=true', True, lParsed.Get('ok', False));
  finally
    lParsed.Free;
  end;
  lRead := RunReadProperty('FixtureFormA.OkButton', 'Enabled');
  try
    AssertEquals('Enabled reads back the value just set', False, lRead.Find('value').AsBoolean);
  finally
    lRead.Free;
  end;
end;


procedure TMCPControlToolsTest.TestSetEnumObservableViaRead;

var
  lParsed, lRead : TJSONObject;

begin
  // AC #4: set an enum property by name (Align is tkEnumeration); observable via readProperty,
  // which returns the enum name just set.
  lParsed := RunSetProperty('FixtureFormA.OkButton', 'Align', TJSONString.Create('alTop'));
  try
    AssertEquals('setProperty confirms with ok=true', True, lParsed.Get('ok', False));
  finally
    lParsed.Free;
  end;
  lRead := RunReadProperty('FixtureFormA.OkButton', 'Align');
  try
    AssertEquals('Align reads back the enum name just set', 'alTop', lRead.Find('value').AsString);
  finally
    lRead.Free;
  end;
end;


procedure TMCPControlToolsTest.TestSetWrongTypeRaisesPropertyType;

var
  lParsed, lRead : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #5: a value whose type does not match the property (a JSON string for an integer
  // property) raises EMCPException naming the property, and leaves the property unchanged.
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunSetProperty('FixtureFormA.OkButton', 'Width', TJSONString.Create('not-a-number'));
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('wrong value type must raise EMCPException', lRaised);
  AssertTrue('error message names the property', Pos('Width', lMessage) > 0);
  lRead := RunReadProperty('FixtureFormA.OkButton', 'Width');
  try
    AssertEquals('Width is left unchanged after a rejected write', 75, lRead.Find('value').AsInteger);
  finally
    lRead.Free;
  end;
end;


procedure TMCPControlToolsTest.TestSetUnknownEnumRaisesPropertyType;

var
  lParsed, lRead : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #5 (second clause): an unknown enum NAME for an enum property raises EMCPException
  // naming the property (GetEnumValue = -1 path), and leaves the property unchanged.
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunSetProperty('FixtureFormA.OkButton', 'Align', TJSONString.Create('alNoSuchValue'));
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('unknown enum name must raise EMCPException', lRaised);
  AssertTrue('error message names the property', Pos('Align', lMessage) > 0);
  lRead := RunReadProperty('FixtureFormA.OkButton', 'Align');
  try
    AssertEquals('Align is left unchanged after a rejected enum write', 'alNone',
      lRead.Find('value').AsString);
  finally
    lRead.Free;
  end;
end;


procedure TMCPControlToolsTest.TestSetWhenControlDisabledRaises;

var
  lParsed, lRead : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #6: with control disabled the gate (inherited from TMCPControlTool) raises
  // SErrControlDisabled BEFORE any mutation occurs - the property is left unchanged.
  SetGUIControlAllowed(False);
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunSetProperty('FixtureFormA', 'Caption', TJSONString.Create('Should Not Apply'));
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('disabled control must raise EMCPException', lRaised);
  AssertEquals('message must be SErrControlDisabled', SErrControlDisabled, lMessage);
  lRead := RunReadProperty('FixtureFormA', 'Caption');
  try
    AssertEquals('Caption is left unchanged when control is disabled', 'Fixture Form A',
      lRead.Find('value').AsString);
  finally
    lRead.Free;
  end;
end;


procedure TMCPControlToolsTest.TestSetUnknownTargetRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #7: an unresolved target raises EMCPException (SErrLocatorNotFound), surfaced unchanged.
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunSetProperty('NoSuchForm', 'Caption', TJSONString.Create('x'));
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('unknown target must raise EMCPException', lRaised);
  AssertTrue('error message names the missing target', Pos('NoSuchForm', lMessage) > 0);
end;


procedure TMCPControlToolsTest.TestSetUnknownPropertyRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #7: an unknown/non-published property raises EMCPException (SErrNoProperty).
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunSetProperty('FixtureFormA', 'NoSuchProp', TJSONString.Create('x'));
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('unknown property must raise EMCPException', lRaised);
  AssertTrue('error message names the missing property', Pos('NoSuchProp', lMessage) > 0);
end;


procedure TMCPControlToolsTest.TestSetPropertyMarshalsToMainThread;

var
  lTool : TProbeSetPropertyTool;
  lInput, lOutput : TJSONObject;
  lWorker : TControlMarshalWorker;
  lIterations : Integer;

begin
  // AC (mirrors inspect): drive the tool from a worker thread; it must hop to the main thread
  // via RunOnMainThread, so SetValue runs on MainThreadID. Drain on the main (test) thread with
  // a bounded ceiling so a buggy bridge fails the test rather than hangs it.
  lTool := TProbeSetPropertyTool.Create('setProperty', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA', 'property', 'Caption']);
  lInput.Add('value', TJSONString.Create('Marshalled'));
  lOutput := TJSONObject.Create;
  try
    lWorker := TControlMarshalWorker.Create(lTool, lInput, lOutput);
    try
      lIterations := 0;
      while (not lWorker.Finished) and (lIterations < 100) do // 100 * 50ms = 5s hard ceiling
        begin
        CheckSynchronize(50);
        Inc(lIterations);
        end;
      if not lWorker.Finished then
        Fail('Worker did not finish within the drain ceiling - possible hang');
      lWorker.WaitFor;
      AssertEquals('Execute must not raise', '', lWorker.ErrMsg);
      AssertTrue('Worker should have returned normally', lWorker.Returned);
      AssertEquals('SetValue must run on the main thread', MainThreadID, lTool.SetThreadId);
    finally
      lWorker.Free;
    end;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestInvokeOnClickFires;

var
  lParsed : TJSONObject;

begin
  // AC #1: a control with an assigned OnClick handler fires it; the tool confirms with ok=true.
  FButton.OnClick := @HandleClick;
  lParsed := RunInvokeAction('FixtureFormA.OkButton');
  try
    AssertTrue('OnClick handler must have fired', FClicked);
    AssertEquals('invokeAction confirms with ok=true', True, lParsed.Get('ok', False));
  finally
    lParsed.Free;
  end;
end;


procedure TMCPControlToolsTest.TestInvokeBoundActionFires;

var
  lParsed : TJSONObject;

begin
  // AC #2: a control with no OnClick but a bound TAction executes the action (OnExecute fires).
  FAction := TAction.Create(FFormA);
  FAction.OnExecute := @HandleActionExecute;
  FButton.Action := FAction;
  lParsed := RunInvokeAction('FixtureFormA.OkButton');
  try
    AssertTrue('bound action OnExecute must have fired', FActionFired);
    AssertEquals('invokeAction confirms with ok=true', True, lParsed.Get('ok', False));
  finally
    lParsed.Free;
  end;
end;


procedure TMCPControlToolsTest.TestInvokeNotActionableRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #3: a control with neither an OnClick handler nor a bound action raises EMCPException
  // (SErrNotActionable) naming the target; nothing is executed.
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunInvokeAction('FixtureFormA.OkButton');
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('a not-actionable target must raise EMCPException', lRaised);
  AssertTrue('error message names the target', Pos('FixtureFormA.OkButton', lMessage) > 0);
end;


procedure TMCPControlToolsTest.TestInvokeWhenControlDisabledRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #4: with control disabled the gate (inherited from TMCPControlTool) raises
  // SErrControlDisabled BEFORE any invocation - the OnClick handler never fires.
  FButton.OnClick := @HandleClick;
  SetGUIControlAllowed(False);
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunInvokeAction('FixtureFormA.OkButton');
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('disabled control must raise EMCPException', lRaised);
  AssertEquals('message must be SErrControlDisabled', SErrControlDisabled, lMessage);
  AssertFalse('the gate must fire before any invocation', FClicked);
end;


procedure TMCPControlToolsTest.TestInvokeUnknownTargetRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #5: an unresolved target raises EMCPException (SErrLocatorNotFound), surfaced unchanged.
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunInvokeAction('NoSuchForm');
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('unknown target must raise EMCPException', lRaised);
  AssertTrue('error message names the missing target', Pos('NoSuchForm', lMessage) > 0);
end;


procedure TMCPControlToolsTest.TestInvokeMarshalsToMainThread;

var
  lTool : TProbeInvokeActionTool;
  lInput, lOutput : TJSONObject;
  lWorker : TControlMarshalWorker;
  lIterations : Integer;

begin
  // AC #6: drive the tool from a worker thread; it must hop to the main thread via
  // RunOnMainThread, so InvokeOnMain runs on MainThreadID. Assign OnClick first so the inherited
  // InvokeOnMain succeeds. Drain on the main (test) thread with a bounded ceiling so a buggy
  // bridge fails the test rather than hangs it.
  FButton.OnClick := @HandleClick;
  lTool := TProbeInvokeActionTool.Create('invokeAction', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA.OkButton']);
  lOutput := TJSONObject.Create;
  try
    lWorker := TControlMarshalWorker.Create(lTool, lInput, lOutput);
    try
      lIterations := 0;
      while (not lWorker.Finished) and (lIterations < 100) do // 100 * 50ms = 5s hard ceiling
        begin
        CheckSynchronize(50);
        Inc(lIterations);
        end;
      if not lWorker.Finished then
        Fail('Worker did not finish within the drain ceiling - possible hang');
      lWorker.WaitFor;
      AssertEquals('Execute must not raise', '', lWorker.ErrMsg);
      AssertTrue('Worker should have returned normally', lWorker.Returned);
      AssertEquals('InvokeOnMain must run on the main thread', MainThreadID, lTool.InvokeThreadId);
    finally
      lWorker.Free;
    end;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestInjectKeyFiresKeyDown;

var
  lParsed : TJSONObject;

begin
  // AC #1: a TWinControl with an assigned OnKeyDown handler fires it via the injected CN_KEYDOWN;
  // the tool confirms with ok=true.
  FButton.OnKeyDown := @HandleKeyDown;
  lParsed := RunInjectKey('FixtureFormA.OkButton', VK_RETURN);
  try
    AssertTrue('OnKeyDown handler must have fired', FKeyDownFired);
    AssertEquals('the handler received the injected key code', VK_RETURN, FKeyDownCode);
    AssertEquals('injectKey confirms with ok=true', True, lParsed.Get('ok', False));
  finally
    lParsed.Free;
  end;
end;


procedure TMCPControlToolsTest.TestInjectClickFiresMouseDown;

var
  lParsed : TJSONObject;

begin
  // AC #2: a control with an assigned OnMouseDown handler fires it (with mbLeft) via the injected
  // LM_LBUTTONDOWN; the tool confirms with ok=true.
  FButton.OnMouseDown := @HandleMouseDown;
  lParsed := RunInjectClick('FixtureFormA.OkButton');
  try
    AssertTrue('OnMouseDown handler must have fired', FMouseDownFired);
    AssertTrue('the handler received a left-button click', FMouseButton = mbLeft);
    AssertEquals('injectClick confirms with ok=true', True, lParsed.Get('ok', False));
  finally
    lParsed.Free;
  end;
end;


procedure TMCPControlToolsTest.TestInjectKeyNotInjectableRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #4: a TLabel is a TControl but not a TWinControl, so injectKey cannot deliver a key event;
  // it raises EMCPException (SErrNotInjectable) naming the target and nothing is injected.
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunInjectKey('FixtureFormA.InfoLabel', VK_RETURN);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('a not-injectable target must raise EMCPException', lRaised);
  AssertTrue('error message names the target', Pos('FixtureFormA.InfoLabel', lMessage) > 0);
end;


procedure TMCPControlToolsTest.TestInjectKeyWhenControlDisabledRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #3: with control disabled the gate (inherited from TMCPControlTool) raises
  // SErrControlDisabled BEFORE any injection - the OnKeyDown handler never fires.
  FButton.OnKeyDown := @HandleKeyDown;
  SetGUIControlAllowed(False);
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunInjectKey('FixtureFormA.OkButton', VK_RETURN);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('disabled control must raise EMCPException', lRaised);
  AssertEquals('message must be SErrControlDisabled', SErrControlDisabled, lMessage);
  AssertFalse('the gate must fire before any injection', FKeyDownFired);
end;


procedure TMCPControlToolsTest.TestInjectClickWhenControlDisabledRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #3: with control disabled the gate (inherited from TMCPControlTool) raises
  // SErrControlDisabled BEFORE any injection - the OnMouseDown handler never fires.
  FButton.OnMouseDown := @HandleMouseDown;
  SetGUIControlAllowed(False);
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunInjectClick('FixtureFormA.OkButton');
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('disabled control must raise EMCPException', lRaised);
  AssertEquals('message must be SErrControlDisabled', SErrControlDisabled, lMessage);
  AssertFalse('the gate must fire before any injection', FMouseDownFired);
end;


procedure TMCPControlToolsTest.TestInjectKeyUnknownTargetRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #5: an unresolved target raises EMCPException (SErrLocatorNotFound), surfaced unchanged.
  // One unknown-target test covers the shared ResolveTarget path for both inject tools.
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunInjectKey('NoSuchForm', VK_RETURN);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('unknown target must raise EMCPException', lRaised);
  AssertTrue('error message names the missing target', Pos('NoSuchForm', lMessage) > 0);
end;


procedure TMCPControlToolsTest.TestInjectKeyMarshalsToMainThread;

var
  lTool : TProbeInjectKeyTool;
  lInput, lOutput : TJSONObject;
  lWorker : TControlMarshalWorker;
  lIterations : Integer;

begin
  // AC #6: drive the tool from a worker thread; it must hop to the main thread via
  // RunOnMainThread, so InjectOnMain runs on MainThreadID. Assign OnKeyDown first so the inherited
  // InjectOnMain succeeds. Drain on the main (test) thread with a bounded ceiling so a buggy
  // bridge fails the test rather than hangs it.
  FButton.OnKeyDown := @HandleKeyDown;
  lTool := TProbeInjectKeyTool.Create('injectKey', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA.OkButton', 'key', VK_RETURN]);
  lOutput := TJSONObject.Create;
  try
    lWorker := TControlMarshalWorker.Create(lTool, lInput, lOutput);
    try
      lIterations := 0;
      while (not lWorker.Finished) and (lIterations < 100) do // 100 * 50ms = 5s hard ceiling
        begin
        CheckSynchronize(50);
        Inc(lIterations);
        end;
      if not lWorker.Finished then
        Fail('Worker did not finish within the drain ceiling - possible hang');
      lWorker.WaitFor;
      AssertEquals('Execute must not raise', '', lWorker.ErrMsg);
      AssertTrue('Worker should have returned normally', lWorker.Returned);
      AssertEquals('InjectOnMain must run on the main thread', MainThreadID, lTool.InjectThreadId);
    finally
      lWorker.Free;
    end;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestInjectClickMarshalsToMainThread;

var
  lTool : TProbeInjectClickTool;
  lInput, lOutput : TJSONObject;
  lWorker : TControlMarshalWorker;
  lIterations : Integer;

begin
  // AC #6: drive the tool from a worker thread; it must hop to the main thread via
  // RunOnMainThread, so InjectOnMain runs on MainThreadID. Assign OnMouseDown first so the
  // inherited InjectOnMain succeeds. Drain on the main (test) thread with a bounded ceiling so a
  // buggy bridge fails the test rather than hangs it.
  FButton.OnMouseDown := @HandleMouseDown;
  lTool := TProbeInjectClickTool.Create('injectClick', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA.OkButton']);
  lOutput := TJSONObject.Create;
  try
    lWorker := TControlMarshalWorker.Create(lTool, lInput, lOutput);
    try
      lIterations := 0;
      while (not lWorker.Finished) and (lIterations < 100) do // 100 * 50ms = 5s hard ceiling
        begin
        CheckSynchronize(50);
        Inc(lIterations);
        end;
      if not lWorker.Finished then
        Fail('Worker did not finish within the drain ceiling - possible hang');
      lWorker.WaitFor;
      AssertEquals('Execute must not raise', '', lWorker.ErrMsg);
      AssertTrue('Worker should have returned normally', lWorker.Returned);
      AssertEquals('InjectOnMain must run on the main thread', MainThreadID, lTool.InjectThreadId);
    finally
      lWorker.Free;
    end;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;

procedure TMCPControlToolsTest.TestWaitForPropertyMatchesAfterDelay;

var
  lTool : TWaitForPropertyTool;
  lInput, lOutput, lParsed : TJSONObject;
  lWorker : TControlMarshalWorker;
  lIterations : Integer;

begin
  // AC #1: the property flips to the expected value mid-wait; waitForProperty returns ok=true.
  // Driven from a worker so the main (test) thread can both drain the queued reads and mutate the
  // property. A generous timeoutMs (5000) means the 100*50ms drain ceiling - not the wait timeout
  // - is the safety net; the flip happens at iteration 2, well before either.
  lParsed := Nil;
  lTool := TWaitForPropertyTool.Create('waitForProperty', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA.OkButton', 'property', 'Caption',
    'value', 'Ready', 'timeoutMs', 5000]);
  lOutput := TJSONObject.Create;
  try
    lWorker := TControlMarshalWorker.Create(lTool, lInput, lOutput);
    try
      lIterations := 0;
      while (not lWorker.Finished) and (lIterations < 100) do // 100 * 50ms = 5s hard ceiling
        begin
        if lIterations = 2 then
          FButton.Caption := 'Ready';   // legal main-thread mutation (test thread IS MainThreadID)
        CheckSynchronize(50);
        Inc(lIterations);
        end;
      if not lWorker.Finished then
        Fail('Worker did not finish within the drain ceiling - possible hang');
      lWorker.WaitFor;
      AssertEquals('Execute must not raise', '', lWorker.ErrMsg);
      AssertTrue('Worker should have returned normally', lWorker.Returned);
      lParsed := GetJSON(lOutput.FindPath('content[0].text').AsString) as TJSONObject;
      AssertEquals('waitForProperty confirms with ok=true', True, lParsed.Get('ok', False));
    finally
      lWorker.Free;
    end;
  finally
    lParsed.Free;
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestWaitForPropertyTimesOut;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #2: the property never reaches the expected value, so after timeoutMs the tool raises
  // EMCPException (SErrWaitTimeout) naming target.property. Run directly on the test/main thread -
  // nothing changes the property, so no draining is needed; the call blocks ~150ms then raises.
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunWaitForProperty('FixtureFormA.OkButton', 'Caption', 'NeverThisValue', 150);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('a wait that never matches must raise EMCPException', lRaised);
  AssertEquals('message must be SErrWaitTimeout for target.property', SysUtils.Format(SErrWaitTimeout,
    ['FixtureFormA.OkButton.Caption']), lMessage);
end;


procedure TMCPControlToolsTest.TestWaitForPropertyPollsOnMainThread;

var
  lTool : TProbeWaitForPropertyTool;
  lInput, lOutput : TJSONObject;
  lWorker : TControlMarshalWorker;
  lIterations : Integer;

begin
  // AC #3: polling hops to the main thread via the bounded bridge. The value 'Ok' matches the
  // initial FButton.Caption immediately, so it matches on the first poll; driven from a worker so
  // PollOnce runs marshalled. After the worker finishes, PollOnce must have run on MainThreadID.
  lTool := TProbeWaitForPropertyTool.Create('waitForProperty', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA.OkButton', 'property', 'Caption',
    'value', 'Ok', 'timeoutMs', 5000]);
  lOutput := TJSONObject.Create;
  try
    lWorker := TControlMarshalWorker.Create(lTool, lInput, lOutput);
    try
      lIterations := 0;
      while (not lWorker.Finished) and (lIterations < 100) do // 100 * 50ms = 5s hard ceiling
        begin
        CheckSynchronize(50);
        Inc(lIterations);
        end;
      if not lWorker.Finished then
        Fail('Worker did not finish within the drain ceiling - possible hang');
      lWorker.WaitFor;
      AssertEquals('Execute must not raise', '', lWorker.ErrMsg);
      AssertTrue('Worker should have returned normally', lWorker.Returned);
      AssertEquals('PollOnce must run on the main thread', MainThreadID, lTool.PollThreadId);
      AssertTrue('PollOnce must have run at least once', lTool.PollCount >= 1);
    finally
      lWorker.Free;
    end;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestWaitForPropertyWhenControlDisabledRaises;

var
  lTool : TProbeWaitForPropertyTool;
  lInput, lOutput : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #4: with control disabled the gate (inherited from TMCPControlTool) raises
  // SErrControlDisabled BEFORE any poll. The value 'Ok' would match the initial Caption, so a
  // missing gate would return ok=true instead of raising - PollCount = 0 proves the gate ran
  // first. Drive a probe instance directly (the gate raises before any marshalling).
  SetGUIControlAllowed(False);
  lRaised := False;
  lMessage := '';
  lTool := TProbeWaitForPropertyTool.Create('waitForProperty', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA.OkButton', 'property', 'Caption',
    'value', 'Ok', 'timeoutMs', 5000]);
  lOutput := TJSONObject.Create;
  try
    try
      lTool.Execute(lInput, lOutput);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
    AssertTrue('disabled control must raise EMCPException', lRaised);
    AssertEquals('message must be SErrControlDisabled', SErrControlDisabled, lMessage);
    AssertEquals('the gate must fire before any poll', 0, lTool.PollCount);
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestWaitForPropertyUnknownTargetRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #5: an unresolved target raises EMCPException (SErrLocatorNotFound) from the first poll,
  // surfaced unchanged - NOT swallowed into a wait timeout. Assert the exact locator message (a
  // SErrWaitTimeout would also contain the target name, so exact equality is what proves it).
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunWaitForProperty('NoSuchForm', 'Caption', 'Ok', 1000);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('unknown target must raise EMCPException', lRaised);
  AssertEquals('read error must surface unchanged, not as a timeout',
    SysUtils.Format(SErrLocatorNotFound, ['NoSuchForm']), lMessage);
end;


procedure TMCPControlToolsTest.TestWaitForPropertyUnknownPropertyRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #5: an unknown property raises EMCPException (SErrNoProperty) from the first poll, surfaced
  // unchanged - never masked as a wait timeout. Exact-message assertion proves it is the read
  // error and not SErrWaitTimeout.
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunWaitForProperty('FixtureFormA.OkButton', 'NoSuchProp', 'Ok', 1000);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('unknown property must raise EMCPException', lRaised);
  AssertEquals('read error must surface unchanged, not as a timeout',
    SysUtils.Format(SErrNoProperty, ['NoSuchProp']), lMessage);
end;


function TMCPControlToolsTest.RunWriteAccessor(const aTarget, aName, aValue : String) : TJSONObject;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TWriteAccessorTool.Create('writeAccessor', 'x');
  try
    lInput := TJSONObject.Create(['target', aTarget, 'name', aName, 'value', aValue]);
    lOutput := TJSONObject.Create;
    lTool.Execute(lInput, lOutput);
    lContent := lOutput.FindPath('content[0].text');
    if lContent = Nil then
      Fail('tool result is missing the content[0].text envelope');
    Result := GetJSON(lContent.AsString) as TJSONObject;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestWriteAccessorObservable;

var
  lParsed : TJSONObject;
  lReadTool : TMCPTool;
  lReadIn, lReadOut : TJSONObject;
  lRead : TJSONObject;

begin
  // AC #2: with control enabled (SetUp turns the gate ON) writeAccessor invokes the registered
  // setter; the tool confirms with ok=true and the change is observable - both via the backing
  // store and end-to-end via a readAccessor drive (mcp.lcl.tools.inspect is already in uses).
  lParsed := RunWriteAccessor('FixtureFormA', 'probe', 'changed');
  try
    AssertEquals('writeAccessor confirms with ok=true', True, lParsed.Get('ok', False));
  finally
    lParsed.Free;
  end;
  AssertTrue('the setter must have run', GAccessorSetterCalled);
  AssertEquals('the backing store reflects the written value', 'changed', GAccessorState);
  lRead := Nil;
  lReadIn := Nil;
  lReadOut := Nil;
  lReadTool := TReadAccessorTool.Create('readAccessor', 'x');
  try
    lReadIn := TJSONObject.Create(['target', 'FixtureFormA', 'name', 'probe']);
    lReadOut := TJSONObject.Create;
    lReadTool.Execute(lReadIn, lReadOut);
    lRead := GetJSON(lReadOut.FindPath('content[0].text').AsString) as TJSONObject;
    AssertEquals('readAccessor observes the value just written', 'changed', lRead.Find('value').AsString);
  finally
    lRead.Free;
    lReadIn.Free;
    lReadOut.Free;
    lReadTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestWriteAccessorWhenControlDisabledRaises;

var
  lTool : TProbeWriteAccessorTool;
  lInput, lOutput : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #4: with control disabled the gate (inherited from TMCPControlTool) raises
  // SErrControlDisabled BEFORE any mutation - the setter never runs and the store is untouched.
  // WriteCount = 0 proves the gate fired ahead of the body. Drive a probe instance directly.
  SetGUIControlAllowed(False);
  GAccessorSetterCalled := False;
  GAccessorState := 'unchanged';
  lRaised := False;
  lMessage := '';
  lTool := TProbeWriteAccessorTool.Create('writeAccessor', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA', 'name', 'probe', 'value', 'should-not-apply']);
  lOutput := TJSONObject.Create;
  try
    try
      lTool.Execute(lInput, lOutput);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
    AssertTrue('disabled control must raise EMCPException', lRaised);
    AssertEquals('message must be SErrControlDisabled', SErrControlDisabled, lMessage);
    AssertEquals('the gate must fire before any write', 0, lTool.WriteCount);
    AssertFalse('the setter must NOT run when control is disabled', GAccessorSetterCalled);
    AssertEquals('the backing store is left unchanged', 'unchanged', GAccessorState);
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestWriteAccessorUnknownNameRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #3: gate ON; an unregistered name raises EMCPException (SErrNoAccessor) naming the accessor.
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunWriteAccessor('FixtureFormA', 'nope', 'x');
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('unknown name must raise EMCPException', lRaised);
  AssertEquals('message must be SErrNoAccessor for the name', SysUtils.Format(SErrNoAccessor, ['nope']), lMessage);
end;


procedure TMCPControlToolsTest.TestWriteAccessorUnknownTargetRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #5: an unresolved target raises EMCPException (SErrLocatorNotFound), surfaced unchanged -
  // NOT masked as SErrNoAccessor.
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunWriteAccessor('NoSuchForm', 'probe', 'x');
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('unknown target must raise EMCPException', lRaised);
  AssertEquals('locator error must surface unchanged, not as SErrNoAccessor',
    SysUtils.Format(SErrLocatorNotFound, ['NoSuchForm']), lMessage);
end;


procedure TMCPControlToolsTest.TestWriteAccessorMarshalsToMainThread;

var
  lTool : TProbeWriteAccessorTool;
  lInput, lOutput : TJSONObject;
  lWorker : TControlMarshalWorker;
  lIterations : Integer;

begin
  // AC #6: drive the tool from a worker thread; it must hop to the main thread via
  // RunOnMainThread, so WriteOnMain runs on MainThreadID. Drain on the main (test) thread with a
  // bounded ceiling so a buggy bridge fails the test rather than hangs it.
  lTool := TProbeWriteAccessorTool.Create('writeAccessor', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA', 'name', 'probe', 'value', 'Marshalled']);
  lOutput := TJSONObject.Create;
  try
    lWorker := TControlMarshalWorker.Create(lTool, lInput, lOutput);
    try
      lIterations := 0;
      while (not lWorker.Finished) and (lIterations < 100) do // 100 * 50ms = 5s hard ceiling
        begin
        CheckSynchronize(50);
        Inc(lIterations);
        end;
      if not lWorker.Finished then
        Fail('Worker did not finish within the drain ceiling - possible hang');
      lWorker.WaitFor;
      AssertEquals('Execute must not raise', '', lWorker.ErrMsg);
      AssertTrue('Worker should have returned normally', lWorker.Returned);
      AssertEquals('WriteOnMain must run on the main thread', MainThreadID, lTool.WriteThreadId);
    finally
      lWorker.Free;
    end;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


function TMCPControlToolsTest.RunInjectOsKey(const aTarget : String; aKey : Integer) : TJSONObject;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TInjectOsKeyTool.Create('injectOsKey', 'x');
  try
    lInput := TJSONObject.Create(['target', aTarget, 'key', aKey]);
    lOutput := TJSONObject.Create;
    lTool.Execute(lInput, lOutput);
    lContent := lOutput.FindPath('content[0].text');
    if lContent = Nil then
      Fail('tool result is missing the content[0].text envelope');
    Result := GetJSON(lContent.AsString) as TJSONObject;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


function TMCPControlToolsTest.RunInjectOsClick(const aTarget : String) : TJSONObject;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TInjectOsClickTool.Create('injectOsClick', 'x');
  try
    lInput := TJSONObject.Create(['target', aTarget]);
    lOutput := TJSONObject.Create;
    lTool.Execute(lInput, lOutput);
    lContent := lOutput.FindPath('content[0].text');
    if lContent = Nil then
      Fail('tool result is missing the content[0].text envelope');
    Result := GetJSON(lContent.AsString) as TJSONObject;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestInjectOsClickDeliversOrUnavailable;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #1, #8: gate ON (SetUp enables control). Where an OS backend is available the tool wires
  // resolve -> screen-centre -> OSInjectClickAt -> ok=true; else it raises SErrOSInputUnavailable.
  // (The headless unit test already proves the OS path moves the pointer; this proves the wiring.)
  if OSInputAvailable then
    begin
    lParsed := RunInjectOsClick('FixtureFormA.OkButton');
    try
      AssertEquals('injectOsClick confirms with ok=true', True, lParsed.Get('ok', False));
    finally
      lParsed.Free;
    end;
    end
  else
    begin
    lRaised := False;
    lMessage := '';
    lParsed := Nil;
    try
      try
        lParsed := RunInjectOsClick('FixtureFormA.OkButton');
      except
        on E : EMCPException do
          begin
          lRaised := True;
          lMessage := E.Message;
          end;
      end;
    finally
      lParsed.Free;
    end;
    AssertTrue('no backend must raise EMCPException', lRaised);
    AssertTrue('message must be SErrOSInputUnavailable', Pos('not available', lMessage) > 0);
    end;
end;


procedure TMCPControlToolsTest.TestInjectOsKeyDeliversOrUnavailable;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #2, #8: gate ON. Where a backend is available the tool returns ok=true; else it raises
  // SErrOSInputUnavailable. $FF0D is XK_Return on the X11 key path.
  if OSInputAvailable then
    begin
    lParsed := RunInjectOsKey('FixtureFormA.OkButton', $FF0D);
    try
      AssertEquals('injectOsKey confirms with ok=true', True, lParsed.Get('ok', False));
    finally
      lParsed.Free;
    end;
    end
  else
    begin
    lRaised := False;
    lMessage := '';
    lParsed := Nil;
    try
      try
        lParsed := RunInjectOsKey('FixtureFormA.OkButton', $FF0D);
      except
        on E : EMCPException do
          begin
          lRaised := True;
          lMessage := E.Message;
          end;
      end;
    finally
      lParsed.Free;
    end;
    AssertTrue('no backend must raise EMCPException', lRaised);
    AssertTrue('message must be SErrOSInputUnavailable', Pos('not available', lMessage) > 0);
    end;
end;


procedure TMCPControlToolsTest.TestInjectOsKeyWhenControlDisabledRaises;

var
  lTool : TProbeInjectOsKeyTool;
  lInput, lOutput : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #4: with control disabled the gate (inherited from TMCPControlTool) raises
  // SErrControlDisabled BEFORE any OS call - InjectCount = 0 proves it, deterministically
  // regardless of backend availability. Drive a probe instance directly (the gate raises before
  // any marshalling).
  SetGUIControlAllowed(False);
  lRaised := False;
  lMessage := '';
  lTool := TProbeInjectOsKeyTool.Create('injectOsKey', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA.OkButton', 'key', $FF0D]);
  lOutput := TJSONObject.Create;
  try
    try
      lTool.Execute(lInput, lOutput);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
    AssertTrue('disabled control must raise EMCPException', lRaised);
    AssertEquals('message must be SErrControlDisabled', SErrControlDisabled, lMessage);
    AssertEquals('the gate must fire before any OS call', 0, lTool.InjectCount);
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestInjectOsClickWhenControlDisabledRaises;

var
  lTool : TProbeInjectOsClickTool;
  lInput, lOutput : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #4: same as the key gate test, with the click tool. InjectCount = 0 proves the gate fired
  // before any OS call regardless of backend availability.
  SetGUIControlAllowed(False);
  lRaised := False;
  lMessage := '';
  lTool := TProbeInjectOsClickTool.Create('injectOsClick', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA.OkButton']);
  lOutput := TJSONObject.Create;
  try
    try
      lTool.Execute(lInput, lOutput);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
    AssertTrue('disabled control must raise EMCPException', lRaised);
    AssertEquals('message must be SErrControlDisabled', SErrControlDisabled, lMessage);
    AssertEquals('the gate must fire before any OS call', 0, lTool.InjectCount);
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestInjectOsKeyUnknownTargetRaises;

var
  lParsed : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #5: gate ON; an unresolved target raises EMCPException (SErrLocatorNotFound) surfaced
  // unchanged - NOT masked as SErrOSInputUnavailable. One unknown-target test covers the shared
  // ResolveTarget path for both OS tools (an injectOsClick duplicate would be redundant).
  lRaised := False;
  lMessage := '';
  lParsed := Nil;
  try
    try
      lParsed := RunInjectOsKey('NoSuchForm', $FF0D);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
  finally
    lParsed.Free;
  end;
  AssertTrue('unknown target must raise EMCPException', lRaised);
  AssertTrue('error message names the missing target', Pos('NoSuchForm', lMessage) > 0);
end;


procedure TMCPControlToolsTest.TestInjectOsKeyMarshalsToMainThread;

var
  lTool : TProbeInjectOsKeyTool;
  lInput, lOutput : TJSONObject;
  lWorker : TControlMarshalWorker;
  lIterations : Integer;

begin
  // AC #6: drive the tool from a worker thread; it must hop to the main thread via RunOnMainThread,
  // so InjectOnMain runs on MainThreadID. Do NOT assert Returned/ErrMsg='': when no backend is
  // available inherited InjectOnMain raises SErrOSInputUnavailable (environment-dependent); the
  // thread id (recorded before inherited) is the invariant the hop test proves.
  lTool := TProbeInjectOsKeyTool.Create('injectOsKey', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA.OkButton', 'key', $FF0D]);
  lOutput := TJSONObject.Create;
  try
    lWorker := TControlMarshalWorker.Create(lTool, lInput, lOutput);
    try
      lIterations := 0;
      while (not lWorker.Finished) and (lIterations < 100) do // 100 * 50ms = 5s hard ceiling
        begin
        CheckSynchronize(50);
        Inc(lIterations);
        end;
      if not lWorker.Finished then
        Fail('Worker did not finish within the drain ceiling - possible hang');
      lWorker.WaitFor;
      AssertEquals('InjectOnMain must run on the main thread', MainThreadID, lTool.InjectThreadId);
    finally
      lWorker.Free;
    end;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPControlToolsTest.TestInjectOsClickMarshalsToMainThread;

var
  lTool : TProbeInjectOsClickTool;
  lInput, lOutput : TJSONObject;
  lWorker : TControlMarshalWorker;
  lIterations : Integer;

begin
  // AC #6: same shape as the key hop test, with the click tool. The thread id (recorded before
  // inherited) is the invariant; backend availability is irrelevant to it.
  lTool := TProbeInjectOsClickTool.Create('injectOsClick', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA.OkButton']);
  lOutput := TJSONObject.Create;
  try
    lWorker := TControlMarshalWorker.Create(lTool, lInput, lOutput);
    try
      lIterations := 0;
      while (not lWorker.Finished) and (lIterations < 100) do // 100 * 50ms = 5s hard ceiling
        begin
        CheckSynchronize(50);
        Inc(lIterations);
        end;
      if not lWorker.Finished then
        Fail('Worker did not finish within the drain ceiling - possible hang');
      lWorker.WaitFor;
      AssertEquals('InjectOnMain must run on the main thread', MainThreadID, lTool.InjectThreadId);
    finally
      lWorker.Free;
    end;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;

{$ENDIF}

initialization
{$IFDEF MCP_GUICONTROL}
  RegisterTest(TMCPControlToolsTest);
{$ENDIF}
end.

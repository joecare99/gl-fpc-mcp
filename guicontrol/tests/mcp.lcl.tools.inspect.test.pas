{
    This file is part of the Free Component Library

    MCP LCL control - inspection tools tests
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.tools.inspect.test;

{$mode objfpc}{$H+}

interface

{$IFDEF MCP_GUICONTROL}
uses
  TestRegistry, Classes, SysUtils, fpjson, jsonparser, fpcunit, base64,
  Forms, Controls, StdCtrls, mcp.types, mcp.tools, mcp.lcl.tools.inspect, mcp.lcl.mainthread,
  mcp.lcl.locator, mcp.lcl.accessors, mcp.lcl.strings;

type

  { TMCPInspectToolsTest }

  TMCPInspectToolsTest = class(TTestCase)
  private
    FFormA : TForm;
    FFormB : TForm;
    FDataModule : TDataModule;
    // Runs aTool.Execute and returns the parsed inner JSON object (the caller
    // owns and must free it). aTool is freed before returning.
    function RunTool(aTool : TMCPTool) : TJSONObject;
    // Drives readProperty with the given target/property and returns the parsed
    // inner JSON object (the caller owns and must free it).
    function RunReadProperty(const aTarget, aProperty : String) : TJSONObject;
    // Drives snapshotForm with the given target and returns the parsed inner JSON
    // object (the caller owns and must free it).
    function RunSnapshotForm(const aTarget : String) : TJSONObject;
    // Drives findControls with aInput (which the helper takes ownership of and frees) and
    // returns the parsed inner JSON object (the caller owns and must free it).
    function RunFindControls(aInput : TJSONObject) : TJSONObject;
    // Drives readAccessor with the given target/name and returns the parsed inner JSON
    // object (the caller owns and must free it).
    function RunReadAccessor(const aTarget, aName : String) : TJSONObject;
    // Drives screenshot with the given target and returns the base64-decoded PNG bytes
    // (the content[0].data member). Fails the test if the image envelope is missing.
    function RunScreenshot(const aTarget : String) : TBytes;
    // Finds the array entry whose 'name' member equals aName, or Nil if absent.
    function FindEntryByName(aArray : TJSONArray; const aName : String) : TJSONObject;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestListFormsIncludesFixtureForm;
    procedure TestListDataModulesIncludesFixture;
    procedure TestListDataModulesEmptyWhenNoneReturnsEmptyArray;
    procedure TestListFormsMarshalsToMainThread;
    procedure TestReadPropertyStringViaLocator;
    procedure TestReadPropertyBooleanViaLocator;
    procedure TestReadPropertyNestedControlViaDotPath;
    procedure TestReadPropertyUnknownPropertyRaises;
    procedure TestReadPropertyUnknownTargetRaises;
    procedure TestSnapshotFormReturnsLFMWithChildControl;
    procedure TestSnapshotFormUnknownTargetRaises;
    procedure TestScreenshotReturnsPngMatchingControlSize;
    procedure TestScreenshotUnknownTargetRaises;
    procedure TestScreenshotNonControlTargetRaises;
    procedure TestFindControlsByClassNameRoundTrips;
    procedure TestFindControlsUnnamedControlRoundTripsByIndex;
    procedure TestFindControlsByCaptionSubstring;
    procedure TestFindControlsByEnabledState;
    procedure TestFindControlsNoMatchReturnsEmptyArray;
    procedure TestFindControlsMarshalsToMainThread;
    procedure TestReadAccessorReturnsValue;
    procedure TestReadAccessorUnknownNameRaises;
    procedure TestReadAccessorUnknownTargetRaises;
    procedure TestReadAccessorMarshalsToMainThread;
  end;

implementation

type

  { TProbeListFormsTool }

  // Test-only subclass that records which thread CollectForms ran on, so the
  // marshalled-from-a-worker test can prove the LCL access happened on the main thread.
  TProbeListFormsTool = class(TListFormsTool)
  private
    FCollectThreadId : TThreadID;
  protected
    procedure CollectForms; override;
  public
    // Thread id on which CollectForms last executed.
    property CollectThreadId : TThreadID read FCollectThreadId;
  end;

  { TProbeFindControlsTool }

  // Test-only subclass that records which thread BuildMatches ran on, so the
  // marshalled-from-a-worker test can prove the LCL walk happened on the main thread.
  TProbeFindControlsTool = class(TFindControlsTool)
  private
    FBuildThreadId : TThreadID;
  protected
    procedure BuildMatches; override;
  public
    // Thread id on which BuildMatches last executed.
    property BuildThreadId : TThreadID read FBuildThreadId;
  end;

  { TProbeReadAccessorTool }

  // Test-only subclass that records which thread ReadOnMain ran on, so the
  // marshalled-from-a-worker test can prove the registry read happened on the main thread.
  TProbeReadAccessorTool = class(TReadAccessorTool)
  private
    FReadThreadId : TThreadID;
  protected
    procedure ReadOnMain; override;
  public
    // Thread id on which ReadOnMain last executed.
    property ReadThreadId : TThreadID read FReadThreadId;
  end;

  { TInspectMarshalWorker }

  // Worker thread that drives a tool's public Execute (which internally hops to
  // the main thread via RunOnMainThread) and recaptures any exception so the
  // main (test) thread can assert on it after WaitFor.
  TInspectMarshalWorker = class(TThread)
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


procedure TProbeListFormsTool.CollectForms;

begin
  FCollectThreadId := GetCurrentThreadID;
  inherited CollectForms;
end;


procedure TProbeFindControlsTool.BuildMatches;

begin
  FBuildThreadId := GetCurrentThreadID;
  inherited BuildMatches;
end;


var
  // Backing store for the test accessor registered against the fixture form's class. The shared
  // fixture forms have no spare non-published field, so the getter/setter read/write this module
  // global - proving the tool->registry->getter wiring end-to-end without touching the fixtures.
  GInspectAccessorState : string;

// Module-level getter for the 'probe' accessor: returns the module-global backing store.
function InspectAccessorGet(aInstance: TObject): string;

begin
  Result := GInspectAccessorState;
end;


// Module-level setter for the 'probe' accessor: writes the module-global backing store.
procedure InspectAccessorSet(aInstance: TObject; const aValue: string);

begin
  GInspectAccessorState := aValue;
end;


procedure TProbeReadAccessorTool.ReadOnMain;

begin
  FReadThreadId := GetCurrentThreadID;
  inherited ReadOnMain;
end;


constructor TInspectMarshalWorker.Create(aTool : TMCPTool; aInput, aResult : TJSONObject);

begin
  FTool := aTool;
  FInput := aInput;
  FResult := aResult;
  inherited Create(False);
end;


procedure TInspectMarshalWorker.Execute;

begin
  try
    FTool.Execute(FInput, FResult);
    FReturned := True;
  except
    on E : Exception do
      FErrMsg := E.Message;
  end;
end;


{ TMCPInspectToolsTest }

procedure TMCPInspectToolsTest.SetUp;

begin
  inherited SetUp;
  FFormA := TForm.CreateNew(nil);
  FFormA.Name := 'FixtureFormA';
  FFormA.Caption := 'Fixture Form A';
  FFormA.Visible := False;
  FFormB := TForm.CreateNew(nil);
  FFormB.Name := 'FixtureFormB';
  FFormB.Caption := 'Fixture Form B';
  FFormB.Visible := False;
  FDataModule := TDataModule.Create(nil);
  FDataModule.Name := 'FixtureDataModule';
  // Register a test accessor against the fixture form's class for the readAccessor tests; reset
  // the registry both ends (it is a process-global - isolate it like the singleton registries).
  ClearAccessors;
  GInspectAccessorState := '';
  RegisterAccessor(TForm, 'probe', @InspectAccessorGet, @InspectAccessorSet);
end;


procedure TMCPInspectToolsTest.TearDown;

begin
  ClearAccessors;
  FreeAndNil(FFormA);
  FreeAndNil(FFormB);
  FreeAndNil(FDataModule);
  inherited TearDown;
end;


function TMCPInspectToolsTest.RunTool(aTool : TMCPTool) : TJSONObject;

var
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  try
    lInput := TJSONObject.Create;
    lOutput := TJSONObject.Create;
    aTool.Execute(lInput, lOutput);
    lContent := lOutput.FindPath('content[0].text');
    if lContent = Nil then
      Fail('tool result is missing the content[0].text envelope');
    Result := GetJSON(lContent.AsString) as TJSONObject;
  finally
    lInput.Free;
    lOutput.Free;
    aTool.Free;
  end;
end;


function TMCPInspectToolsTest.RunReadProperty(const aTarget, aProperty : String) : TJSONObject;

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


function TMCPInspectToolsTest.RunSnapshotForm(const aTarget : String) : TJSONObject;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TSnapshotFormTool.Create('snapshotForm', 'x');
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


function TMCPInspectToolsTest.RunFindControls(aInput : TJSONObject) : TJSONObject;

var
  lTool : TMCPTool;
  lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lOutput := Nil;
  lTool := TFindControlsTool.Create('findControls', 'x');
  try
    lOutput := TJSONObject.Create;
    lTool.Execute(aInput, lOutput);
    lContent := lOutput.FindPath('content[0].text');
    if lContent = Nil then
      Fail('tool result is missing the content[0].text envelope');
    Result := GetJSON(lContent.AsString) as TJSONObject;
  finally
    aInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


function TMCPInspectToolsTest.RunScreenshot(const aTarget : String) : TBytes;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lType, lMime, lData : TJSONData;
  lDecoded : AnsiString;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TScreenshotTool.Create('screenshot', 'x');
  try
    lInput := TJSONObject.Create(['target', aTarget]);
    lOutput := TJSONObject.Create;
    lTool.Execute(lInput, lOutput);
    // Nil-guard each member before AsString so a regressed (e.g. text) envelope fails
    // cleanly via Fail instead of an access violation on a missing node.
    lType := lOutput.FindPath('content[0].type');
    if lType = Nil then
      Fail('image result is missing the content[0].type envelope');
    AssertEquals('content[0].type must be image', 'image', lType.AsString);
    lMime := lOutput.FindPath('content[0].mimeType');
    if lMime = Nil then
      Fail('image result is missing the content[0].mimeType envelope');
    AssertEquals('content[0].mimeType must be image/png', 'image/png', lMime.AsString);
    lData := lOutput.FindPath('content[0].data');
    if lData = Nil then
      Fail('image result is missing the content[0].data envelope');
    lDecoded := DecodeStringBase64(lData.AsString);
    SetLength(Result, Length(lDecoded));
    if Length(lDecoded) > 0 then
      Move(lDecoded[1], Result[0], Length(lDecoded));
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


function TMCPInspectToolsTest.FindEntryByName(aArray : TJSONArray; const aName : String) : TJSONObject;

var
  I : Integer;
  lEntry : TJSONObject;

begin
  Result := Nil;
  for I := 0 to aArray.Count - 1 do
    begin
    lEntry := aArray.Objects[I];
    if lEntry.Get('name', '') = aName then
      Exit(lEntry);
    end;
end;


procedure TMCPInspectToolsTest.TestListFormsIncludesFixtureForm;

var
  lParsed : TJSONObject;
  lForms : TJSONArray;
  lEntry : TJSONObject;

begin
  // AC #1: listForms returns {forms:[{name,class,caption,visible}, ...]} including
  // both fixture forms; assert by searching for the known names (the LCL may track
  // other forms, so never assume length or position).
  lParsed := RunTool(TListFormsTool.Create('listForms', 'x'));
  try
    AssertNotNull('result must carry a forms member', lParsed.Find('forms'));
    lForms := lParsed.Arrays['forms'];
    lEntry := FindEntryByName(lForms, 'FixtureFormA');
    AssertNotNull('forms must include FixtureFormA', lEntry);
    AssertEquals('FixtureFormA class', 'TForm', lEntry.Get('class', ''));
    AssertEquals('FixtureFormA caption', 'Fixture Form A', lEntry.Get('caption', ''));
    AssertEquals('FixtureFormA visible JSON type', Ord(jtBoolean), Ord(lEntry.Find('visible').JSONType));
    AssertFalse('FixtureFormA visible value', lEntry.Get('visible', True));
    AssertNotNull('forms must include FixtureFormB', FindEntryByName(lForms, 'FixtureFormB'));
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestListDataModulesIncludesFixture;

var
  lParsed : TJSONObject;
  lModules : TJSONArray;
  lEntry : TJSONObject;

begin
  // AC #2: listDataModules returns {dataModules:[{name,class}, ...]} including the fixture.
  lParsed := RunTool(TListDataModulesTool.Create('listDataModules', 'x'));
  try
    AssertNotNull('result must carry a dataModules member', lParsed.Find('dataModules'));
    lModules := lParsed.Arrays['dataModules'];
    lEntry := FindEntryByName(lModules, 'FixtureDataModule');
    AssertNotNull('dataModules must include FixtureDataModule', lEntry);
    AssertEquals('FixtureDataModule class', 'TDataModule', lEntry.Get('class', ''));
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestListDataModulesEmptyWhenNoneReturnsEmptyArray;

var
  lParsed : TJSONObject;

begin
  // AC #3: with no datamodules present the tool must return an empty array under
  // 'dataModules' - it must NOT raise and must NOT omit the key.
  FreeAndNil(FDataModule);
  lParsed := RunTool(TListDataModulesTool.Create('listDataModules', 'x'));
  try
    AssertNotNull('dataModules key must be present', lParsed.Find('dataModules'));
    AssertEquals('dataModules must be an empty array', 0, lParsed.Arrays['dataModules'].Count);
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestListFormsMarshalsToMainThread;

var
  lTool : TProbeListFormsTool;
  lInput, lOutput : TJSONObject;
  lWorker : TInspectMarshalWorker;
  lIterations : Integer;

begin
  // AC #4: drive the tool from a worker thread; it must hop to the main thread via
  // RunOnMainThread, so CollectForms runs on MainThreadID. Drain on the main (test)
  // thread with a bounded ceiling so a buggy bridge fails the test rather than hangs it.
  lTool := TProbeListFormsTool.Create('listForms', 'x');
  lInput := TJSONObject.Create;
  lOutput := TJSONObject.Create;
  try
    lWorker := TInspectMarshalWorker.Create(lTool, lInput, lOutput);
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
      AssertEquals('CollectForms must run on the main thread', MainThreadID, lTool.CollectThreadId);
    finally
      lWorker.Free;
    end;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestReadPropertyStringViaLocator;

var
  lParsed : TJSONObject;
  lValue : TJSONData;

begin
  // AC #1, #3: resolve a named root form via the shared locator and read a string
  // property; the value member must be a JSON string.
  lParsed := RunReadProperty('FixtureFormA', 'Caption');
  try
    lValue := lParsed.Find('value');
    AssertNotNull('result must carry a value member', lValue);
    AssertEquals('Caption is a JSON string', Ord(jtString), Ord(lValue.JSONType));
    AssertEquals('Caption value', 'Fixture Form A', lValue.AsString);
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestReadPropertyBooleanViaLocator;

var
  lParsed : TJSONObject;
  lValue : TJSONData;

begin
  // AC #1, #3: a Boolean property comes back as a JSON boolean (the fixture sets Visible := False).
  lParsed := RunReadProperty('FixtureFormA', 'Visible');
  try
    lValue := lParsed.Find('value');
    AssertNotNull('result must carry a value member', lValue);
    AssertEquals('Visible is a JSON boolean', Ord(jtBoolean), Ord(lValue.JSONType));
    AssertFalse('Visible value', lValue.AsBoolean);
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestReadPropertyNestedControlViaDotPath;

var
  lBtn : TButton;
  lParsed : TJSONObject;
  lValue : TJSONData;

begin
  // AC #3: a multi-segment dot-path resolves through the locator's visual Controls[]
  // model. The form owns lBtn (freed at TearDown).
  lBtn := TButton.Create(FFormA);
  lBtn.Name := 'OkButton';
  lBtn.Parent := FFormA;
  lBtn.Caption := 'Click me';
  lParsed := RunReadProperty('FixtureFormA.OkButton', 'Caption');
  try
    lValue := lParsed.Find('value');
    AssertNotNull('result must carry a value member', lValue);
    AssertEquals('nested control Caption', 'Click me', lValue.AsString);
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestReadPropertyUnknownPropertyRaises;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lRaised : Boolean;

begin
  // AC #2: an unknown property raises EMCPException (SErrNoProperty); Execute does not
  // swallow it. Driven from the main thread, RunOnMainThread short-circuits inline.
  lRaised := False;
  lTool := TReadPropertyTool.Create('readProperty', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA', 'property', 'NoSuchProp']);
  lOutput := TJSONObject.Create;
  try
    try
      lTool.Execute(lInput, lOutput);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        AssertTrue('error message names the missing property', Pos('NoSuchProp', E.Message) > 0);
        end;
    end;
    AssertTrue('unknown property must raise EMCPException', lRaised);
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestReadPropertyUnknownTargetRaises;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lRaised : Boolean;

begin
  // AC #2: an unresolved target raises EMCPException (SErrLocatorNotFound) from the
  // shared locator, surfaced unchanged.
  lRaised := False;
  lTool := TReadPropertyTool.Create('readProperty', 'x');
  lInput := TJSONObject.Create(['target', 'NoSuchForm', 'property', 'Caption']);
  lOutput := TJSONObject.Create;
  try
    try
      lTool.Execute(lInput, lOutput);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        AssertTrue('error message names the missing target', Pos('NoSuchForm', E.Message) > 0);
        end;
    end;
    AssertTrue('unknown target must raise EMCPException', lRaised);
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestSnapshotFormReturnsLFMWithChildControl;

var
  lBtn : TButton;
  lParsed : TJSONObject;
  lLfmData : TJSONData;
  lLfm : String;

begin
  // AC #1, #2, #3: snapshot a named root form (resolved via the shared locator) to LFM
  // text; the lfm member is a JSON string whose text looks like LFM, names the root form
  // and includes a nested child control. The form owns lBtn (freed at TearDown).
  lBtn := TButton.Create(FFormA);
  lBtn.Name := 'OkButton';
  lBtn.Parent := FFormA;
  lBtn.Caption := 'Click me';
  lParsed := RunSnapshotForm('FixtureFormA');
  try
    lLfmData := lParsed.Find('lfm');
    AssertNotNull('result must carry an lfm member', lLfmData);
    AssertEquals('lfm is a JSON string', Ord(jtString), Ord(lLfmData.JSONType));
    lLfm := lLfmData.AsString;
    AssertTrue('lfm looks like LFM text', Pos('object', lLfm) > 0);
    AssertTrue('lfm names the root form', Pos('FixtureFormA', lLfm) > 0);
    AssertTrue('lfm includes the child control', Pos('OkButton', lLfm) > 0);
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestSnapshotFormUnknownTargetRaises;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lRaised : Boolean;

begin
  // AC #2: an unresolved target raises EMCPException (SErrLocatorNotFound) from the
  // shared locator, surfaced unchanged. Driven from the main thread, RunOnMainThread
  // short-circuits inline so the exception surfaces synchronously.
  lRaised := False;
  lTool := TSnapshotFormTool.Create('snapshotForm', 'x');
  lInput := TJSONObject.Create(['target', 'NoSuchForm']);
  lOutput := TJSONObject.Create;
  try
    try
      lTool.Execute(lInput, lOutput);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        AssertTrue('error message names the missing target', Pos('NoSuchForm', E.Message) > 0);
        end;
    end;
    AssertTrue('unknown target must raise EMCPException', lRaised);
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


function ReadBE32(const aBytes : TBytes; aOffset : Integer) : LongWord;
// Reads a big-endian 32-bit unsigned integer from aBytes at aOffset (PNG fields are BE).

begin
  Result := (LongWord(aBytes[aOffset]) shl 24) or (LongWord(aBytes[aOffset + 1]) shl 16)
    or (LongWord(aBytes[aOffset + 2]) shl 8) or LongWord(aBytes[aOffset + 3]);
end;


procedure TMCPInspectToolsTest.TestScreenshotReturnsPngMatchingControlSize;

var
  lBtn : TButton;
  lPng : TBytes;

begin
  // AC #1, #2, #3, #5: screenshot a located, sized child control. The result must be a
  // valid PNG (8-byte signature) whose IHDR width/height equal the control's Width/Height.
  // Resolving 'FixtureFormA.ShotButton' also exercises the dot-path locator (AC #3).
  lBtn := TButton.Create(FFormA);
  lBtn.Name := 'ShotButton';
  lBtn.Parent := FFormA;
  lBtn.SetBounds(0, 0, 120, 40);
  lPng := RunScreenshot('FixtureFormA.ShotButton');
  AssertTrue('PNG must hold at least signature + IHDR', Length(lPng) >= 24);
  AssertEquals('PNG signature byte 0', 137, lPng[0]);
  AssertEquals('PNG signature byte 1', 80, lPng[1]);
  AssertEquals('PNG signature byte 2', 78, lPng[2]);
  AssertEquals('PNG signature byte 3', 71, lPng[3]);
  AssertEquals('PNG signature byte 4', 13, lPng[4]);
  AssertEquals('PNG signature byte 5', 10, lPng[5]);
  AssertEquals('PNG signature byte 6', 26, lPng[6]);
  AssertEquals('PNG signature byte 7', 10, lPng[7]);
  AssertEquals('IHDR width equals control Width', LongWord(lBtn.Width), ReadBE32(lPng, 16));
  AssertEquals('IHDR height equals control Height', LongWord(lBtn.Height), ReadBE32(lPng, 20));
end;


procedure TMCPInspectToolsTest.TestScreenshotUnknownTargetRaises;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lRaised : Boolean;

begin
  // AC #3: an unresolved target raises EMCPException (SErrLocatorNotFound) from the shared
  // locator, surfaced unchanged. Driven from the main thread, RunOnMainThread short-circuits.
  lRaised := False;
  lTool := TScreenshotTool.Create('screenshot', 'x');
  lInput := TJSONObject.Create(['target', 'NoSuchForm']);
  lOutput := TJSONObject.Create;
  try
    try
      lTool.Execute(lInput, lOutput);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        AssertTrue('error message names the missing target', Pos('NoSuchForm', E.Message) > 0);
        end;
    end;
    AssertTrue('unknown target must raise EMCPException', lRaised);
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestScreenshotNonControlTargetRaises;

var
  lLbl : TLabel;
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lRaised : Boolean;

begin
  // AC #4: a target resolving to a non-TWinControl raises EMCPException (SErrNotAControl).
  // A TLabel is a TGraphicControl (a TControl, NOT a TWinControl): parented to the form it
  // is reachable via the locator's visual Controls[] model, yet has no PaintTo - so it is the
  // in-fixture non-paintable target. (A plain TComponent child is owned but not parented, so
  // it never appears in a TWinControl's Controls[] and would resolve to SErrLocatorNotFound
  // instead - the wrong error - hence the TLabel choice; see Completion Notes.)
  lLbl := TLabel.Create(FFormA);
  lLbl.Name := 'PlainLabel';
  lLbl.Parent := FFormA;
  lRaised := False;
  lTool := TScreenshotTool.Create('screenshot', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA.PlainLabel']);
  lOutput := TJSONObject.Create;
  try
    try
      lTool.Execute(lInput, lOutput);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        AssertTrue('error message names the non-control target', Pos('PlainLabel', E.Message) > 0);
        end;
    end;
    AssertTrue('non-control target must raise EMCPException', lRaised);
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestFindControlsByClassNameRoundTrips;

var
  lBtn : TButton;
  lParsed : TJSONObject;
  lControls : TJSONArray;
  lEntry : TJSONObject;
  lLocator : String;

begin
  // AC #1, #2: a className query returns the fixture control AND its returned locator
  // round-trips through ResolveTarget back to the SAME instance (the defining property).
  // The form owns lBtn (freed at TearDown).
  lBtn := TButton.Create(FFormA);
  lBtn.Name := 'SaveButton';
  lBtn.Parent := FFormA;
  lBtn.Caption := 'Save';
  lParsed := RunFindControls(TJSONObject.Create(['className', 'TButton']));
  try
    AssertNotNull('result must carry a controls member', lParsed.Find('controls'));
    lControls := lParsed.Arrays['controls'];
    lEntry := FindEntryByName(lControls, 'SaveButton');
    AssertNotNull('controls must include SaveButton', lEntry);
    AssertEquals('SaveButton class', 'TButton', lEntry.Get('class', ''));
    lLocator := lEntry.Get('locator', '');
    AssertTrue('locator round-trips to the same control', ResolveTarget(lLocator) = lBtn);
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestFindControlsUnnamedControlRoundTripsByIndex;

var
  lBtn : TButton;
  lParsed : TJSONObject;
  lControls : TJSONArray;
  lEntry : TJSONObject;
  lLocator : String;

begin
  // AC #2 (bracket-fallback half): an UNNAMED control must come back with a positional
  // bracket locator (no '.Name' step) that ALSO round-trips through ResolveTarget to the
  // same instance. The className test proves the dot-path half; this proves the index half.
  // The unique caption lets us find the (nameless) entry. The form owns lBtn (freed at TearDown).
  lBtn := TButton.Create(FFormA);
  lBtn.Parent := FFormA;
  lBtn.Caption := 'ZZUnnamedFindFixture';
  lParsed := RunFindControls(TJSONObject.Create(['caption', 'ZZUnnamedFindFixture']));
  try
    AssertNotNull('result must carry a controls member', lParsed.Find('controls'));
    lControls := lParsed.Arrays['controls'];
    AssertEquals('exactly one control matches the unique caption', 1, lControls.Count);
    lEntry := lControls.Objects[0];
    AssertEquals('matched control is unnamed', '', lEntry.Get('name', 'x'));
    lLocator := lEntry.Get('locator', '');
    AssertTrue('unnamed control must use a positional bracket step, not a dot-name',
      Pos('[', lLocator) > 0);
    AssertTrue('bracket locator round-trips to the same control', ResolveTarget(lLocator) = lBtn);
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestFindControlsByCaptionSubstring;

var
  lSaveBtn, lCancelBtn : TButton;
  lParsed : TJSONObject;
  lControls : TJSONArray;

begin
  // AC #1: a caption substring filter is case-insensitive and matches only the intended
  // control. The form owns both buttons (freed at TearDown).
  lSaveBtn := TButton.Create(FFormA);
  lSaveBtn.Name := 'SaveDocBtn';
  lSaveBtn.Parent := FFormA;
  lSaveBtn.Caption := 'Save Document';
  lCancelBtn := TButton.Create(FFormA);
  lCancelBtn.Name := 'CancelBtn';
  lCancelBtn.Parent := FFormA;
  lCancelBtn.Caption := 'Cancel';
  lParsed := RunFindControls(TJSONObject.Create(['caption', 'doc']));
  try
    AssertNotNull('result must carry a controls member', lParsed.Find('controls'));
    lControls := lParsed.Arrays['controls'];
    AssertNotNull('controls must include SaveDocBtn', FindEntryByName(lControls, 'SaveDocBtn'));
    AssertNull('controls must NOT include CancelBtn', FindEntryByName(lControls, 'CancelBtn'));
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestFindControlsByEnabledState;

var
  lOnBtn, lOffBtn : TButton;
  lParsed : TJSONObject;
  lControls : TJSONArray;

begin
  // AC #1: an enabled filter selects by the published Enabled state. The form owns both
  // buttons (freed at TearDown).
  lOnBtn := TButton.Create(FFormA);
  lOnBtn.Name := 'OnBtn';
  lOnBtn.Parent := FFormA;
  lOffBtn := TButton.Create(FFormA);
  lOffBtn.Name := 'OffBtn';
  lOffBtn.Parent := FFormA;
  lOffBtn.Enabled := False;
  lParsed := RunFindControls(TJSONObject.Create(['className', 'TButton', 'enabled', False]));
  try
    AssertNotNull('result must carry a controls member', lParsed.Find('controls'));
    lControls := lParsed.Arrays['controls'];
    AssertNotNull('controls must include OffBtn', FindEntryByName(lControls, 'OffBtn'));
    AssertNull('controls must NOT include OnBtn', FindEntryByName(lControls, 'OnBtn'));
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestFindControlsNoMatchReturnsEmptyArray;

var
  lParsed : TJSONObject;

begin
  // AC #3: a query matching nothing returns an empty array under 'controls' - it must NOT
  // raise and must NOT omit the key.
  lParsed := RunFindControls(TJSONObject.Create(['className', 'TNoSuchControlClass']));
  try
    AssertNotNull('controls key must be present', lParsed.Find('controls'));
    AssertEquals('controls must be an empty array', 0, lParsed.Arrays['controls'].Count);
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestFindControlsMarshalsToMainThread;

var
  lTool : TProbeFindControlsTool;
  lInput, lOutput : TJSONObject;
  lWorker : TInspectMarshalWorker;
  lIterations : Integer;

begin
  // AC #5: drive the tool from a worker thread; it must hop to the main thread via
  // RunOnMainThread, so BuildMatches runs on MainThreadID. Drain on the main (test)
  // thread with a bounded ceiling so a buggy bridge fails the test rather than hangs it.
  lTool := TProbeFindControlsTool.Create('findControls', 'x');
  lInput := TJSONObject.Create;
  lOutput := TJSONObject.Create;
  try
    lWorker := TInspectMarshalWorker.Create(lTool, lInput, lOutput);
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
      AssertEquals('BuildMatches must run on the main thread', MainThreadID, lTool.BuildThreadId);
    finally
      lWorker.Free;
    end;
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


function TMCPInspectToolsTest.RunReadAccessor(const aTarget, aName : String) : TJSONObject;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lContent : TJSONData;

begin
  Result := Nil;
  lInput := Nil;
  lOutput := Nil;
  lTool := TReadAccessorTool.Create('readAccessor', 'x');
  try
    lInput := TJSONObject.Create(['target', aTarget, 'name', aName]);
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


procedure TMCPInspectToolsTest.TestReadAccessorReturnsValue;

var
  lParsed : TJSONObject;
  lValue : TJSONData;

begin
  // AC #1: readAccessor resolves the fixture form via the shared locator, calls the registered
  // getter and returns its value as {value:<string>}.
  GInspectAccessorState := 'live';
  lParsed := RunReadAccessor('FixtureFormA', 'probe');
  try
    lValue := lParsed.Find('value');
    AssertNotNull('result must carry a value member', lValue);
    AssertEquals('value is a JSON string', Ord(jtString), Ord(lValue.JSONType));
    AssertEquals('value is the getter result', 'live', lValue.AsString);
  finally
    lParsed.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestReadAccessorUnknownNameRaises;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #3: an unregistered name raises EMCPException (SErrNoAccessor) naming the accessor.
  lRaised := False;
  lMessage := '';
  lTool := TReadAccessorTool.Create('readAccessor', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA', 'name', 'nope']);
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
    AssertTrue('unknown name must raise EMCPException', lRaised);
    AssertEquals('message must be SErrNoAccessor for the name', Format(SErrNoAccessor, ['nope']), lMessage);
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestReadAccessorUnknownTargetRaises;

var
  lTool : TMCPTool;
  lInput, lOutput : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #5: an unresolved target raises EMCPException (SErrLocatorNotFound) from the shared locator,
  // surfaced unchanged - NOT masked as SErrNoAccessor.
  lRaised := False;
  lMessage := '';
  lTool := TReadAccessorTool.Create('readAccessor', 'x');
  lInput := TJSONObject.Create(['target', 'NoSuchForm', 'name', 'probe']);
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
    AssertTrue('unknown target must raise EMCPException', lRaised);
    AssertEquals('read error must surface unchanged, not as SErrNoAccessor',
      Format(SErrLocatorNotFound, ['NoSuchForm']), lMessage);
  finally
    lInput.Free;
    lOutput.Free;
    lTool.Free;
  end;
end;


procedure TMCPInspectToolsTest.TestReadAccessorMarshalsToMainThread;

var
  lTool : TProbeReadAccessorTool;
  lInput, lOutput : TJSONObject;
  lWorker : TInspectMarshalWorker;
  lIterations : Integer;

begin
  // AC #6: drive the tool from a worker thread; it must hop to the main thread via
  // RunOnMainThread, so ReadOnMain runs on MainThreadID. Drain on the main (test) thread with a
  // bounded ceiling so a buggy bridge fails the test rather than hangs it.
  GInspectAccessorState := 'marshalled';
  lTool := TProbeReadAccessorTool.Create('readAccessor', 'x');
  lInput := TJSONObject.Create(['target', 'FixtureFormA', 'name', 'probe']);
  lOutput := TJSONObject.Create;
  try
    lWorker := TInspectMarshalWorker.Create(lTool, lInput, lOutput);
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
      AssertEquals('ReadOnMain must run on the main thread', MainThreadID, lTool.ReadThreadId);
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
  RegisterTest(TMCPInspectToolsTest);
{$ENDIF}
end.

unit mcp.tools.test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson,
  mcp.types,
  mcp.strings,
  mcp.tools;

type





  TMockToolRegistry = class(TMCPToolRegistry)
  end;




  TTestConcreteTool = class(TMCPTool)
  private
    FMockDoExecuteResult: TJSONObject;
    FRecordedDoExecuteInput: TJSONObject;
  protected
    function DoExecute(aInput: TJSONObject): TJSONObject; override;
  public
    constructor Create(const aName, aDescription: string); override;
    destructor Destroy; override;

    property MockDoExecuteResult: TJSONObject write FMockDoExecuteResult;
    property RecordedDoExecuteInput: TJSONObject read FRecordedDoExecuteInput;
  end;


  { TMCPToolsTest }
  TMCPToolsTest = class(TTestCase)
  private
    FMockToolRegistry: TMockToolRegistry;
    FEventToolTriggered: Boolean;
    FEventToolReceivedInput: TJSONData;
    FEventToolSetOutput: TJSONData;
    procedure HandleToolInvocationEvent(aInput: TJSONData; var aOutput: TJSONData);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestToolCreationAndProperties;
    procedure TestToolMetaOwnership;
    procedure TestToolExecuteMethod;
    procedure TestEventToolCreation;
    procedure TestEventToolExecution;
    procedure TestToolRegistryAddFindRemove;
    procedure TestToolRegistryGetAndExceptions;
    procedure TestToolRegistryCountProperty;
    procedure TestToolRegistryLockUnlockList;
    procedure TestToolRegistryInitMethod;
  end;

implementation

uses
  TypInfo;

constructor TTestConcreteTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  FMockDoExecuteResult := nil;
  FRecordedDoExecuteInput := nil;
end;

destructor TTestConcreteTool.Destroy;
begin
  FreeAndNil(FMockDoExecuteResult);
  inherited Destroy;
end;

function TTestConcreteTool.DoExecute(aInput: TJSONObject): TJSONObject;
begin
  FreeAndNil(FRecordedDoExecuteInput);
  if Assigned(aInput) then
    FRecordedDoExecuteInput := aInput
  else
    FRecordedDoExecuteInput := nil;
  Result := FMockDoExecuteResult;
  FMockDoExecuteResult := nil;
end;

procedure TMCPToolsTest.HandleToolInvocationEvent(aInput: TJSONData; var aOutput: TJSONData);
begin
  FEventToolTriggered := True;
  FEventToolReceivedInput := aInput;
  if (aInput is TJSONObject) and ((aInput as TJSONObject).IndexOfName('input_value') <> -1) then
  begin
    aOutput := TJSONObject.Create;
    (aOutput as TJSONObject).Add('result', 'success');
    (aOutput as TJSONObject).Add('calculated_value', (aInput as TJSONObject).Get('input_value',0) * 10);
  end
  else
  begin
    aOutput := TJSONObject.Create;
    (aOutput as TJSONObject).Add('result', 'error');
  end;
  FEventToolSetOutput := aOutput;
end;

procedure TMCPToolsTest.SetUp;
begin
  inherited SetUp;
  FEventToolTriggered := False;
  FEventToolReceivedInput := nil;
  FEventToolSetOutput := nil;
  TMCPToolRegistry.Done;
  TMCPToolRegistry.Init(TMockToolRegistry);
  FMockToolRegistry:=TMCPToolRegistry.Instance as TMockToolRegistry;
end;

procedure TMCPToolsTest.TearDown;
begin
  TMCPToolRegistry.Done;
  FMockToolRegistry:=nil;
  FreeAndNil(FEventToolSetOutput);
  inherited TearDown;
end;

procedure TMCPToolsTest.TestToolCreationAndProperties;
var
  Tool: TTestConcreteTool;
  TestMeta: TJSONObject;
begin
  Tool := TTestConcreteTool.Create('test_tool_name', 'This is a test tool description.');
  TestMeta := TJSONObject.Create;
  TestMeta.Add('version', '1.0');
  TestMeta.Add('author', 'Tester');
  try
    AssertEquals('Name property should match constructor argument', 'test_tool_name', Tool.Name);
    AssertEquals('Description property should match constructor argument', 'This is a test tool description.', Tool.Description);
    AssertNotNull('InputSchema should be created', Tool.InputSchema);
    AssertNotNull('OutputSchema should be created', Tool.OutputSchema);
    AssertNull('_Meta should be nil by default', Tool._Meta);
    AssertFalse('Annotations should be uninitialized by default', Tool.Annotations.Initialized);
    Tool._Meta := TestMeta;
    AssertSame('_Meta property should return the assigned object', TestMeta, Tool._Meta);
    Tool.Annotations.Priority := True;
    Tool.Annotations.Roles:=Tool.Annotations.Roles+[prAssistant];
    AssertTrue('Annotations.Priority should be true', Tool.Annotations.Priority);
    AssertTrue('Annotations.Roles should include prAssistant', prAssistant in Tool.Annotations.Roles);
  finally
    Tool.Free;
  end;
end;

procedure TMCPToolsTest.TestToolMetaOwnership;
var
  Tool: TTestConcreteTool;
  Meta1, Meta2: TJSONObject;
begin
  Tool := TTestConcreteTool.Create('owner_tool', 'Tests _Meta ownership.');
  Meta1 := TJSONObject.Create;
  Meta1.Add('id', 1);
  Meta2 := TJSONObject.Create;
  Meta2.Add('id', 2);
  try
    Tool._Meta := Meta1;
    AssertSame('Tool should now own Meta1', Meta1, Tool._Meta);
    Tool._Meta := Meta2;
    AssertSame('Tool should now own Meta2', Meta2, Tool._Meta);
    Tool._Meta := nil;
    AssertNull('Tool should have no _Meta object', Tool._Meta);
  finally
    Tool.Free;
  end;
end;

procedure TMCPToolsTest.TestToolExecuteMethod;
var
  Tool: TTestConcreteTool;
  InputJson: TJSONObject;
  ExpectedOutputJson: TJSONObject;
  ActualOutputJson: TJSONObject;
begin
  ActualOutputJson:=Nil;
  InputJson:=Nil;
  Tool := TTestConcreteTool.Create('exec_tool', 'Tests the Execute method.');
  try
    InputJson := TJSONObject.Create;
    InputJson.Add('param1', 'value1');
    InputJson.Add('param2', 123);
    ExpectedOutputJson := TJSONObject.Create;
    ExpectedOutputJson.Add('status', 'OK');
    ExpectedOutputJson.Add('data', 'processed');
    Tool.MockDoExecuteResult := ExpectedOutputJson;
    ActualOutputJson := Tool.Execute(InputJson);
    AssertNotNull('Recorded input to DoExecute should not be nil', Tool.RecordedDoExecuteInput);
    AssertEquals('Recorded input param1 should match original', InputJson.Get('param1',''), Tool.RecordedDoExecuteInput.Get('param1',''));
    AssertEquals('Recorded input param2 should match original', InputJson.Get('param2',0), Tool.RecordedDoExecuteInput.Get('param2',0));
    AssertNotNull('Actual output from Execute should not be nil', ActualOutputJson);
    AssertSame('Actual output object should be the expected mock result', ExpectedOutputJson, ActualOutputJson);
    AssertEquals('Output status should be OK', 'OK', ActualOutputJson.Get('status',''));
    AssertEquals('Output data should be processed', 'processed', ActualOutputJson.Get('data',''));
  finally
    ActualOutputJson.Free;
    InputJson.Free;
    Tool.Free;
  end;
end;

Type
  TMyEventTool = Class(TMCPEventTool)
  public
    Property OnExecute;
  end;

procedure TMCPToolsTest.TestEventToolCreation;
var
  Tool: TMyEventTool;
begin
  Tool := TMyEventTool.Create('event_create_tool', 'Event tool description.', @HandleToolInvocationEvent);
  try
    AssertEquals('Name property should be set', 'event_create_tool', Tool.Name);
    AssertEquals('Description property should be set', 'Event tool description.', Tool.Description);
    AssertSame('OnExecute event should be assigned', TMethod(@HandleToolInvocationEvent).Code, TMethod(Tool.OnExecute).code);
  finally
    Tool.Free;
  end;
end;

procedure TMCPToolsTest.TestEventToolExecution;
var
  Tool: TMyEventTool;
  InputJson: TJSONObject;
  ActualOutputJson: TJSONObject;
begin
  InputJSON:=Nil;
  Tool := TMyEventTool.Create('event_exec_tool', 'Event tool for execution.', @HandleToolInvocationEvent);
  try
    InputJson := TJSONObject.Create;
    InputJson.Add('input_value', 5);
    InputJson.Add('some_other_key', 'hello');
    ActualOutputJson := Tool.Execute(InputJson);
    AssertTrue('HandleToolInvocationEvent should have been triggered', FEventToolTriggered);
    AssertSame('Input JSON received by event handler should be the same object as passed', InputJson, FEventToolReceivedInput);
    AssertNotNull('Actual output JSON should not be nil', ActualOutputJson);
    AssertSame('Actual output object should be the one set by the event handler', FEventToolSetOutput, ActualOutputJson);
    AssertTrue('Output should contain "result" key', ActualOutputJson.IndexOfName('result') <> -1);
    AssertEquals('Output result should be "success"', 'success', ActualOutputJson.Get('result',''));
    AssertTrue('Output should contain "calculated_value" key', ActualOutputJson.IndexOfName('calculated_value') <> -1);
    AssertEquals('Calculated value should be 50 (5 * 10)', 50, ActualOutputJson.Get('calculated_value',0));
  finally
    InputJson.Free;
    Tool.Free;
  end;
end;



procedure TMCPToolsTest.TestToolRegistryAddFindRemove;
var
  Tool1, Tool2: TMCPTool;
begin
  Tool1 := TTestConcreteTool.Create('tool_A', 'Description A');
  Tool2 := TTestConcreteTool.Create('tool_B', 'Description B');


  FMockToolRegistry.Add(Tool1);
  AssertEquals('Count should be 1 after adding tool_A', 1, FMockToolRegistry.Count);
  AssertSame('Find("tool_A") should return Tool1', Tool1, FMockToolRegistry.Find('tool_A'));
  AssertNull('Find("non_existent") should return nil', FMockToolRegistry.Find('non_existent'));

  FMockToolRegistry.Add(Tool2);
  AssertEquals('Count should be 2 after adding tool_B', 2, FMockToolRegistry.Count);
  AssertSame('Find("tool_B") should return Tool2', Tool2, FMockToolRegistry.Find('tool_B'));


  FMockToolRegistry.Remove('tool_A');
  AssertEquals('Count should be 1 after removing tool_A by name', 1, FMockToolRegistry.Count);
  AssertNull('Find("tool_A") should now return nil', FMockToolRegistry.Find('tool_A'));


  FMockToolRegistry.Remove(Tool2);
  AssertEquals('Count should be 0 after removing tool_B by object', 0, FMockToolRegistry.Count);
  AssertNull('Find("tool_B") should now return nil', FMockToolRegistry.Find('tool_B'));


end;

procedure TMCPToolsTest.TestToolRegistryGetAndExceptions;
var
  Tool: TMCPTool;
begin
  Tool := TTestConcreteTool.Create('get_me', 'A tool to be retrieved.');
  FMockToolRegistry.Add(Tool);


  AssertSame('Get("get_me") should return the correct tool', Tool, FMockToolRegistry.Get('get_me'));


  try
    FMockToolRegistry.Get('non_existent_tool_for_get');
    Fail('Expected EMCPException for Get of a non-existent tool.');
  except
    on E: EMCPException do
      AssertEquals('Exception message should indicate unknown tool', Format(SErrUnknownTool, ['non_existent_tool_for_get']), E.Message);
  end;

end;

procedure TMCPToolsTest.TestToolRegistryCountProperty;
var
  Tool1, Tool2: TMCPTool;
begin
  AssertEquals('Initial registry count should be 0', 0, FMockToolRegistry.Count);

  Tool1 := TTestConcreteTool.Create('count_tool_1', '');
  FMockToolRegistry.Add(Tool1);
  AssertEquals('Count should be 1 after adding one tool', 1, FMockToolRegistry.Count);

  Tool2 := TTestConcreteTool.Create('count_tool_2', '');
  FMockToolRegistry.Add(Tool2);
  AssertEquals('Count should be 2 after adding a second tool', 2, FMockToolRegistry.Count);

  FMockToolRegistry.Remove(Tool1);
  AssertEquals('Count should be 1 after removing one tool', 1, FMockToolRegistry.Count);

  FMockToolRegistry.Remove(Tool2);
  AssertEquals('Count should be 0 after removing all tools', 0, FMockToolRegistry.Count);
end;

procedure TMCPToolsTest.TestToolRegistryLockUnlockList;
var
  Tool1, Tool2, Tool3: TMCPTool;
  ToolArray: TMCPToolArray;
  FPList: TFPList;
begin
  Tool1 := TTestConcreteTool.Create('lock_tool_1', '');
  Tool2 := TTestConcreteTool.Create('lock_tool_2', '');
  Tool3 := TTestConcreteTool.Create('lock_tool_3', '');

  FMockToolRegistry.Add(Tool1);
  FMockToolRegistry.Add(Tool2);
  FMockToolRegistry.Add(Tool3);


  ToolArray := nil; // Ensure it's empty before locking
  FMockToolRegistry.LockList(ToolArray);
  try
    AssertEquals('Locked TMCPToolArray should have 3 elements', 3, Length(ToolArray));

    AssertTrue('Tool1 should be in the array', (ToolArray[0] = Tool1) or (ToolArray[1] = Tool1) or (ToolArray[2] = Tool1));
    AssertTrue('Tool2 should be in the array', (ToolArray[0] = Tool2) or (ToolArray[1] = Tool2) or (ToolArray[2] = Tool2));
    AssertTrue('Tool3 should be in the array', (ToolArray[0] = Tool3) or (ToolArray[1] = Tool3) or (ToolArray[2] = Tool3));
  finally
    FMockToolRegistry.UnlockList;
    // ToolArray does not need manual SetLength(0) as it's a local variable and will be managed.
  end;


  FPList := TFPList.Create;
  try
    FMockToolRegistry.LockList(FPList);
    try
      AssertEquals('Locked TFPList should have 3 elements', 3, FPList.Count);

      AssertTrue('Tool1 should be in the TFPList', FPList.IndexOf(Tool1)<>-1);
      AssertTrue('Tool2 should be in the TFPList', FPList.IndexOf(Tool2)<>-1);
      AssertTrue('Tool3 should be in the TFPList', FPList.IndexOf(Tool3)<>-1);
    finally
      FMockToolRegistry.UnlockList;
    end;
  finally
    FPList.Free;
  end;

end;

procedure TMCPToolsTest.TestToolRegistryInitMethod;
var
  TempInstance: TMCPToolRegistry;
begin

  TempInstance := TMCPToolRegistry.Instance;
  PPointer(@TMCPToolRegistry._instance)^ := nil;
  FreeAndNil(TempInstance);


  try
    TMCPToolRegistry.Init(TMCPToolRegistry);
    AssertNotNull('TMCPToolRegistry.Instance should not be nil after Init', TMCPToolRegistry.Instance);
    AssertTrue('Instance should be of TMCPToolRegistry type', TMCPToolRegistry.Instance is TMCPToolRegistry);
  except
    on E: Exception do
      Fail(Format('Unexpected exception during initial TMCPToolRegistry.Init: %s', [E.Message]));
  end;


  try
    TMCPToolRegistry.Init(TMCPToolRegistry);
    Fail('Expected EMCPException when Init is called on an already instantiated registry');
  except
    on E: EMCPException do
      AssertEquals('Exception message should be SErrRegistryALreadyInstantiated', SErrRegistryALreadyInstantiated, E.Message);
  end;


  FreeAndNil(PPointer(@TMCPToolRegistry._instance)^);


  try
    TMCPToolRegistry.Init(nil);
    Fail('Expected EMCPException when Init is called with a nil class');
  except
    on E: EMCPException do
      AssertEquals('Exception message should be SErrRegistryClassEmpty', SErrRegistryClassEmpty, E.Message);
  end;


end;


initialization
  RegisterTest(TMCPToolsTest);
end.

unit mcp.client.calls.test;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson, mcp.client.base, mcp.client.calls, mcp.types;

type

  { TMockTransport }
  TMockTransport = class(TMCPClientCustomTransport)
  protected
    procedure DoConnect; override;
    procedure DoDisconnect; override;
    procedure DoSendMessage(J: TJSONStringType); override;
    function DoGetMessage(out J: TJSONStringType): Boolean; override;
  end;

  { TMockClient }
  TMockClient = class(TMCPCustomClient)
  private
    FLastRequestArgs: TJSONObject;
    FMockRequestID: TRequestID;
    FLastRequest: TMCPCall;
    FLastRequestID: TRequestID;
  protected
    procedure DoRequest(aRequest: TMCPCall; aRequestID: TRequestID; aArgs: TJSONObject); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SimulateResponse(aRequestID: TRequestID; aResponse: TJSONObject);
    procedure SimulateError(aRequestID: TRequestID; const aError: TRPCError);
    property LastRequestArgs: TJSONObject read FLastRequestArgs;
    property LastRequest: TMCPCall read FLastRequest;
    property LastRequestID: TRequestID read FLastRequestID;
    property MockRequestID: TRequestID read FMockRequestID write FMockRequestID;
  end;

  { TMCPListToolsTest }
  TMCPListToolsTest = class(TTestCase)
  private
    FClient: TMockClient;
    FListTools: TMCPListTools;
    FCallbackExecuted: Boolean;
    FLastToolList: TMCPToolInfoList;
    FCallbackSender: TObject;
    FResponseCount: Integer;
    // Additional callback for multi-callback test
    FSecondCallbackExecuted: Boolean;
    FSecondToolList: TMCPToolInfoList;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure OnListToolsReply(aSender: TObject; aList: TMCPToolInfoList);
    procedure OnSecondListToolsReply(aSender: TObject; aList: TMCPToolInfoList);
    function CreateMockToolsResponse: TJSONObject;
    function CreateEmptyToolsResponse: TJSONObject;
    function CreateMalformedToolsResponse: TJSONObject;
  published
    // Basic functionality tests
    procedure TestMethodName;
    procedure TestListToolsCall;
    procedure TestListToolsCallWithEmptyArgs;

    // Response parsing tests
    procedure TestResponseWithMultipleTools;
    procedure TestResponseWithSingleTool;
    procedure TestResponseWithEmptyToolsList;
    procedure TestResponseWithMalformedJSON;
    procedure TestResponseWithMissingToolsField;

    // Tool information parsing tests
    procedure TestToolWithAllFields;
    procedure TestToolWithMinimalFields;
    procedure TestToolWithMissingFields;

    // Callback and event tests
    procedure TestCallbackExecution;
    procedure TestCallbackWithNilList;
    procedure TestMultipleCallbacks;

    // Error handling tests
    procedure TestErrorHandling;
    procedure TestErrorCallback;
    procedure TestRPCErrorResponse;

    // Memory management tests
    procedure TestMemoryCleanupOnSuccess;
    procedure TestMemoryCleanupOnError;

    // Integration tests with TMCPCustomClient
    procedure TestClientListToolsMethod;
    procedure TestClientListToolsReturnType;
  end;

  { TMCPReadPromptListTest }
  TMCPReadPromptListTest = class(TTestCase)
  private
    FClient: TMockClient;
    FReadPromptList: TMCPReadPromptList;
    FCallbackExecuted: Boolean;
    FLastPromptList: TMCPPromptInfoList;
    FCallbackSender: TObject;
    FResponseCount: Integer;
    // Additional callback for multi-callback test
    FSecondCallbackExecuted: Boolean;
    FSecondPromptList: TMCPPromptInfoList;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure OnListPromptsReply(aSender: TObject; aList: TMCPPromptInfoList);
    procedure OnSecondListPromptsReply(aSender: TObject; aList: TMCPPromptInfoList);
    function CreateMockPromptsResponse: TJSONObject;
    function CreateEmptyPromptsResponse: TJSONObject;
    function CreateMalformedPromptsResponse: TJSONObject;
  published
    // Basic functionality tests
    procedure TestMethodName;
    procedure TestReadPromptListCall;
    procedure TestReadPromptListCallWithEmptyArgs;

    // Response parsing tests
    procedure TestResponseWithMultiplePrompts;
    procedure TestResponseWithSinglePrompt;
    procedure TestResponseWithEmptyPromptsList;
    procedure TestResponseWithMalformedJSON;
    procedure TestResponseWithMissingPromptsField;

    // Prompt information parsing tests
    procedure TestPromptWithAllFields;
    procedure TestPromptWithMinimalFields;
    procedure TestPromptWithMissingFields;

    // Callback and event tests
    procedure TestCallbackExecution;
    procedure TestCallbackWithNilList;
    procedure TestMultipleCallbacks;

    // Error handling tests
    procedure TestErrorHandling;
    procedure TestErrorCallback;
    procedure TestRPCErrorResponse;

    // Memory management tests
    procedure TestMemoryCleanupOnSuccess;
    procedure TestMemoryCleanupOnError;

    // Integration tests with TMCPCustomClient
    procedure TestClientListPromptsMethod;
    procedure TestClientListPromptsReturnType;
  end;

  { TMCPReadResourceListTest }
  TMCPReadResourceListTest = class(TTestCase)
  private
    FClient: TMockClient;
    FReadResourceList: TMCPReadResourceList;
    FCallbackExecuted: Boolean;
    FLastResourceList: TMCPResourceInfoList;
    FCallbackSender: TObject;
    FResponseCount: Integer;
    // Additional callback for multi-callback test
    FSecondCallbackExecuted: Boolean;
    FSecondResourceList: TMCPResourceInfoList;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure OnListResourcesReply(aSender: TObject; aList: TMCPResourceInfoList);
    procedure OnSecondListResourcesReply(aSender: TObject; aList: TMCPResourceInfoList);
    function CreateMockResourcesResponse: TJSONObject;
    function CreateEmptyResourcesResponse: TJSONObject;
    function CreateMalformedResourcesResponse: TJSONObject;
  published
    // Basic functionality tests
    procedure TestMethodName;
    procedure TestReadResourceListCall;
    procedure TestReadResourceListCallWithEmptyArgs;

    // Response parsing tests
    procedure TestResponseWithMultipleResources;
    procedure TestResponseWithSingleResource;
    procedure TestResponseWithEmptyResourcesList;
    procedure TestResponseWithMalformedJSON;
    procedure TestResponseWithMissingResourcesField;

    // Resource information parsing tests
    procedure TestResourceWithAllFields;
    procedure TestResourceWithMinimalFields;
    procedure TestResourceWithMissingFields;

    // Callback and event tests
    procedure TestCallbackExecution;
    procedure TestCallbackWithNilList;
    procedure TestMultipleCallbacks;

    // Error handling tests
    procedure TestErrorHandling;
    procedure TestErrorCallback;
    procedure TestRPCErrorResponse;

    // Memory management tests
    procedure TestMemoryCleanupOnSuccess;
    procedure TestMemoryCleanupOnError;

    // Integration tests with TMCPCustomClient
    procedure TestClientListResourcesMethod;
    procedure TestClientListResourcesReturnType;
  end;

  { TMCPGetResourceTest }
  TMCPGetResourceTest = class(TTestCase)
  private
    FClient: TMockClient;
    FGetResource: TMCPGetResource;
    FCallbackExecuted: Boolean;
    FLastResource: TMCPResourceInfo;
    FCallbackSender: TObject;
    FResponseCount: Integer;
    // Additional callback for multi-callback test
    FSecondCallbackExecuted: Boolean;
    FSecondResource: TMCPResourceInfo;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure OnGetResourceReply(aSender: TObject; aResource: TMCPResourceInfo);
    procedure OnSecondGetResourceReply(aSender: TObject; aResource: TMCPResourceInfo);
    function CreateMockResourceResponse: TJSONObject;
    function CreateMockResourceWithDataResponse: TJSONObject;
    function CreateMalformedResourceResponse: TJSONObject;
  published
    // Basic functionality tests
    procedure TestMethodName;
    procedure TestGetResourceCall;
    procedure TestGetResourceCallWithURI;

    // Response parsing tests
    procedure TestResponseWithCompleteResource;
    procedure TestResponseWithMinimalResource;
    procedure TestResponseWithTextData;
    procedure TestResponseWithBinaryData;
    procedure TestResponseWithMalformedJSON;
    procedure TestResponseWithMissingFields;

    // URI parameter tests
    procedure TestCallWithEmptyURI;
    procedure TestCallWithValidURI;
    procedure TestCallWithSpecialCharactersInURI;

    // Callback and event tests
    procedure TestCallbackExecution;
    procedure TestCallbackWithNilResource;
    procedure TestMultipleCallbacks;

    // Error handling tests
    procedure TestErrorHandling;
    procedure TestErrorCallback;
    procedure TestRPCErrorResponse;

    // Memory management tests
    procedure TestMemoryCleanupOnSuccess;
    procedure TestMemoryCleanupOnError;

    // Integration tests with TMCPCustomClient
    procedure TestClientGetResourceMethod;
    procedure TestClientGetResourceReturnType;
  end;


implementation

{ TMockTransport }

procedure TMockTransport.DoConnect;
begin
  // Mock connection - do nothing
end;

procedure TMockTransport.DoDisconnect;
begin
  // Mock disconnection - do nothing
end;

procedure TMockTransport.DoSendMessage(J: TJSONStringType);
begin
  // Mock send - do nothing
end;

function TMockTransport.DoGetMessage(out J: TJSONStringType): Boolean;
begin
  Result := False; // No messages available
end;

{ TMockClient }

constructor TMockClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMockRequestID := 1;
  ClientName := 'MockClient';
  ClientVersion := '1.0';
  ProtocolVersion := '2025-06-18';
  Transport := TMockTransport.Create(Self);
end;

destructor TMockClient.Destroy;
begin
  FLastRequestArgs.Free;
  inherited Destroy;
end;

procedure TMockClient.DoRequest(aRequest: TMCPCall; aRequestID: TRequestID; aArgs: TJSONObject);
begin
  FLastRequestArgs.Free;
  FLastRequestArgs := aArgs.Clone as TJSONObject;
  FLastRequest := aRequest;
  FLastRequestID := aRequestID;
  // Don't call inherited - we don't want actual network operations
end;

procedure TMockClient.SimulateResponse(aRequestID: TRequestID; aResponse: TJSONObject);

begin
  DoServerResponse(IntToStr(aRequestID), aResponse);
end;

procedure TMockClient.SimulateError(aRequestID: TRequestID; const aError: TRPCError);
var
  ErrorData: TJSONObject;
begin
  ErrorData := TJSONObject.Create;
  try
    aError.ToJSON(ErrorData);
    DoServerError(IntToStr(aRequestID), ErrorData);
  finally
    ErrorData.Free;
  end;
end;

{ TMCPListToolsTest }

procedure TMCPListToolsTest.SetUp;
begin
  inherited SetUp;
  FClient := TMockClient.Create(nil);
  FListTools := TMCPListTools.Create(FClient);
  FCallbackExecuted := False;
  FLastToolList := nil;
  FCallbackSender := nil;
  FResponseCount := 0;
  FSecondCallbackExecuted := False;
  FSecondToolList := nil;
end;

procedure TMCPListToolsTest.TearDown;
begin
  FLastToolList.Free;
  FSecondToolList.Free;
  FListTools.Free;
  FClient.Free;
  inherited TearDown;
end;

procedure TMCPListToolsTest.OnListToolsReply(aSender: TObject; aList: TMCPToolInfoList);
begin
  FCallbackExecuted := True;
  FCallbackSender := aSender;
  FLastToolList.Free; // Free previous list if any
  FLastToolList := aList; // Take ownership
  Inc(FResponseCount);
end;

procedure TMCPListToolsTest.OnSecondListToolsReply(aSender: TObject; aList: TMCPToolInfoList);
begin
  FSecondCallbackExecuted := True;
  FSecondToolList.Free; // Free previous list if any
  FSecondToolList := aList; // Take ownership
end;

function TMCPListToolsTest.CreateMockToolsResponse: TJSONObject;
var
  ToolsArray: TJSONArray;
  Tool1, Tool2: TJSONObject;
begin
  Result := TJSONObject.Create;
  ToolsArray := TJSONArray.Create;

  // Tool 1
  Tool1 := TJSONObject.Create;
  Tool1.Add('name', 'test-tool-1');
  Tool1.Add('description', 'First test tool');
  Tool1.Add('title', 'Test Tool 1');
  ToolsArray.Add(Tool1);

  // Tool 2
  Tool2 := TJSONObject.Create;
  Tool2.Add('name', 'test-tool-2');
  Tool2.Add('description', 'Second test tool');
  Tool2.Add('title', 'Test Tool 2');
  ToolsArray.Add(Tool2);

  Result.Add('tools', ToolsArray);
end;

function TMCPListToolsTest.CreateEmptyToolsResponse: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('tools', TJSONArray.Create);
end;

function TMCPListToolsTest.CreateMalformedToolsResponse: TJSONObject;
var
  ToolsArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  ToolsArray := TJSONArray.Create;
  ToolsArray.Add('invalid-tool-data'); // String instead of object
  Result.Add('tools', ToolsArray);
end;

procedure TMCPListToolsTest.TestMethodName;
begin
  AssertEquals('Method name should be tools/list', 'tools/list', TMCPListTools.MethodName);
end;

procedure TMCPListToolsTest.TestListToolsCall;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  // Verify the request was sent correctly
  AssertNotNull('Should have sent request arguments', FClient.LastRequestArgs);
  AssertTrue('Should be TMCPListTools instance', FClient.LastRequest is TMCPListTools);
end;

procedure TMCPListToolsTest.TestListToolsCallWithEmptyArgs;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  // Verify empty JSON object was sent
  AssertNotNull('Should have sent request arguments', FClient.LastRequestArgs);
  AssertEquals('Should have no arguments', 0, FClient.LastRequestArgs.Count);
end;

procedure TMCPListToolsTest.TestResponseWithMultipleTools;
var
  MockResponse: TJSONObject;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  MockResponse := CreateMockToolsResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Tool list should not be nil', FLastToolList);
    AssertEquals('Should have 2 tools', 2, FLastToolList.Count);
    AssertEquals('First tool name', 'test-tool-1', FLastToolList[0].Name);
    AssertEquals('Second tool name', 'test-tool-2', FLastToolList[1].Name);
    AssertEquals('First tool description', 'First test tool', FLastToolList[0].Description);
    AssertEquals('Second tool description', 'Second test tool', FLastToolList[1].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPListToolsTest.TestResponseWithSingleTool;
var
  MockResponse: TJSONObject;
  ToolsArray: TJSONArray;
  Tool: TJSONObject;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  MockResponse := TJSONObject.Create;
  try
    ToolsArray := TJSONArray.Create;
    Tool := TJSONObject.Create;
    Tool.Add('name', 'single-tool');
    Tool.Add('description', 'Single tool description');
    ToolsArray.Add(Tool);
    MockResponse.Add('tools', ToolsArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Tool list should not be nil', FLastToolList);
    AssertEquals('Should have 1 tool', 1, FLastToolList.Count);
    AssertEquals('Tool name', 'single-tool', FLastToolList[0].Name);
    AssertEquals('Tool description', 'Single tool description', FLastToolList[0].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPListToolsTest.TestResponseWithEmptyToolsList;
var
  MockResponse: TJSONObject;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  MockResponse := CreateEmptyToolsResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Tool list should not be nil', FLastToolList);
    AssertEquals('Should have 0 tools', 0, FLastToolList.Count);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPListToolsTest.TestResponseWithMalformedJSON;
var
  MockResponse: TJSONObject;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  MockResponse := CreateMalformedToolsResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Tool list should not be nil even with malformed data', FLastToolList);
    // Should handle malformed data gracefully - malformed entries are skipped
    AssertEquals('Should have 0 tools due to malformed data', 0, FLastToolList.Count);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPListToolsTest.TestResponseWithMissingToolsField;
var
  MockResponse: TJSONObject;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  MockResponse := TJSONObject.Create;
  try
    // No 'tools' field
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Tool list should not be nil', FLastToolList);
    AssertEquals('Should have 0 tools when field is missing', 0, FLastToolList.Count);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPListToolsTest.TestToolWithAllFields;
var
  MockResponse: TJSONObject;
  ToolsArray: TJSONArray;
  Tool: TJSONObject;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  MockResponse := TJSONObject.Create;
  try
    ToolsArray := TJSONArray.Create;
    Tool := TJSONObject.Create;
    Tool.Add('name', 'full-tool');
    Tool.Add('description', 'Full tool description');
    Tool.Add('title', 'Full Tool Title');
    // Note: InputSchema, OutputSchema, etc. would be in the record version
    ToolsArray.Add(Tool);
    MockResponse.Add('tools', ToolsArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Tool list should not be nil', FLastToolList);
    AssertEquals('Should have 1 tool', 1, FLastToolList.Count);
    AssertEquals('Tool name', 'full-tool', FLastToolList[0].Name);
    AssertEquals('Tool description', 'Full tool description', FLastToolList[0].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPListToolsTest.TestToolWithMinimalFields;
var
  MockResponse: TJSONObject;
  ToolsArray: TJSONArray;
  Tool: TJSONObject;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  MockResponse := TJSONObject.Create;
  try
    ToolsArray := TJSONArray.Create;
    Tool := TJSONObject.Create;
    Tool.Add('name', 'minimal-tool');
    Tool.Add('description', 'Minimal description');
    ToolsArray.Add(Tool);
    MockResponse.Add('tools', ToolsArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Tool list should not be nil', FLastToolList);
    AssertEquals('Should have 1 tool', 1, FLastToolList.Count);
    AssertEquals('Tool name', 'minimal-tool', FLastToolList[0].Name);
    AssertEquals('Tool description', 'Minimal description', FLastToolList[0].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPListToolsTest.TestToolWithMissingFields;
var
  MockResponse: TJSONObject;
  ToolsArray: TJSONArray;
  Tool: TJSONObject;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  MockResponse := TJSONObject.Create;
  try
    ToolsArray := TJSONArray.Create;
    Tool := TJSONObject.Create;
    Tool.Add('name', 'incomplete-tool');
    // Missing description field
    ToolsArray.Add(Tool);
    MockResponse.Add('tools', ToolsArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Tool list should not be nil', FLastToolList);
    AssertEquals('Should have 1 tool', 1, FLastToolList.Count);
    AssertEquals('Tool name', 'incomplete-tool', FLastToolList[0].Name);
    AssertEquals('Tool description should be empty', '', FLastToolList[0].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPListToolsTest.TestCallbackExecution;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  AssertFalse('Callback should not be executed yet', FCallbackExecuted);

  FClient.SimulateResponse(FClient.LastRequestID, CreateEmptyToolsResponse);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertTrue('Sender should be the TMCPListTools instance', FCallbackSender = FListTools);
end;

procedure TMCPListToolsTest.TestCallbackWithNilList;
var
  Error: TRPCError;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  Error.Code := -32601;
  Error.Message := 'Method not found';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Tool list should be nil on error', FLastToolList);
end;

procedure TMCPListToolsTest.TestMultipleCallbacks;
var
  SecondListTools: TMCPListTools;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  SecondListTools := TMCPListTools.Create(FClient);
  try
    SecondListTools.OnReply := @OnSecondListToolsReply;
    SecondListTools.Call();

    // Simulate responses
    FClient.SimulateResponse(FClient.LastRequestID - 1, CreateEmptyToolsResponse);
    FClient.SimulateResponse(FClient.LastRequestID, CreateMockToolsResponse);

    AssertTrue('First callback should have been executed', FCallbackExecuted);
    AssertTrue('Second callback should have been executed', FSecondCallbackExecuted);
    AssertEquals('First should get empty list', 0, FLastToolList.Count);
    AssertEquals('Second should get tools', 2, FSecondToolList.Count);
  finally
    SecondListTools.Free;
  end;
end;

procedure TMCPListToolsTest.TestErrorHandling;
var
  Error: TRPCError;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  Error.Code := -32000;
  Error.Message := 'Server error';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Tool list should be nil on error', FLastToolList);
end;

procedure TMCPListToolsTest.TestErrorCallback;
var
  Error: TRPCError;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  Error.Code := -32601;
  Error.Message := 'Method not found: tools/list';
  Error.Data := '{"detail": "Server does not support tools"}';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Error callback should have been executed', FCallbackExecuted);
  AssertNull('Tool list should be nil on error', FLastToolList);
  AssertTrue('Should be the ListTools instance', FCallbackSender = FListTools);
end;

procedure TMCPListToolsTest.TestRPCErrorResponse;
var
  Error: TRPCError;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  Error.Code := -32602;
  Error.Message := 'Invalid params';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Tool list should be nil on RPC error', FLastToolList);
end;

procedure TMCPListToolsTest.TestMemoryCleanupOnSuccess;
var
  MockResponse: TJSONObject;
  InitialList: TMCPToolInfoList;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  MockResponse := CreateMockToolsResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Tool list should not be nil', FLastToolList);

    // Save reference and test cleanup
    InitialList := FLastToolList;
    FLastToolList := nil; // Simulate that callback took ownership

    // List should still be valid since callback owns it
    AssertEquals('List should still be accessible', 2, InitialList.Count);

    InitialList.Free; // Cleanup
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPListToolsTest.TestMemoryCleanupOnError;
var
  Error: TRPCError;
begin
  FListTools.OnReply := @OnListToolsReply;
  FListTools.Call();

  Error.Code := -32000;
  Error.Message := 'Server error';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Tool list should be nil on error', FLastToolList);

  // No memory leaks should occur
end;

procedure TMCPListToolsTest.TestClientListToolsMethod;
var
  ListToolsCall: TMCPCall;
begin
  ListToolsCall := FClient.ListTools(@OnListToolsReply);

  AssertNotNull('Should return a call object', ListToolsCall);
  AssertTrue('Should be TMCPListTools type', ListToolsCall is TMCPListTools);

  // Simulate response
  FClient.SimulateResponse(FClient.LastRequestID, CreateMockToolsResponse);

  AssertTrue('Client callback should have been executed', FCallbackExecuted);
  AssertNotNull('Result list should not be nil', FLastToolList);
  AssertEquals('Should have 2 tools from client method', 2, FLastToolList.Count);
end;

procedure TMCPListToolsTest.TestClientListToolsReturnType;
var
  ListToolsCall: TMCPCall;
  ListToolsInstance: TMCPListTools;
begin
  ListToolsCall := FClient.ListTools(@OnListToolsReply);

  AssertNotNull('Should return a call object', ListToolsCall);
  AssertTrue('Should be TMCPListTools instance', ListToolsCall is TMCPListTools);

  // Type cast should work
  ListToolsInstance := TMCPListTools(ListToolsCall);
  AssertNotNull('Type cast should succeed', ListToolsInstance);
  AssertEquals('Method name should be correct', 'tools/list', ListToolsInstance.MethodName);
end;

{ TMCPReadPromptListTest }

procedure TMCPReadPromptListTest.SetUp;
begin
  inherited SetUp;
  FClient := TMockClient.Create(nil);
  FReadPromptList := TMCPReadPromptList.Create(FClient);
  FCallbackExecuted := False;
  FLastPromptList := nil;
  FCallbackSender := nil;
  FResponseCount := 0;
  FSecondCallbackExecuted := False;
  FSecondPromptList := nil;
end;

procedure TMCPReadPromptListTest.TearDown;
begin
  FLastPromptList.Free;
  FSecondPromptList.Free;
  FReadPromptList.Free;
  FClient.Free;
  inherited TearDown;
end;

procedure TMCPReadPromptListTest.OnListPromptsReply(aSender: TObject; aList: TMCPPromptInfoList);
begin
  FCallbackExecuted := True;
  FCallbackSender := aSender;
  FLastPromptList.Free; // Free previous list if any
  FLastPromptList := aList; // Take ownership
  Inc(FResponseCount);
end;

procedure TMCPReadPromptListTest.OnSecondListPromptsReply(aSender: TObject; aList: TMCPPromptInfoList);
begin
  FSecondCallbackExecuted := True;
  FSecondPromptList.Free; // Free previous list if any
  FSecondPromptList := aList; // Take ownership
end;

function TMCPReadPromptListTest.CreateMockPromptsResponse: TJSONObject;
var
  PromptsArray: TJSONArray;
  Prompt1, Prompt2: TJSONObject;
begin
  Result := TJSONObject.Create;
  PromptsArray := TJSONArray.Create;

  // Prompt 1
  Prompt1 := TJSONObject.Create;
  Prompt1.Add('name', 'test-prompt-1');
  Prompt1.Add('description', 'First test prompt');
  Prompt1.Add('title', 'Test Prompt 1');
  PromptsArray.Add(Prompt1);

  // Prompt 2
  Prompt2 := TJSONObject.Create;
  Prompt2.Add('name', 'test-prompt-2');
  Prompt2.Add('description', 'Second test prompt');
  Prompt2.Add('title', 'Test Prompt 2');
  PromptsArray.Add(Prompt2);

  Result.Add('prompts', PromptsArray);
end;

function TMCPReadPromptListTest.CreateEmptyPromptsResponse: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('prompts', TJSONArray.Create);
end;

function TMCPReadPromptListTest.CreateMalformedPromptsResponse: TJSONObject;
var
  PromptsArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  PromptsArray := TJSONArray.Create;
  PromptsArray.Add('invalid-prompt-data'); // String instead of object
  Result.Add('prompts', PromptsArray);
end;

procedure TMCPReadPromptListTest.TestMethodName;
begin
  AssertEquals('Method name should be prompts/list', 'prompts/list', TMCPReadPromptList.MethodName);
end;

procedure TMCPReadPromptListTest.TestReadPromptListCall;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  // Verify the request was sent correctly
  AssertNotNull('Should have sent request arguments', FClient.LastRequestArgs);
  AssertTrue('Should be TMCPReadPromptList instance', FClient.LastRequest is TMCPReadPromptList);
end;

procedure TMCPReadPromptListTest.TestReadPromptListCallWithEmptyArgs;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  // Verify empty JSON object was sent
  AssertNotNull('Should have sent request arguments', FClient.LastRequestArgs);
  AssertEquals('Should have no arguments', 0, FClient.LastRequestArgs.Count);
end;

procedure TMCPReadPromptListTest.TestResponseWithMultiplePrompts;
var
  MockResponse: TJSONObject;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  MockResponse := CreateMockPromptsResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Prompt list should not be nil', FLastPromptList);
    AssertEquals('Should have 2 prompts', 2, FLastPromptList.Count);
    AssertEquals('First prompt name', 'test-prompt-1', FLastPromptList[0].Name);
    AssertEquals('Second prompt name', 'test-prompt-2', FLastPromptList[1].Name);
    AssertEquals('First prompt description', 'First test prompt', FLastPromptList[0].Description);
    AssertEquals('Second prompt description', 'Second test prompt', FLastPromptList[1].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadPromptListTest.TestResponseWithSinglePrompt;
var
  MockResponse: TJSONObject;
  PromptsArray: TJSONArray;
  Prompt: TJSONObject;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  MockResponse := TJSONObject.Create;
  try
    PromptsArray := TJSONArray.Create;
    Prompt := TJSONObject.Create;
    Prompt.Add('name', 'single-prompt');
    Prompt.Add('description', 'Single prompt description');
    PromptsArray.Add(Prompt);
    MockResponse.Add('prompts', PromptsArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Prompt list should not be nil', FLastPromptList);
    AssertEquals('Should have 1 prompt', 1, FLastPromptList.Count);
    AssertEquals('Prompt name', 'single-prompt', FLastPromptList[0].Name);
    AssertEquals('Prompt description', 'Single prompt description', FLastPromptList[0].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadPromptListTest.TestResponseWithEmptyPromptsList;
var
  MockResponse: TJSONObject;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  MockResponse := CreateEmptyPromptsResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Prompt list should not be nil', FLastPromptList);
    AssertEquals('Should have 0 prompts', 0, FLastPromptList.Count);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadPromptListTest.TestResponseWithMalformedJSON;
var
  MockResponse: TJSONObject;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  MockResponse := CreateMalformedPromptsResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Prompt list should not be nil even with malformed data', FLastPromptList);
    // Should handle malformed data gracefully - malformed entries are skipped
    AssertEquals('Should have 0 prompts due to malformed data', 0, FLastPromptList.Count);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadPromptListTest.TestResponseWithMissingPromptsField;
var
  MockResponse: TJSONObject;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  MockResponse := TJSONObject.Create;
  try
    // No 'prompts' field
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Prompt list should not be nil', FLastPromptList);
    AssertEquals('Should have 0 prompts when field is missing', 0, FLastPromptList.Count);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadPromptListTest.TestPromptWithAllFields;
var
  MockResponse: TJSONObject;
  PromptsArray: TJSONArray;
  Prompt: TJSONObject;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  MockResponse := TJSONObject.Create;
  try
    PromptsArray := TJSONArray.Create;
    Prompt := TJSONObject.Create;
    Prompt.Add('name', 'full-prompt');
    Prompt.Add('description', 'Full prompt description');
    Prompt.Add('title', 'Full Prompt Title');
    PromptsArray.Add(Prompt);
    MockResponse.Add('prompts', PromptsArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Prompt list should not be nil', FLastPromptList);
    AssertEquals('Should have 1 prompt', 1, FLastPromptList.Count);
    AssertEquals('Prompt name', 'full-prompt', FLastPromptList[0].Name);
    AssertEquals('Prompt description', 'Full prompt description', FLastPromptList[0].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadPromptListTest.TestPromptWithMinimalFields;
var
  MockResponse: TJSONObject;
  PromptsArray: TJSONArray;
  Prompt: TJSONObject;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  MockResponse := TJSONObject.Create;
  try
    PromptsArray := TJSONArray.Create;
    Prompt := TJSONObject.Create;
    Prompt.Add('name', 'minimal-prompt');
    Prompt.Add('description', 'Minimal description');
    PromptsArray.Add(Prompt);
    MockResponse.Add('prompts', PromptsArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Prompt list should not be nil', FLastPromptList);
    AssertEquals('Should have 1 prompt', 1, FLastPromptList.Count);
    AssertEquals('Prompt name', 'minimal-prompt', FLastPromptList[0].Name);
    AssertEquals('Prompt description', 'Minimal description', FLastPromptList[0].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadPromptListTest.TestPromptWithMissingFields;
var
  MockResponse: TJSONObject;
  PromptsArray: TJSONArray;
  Prompt: TJSONObject;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  MockResponse := TJSONObject.Create;
  try
    PromptsArray := TJSONArray.Create;
    Prompt := TJSONObject.Create;
    Prompt.Add('name', 'incomplete-prompt');
    // Missing description field
    PromptsArray.Add(Prompt);
    MockResponse.Add('prompts', PromptsArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Prompt list should not be nil', FLastPromptList);
    AssertEquals('Should have 1 prompt', 1, FLastPromptList.Count);
    AssertEquals('Prompt name', 'incomplete-prompt', FLastPromptList[0].Name);
    AssertEquals('Prompt description should be empty', '', FLastPromptList[0].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadPromptListTest.TestCallbackExecution;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  AssertFalse('Callback should not be executed yet', FCallbackExecuted);

  FClient.SimulateResponse(FClient.LastRequestID, CreateEmptyPromptsResponse);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertTrue('Sender should be the TMCPReadPromptList instance', FCallbackSender = FReadPromptList);
end;

procedure TMCPReadPromptListTest.TestCallbackWithNilList;
var
  Error: TRPCError;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  Error.Code := -32601;
  Error.Message := 'Method not found';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Prompt list should be nil on error', FLastPromptList);
end;

procedure TMCPReadPromptListTest.TestMultipleCallbacks;
var
  SecondReadPromptList: TMCPReadPromptList;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  SecondReadPromptList := TMCPReadPromptList.Create(FClient);
  try
    SecondReadPromptList.OnReply := @OnSecondListPromptsReply;
    SecondReadPromptList.Call();

    // Simulate responses
    FClient.SimulateResponse(FClient.LastRequestID - 1, CreateEmptyPromptsResponse);
    FClient.SimulateResponse(FClient.LastRequestID, CreateMockPromptsResponse);

    AssertTrue('First callback should have been executed', FCallbackExecuted);
    AssertTrue('Second callback should have been executed', FSecondCallbackExecuted);
    AssertEquals('First should get empty list', 0, FLastPromptList.Count);
    AssertEquals('Second should get prompts', 2, FSecondPromptList.Count);
  finally
    SecondReadPromptList.Free;
  end;
end;

procedure TMCPReadPromptListTest.TestErrorHandling;
var
  Error: TRPCError;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  Error.Code := -32000;
  Error.Message := 'Server error';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Prompt list should be nil on error', FLastPromptList);
end;

procedure TMCPReadPromptListTest.TestErrorCallback;
var
  Error: TRPCError;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  Error.Code := -32601;
  Error.Message := 'Method not found: prompts/list';
  Error.Data := '{"detail": "Server does not support prompts"}';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Error callback should have been executed', FCallbackExecuted);
  AssertNull('Prompt list should be nil on error', FLastPromptList);
  AssertTrue('Should be the ReadPromptList instance', FCallbackSender = FReadPromptList);
end;

procedure TMCPReadPromptListTest.TestRPCErrorResponse;
var
  Error: TRPCError;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  Error.Code := -32602;
  Error.Message := 'Invalid params';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Prompt list should be nil on RPC error', FLastPromptList);
end;

procedure TMCPReadPromptListTest.TestMemoryCleanupOnSuccess;
var
  MockResponse: TJSONObject;
  InitialList: TMCPPromptInfoList;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  MockResponse := CreateMockPromptsResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Prompt list should not be nil', FLastPromptList);

    // Save reference and test cleanup
    InitialList := FLastPromptList;
    FLastPromptList := nil; // Simulate that callback took ownership

    // List should still be valid since callback owns it
    AssertEquals('List should still be accessible', 2, InitialList.Count);

    InitialList.Free; // Cleanup
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadPromptListTest.TestMemoryCleanupOnError;
var
  Error: TRPCError;
begin
  FReadPromptList.OnReply := @OnListPromptsReply;
  FReadPromptList.Call();

  Error.Code := -32000;
  Error.Message := 'Server error';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Prompt list should be nil on error', FLastPromptList);

  // No memory leaks should occur
end;

procedure TMCPReadPromptListTest.TestClientListPromptsMethod;
var
  ListPromptsCall: TMCPCall;
begin
  ListPromptsCall := FClient.ListPrompts(@OnListPromptsReply);

  AssertNotNull('Should return a call object', ListPromptsCall);
  AssertTrue('Should be TMCPReadPromptList type', ListPromptsCall is TMCPReadPromptList);

  // Simulate response
  FClient.SimulateResponse(FClient.LastRequestID, CreateMockPromptsResponse);

  AssertTrue('Client callback should have been executed', FCallbackExecuted);
  AssertNotNull('Result list should not be nil', FLastPromptList);
  AssertEquals('Should have 2 prompts from client method', 2, FLastPromptList.Count);
end;

procedure TMCPReadPromptListTest.TestClientListPromptsReturnType;
var
  ListPromptsCall: TMCPCall;
  ListPromptsInstance: TMCPReadPromptList;
begin
  ListPromptsCall := FClient.ListPrompts(@OnListPromptsReply);

  AssertNotNull('Should return a call object', ListPromptsCall);
  AssertTrue('Should be TMCPReadPromptList instance', ListPromptsCall is TMCPReadPromptList);

  // Type cast should work
  ListPromptsInstance := TMCPReadPromptList(ListPromptsCall);
  AssertNotNull('Type cast should succeed', ListPromptsInstance);
  AssertEquals('Method name should be correct', 'prompts/list', ListPromptsInstance.MethodName);
end;

{ TMCPReadResourceListTest }

procedure TMCPReadResourceListTest.SetUp;
begin
  inherited SetUp;
  FClient := TMockClient.Create(nil);
  FReadResourceList := TMCPReadResourceList.Create(FClient);
  FCallbackExecuted := False;
  FLastResourceList := nil;
  FCallbackSender := nil;
  FResponseCount := 0;
  FSecondCallbackExecuted := False;
  FSecondResourceList := nil;
end;

procedure TMCPReadResourceListTest.TearDown;
begin
  FLastResourceList.Free;
  FSecondResourceList.Free;
  FReadResourceList.Free;
  FClient.Free;
  inherited TearDown;
end;

procedure TMCPReadResourceListTest.OnListResourcesReply(aSender: TObject; aList: TMCPResourceInfoList);
begin
  FCallbackExecuted := True;
  FCallbackSender := aSender;
  FLastResourceList.Free; // Free previous list if any
  FLastResourceList := aList; // Take ownership
  Inc(FResponseCount);
end;

procedure TMCPReadResourceListTest.OnSecondListResourcesReply(aSender: TObject; aList: TMCPResourceInfoList);
begin
  FSecondCallbackExecuted := True;
  FSecondResourceList.Free; // Free previous list if any
  FSecondResourceList := aList; // Take ownership
end;

function TMCPReadResourceListTest.CreateMockResourcesResponse: TJSONObject;
var
  ResourcesArray: TJSONArray;
  Resource1, Resource2: TJSONObject;
begin
  Result := TJSONObject.Create;
  ResourcesArray := TJSONArray.Create;

  // Resource 1
  Resource1 := TJSONObject.Create;
  Resource1.Add('uri', 'file:///test-resource-1.txt');
  Resource1.Add('name', 'test-resource-1');
  Resource1.Add('description', 'First test resource');
  Resource1.Add('mimetype', 'text/plain');
  ResourcesArray.Add(Resource1);

  // Resource 2
  Resource2 := TJSONObject.Create;
  Resource2.Add('uri', 'file:///test-resource-2.txt');
  Resource2.Add('name', 'test-resource-2');
  Resource2.Add('description', 'Second test resource');
  Resource2.Add('mimetype', 'text/plain');
  ResourcesArray.Add(Resource2);

  Result.Add('resources', ResourcesArray);
end;

function TMCPReadResourceListTest.CreateEmptyResourcesResponse: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('resources', TJSONArray.Create);
end;

function TMCPReadResourceListTest.CreateMalformedResourcesResponse: TJSONObject;
var
  ResourcesArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  ResourcesArray := TJSONArray.Create;
  ResourcesArray.Add('invalid-resource-data'); // String instead of object
  Result.Add('resources', ResourcesArray);
end;

procedure TMCPReadResourceListTest.TestMethodName;
begin
  AssertEquals('Method name should be resources/list', 'resources/list', TMCPReadResourceList.MethodName);
end;

procedure TMCPReadResourceListTest.TestReadResourceListCall;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  // Verify the request was sent correctly
  AssertNotNull('Should have sent request arguments', FClient.LastRequestArgs);
  AssertTrue('Should be TMCPReadResourceList instance', FClient.LastRequest is TMCPReadResourceList);
end;

procedure TMCPReadResourceListTest.TestReadResourceListCallWithEmptyArgs;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  // Verify empty JSON object was sent
  AssertNotNull('Should have sent request arguments', FClient.LastRequestArgs);
  AssertEquals('Should have no arguments', 0, FClient.LastRequestArgs.Count);
end;

procedure TMCPReadResourceListTest.TestResponseWithMultipleResources;
var
  MockResponse: TJSONObject;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  MockResponse := CreateMockResourcesResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource list should not be nil', FLastResourceList);
    AssertEquals('Should have 2 resources', 2, FLastResourceList.Count);
    AssertEquals('First resource uri', 'file:///test-resource-1.txt', FLastResourceList[0].URI);
    AssertEquals('Second resource uri', 'file:///test-resource-2.txt', FLastResourceList[1].URI);
    AssertEquals('First resource name', 'test-resource-1', FLastResourceList[0].Name);
    AssertEquals('Second resource name', 'test-resource-2', FLastResourceList[1].Name);
    AssertEquals('First resource description', 'First test resource', FLastResourceList[0].Description);
    AssertEquals('Second resource description', 'Second test resource', FLastResourceList[1].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadResourceListTest.TestResponseWithSingleResource;
var
  MockResponse: TJSONObject;
  ResourcesArray: TJSONArray;
  Resource: TJSONObject;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  MockResponse := TJSONObject.Create;
  try
    ResourcesArray := TJSONArray.Create;
    Resource := TJSONObject.Create;
    Resource.Add('uri', 'file:///single-resource.txt');
    Resource.Add('name', 'single-resource');
    Resource.Add('description', 'Single resource description');
    Resource.Add('mimetype', 'text/plain');
    ResourcesArray.Add(Resource);
    MockResponse.Add('resources', ResourcesArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource list should not be nil', FLastResourceList);
    AssertEquals('Should have 1 resource', 1, FLastResourceList.Count);
    AssertEquals('Resource uri', 'file:///single-resource.txt', FLastResourceList[0].URI);
    AssertEquals('Resource name', 'single-resource', FLastResourceList[0].Name);
    AssertEquals('Resource description', 'Single resource description', FLastResourceList[0].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadResourceListTest.TestResponseWithEmptyResourcesList;
var
  MockResponse: TJSONObject;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  MockResponse := CreateEmptyResourcesResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource list should not be nil', FLastResourceList);
    AssertEquals('Should have 0 resources', 0, FLastResourceList.Count);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadResourceListTest.TestResponseWithMalformedJSON;
var
  MockResponse: TJSONObject;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  MockResponse := CreateMalformedResourcesResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource list should not be nil even with malformed data', FLastResourceList);
    // Should handle malformed data gracefully - malformed entries are skipped
    AssertEquals('Should have 0 resources due to malformed data', 0, FLastResourceList.Count);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadResourceListTest.TestResponseWithMissingResourcesField;
var
  MockResponse: TJSONObject;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  MockResponse := TJSONObject.Create;
  try
    // No 'resources' field
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource list should not be nil', FLastResourceList);
    AssertEquals('Should have 0 resources when field is missing', 0, FLastResourceList.Count);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadResourceListTest.TestResourceWithAllFields;
var
  MockResponse: TJSONObject;
  ResourcesArray: TJSONArray;
  Resource: TJSONObject;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  MockResponse := TJSONObject.Create;
  try
    ResourcesArray := TJSONArray.Create;
    Resource := TJSONObject.Create;
    Resource.Add('uri', 'file:///full-resource.txt');
    Resource.Add('name', 'full-resource');
    Resource.Add('description', 'Full resource description');
    Resource.Add('mimetype', 'text/plain');
    ResourcesArray.Add(Resource);
    MockResponse.Add('resources', ResourcesArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource list should not be nil', FLastResourceList);
    AssertEquals('Should have 1 resource', 1, FLastResourceList.Count);
    AssertEquals('Resource uri', 'file:///full-resource.txt', FLastResourceList[0].URI);
    AssertEquals('Resource name', 'full-resource', FLastResourceList[0].Name);
    AssertEquals('Resource description', 'Full resource description', FLastResourceList[0].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadResourceListTest.TestResourceWithMinimalFields;
var
  MockResponse: TJSONObject;
  ResourcesArray: TJSONArray;
  Resource: TJSONObject;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  MockResponse := TJSONObject.Create;
  try
    ResourcesArray := TJSONArray.Create;
    Resource := TJSONObject.Create;
    Resource.Add('uri', 'file:///minimal-resource.txt');
    Resource.Add('name', 'minimal-resource');
    ResourcesArray.Add(Resource);
    MockResponse.Add('resources', ResourcesArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource list should not be nil', FLastResourceList);
    AssertEquals('Should have 1 resource', 1, FLastResourceList.Count);
    AssertEquals('Resource uri', 'file:///minimal-resource.txt', FLastResourceList[0].URI);
    AssertEquals('Resource name', 'minimal-resource', FLastResourceList[0].Name);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadResourceListTest.TestResourceWithMissingFields;
var
  MockResponse: TJSONObject;
  ResourcesArray: TJSONArray;
  Resource: TJSONObject;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  MockResponse := TJSONObject.Create;
  try
    ResourcesArray := TJSONArray.Create;
    Resource := TJSONObject.Create;
    Resource.Add('uri', 'file:///incomplete-resource.txt');
    Resource.Add('name', 'incomplete-resource');
    // Missing description and other optional fields
    ResourcesArray.Add(Resource);
    MockResponse.Add('resources', ResourcesArray);

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource list should not be nil', FLastResourceList);
    AssertEquals('Should have 1 resource', 1, FLastResourceList.Count);
    AssertEquals('Resource uri', 'file:///incomplete-resource.txt', FLastResourceList[0].URI);
    AssertEquals('Resource name', 'incomplete-resource', FLastResourceList[0].Name);
    AssertEquals('Resource description should be empty', '', FLastResourceList[0].Description);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadResourceListTest.TestCallbackExecution;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  AssertFalse('Callback should not be executed yet', FCallbackExecuted);

  FClient.SimulateResponse(FClient.LastRequestID, CreateEmptyResourcesResponse);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertTrue('Sender should be the TMCPReadResourceList instance', FCallbackSender = FReadResourceList);
end;

procedure TMCPReadResourceListTest.TestCallbackWithNilList;
var
  Error: TRPCError;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  Error.Code := -32601;
  Error.Message := 'Method not found';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Resource list should be nil on error', FLastResourceList);
end;

procedure TMCPReadResourceListTest.TestMultipleCallbacks;
var
  SecondReadResourceList: TMCPReadResourceList;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  SecondReadResourceList := TMCPReadResourceList.Create(FClient);
  try
    SecondReadResourceList.OnReply := @OnSecondListResourcesReply;
    SecondReadResourceList.Call();

    // Simulate responses
    FClient.SimulateResponse(FClient.LastRequestID - 1, CreateEmptyResourcesResponse);
    FClient.SimulateResponse(FClient.LastRequestID, CreateMockResourcesResponse);

    AssertTrue('First callback should have been executed', FCallbackExecuted);
    AssertTrue('Second callback should have been executed', FSecondCallbackExecuted);
    AssertEquals('First should get empty list', 0, FLastResourceList.Count);
    AssertEquals('Second should get resources', 2, FSecondResourceList.Count);
  finally
    SecondReadResourceList.Free;
  end;
end;

procedure TMCPReadResourceListTest.TestErrorHandling;
var
  Error: TRPCError;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  Error.Code := -32000;
  Error.Message := 'Server error';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Resource list should be nil on error', FLastResourceList);
end;

procedure TMCPReadResourceListTest.TestErrorCallback;
var
  Error: TRPCError;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  Error.Code := -32601;
  Error.Message := 'Method not found: resources/list';
  Error.Data := '{"detail": "Server does not support resources"}';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Error callback should have been executed', FCallbackExecuted);
  AssertNull('Resource list should be nil on error', FLastResourceList);
  AssertTrue('Should be the ReadResourceList instance', FCallbackSender = FReadResourceList);
end;

procedure TMCPReadResourceListTest.TestRPCErrorResponse;
var
  Error: TRPCError;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  Error.Code := -32602;
  Error.Message := 'Invalid params';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Resource list should be nil on RPC error', FLastResourceList);
end;

procedure TMCPReadResourceListTest.TestMemoryCleanupOnSuccess;
var
  MockResponse: TJSONObject;
  InitialList: TMCPResourceInfoList;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  MockResponse := CreateMockResourcesResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource list should not be nil', FLastResourceList);

    // Save reference and test cleanup
    InitialList := FLastResourceList;
    FLastResourceList := nil; // Simulate that callback took ownership

    // List should still be valid since callback owns it
    AssertEquals('List should still be accessible', 2, InitialList.Count);

    InitialList.Free; // Cleanup
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPReadResourceListTest.TestMemoryCleanupOnError;
var
  Error: TRPCError;
begin
  FReadResourceList.OnReply := @OnListResourcesReply;
  FReadResourceList.Call();

  Error.Code := -32000;
  Error.Message := 'Server error';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Resource list should be nil on error', FLastResourceList);

  // No memory leaks should occur
end;

procedure TMCPReadResourceListTest.TestClientListResourcesMethod;
var
  ListResourcesCall: TMCPCall;
begin
  ListResourcesCall := FClient.ListResources(@OnListResourcesReply);

  AssertNotNull('Should return a call object', ListResourcesCall);
  AssertTrue('Should be TMCPReadResourceList type', ListResourcesCall is TMCPReadResourceList);

  // Simulate response
  FClient.SimulateResponse(FClient.LastRequestID, CreateMockResourcesResponse);

  AssertTrue('Client callback should have been executed', FCallbackExecuted);
  AssertNotNull('Result list should not be nil', FLastResourceList);
  AssertEquals('Should have 2 resources from client method', 2, FLastResourceList.Count);
end;

procedure TMCPReadResourceListTest.TestClientListResourcesReturnType;
var
  ListResourcesCall: TMCPCall;
  ListResourcesInstance: TMCPReadResourceList;
begin
  ListResourcesCall := FClient.ListResources(@OnListResourcesReply);

  AssertNotNull('Should return a call object', ListResourcesCall);
  AssertTrue('Should be TMCPReadResourceList instance', ListResourcesCall is TMCPReadResourceList);

  // Type cast should work
  ListResourcesInstance := TMCPReadResourceList(ListResourcesCall);
  AssertNotNull('Type cast should succeed', ListResourcesInstance);
  AssertEquals('Method name should be correct', 'resources/list', ListResourcesInstance.MethodName);
end;

{ TMCPGetResourceTest }

procedure TMCPGetResourceTest.SetUp;
begin
  inherited SetUp;
  FClient := TMockClient.Create(nil);
  FGetResource := TMCPGetResource.Create(FClient);
  FCallbackExecuted := False;
  FLastResource := nil;
  FCallbackSender := nil;
  FResponseCount := 0;
  FSecondCallbackExecuted := False;
  FSecondResource := nil;
end;

procedure TMCPGetResourceTest.TearDown;
begin
  FLastResource.Free;
  FSecondResource.Free;
  FGetResource.Free;
  FClient.Free;
  inherited TearDown;
end;

procedure TMCPGetResourceTest.OnGetResourceReply(aSender: TObject; aResource: TMCPResourceInfo);
begin
  FCallbackExecuted := True;
  FCallbackSender := aSender;
  FLastResource.Free; // Free previous resource if any
  FLastResource := aResource; // Take ownership
  Inc(FResponseCount);
end;

procedure TMCPGetResourceTest.OnSecondGetResourceReply(aSender: TObject; aResource: TMCPResourceInfo);
begin
  FSecondCallbackExecuted := True;
  FSecondResource.Free; // Free previous resource if any
  FSecondResource := aResource; // Take ownership
end;

function TMCPGetResourceTest.CreateMockResourceResponse: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('uri', 'file:///test/resource.txt');
  Result.Add('name', 'test-resource');
  Result.Add('title', 'Test Resource');
  Result.Add('description', 'A test resource for unit testing');
  Result.Add('mimetype', 'text/plain');
end;

function TMCPGetResourceTest.CreateMockResourceWithDataResponse: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('uri', 'file:///test/data-resource.txt');
  Result.Add('name', 'data-resource');
  Result.Add('title', 'Data Resource');
  Result.Add('description', 'A test resource with data');
  Result.Add('mimetype', 'text/plain');
  Result.Add('text', 'Hello from resource data!');
end;

function TMCPGetResourceTest.CreateMalformedResourceResponse: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('invalid_field', 'invalid_value');
  Result.Add('missing_uri', true);
end;

procedure TMCPGetResourceTest.TestMethodName;
begin
  AssertEquals('Method name should be resources/read', 'resources/read', TMCPGetResource.MethodName);
end;

procedure TMCPGetResourceTest.TestGetResourceCall;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///test.txt');

  // Verify the request was sent correctly
  AssertNotNull('Should have sent request arguments', FClient.LastRequestArgs);
  AssertTrue('Should be TMCPGetResource instance', FClient.LastRequest is TMCPGetResource);
  AssertEquals('Should include uri parameter', 'file:///test.txt', FClient.LastRequestArgs.Get('uri', ''));
end;

procedure TMCPGetResourceTest.TestGetResourceCallWithURI;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('https://example.com/api/resource/123');

  // Verify the URI parameter was sent correctly
  AssertNotNull('Should have sent request arguments', FClient.LastRequestArgs);
  AssertEquals('Should include correct uri parameter', 'https://example.com/api/resource/123', FClient.LastRequestArgs.Get('uri', ''));
end;

procedure TMCPGetResourceTest.TestResponseWithCompleteResource;
var
  MockResponse: TJSONObject;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///test.txt');

  MockResponse := CreateMockResourceResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource should not be nil', FLastResource);
    AssertEquals('Resource URI should be correct', 'file:///test/resource.txt', FLastResource.URI);
    AssertEquals('Resource name should be correct', 'test-resource', FLastResource.Name);
    AssertEquals('Resource title should be correct', 'Test Resource', FLastResource.Title);
    AssertEquals('Resource description should be correct', 'A test resource for unit testing', FLastResource.Description);
    AssertEquals('Resource mimeType should be correct', 'text/plain', FLastResource.MimeType);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPGetResourceTest.TestResponseWithMinimalResource;
var
  MockResponse: TJSONObject;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///minimal.txt');

  MockResponse := TJSONObject.Create;
  try
    MockResponse.Add('uri', 'file:///minimal.txt');
    MockResponse.Add('name', 'minimal');

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource should not be nil', FLastResource);
    AssertEquals('Resource URI should be correct', 'file:///minimal.txt', FLastResource.URI);
    AssertEquals('Resource name should be correct', 'minimal', FLastResource.Name);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPGetResourceTest.TestResponseWithTextData;
var
  MockResponse: TJSONObject;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///data.txt');

  MockResponse := CreateMockResourceWithDataResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource should not be nil', FLastResource);
    AssertEquals('Resource text should be correct', 'Hello from resource data!', FLastResource.Text);
    AssertTrue('Resource kind should be rkText', FLastResource.Kind = rkText);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPGetResourceTest.TestResponseWithBinaryData;
var
  MockResponse: TJSONObject;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///binary.dat');

  MockResponse := TJSONObject.Create;
  try
    MockResponse.Add('uri', 'file:///binary.dat');
    MockResponse.Add('name', 'binary-file');
    MockResponse.Add('mimetype', 'application/octet-stream');
    MockResponse.Add('text', 'SGVsbG8gV29ybGQh'); // Base64 for "Hello World!"

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource should not be nil', FLastResource);
    AssertEquals('Resource mimeType should be binary', 'application/octet-stream', FLastResource.MimeType);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPGetResourceTest.TestResponseWithMalformedJSON;
var
  MockResponse: TJSONObject;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///bad.txt');

  MockResponse := CreateMalformedResourceResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource should not be nil even with malformed data', FLastResource);
    // The TMCPResourceInfo.FromJSON should handle missing fields gracefully
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPGetResourceTest.TestResponseWithMissingFields;
var
  MockResponse: TJSONObject;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///incomplete.txt');

  MockResponse := TJSONObject.Create;
  try
    MockResponse.Add('uri', 'file:///incomplete.txt');
    // Missing name and other fields

    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource should not be nil', FLastResource);
    AssertEquals('URI should be loaded', 'file:///incomplete.txt', FLastResource.URI);
    AssertEquals('Name should be empty when missing', '', FLastResource.Name);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPGetResourceTest.TestCallWithEmptyURI;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('');

  AssertNotNull('Should have sent request arguments', FClient.LastRequestArgs);
  AssertEquals('Should include empty uri parameter', '', FClient.LastRequestArgs.Get('uri', 'default'));
end;

procedure TMCPGetResourceTest.TestCallWithValidURI;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///path/to/resource.txt');

  AssertNotNull('Should have sent request arguments', FClient.LastRequestArgs);
  AssertEquals('Should include uri parameter', 'file:///path/to/resource.txt', FClient.LastRequestArgs.Get('uri', ''));
end;

procedure TMCPGetResourceTest.TestCallWithSpecialCharactersInURI;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///path with spaces/resource-name_123.txt');

  AssertNotNull('Should have sent request arguments', FClient.LastRequestArgs);
  AssertEquals('Should handle special characters in URI', 'file:///path with spaces/resource-name_123.txt', FClient.LastRequestArgs.Get('uri', ''));
end;

procedure TMCPGetResourceTest.TestCallbackExecution;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///test.txt');

  AssertFalse('Callback should not be executed yet', FCallbackExecuted);

  FClient.SimulateResponse(FClient.LastRequestID, CreateMockResourceResponse);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertTrue('Sender should be the TMCPGetResource instance', FCallbackSender = FGetResource);
end;

procedure TMCPGetResourceTest.TestCallbackWithNilResource;
var
  Error: TRPCError;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///missing.txt');

  Error.Code := -32601;
  Error.Message := 'Resource not found';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Resource should be nil on error', FLastResource);
end;

procedure TMCPGetResourceTest.TestMultipleCallbacks;
var
  SecondGetResource: TMCPGetResource;
  MockResponse: TJSONObject;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///first.txt');

  SecondGetResource := TMCPGetResource.Create(FClient);
  try
    SecondGetResource.OnReply := @OnSecondGetResourceReply;
    SecondGetResource.Call('file:///second.txt');

    // Simulate responses
    MockResponse := CreateMockResourceResponse;
    try
      FClient.SimulateResponse(FClient.LastRequestID - 1, MockResponse);
      FClient.SimulateResponse(FClient.LastRequestID, CreateMockResourceWithDataResponse);

      AssertTrue('First callback should have been executed', FCallbackExecuted);
      AssertTrue('Second callback should have been executed', FSecondCallbackExecuted);
      AssertNotNull('First resource should not be nil', FLastResource);
      AssertNotNull('Second resource should not be nil', FSecondResource);
    finally
      MockResponse.Free;
    end;
  finally
    SecondGetResource.Free;
  end;
end;

procedure TMCPGetResourceTest.TestErrorHandling;
var
  Error: TRPCError;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///error.txt');

  Error.Code := -32000;
  Error.Message := 'Server error';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Resource should be nil on error', FLastResource);
end;

procedure TMCPGetResourceTest.TestErrorCallback;
var
  Error: TRPCError;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///forbidden.txt');

  Error.Code := -32601;
  Error.Message := 'Method not found: resources/read';
  Error.Data := '{"detail": "Server does not support resource reading"}';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Error callback should have been executed', FCallbackExecuted);
  AssertNull('Resource should be nil on error', FLastResource);
  AssertTrue('Should be the GetResource instance', FCallbackSender = FGetResource);
end;

procedure TMCPGetResourceTest.TestRPCErrorResponse;
var
  Error: TRPCError;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///invalid.txt');

  Error.Code := -32602;
  Error.Message := 'Invalid params';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Resource should be nil on RPC error', FLastResource);
end;

procedure TMCPGetResourceTest.TestMemoryCleanupOnSuccess;
var
  MockResponse: TJSONObject;
  InitialResource: TMCPResourceInfo;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///memory-test.txt');

  MockResponse := CreateMockResourceResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Callback should have been executed', FCallbackExecuted);
    AssertNotNull('Resource should not be nil', FLastResource);

    // Save reference and test cleanup
    InitialResource := FLastResource;
    FLastResource := nil; // Simulate that callback took ownership

    // Resource should still be valid since callback owns it
    AssertEquals('Resource should still be accessible', 'file:///test/resource.txt', InitialResource.URI);

    InitialResource.Free; // Cleanup
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPGetResourceTest.TestMemoryCleanupOnError;
var
  Error: TRPCError;
begin
  FGetResource.OnReply := @OnGetResourceReply;
  FGetResource.Call('file:///error-memory.txt');

  Error.Code := -32000;
  Error.Message := 'Server error';
  Error.Data := '';

  FClient.SimulateError(FClient.LastRequestID, Error);

  AssertTrue('Callback should have been executed', FCallbackExecuted);
  AssertNull('Resource should be nil on error', FLastResource);

  // No memory leaks should occur
end;

procedure TMCPGetResourceTest.TestClientGetResourceMethod;
var
  GetResourceCall: TMCPCall;
  MockResponse: TJSONObject;
begin
  GetResourceCall := FClient.GetResource('file:///client-test.txt', @OnGetResourceReply);

  AssertNotNull('Should return a call object', GetResourceCall);
  AssertTrue('Should be TMCPGetResource type', GetResourceCall is TMCPGetResource);

  // Simulate response
  MockResponse := CreateMockResourceResponse;
  try
    FClient.SimulateResponse(FClient.LastRequestID, MockResponse);

    AssertTrue('Client callback should have been executed', FCallbackExecuted);
    AssertNotNull('Result resource should not be nil', FLastResource);
    AssertEquals('Should get correct resource from client method', 'file:///test/resource.txt', FLastResource.URI);
  finally
    MockResponse.Free;
  end;
end;

procedure TMCPGetResourceTest.TestClientGetResourceReturnType;
var
  GetResourceCall: TMCPCall;
  GetResourceInstance: TMCPGetResource;
begin
  GetResourceCall := FClient.GetResource('file:///type-test.txt', @OnGetResourceReply);

  AssertNotNull('Should return a call object', GetResourceCall);
  AssertTrue('Should be TMCPGetResource instance', GetResourceCall is TMCPGetResource);

  // Type cast should work
  GetResourceInstance := TMCPGetResource(GetResourceCall);
  AssertNotNull('Type cast should succeed', GetResourceInstance);
  AssertEquals('Method name should be correct', 'resources/read', GetResourceInstance.MethodName);
end;


initialization
  RegisterTest(TMCPListToolsTest);
  RegisterTest(TMCPReadPromptListTest);
  RegisterTest(TMCPReadResourceListTest);
  RegisterTest(TMCPGetResourceTest);

end.

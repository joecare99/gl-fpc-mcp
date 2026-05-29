unit mcpmailtools.test;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson,
  mcp.types, mcp.tools, mcpmailtools;

type

  { TTestIMAPMailTool - concrete subclass for testing abstract TIMAPMailTool }

  TTestIMAPMailTool = class(TIMAPMailTool)
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TIMAPConnectionManagerTest }

  TIMAPConnectionManagerTest = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestSingletonInstanceNotNil;
    procedure TestFunctionReturnsInstance;
    procedure TestSetConfigDoesNotRaise;
    procedure TestSelectFolderStoresValue;
    procedure TestSelectedFolderReturnsStoredValue;
    procedure TestSelectedFolderEmptyByDefault;
    procedure TestRequireFolderRaisesWhenEmpty;
    procedure TestRequireFolderDoesNotRaiseWhenSet;
    procedure TestRequireFolderExceptionMessage;
    procedure TestSelectFolderOverwritesPrevious;
  end;

  { TIMAPMailToolTest }

  TIMAPMailToolTest = class(TTestCase)
  published
    procedure TestConnMgrReturnsSingleton;
    procedure TestRequireFolderDelegatesToConnMgr;
    procedure TestToolInheritsFromTMCPTool;
  end;

  { TListFoldersToolTest }

  TListFoldersToolTest = class(TTestCase)
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasNoRequiredArguments;
  end;

  { TSelectFolderToolTest }

  TSelectFolderToolTest = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestInputSchemaHasFolderArgument;
    procedure TestConnMgrSelectFolderIsUpdatedAfterSuccess;
    procedure TestDescriptionIsSet;
    procedure TestFolderArgumentHasStringType;
    procedure TestFolderArgumentIsRequired;
  end;

  { TCountMessagesToolTest }

  TCountMessagesToolTest = class(TTestCase)
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasNoRequiredArguments;
  end;

  { TCountUnreadToolTest }

  TCountUnreadToolTest = class(TTestCase)
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasNoRequiredArguments;
  end;

  { TCountDeletedToolTest }

  TCountDeletedToolTest = class(TTestCase)
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasNoRequiredArguments;
  end;

  { TGetHeadersToolTest }

  TGetHeadersToolTest = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasFromIndexArg;
    procedure TestInputSchemaHasToIndexArg;
    procedure TestBothArgsAreRequired;
    procedure TestFromIndexArgHasIntegerType;
    procedure TestToIndexArgHasIntegerType;
    procedure TestToIndexLessThanFromIndexRaisesException;
  end;

  { TGetMailToolTest }

  TGetMailToolTest = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasMailIdArg;
    procedure TestMailIdArgHasIntegerType;
    procedure TestMailIdArgIsRequired;
    procedure TestRaisesWhenNoFolderSelected;
  end;

  { TMarkReadToolTest }

  TMarkReadToolTest = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasMailIdArg;
    procedure TestMailIdArgHasIntegerType;
    procedure TestMailIdArgIsRequired;
    procedure TestRaisesWhenNoFolderSelected;
  end;

  { TMarkUnreadToolTest }

  TMarkUnreadToolTest = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasMailIdArg;
    procedure TestMailIdArgHasIntegerType;
    procedure TestMailIdArgIsRequired;
    procedure TestRaisesWhenNoFolderSelected;
  end;

  { TMoveMailToolTest }

  TMoveMailToolTest = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasMailIdArg;
    procedure TestMailIdArgHasIntegerType;
    procedure TestMailIdArgIsRequired;
    procedure TestInputSchemaHasTargetFolderArg;
    procedure TestTargetFolderArgHasStringType;
    procedure TestTargetFolderArgIsRequired;
    procedure TestRaisesWhenNoFolderSelected;
  end;

  { TMarkDeletedToolTest }

  TMarkDeletedToolTest = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasMailIdArg;
    procedure TestMailIdArgHasIntegerType;
    procedure TestMailIdArgIsRequired;
    procedure TestRaisesWhenNoFolderSelected;
  end;

  { TMarkUndeletedToolTest }

  TMarkUndeletedToolTest = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasMailIdArg;
    procedure TestMailIdArgHasIntegerType;
    procedure TestMailIdArgIsRequired;
    procedure TestRaisesWhenNoFolderSelected;
  end;

  { TExpungeFolderToolTest }

  TExpungeFolderToolTest = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasNoRequiredArguments;
    procedure TestRaisesWhenNoFolderSelected;
  end;

  { TCreateFolderToolTest }

  TCreateFolderToolTest = class(TTestCase)
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasFolderNameArg;
    procedure TestFolderNameArgHasStringType;
    procedure TestFolderNameArgIsRequired;
  end;

  { TDeleteFolderToolTest }

  TDeleteFolderToolTest = class(TTestCase)
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasFolderNameArg;
    procedure TestFolderNameArgHasStringType;
    procedure TestFolderNameArgIsRequired;
  end;

  { TRenameFolderToolTest }

  TRenameFolderToolTest = class(TTestCase)
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTIMAPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasFolderNameArg;
    procedure TestFolderNameArgHasStringType;
    procedure TestFolderNameArgIsRequired;
    procedure TestInputSchemaHasNewNameArg;
    procedure TestNewNameArgHasStringType;
    procedure TestNewNameArgIsRequired;
  end;

implementation

{ TTestIMAPMailTool }

procedure TTestIMAPMailTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
begin
  // No-op for testing
end;

{ TIMAPConnectionManagerTest }

procedure TIMAPConnectionManagerTest.SetUp;
begin
  inherited SetUp;
  // Reset folder selection between tests
  TIMAPConnectionManager.Instance.SelectFolder('');
end;

procedure TIMAPConnectionManagerTest.TestSingletonInstanceNotNil;
begin
  AssertNotNull('TIMAPConnectionManager.Instance should not be nil',
    TIMAPConnectionManager.Instance);
end;

procedure TIMAPConnectionManagerTest.TestFunctionReturnsInstance;
begin
  AssertSame('IMAPConnectionManager function should return the singleton',
    TIMAPConnectionManager.Instance, IMAPConnectionManager);
end;

procedure TIMAPConnectionManagerTest.TestSetConfigDoesNotRaise;
begin
  TIMAPConnectionManager.Instance.SetConfig(
    'imap.test.com', '993', 'user@test.com', 'password', True);
  // If we get here without exception, the test passes
  AssertTrue('SetConfig should complete without raising', True);
end;

procedure TIMAPConnectionManagerTest.TestSelectFolderStoresValue;
begin
  TIMAPConnectionManager.Instance.SelectFolder('INBOX');
  AssertEquals('SelectFolder should store the folder name',
    'INBOX', TIMAPConnectionManager.Instance.SelectedFolder);
end;

procedure TIMAPConnectionManagerTest.TestSelectedFolderReturnsStoredValue;
begin
  TIMAPConnectionManager.Instance.SelectFolder('Sent');
  AssertEquals('SelectedFolder should return exact stored value',
    'Sent', TIMAPConnectionManager.Instance.SelectedFolder);
end;

procedure TIMAPConnectionManagerTest.TestSelectedFolderEmptyByDefault;
begin
  AssertEquals('SelectedFolder should be empty after reset',
    '', TIMAPConnectionManager.Instance.SelectedFolder);
end;

procedure TIMAPConnectionManagerTest.TestRequireFolderRaisesWhenEmpty;
begin
  try
    TIMAPConnectionManager.Instance.RequireFolder;
    Fail('Expected EMCPException when no folder is selected');
  except
    on E: EMCPException do
      ; // Expected
  end;
end;

procedure TIMAPConnectionManagerTest.TestRequireFolderDoesNotRaiseWhenSet;
begin
  TIMAPConnectionManager.Instance.SelectFolder('INBOX');
  try
    TIMAPConnectionManager.Instance.RequireFolder;
  except
    on E: EMCPException do
      Fail('RequireFolder should not raise when a folder is selected');
  end;
end;

procedure TIMAPConnectionManagerTest.TestRequireFolderExceptionMessage;
begin
  try
    TIMAPConnectionManager.Instance.RequireFolder;
    Fail('Expected EMCPException');
  except
    on E: EMCPException do
      AssertEquals('Exception message should match AC #8',
        'No folder selected. Use select-folder first.', E.Message);
  end;
end;

procedure TIMAPConnectionManagerTest.TestSelectFolderOverwritesPrevious;
begin
  TIMAPConnectionManager.Instance.SelectFolder('INBOX');
  TIMAPConnectionManager.Instance.SelectFolder('Drafts');
  AssertEquals('SelectFolder should overwrite previous value',
    'Drafts', TIMAPConnectionManager.Instance.SelectedFolder);
end;

{ TIMAPMailToolTest }

procedure TIMAPMailToolTest.TestConnMgrReturnsSingleton;
var
  lTool: TTestIMAPMailTool;
begin
  lTool := TTestIMAPMailTool.Create('test-imap-tool', 'Test IMAP tool');
  try
    AssertSame('ConnMgr should return TIMAPConnectionManager.Instance',
      TIMAPConnectionManager.Instance, lTool.ConnMgr);
  finally
    lTool.Free;
  end;
end;

procedure TIMAPMailToolTest.TestRequireFolderDelegatesToConnMgr;
var
  lTool: TTestIMAPMailTool;
begin
  lTool := TTestIMAPMailTool.Create('test-imap-tool', 'Test IMAP tool');
  try
    TIMAPConnectionManager.Instance.SelectFolder('');
    try
      lTool.RequireFolder;
      Fail('Expected EMCPException from delegated RequireFolder');
    except
      on E: EMCPException do
        AssertEquals('Should delegate to ConnMgr.RequireFolder',
          'No folder selected. Use select-folder first.', E.Message);
    end;
  finally
    lTool.Free;
  end;
end;

procedure TIMAPMailToolTest.TestToolInheritsFromTMCPTool;
var
  lTool: TTestIMAPMailTool;
begin
  lTool := TTestIMAPMailTool.Create('test-imap-tool', 'Test IMAP tool');
  try
    AssertTrue('TIMAPMailTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

{ TListFoldersToolTest }

procedure TListFoldersToolTest.TestInstantiation;
var
  lTool: TListFoldersTool;
begin
  lTool := TListFoldersTool.Create('list-folders', 'List all available mailbox folders.');
  try
    AssertNotNull('TListFoldersTool should be instantiated', lTool);
    AssertEquals('Tool name should be list-folders', 'list-folders', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TListFoldersToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TListFoldersTool;
begin
  lTool := TListFoldersTool.Create('list-folders', 'List all available mailbox folders.');
  try
    AssertTrue('TListFoldersTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TListFoldersToolTest.TestInheritsFromTMCPTool;
var
  lTool: TListFoldersTool;
begin
  lTool := TListFoldersTool.Create('list-folders', 'List all available mailbox folders.');
  try
    AssertTrue('TListFoldersTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TListFoldersToolTest.TestDescriptionIsSet;
var
  lTool: TListFoldersTool;
begin
  lTool := TListFoldersTool.Create('list-folders', 'List all available mailbox folders.');
  try
    AssertEquals('Description should match constructor argument',
      'List all available mailbox folders.', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TListFoldersToolTest.TestInputSchemaHasNoRequiredArguments;
var
  lTool: TListFoldersTool;
begin
  lTool := TListFoldersTool.Create('list-folders', 'List all available mailbox folders.');
  try
    AssertEquals('list-folders takes no input arguments — Required array must be empty',
      0, Length(lTool.InputSchema.Required));
  finally
    lTool.Free;
  end;
end;

{ TSelectFolderToolTest }

procedure TSelectFolderToolTest.SetUp;
begin
  inherited SetUp;
  TIMAPConnectionManager.Instance.SelectFolder('');
end;

procedure TSelectFolderToolTest.TestInstantiation;
var
  lTool: TSelectFolderTool;
begin
  lTool := TSelectFolderTool.Create('select-folder', 'Select a mailbox folder.');
  try
    AssertNotNull('TSelectFolderTool should be instantiated', lTool);
    AssertEquals('Tool name should be select-folder', 'select-folder', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TSelectFolderToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TSelectFolderTool;
begin
  lTool := TSelectFolderTool.Create('select-folder', 'Select a mailbox folder.');
  try
    AssertTrue('TSelectFolderTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TSelectFolderToolTest.TestInheritsFromTMCPTool;
var
  lTool: TSelectFolderTool;
begin
  lTool := TSelectFolderTool.Create('select-folder', 'Select a mailbox folder.');
  try
    AssertTrue('TSelectFolderTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TSelectFolderToolTest.TestInputSchemaHasFolderArgument;
var
  lTool: TSelectFolderTool;
begin
  lTool := TSelectFolderTool.Create('select-folder', 'Select a mailbox folder.');
  try
    AssertNotNull('InputSchema should have a folder argument',
      lTool.InputSchema.Arguments['folder']);
  finally
    lTool.Free;
  end;
end;

procedure TSelectFolderToolTest.TestConnMgrSelectFolderIsUpdatedAfterSuccess;
begin
  // Verify that ConnMgr.SelectFolder updates the selected folder value
  // (unit-level test — verifies ConnMgr state tracking, not live IMAP)
  TIMAPConnectionManager.Instance.SelectFolder('INBOX');
  AssertEquals('ConnMgr.SelectedFolder should return folder set via SelectFolder',
    'INBOX', TIMAPConnectionManager.Instance.SelectedFolder);
  TIMAPConnectionManager.Instance.SelectFolder('Drafts');
  AssertEquals('ConnMgr.SelectedFolder should update when folder changes',
    'Drafts', TIMAPConnectionManager.Instance.SelectedFolder);
end;

procedure TSelectFolderToolTest.TestDescriptionIsSet;
var
  lTool: TSelectFolderTool;
begin
  lTool := TSelectFolderTool.Create('select-folder', 'Select a mailbox folder.');
  try
    AssertEquals('Description should match constructor argument',
      'Select a mailbox folder.', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TSelectFolderToolTest.TestFolderArgumentHasStringType;
var
  lTool: TSelectFolderTool;
begin
  lTool := TSelectFolderTool.Create('select-folder', 'Select a mailbox folder.');
  try
    AssertEquals('folder argument schema type should be string',
      'string', lTool.InputSchema.Arguments['folder'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TSelectFolderToolTest.TestFolderArgumentIsRequired;
var
  lTool: TSelectFolderTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TSelectFolderTool.Create('select-folder', 'Select a mailbox folder.');
  try
    AssertTrue('InputSchema.Required must be non-empty',
      Length(lTool.InputSchema.Required) > 0);
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'folder' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('folder argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

{ TCountMessagesToolTest }

procedure TCountMessagesToolTest.TestInstantiation;
var
  lTool: TCountMessagesTool;
begin
  lTool := TCountMessagesTool.Create('count-messages', 'Get the total number of messages in the selected folder.');
  try
    AssertNotNull('TCountMessagesTool should be instantiated', lTool);
    AssertEquals('Tool name should be count-messages', 'count-messages', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TCountMessagesToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TCountMessagesTool;
begin
  lTool := TCountMessagesTool.Create('count-messages', 'Get the total number of messages in the selected folder.');
  try
    AssertTrue('TCountMessagesTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TCountMessagesToolTest.TestInheritsFromTMCPTool;
var
  lTool: TCountMessagesTool;
begin
  lTool := TCountMessagesTool.Create('count-messages', 'Get the total number of messages in the selected folder.');
  try
    AssertTrue('TCountMessagesTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TCountMessagesToolTest.TestDescriptionIsSet;
var
  lTool: TCountMessagesTool;
begin
  lTool := TCountMessagesTool.Create('count-messages', 'Get the total number of messages in the selected folder.');
  try
    AssertEquals('Description should match constructor argument',
      'Get the total number of messages in the selected folder.', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TCountMessagesToolTest.TestInputSchemaHasNoRequiredArguments;
var
  lTool: TCountMessagesTool;
begin
  lTool := TCountMessagesTool.Create('count-messages', 'Get the total number of messages in the selected folder.');
  try
    AssertEquals('count-messages takes no input arguments — Required array must be empty',
      0, Length(lTool.InputSchema.Required));
  finally
    lTool.Free;
  end;
end;

{ TCountUnreadToolTest }

procedure TCountUnreadToolTest.TestInstantiation;
var
  lTool: TCountUnreadTool;
begin
  lTool := TCountUnreadTool.Create('count-unread', 'Get the number of unread messages in the selected folder.');
  try
    AssertNotNull('TCountUnreadTool should be instantiated', lTool);
    AssertEquals('Tool name should be count-unread', 'count-unread', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TCountUnreadToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TCountUnreadTool;
begin
  lTool := TCountUnreadTool.Create('count-unread', 'Get the number of unread messages in the selected folder.');
  try
    AssertTrue('TCountUnreadTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TCountUnreadToolTest.TestInheritsFromTMCPTool;
var
  lTool: TCountUnreadTool;
begin
  lTool := TCountUnreadTool.Create('count-unread', 'Get the number of unread messages in the selected folder.');
  try
    AssertTrue('TCountUnreadTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TCountUnreadToolTest.TestDescriptionIsSet;
var
  lTool: TCountUnreadTool;
begin
  lTool := TCountUnreadTool.Create('count-unread', 'Get the number of unread messages in the selected folder.');
  try
    AssertEquals('Description should match constructor argument',
      'Get the number of unread messages in the selected folder.', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TCountUnreadToolTest.TestInputSchemaHasNoRequiredArguments;
var
  lTool: TCountUnreadTool;
begin
  lTool := TCountUnreadTool.Create('count-unread', 'Get the number of unread messages in the selected folder.');
  try
    AssertEquals('count-unread takes no input arguments — Required array must be empty',
      0, Length(lTool.InputSchema.Required));
  finally
    lTool.Free;
  end;
end;

{ TCountDeletedToolTest }

procedure TCountDeletedToolTest.TestInstantiation;
var
  lTool: TCountDeletedTool;
begin
  lTool := TCountDeletedTool.Create('count-deleted', 'Get the number of messages marked for deletion in the selected folder.');
  try
    AssertNotNull('TCountDeletedTool should be instantiated', lTool);
    AssertEquals('Tool name should be count-deleted', 'count-deleted', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TCountDeletedToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TCountDeletedTool;
begin
  lTool := TCountDeletedTool.Create('count-deleted', 'Get the number of messages marked for deletion in the selected folder.');
  try
    AssertTrue('TCountDeletedTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TCountDeletedToolTest.TestInheritsFromTMCPTool;
var
  lTool: TCountDeletedTool;
begin
  lTool := TCountDeletedTool.Create('count-deleted', 'Get the number of messages marked for deletion in the selected folder.');
  try
    AssertTrue('TCountDeletedTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TCountDeletedToolTest.TestDescriptionIsSet;
var
  lTool: TCountDeletedTool;
begin
  lTool := TCountDeletedTool.Create('count-deleted', 'Get the number of messages marked for deletion in the selected folder.');
  try
    AssertEquals('Description should match constructor argument',
      'Get the number of messages marked for deletion in the selected folder.', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TCountDeletedToolTest.TestInputSchemaHasNoRequiredArguments;
var
  lTool: TCountDeletedTool;
begin
  lTool := TCountDeletedTool.Create('count-deleted', 'Get the number of messages marked for deletion in the selected folder.');
  try
    AssertEquals('count-deleted takes no input arguments — Required array must be empty',
      0, Length(lTool.InputSchema.Required));
  finally
    lTool.Free;
  end;
end;

{ TGetHeadersToolTest }

procedure TGetHeadersToolTest.SetUp;
begin
  inherited SetUp;
  TIMAPConnectionManager.Instance.SelectFolder('');
end;

procedure TGetHeadersToolTest.TestInstantiation;
var
  lTool: TGetHeadersTool;
begin
  lTool := TGetHeadersTool.Create('get-headers', 'Get message headers for a range of messages by zero-based index.');
  try
    AssertNotNull('TGetHeadersTool should be instantiated', lTool);
    AssertEquals('Tool name should be get-headers', 'get-headers', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TGetHeadersToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TGetHeadersTool;
begin
  lTool := TGetHeadersTool.Create('get-headers', 'Get message headers for a range of messages by zero-based index.');
  try
    AssertTrue('TGetHeadersTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TGetHeadersToolTest.TestInheritsFromTMCPTool;
var
  lTool: TGetHeadersTool;
begin
  lTool := TGetHeadersTool.Create('get-headers', 'Get message headers for a range of messages by zero-based index.');
  try
    AssertTrue('TGetHeadersTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TGetHeadersToolTest.TestDescriptionIsSet;
var
  lTool: TGetHeadersTool;
begin
  lTool := TGetHeadersTool.Create('get-headers', 'Get message headers for a range of messages by zero-based index.');
  try
    AssertEquals('Description should match constructor argument',
      'Get message headers for a range of messages by zero-based index.', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TGetHeadersToolTest.TestInputSchemaHasFromIndexArg;
var
  lTool: TGetHeadersTool;
begin
  lTool := TGetHeadersTool.Create('get-headers', 'Get message headers for a range of messages by zero-based index.');
  try
    AssertNotNull('InputSchema should have a from_index argument',
      lTool.InputSchema.Arguments['from_index']);
  finally
    lTool.Free;
  end;
end;

procedure TGetHeadersToolTest.TestInputSchemaHasToIndexArg;
var
  lTool: TGetHeadersTool;
begin
  lTool := TGetHeadersTool.Create('get-headers', 'Get message headers for a range of messages by zero-based index.');
  try
    AssertNotNull('InputSchema should have a to_index argument',
      lTool.InputSchema.Arguments['to_index']);
  finally
    lTool.Free;
  end;
end;

procedure TGetHeadersToolTest.TestBothArgsAreRequired;
var
  lTool: TGetHeadersTool;
  lRequired: TStringArray;
  lHasFrom, lHasTo: Boolean;
  i: Integer;
begin
  lTool := TGetHeadersTool.Create('get-headers', 'Get message headers for a range of messages by zero-based index.');
  try
    lRequired := lTool.InputSchema.Required;
    AssertTrue('InputSchema.Required must have at least 2 entries',
      Length(lRequired) >= 2);
    lHasFrom := False;
    lHasTo := False;
    for i := 0 to High(lRequired) do
    begin
      if lRequired[i] = 'from_index' then lHasFrom := True;
      if lRequired[i] = 'to_index' then lHasTo := True;
    end;
    AssertTrue('from_index must be in Required', lHasFrom);
    AssertTrue('to_index must be in Required', lHasTo);
  finally
    lTool.Free;
  end;
end;

procedure TGetHeadersToolTest.TestFromIndexArgHasIntegerType;
var
  lTool: TGetHeadersTool;
begin
  lTool := TGetHeadersTool.Create('get-headers', 'Get message headers for a range of messages by zero-based index.');
  try
    AssertEquals('from_index argument schema type should be integer',
      'integer', lTool.InputSchema.Arguments['from_index'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TGetHeadersToolTest.TestToIndexArgHasIntegerType;
var
  lTool: TGetHeadersTool;
begin
  lTool := TGetHeadersTool.Create('get-headers', 'Get message headers for a range of messages by zero-based index.');
  try
    AssertEquals('to_index argument schema type should be integer',
      'integer', lTool.InputSchema.Arguments['to_index'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TGetHeadersToolTest.TestToIndexLessThanFromIndexRaisesException;
var
  lTool: TGetHeadersTool;
  lInput, lResult: TJSONObject;
begin
  // Set a folder so RequireFolder passes — validation check fires before GetConnection
  TIMAPConnectionManager.Instance.SelectFolder('INBOX');
  lTool := TGetHeadersTool.Create('get-headers', 'Get message headers for a range of messages by zero-based index.');
  lInput := TJSONObject.Create;
  lResult := TJSONObject.Create;
  try
    lInput.Add('from_index', 5);
    lInput.Add('to_index', 2);
    try
      lTool.Execute(lInput, lResult);
      Fail('Expected EMCPException when to_index < from_index');
    except
      on E: EMCPException do
        AssertEquals('Exception message should match validation rule',
          'to_index must be >= from_index', E.Message);
    end;
  finally
    lTool.Free;
    lInput.Free;
    lResult.Free;
  end;
end;

{ TGetMailToolTest }

procedure TGetMailToolTest.SetUp;
begin
  inherited SetUp;
  TIMAPConnectionManager.Instance.SelectFolder('');
end;

procedure TGetMailToolTest.TestInstantiation;
var
  lTool: TGetMailTool;
begin
  lTool := TGetMailTool.Create('get-mail', 'Get the full body of a message by mail ID.');
  try
    AssertNotNull('TGetMailTool should be instantiated', lTool);
    AssertEquals('Tool name should be get-mail', 'get-mail', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TGetMailToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TGetMailTool;
begin
  lTool := TGetMailTool.Create('get-mail', 'Get the full body of a message by mail ID.');
  try
    AssertTrue('TGetMailTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TGetMailToolTest.TestInheritsFromTMCPTool;
var
  lTool: TGetMailTool;
begin
  lTool := TGetMailTool.Create('get-mail', 'Get the full body of a message by mail ID.');
  try
    AssertTrue('TGetMailTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TGetMailToolTest.TestDescriptionIsSet;
var
  lTool: TGetMailTool;
begin
  lTool := TGetMailTool.Create('get-mail', 'Get the full body of a message by mail ID.');
  try
    AssertEquals('Description should match constructor argument',
      'Get the full body of a message by mail ID.', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TGetMailToolTest.TestInputSchemaHasMailIdArg;
var
  lTool: TGetMailTool;
begin
  lTool := TGetMailTool.Create('get-mail', 'Get the full body of a message by mail ID.');
  try
    AssertNotNull('InputSchema should have a mail_id argument',
      lTool.InputSchema.Arguments['mail_id']);
  finally
    lTool.Free;
  end;
end;

procedure TGetMailToolTest.TestMailIdArgHasIntegerType;
var
  lTool: TGetMailTool;
begin
  lTool := TGetMailTool.Create('get-mail', 'Get the full body of a message by mail ID.');
  try
    AssertEquals('mail_id argument schema type should be integer',
      'integer', lTool.InputSchema.Arguments['mail_id'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TGetMailToolTest.TestMailIdArgIsRequired;
var
  lTool: TGetMailTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TGetMailTool.Create('get-mail', 'Get the full body of a message by mail ID.');
  try
    AssertTrue('InputSchema.Required must be non-empty',
      Length(lTool.InputSchema.Required) > 0);
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'mail_id' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('mail_id argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

procedure TGetMailToolTest.TestRaisesWhenNoFolderSelected;
var
  lTool: TGetMailTool;
  lInput, lResult: TJSONObject;
begin
  lTool := TGetMailTool.Create('get-mail', 'Get the full body of a message by mail ID.');
  lInput := TJSONObject.Create;
  lResult := TJSONObject.Create;
  try
    lInput.Add('mail_id', 0);
    try
      lTool.Execute(lInput, lResult);
      Fail('Expected EMCPException when no folder is selected');
    except
      on E: EMCPException do
        AssertEquals('Exception message should match AC #5',
          'No folder selected. Use select-folder first.', E.Message);
    end;
  finally
    lTool.Free;
    lInput.Free;
    lResult.Free;
  end;
end;

{ TMarkReadToolTest }

procedure TMarkReadToolTest.SetUp;
begin
  inherited SetUp;
  TIMAPConnectionManager.Instance.SelectFolder('');
end;

procedure TMarkReadToolTest.TestInstantiation;
var
  lTool: TMarkReadTool;
begin
  lTool := TMarkReadTool.Create('mark-read', 'Mark a message as read (set Seen flag).');
  try
    AssertNotNull('TMarkReadTool should be instantiated', lTool);
    AssertEquals('Tool name should be mark-read', 'mark-read', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TMarkReadToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TMarkReadTool;
begin
  lTool := TMarkReadTool.Create('mark-read', 'Mark a message as read (set Seen flag).');
  try
    AssertTrue('TMarkReadTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TMarkReadToolTest.TestInheritsFromTMCPTool;
var
  lTool: TMarkReadTool;
begin
  lTool := TMarkReadTool.Create('mark-read', 'Mark a message as read (set Seen flag).');
  try
    AssertTrue('TMarkReadTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TMarkReadToolTest.TestDescriptionIsSet;
var
  lTool: TMarkReadTool;
begin
  lTool := TMarkReadTool.Create('mark-read', 'Mark a message as read (set Seen flag).');
  try
    AssertEquals('Description should match constructor argument',
      'Mark a message as read (set Seen flag).', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TMarkReadToolTest.TestInputSchemaHasMailIdArg;
var
  lTool: TMarkReadTool;
begin
  lTool := TMarkReadTool.Create('mark-read', 'Mark a message as read (set Seen flag).');
  try
    AssertNotNull('InputSchema should have a mail_id argument',
      lTool.InputSchema.Arguments['mail_id']);
  finally
    lTool.Free;
  end;
end;

procedure TMarkReadToolTest.TestMailIdArgHasIntegerType;
var
  lTool: TMarkReadTool;
begin
  lTool := TMarkReadTool.Create('mark-read', 'Mark a message as read (set Seen flag).');
  try
    AssertEquals('mail_id argument schema type should be integer',
      'integer', lTool.InputSchema.Arguments['mail_id'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TMarkReadToolTest.TestMailIdArgIsRequired;
var
  lTool: TMarkReadTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TMarkReadTool.Create('mark-read', 'Mark a message as read (set Seen flag).');
  try
    AssertTrue('InputSchema.Required must be non-empty',
      Length(lTool.InputSchema.Required) > 0);
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'mail_id' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('mail_id argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

procedure TMarkReadToolTest.TestRaisesWhenNoFolderSelected;
var
  lTool: TMarkReadTool;
  lInput, lResult: TJSONObject;
begin
  lTool := TMarkReadTool.Create('mark-read', 'Mark a message as read (set Seen flag).');
  lInput := TJSONObject.Create;
  lResult := TJSONObject.Create;
  try
    lInput.Add('mail_id', 0);
    try
      lTool.Execute(lInput, lResult);
      Fail('Expected EMCPException when no folder is selected');
    except
      on E: EMCPException do
        AssertEquals('Exception message should match AC #5',
          'No folder selected. Use select-folder first.', E.Message);
    end;
  finally
    lTool.Free;
    lInput.Free;
    lResult.Free;
  end;
end;

{ TMarkUnreadToolTest }

procedure TMarkUnreadToolTest.SetUp;
begin
  inherited SetUp;
  TIMAPConnectionManager.Instance.SelectFolder('');
end;

procedure TMarkUnreadToolTest.TestInstantiation;
var
  lTool: TMarkUnreadTool;
begin
  lTool := TMarkUnreadTool.Create('mark-unread', 'Mark a message as unread (remove Seen flag).');
  try
    AssertNotNull('TMarkUnreadTool should be instantiated', lTool);
    AssertEquals('Tool name should be mark-unread', 'mark-unread', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUnreadToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TMarkUnreadTool;
begin
  lTool := TMarkUnreadTool.Create('mark-unread', 'Mark a message as unread (remove Seen flag).');
  try
    AssertTrue('TMarkUnreadTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUnreadToolTest.TestInheritsFromTMCPTool;
var
  lTool: TMarkUnreadTool;
begin
  lTool := TMarkUnreadTool.Create('mark-unread', 'Mark a message as unread (remove Seen flag).');
  try
    AssertTrue('TMarkUnreadTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUnreadToolTest.TestDescriptionIsSet;
var
  lTool: TMarkUnreadTool;
begin
  lTool := TMarkUnreadTool.Create('mark-unread', 'Mark a message as unread (remove Seen flag).');
  try
    AssertEquals('Description should match constructor argument',
      'Mark a message as unread (remove Seen flag).', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUnreadToolTest.TestInputSchemaHasMailIdArg;
var
  lTool: TMarkUnreadTool;
begin
  lTool := TMarkUnreadTool.Create('mark-unread', 'Mark a message as unread (remove Seen flag).');
  try
    AssertNotNull('InputSchema should have a mail_id argument',
      lTool.InputSchema.Arguments['mail_id']);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUnreadToolTest.TestMailIdArgHasIntegerType;
var
  lTool: TMarkUnreadTool;
begin
  lTool := TMarkUnreadTool.Create('mark-unread', 'Mark a message as unread (remove Seen flag).');
  try
    AssertEquals('mail_id argument schema type should be integer',
      'integer', lTool.InputSchema.Arguments['mail_id'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TMarkUnreadToolTest.TestMailIdArgIsRequired;
var
  lTool: TMarkUnreadTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TMarkUnreadTool.Create('mark-unread', 'Mark a message as unread (remove Seen flag).');
  try
    AssertTrue('InputSchema.Required must be non-empty',
      Length(lTool.InputSchema.Required) > 0);
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'mail_id' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('mail_id argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUnreadToolTest.TestRaisesWhenNoFolderSelected;
var
  lTool: TMarkUnreadTool;
  lInput, lResult: TJSONObject;
begin
  lTool := TMarkUnreadTool.Create('mark-unread', 'Mark a message as unread (remove Seen flag).');
  lInput := TJSONObject.Create;
  lResult := TJSONObject.Create;
  try
    lInput.Add('mail_id', 0);
    try
      lTool.Execute(lInput, lResult);
      Fail('Expected EMCPException when no folder is selected');
    except
      on E: EMCPException do
        AssertEquals('Exception message should match AC #5',
          'No folder selected. Use select-folder first.', E.Message);
    end;
  finally
    lTool.Free;
    lInput.Free;
    lResult.Free;
  end;
end;

{ TMoveMailToolTest }

procedure TMoveMailToolTest.SetUp;
begin
  inherited SetUp;
  TIMAPConnectionManager.Instance.SelectFolder('');
end;

procedure TMoveMailToolTest.TestInstantiation;
var
  lTool: TMoveMailTool;
begin
  lTool := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
  try
    AssertNotNull('TMoveMailTool should be instantiated', lTool);
    AssertEquals('Tool name should be move-mail', 'move-mail', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TMoveMailToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TMoveMailTool;
begin
  lTool := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
  try
    AssertTrue('TMoveMailTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TMoveMailToolTest.TestInheritsFromTMCPTool;
var
  lTool: TMoveMailTool;
begin
  lTool := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
  try
    AssertTrue('TMoveMailTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TMoveMailToolTest.TestDescriptionIsSet;
var
  lTool: TMoveMailTool;
begin
  lTool := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
  try
    AssertEquals('Description should match constructor argument',
      'Move a message to another folder.', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TMoveMailToolTest.TestInputSchemaHasMailIdArg;
var
  lTool: TMoveMailTool;
begin
  lTool := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
  try
    AssertNotNull('InputSchema should have a mail_id argument',
      lTool.InputSchema.Arguments['mail_id']);
  finally
    lTool.Free;
  end;
end;

procedure TMoveMailToolTest.TestMailIdArgHasIntegerType;
var
  lTool: TMoveMailTool;
begin
  lTool := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
  try
    AssertEquals('mail_id argument schema type should be integer',
      'integer', lTool.InputSchema.Arguments['mail_id'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TMoveMailToolTest.TestMailIdArgIsRequired;
var
  lTool: TMoveMailTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
  try
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'mail_id' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('mail_id argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

procedure TMoveMailToolTest.TestInputSchemaHasTargetFolderArg;
var
  lTool: TMoveMailTool;
begin
  lTool := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
  try
    AssertNotNull('InputSchema should have a target_folder argument',
      lTool.InputSchema.Arguments['target_folder']);
  finally
    lTool.Free;
  end;
end;

procedure TMoveMailToolTest.TestTargetFolderArgHasStringType;
var
  lTool: TMoveMailTool;
begin
  lTool := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
  try
    AssertEquals('target_folder argument schema type should be string',
      'string', lTool.InputSchema.Arguments['target_folder'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TMoveMailToolTest.TestTargetFolderArgIsRequired;
var
  lTool: TMoveMailTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
  try
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'target_folder' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('target_folder argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

procedure TMoveMailToolTest.TestRaisesWhenNoFolderSelected;
var
  lTool: TMoveMailTool;
  lInput, lResult: TJSONObject;
begin
  lTool := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
  lInput := TJSONObject.Create;
  lResult := TJSONObject.Create;
  try
    lInput.Add('mail_id', 0);
    lInput.Add('target_folder', 'INBOX');
    try
      lTool.Execute(lInput, lResult);
      Fail('Expected EMCPException when no folder is selected');
    except
      on E: EMCPException do
        AssertEquals('Exception message should match AC #6',
          'No folder selected. Use select-folder first.', E.Message);
    end;
  finally
    lTool.Free;
    lInput.Free;
    lResult.Free;
  end;
end;

{ TMarkDeletedToolTest }

procedure TMarkDeletedToolTest.SetUp;
begin
  inherited SetUp;
  TIMAPConnectionManager.Instance.SelectFolder('');
end;

procedure TMarkDeletedToolTest.TestInstantiation;
var
  lTool: TMarkDeletedTool;
begin
  lTool := TMarkDeletedTool.Create('mark-deleted', 'Mark a message for deletion (set Deleted flag).');
  try
    AssertNotNull('TMarkDeletedTool should be instantiated', lTool);
    AssertEquals('Tool name should be mark-deleted', 'mark-deleted', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TMarkDeletedToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TMarkDeletedTool;
begin
  lTool := TMarkDeletedTool.Create('mark-deleted', 'Mark a message for deletion (set Deleted flag).');
  try
    AssertTrue('TMarkDeletedTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TMarkDeletedToolTest.TestInheritsFromTMCPTool;
var
  lTool: TMarkDeletedTool;
begin
  lTool := TMarkDeletedTool.Create('mark-deleted', 'Mark a message for deletion (set Deleted flag).');
  try
    AssertTrue('TMarkDeletedTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TMarkDeletedToolTest.TestDescriptionIsSet;
var
  lTool: TMarkDeletedTool;
begin
  lTool := TMarkDeletedTool.Create('mark-deleted', 'Mark a message for deletion (set Deleted flag).');
  try
    AssertEquals('Description should match constructor argument',
      'Mark a message for deletion (set Deleted flag).', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TMarkDeletedToolTest.TestInputSchemaHasMailIdArg;
var
  lTool: TMarkDeletedTool;
begin
  lTool := TMarkDeletedTool.Create('mark-deleted', 'Mark a message for deletion (set Deleted flag).');
  try
    AssertNotNull('InputSchema should have a mail_id argument',
      lTool.InputSchema.Arguments['mail_id']);
  finally
    lTool.Free;
  end;
end;

procedure TMarkDeletedToolTest.TestMailIdArgHasIntegerType;
var
  lTool: TMarkDeletedTool;
begin
  lTool := TMarkDeletedTool.Create('mark-deleted', 'Mark a message for deletion (set Deleted flag).');
  try
    AssertEquals('mail_id argument schema type should be integer',
      'integer', lTool.InputSchema.Arguments['mail_id'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TMarkDeletedToolTest.TestMailIdArgIsRequired;
var
  lTool: TMarkDeletedTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TMarkDeletedTool.Create('mark-deleted', 'Mark a message for deletion (set Deleted flag).');
  try
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'mail_id' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('mail_id argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

procedure TMarkDeletedToolTest.TestRaisesWhenNoFolderSelected;
var
  lTool: TMarkDeletedTool;
  lInput, lResult: TJSONObject;
begin
  lTool := TMarkDeletedTool.Create('mark-deleted', 'Mark a message for deletion (set Deleted flag).');
  lInput := TJSONObject.Create;
  lResult := TJSONObject.Create;
  try
    lInput.Add('mail_id', 0);
    try
      lTool.Execute(lInput, lResult);
      Fail('Expected EMCPException when no folder is selected');
    except
      on E: EMCPException do
        AssertEquals('Exception message should match AC #6',
          'No folder selected. Use select-folder first.', E.Message);
    end;
  finally
    lTool.Free;
    lInput.Free;
    lResult.Free;
  end;
end;

{ TMarkUndeletedToolTest }

procedure TMarkUndeletedToolTest.SetUp;
begin
  inherited SetUp;
  TIMAPConnectionManager.Instance.SelectFolder('');
end;

procedure TMarkUndeletedToolTest.TestInstantiation;
var
  lTool: TMarkUndeletedTool;
begin
  lTool := TMarkUndeletedTool.Create('mark-undeleted', 'Remove deletion mark from a message (clear Deleted flag).');
  try
    AssertNotNull('TMarkUndeletedTool should be instantiated', lTool);
    AssertEquals('Tool name should be mark-undeleted', 'mark-undeleted', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUndeletedToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TMarkUndeletedTool;
begin
  lTool := TMarkUndeletedTool.Create('mark-undeleted', 'Remove deletion mark from a message (clear Deleted flag).');
  try
    AssertTrue('TMarkUndeletedTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUndeletedToolTest.TestInheritsFromTMCPTool;
var
  lTool: TMarkUndeletedTool;
begin
  lTool := TMarkUndeletedTool.Create('mark-undeleted', 'Remove deletion mark from a message (clear Deleted flag).');
  try
    AssertTrue('TMarkUndeletedTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUndeletedToolTest.TestDescriptionIsSet;
var
  lTool: TMarkUndeletedTool;
begin
  lTool := TMarkUndeletedTool.Create('mark-undeleted', 'Remove deletion mark from a message (clear Deleted flag).');
  try
    AssertEquals('Description should match constructor argument',
      'Remove deletion mark from a message (clear Deleted flag).', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUndeletedToolTest.TestInputSchemaHasMailIdArg;
var
  lTool: TMarkUndeletedTool;
begin
  lTool := TMarkUndeletedTool.Create('mark-undeleted', 'Remove deletion mark from a message (clear Deleted flag).');
  try
    AssertNotNull('InputSchema should have a mail_id argument',
      lTool.InputSchema.Arguments['mail_id']);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUndeletedToolTest.TestMailIdArgHasIntegerType;
var
  lTool: TMarkUndeletedTool;
begin
  lTool := TMarkUndeletedTool.Create('mark-undeleted', 'Remove deletion mark from a message (clear Deleted flag).');
  try
    AssertEquals('mail_id argument schema type should be integer',
      'integer', lTool.InputSchema.Arguments['mail_id'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TMarkUndeletedToolTest.TestMailIdArgIsRequired;
var
  lTool: TMarkUndeletedTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TMarkUndeletedTool.Create('mark-undeleted', 'Remove deletion mark from a message (clear Deleted flag).');
  try
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'mail_id' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('mail_id argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

procedure TMarkUndeletedToolTest.TestRaisesWhenNoFolderSelected;
var
  lTool: TMarkUndeletedTool;
  lInput, lResult: TJSONObject;
begin
  lTool := TMarkUndeletedTool.Create('mark-undeleted', 'Remove deletion mark from a message (clear Deleted flag).');
  lInput := TJSONObject.Create;
  lResult := TJSONObject.Create;
  try
    lInput.Add('mail_id', 0);
    try
      lTool.Execute(lInput, lResult);
      Fail('Expected EMCPException when no folder is selected');
    except
      on E: EMCPException do
        AssertEquals('Exception message should match AC #6',
          'No folder selected. Use select-folder first.', E.Message);
    end;
  finally
    lTool.Free;
    lInput.Free;
    lResult.Free;
  end;
end;

{ TExpungeFolderToolTest }

procedure TExpungeFolderToolTest.SetUp;
begin
  inherited SetUp;
  TIMAPConnectionManager.Instance.SelectFolder('');
end;

procedure TExpungeFolderToolTest.TestInstantiation;
var
  lTool: TExpungeFolderTool;
begin
  lTool := TExpungeFolderTool.Create('expunge-folder', 'Permanently remove all messages marked for deletion in the selected folder.');
  try
    AssertNotNull('TExpungeFolderTool should be instantiated', lTool);
    AssertEquals('Tool name should be expunge-folder', 'expunge-folder', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TExpungeFolderToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TExpungeFolderTool;
begin
  lTool := TExpungeFolderTool.Create('expunge-folder', 'Permanently remove all messages marked for deletion in the selected folder.');
  try
    AssertTrue('TExpungeFolderTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TExpungeFolderToolTest.TestInheritsFromTMCPTool;
var
  lTool: TExpungeFolderTool;
begin
  lTool := TExpungeFolderTool.Create('expunge-folder', 'Permanently remove all messages marked for deletion in the selected folder.');
  try
    AssertTrue('TExpungeFolderTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TExpungeFolderToolTest.TestDescriptionIsSet;
var
  lTool: TExpungeFolderTool;
begin
  lTool := TExpungeFolderTool.Create('expunge-folder', 'Permanently remove all messages marked for deletion in the selected folder.');
  try
    AssertEquals('Description should match constructor argument',
      'Permanently remove all messages marked for deletion in the selected folder.',
      lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TExpungeFolderToolTest.TestInputSchemaHasNoRequiredArguments;
var
  lTool: TExpungeFolderTool;
begin
  lTool := TExpungeFolderTool.Create('expunge-folder', 'Permanently remove all messages marked for deletion in the selected folder.');
  try
    AssertEquals('expunge-folder takes no input arguments — Required array must be empty',
      0, Length(lTool.InputSchema.Required));
  finally
    lTool.Free;
  end;
end;

procedure TExpungeFolderToolTest.TestRaisesWhenNoFolderSelected;
var
  lTool: TExpungeFolderTool;
  lInput, lResult: TJSONObject;
begin
  lTool := TExpungeFolderTool.Create('expunge-folder', 'Permanently remove all messages marked for deletion in the selected folder.');
  lInput := TJSONObject.Create;
  lResult := TJSONObject.Create;
  try
    try
      lTool.Execute(lInput, lResult);
      Fail('Expected EMCPException when no folder is selected');
    except
      on E: EMCPException do
        AssertEquals('Exception message should match AC #6',
          'No folder selected. Use select-folder first.', E.Message);
    end;
  finally
    lTool.Free;
    lInput.Free;
    lResult.Free;
  end;
end;

{ TCreateFolderToolTest }

procedure TCreateFolderToolTest.TestInstantiation;
var
  lTool: TCreateFolderTool;
begin
  lTool := TCreateFolderTool.Create('create-folder', 'Create a new mailbox folder.');
  try
    AssertNotNull('TCreateFolderTool should be instantiated', lTool);
    AssertEquals('Tool name should be create-folder', 'create-folder', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TCreateFolderToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TCreateFolderTool;
begin
  lTool := TCreateFolderTool.Create('create-folder', 'Create a new mailbox folder.');
  try
    AssertTrue('TCreateFolderTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TCreateFolderToolTest.TestInheritsFromTMCPTool;
var
  lTool: TCreateFolderTool;
begin
  lTool := TCreateFolderTool.Create('create-folder', 'Create a new mailbox folder.');
  try
    AssertTrue('TCreateFolderTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TCreateFolderToolTest.TestDescriptionIsSet;
var
  lTool: TCreateFolderTool;
begin
  lTool := TCreateFolderTool.Create('create-folder', 'Create a new mailbox folder.');
  try
    AssertEquals('Description should match constructor argument',
      'Create a new mailbox folder.', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TCreateFolderToolTest.TestInputSchemaHasFolderNameArg;
var
  lTool: TCreateFolderTool;
begin
  lTool := TCreateFolderTool.Create('create-folder', 'Create a new mailbox folder.');
  try
    AssertNotNull('InputSchema should have a folder_name argument',
      lTool.InputSchema.Arguments['folder_name']);
  finally
    lTool.Free;
  end;
end;

procedure TCreateFolderToolTest.TestFolderNameArgHasStringType;
var
  lTool: TCreateFolderTool;
begin
  lTool := TCreateFolderTool.Create('create-folder', 'Create a new mailbox folder.');
  try
    AssertEquals('folder_name argument schema type should be string',
      'string', lTool.InputSchema.Arguments['folder_name'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TCreateFolderToolTest.TestFolderNameArgIsRequired;
var
  lTool: TCreateFolderTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TCreateFolderTool.Create('create-folder', 'Create a new mailbox folder.');
  try
    AssertTrue('InputSchema.Required must be non-empty',
      Length(lTool.InputSchema.Required) > 0);
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'folder_name' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('folder_name argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

{ TDeleteFolderToolTest }

procedure TDeleteFolderToolTest.TestInstantiation;
var
  lTool: TDeleteFolderTool;
begin
  lTool := TDeleteFolderTool.Create('delete-folder', 'Delete a mailbox folder.');
  try
    AssertNotNull('TDeleteFolderTool should be instantiated', lTool);
    AssertEquals('Tool name should be delete-folder', 'delete-folder', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TDeleteFolderToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TDeleteFolderTool;
begin
  lTool := TDeleteFolderTool.Create('delete-folder', 'Delete a mailbox folder.');
  try
    AssertTrue('TDeleteFolderTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TDeleteFolderToolTest.TestInheritsFromTMCPTool;
var
  lTool: TDeleteFolderTool;
begin
  lTool := TDeleteFolderTool.Create('delete-folder', 'Delete a mailbox folder.');
  try
    AssertTrue('TDeleteFolderTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TDeleteFolderToolTest.TestDescriptionIsSet;
var
  lTool: TDeleteFolderTool;
begin
  lTool := TDeleteFolderTool.Create('delete-folder', 'Delete a mailbox folder.');
  try
    AssertEquals('Description should match constructor argument',
      'Delete a mailbox folder.', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TDeleteFolderToolTest.TestInputSchemaHasFolderNameArg;
var
  lTool: TDeleteFolderTool;
begin
  lTool := TDeleteFolderTool.Create('delete-folder', 'Delete a mailbox folder.');
  try
    AssertNotNull('InputSchema should have a folder_name argument',
      lTool.InputSchema.Arguments['folder_name']);
  finally
    lTool.Free;
  end;
end;

procedure TDeleteFolderToolTest.TestFolderNameArgHasStringType;
var
  lTool: TDeleteFolderTool;
begin
  lTool := TDeleteFolderTool.Create('delete-folder', 'Delete a mailbox folder.');
  try
    AssertEquals('folder_name argument schema type should be string',
      'string', lTool.InputSchema.Arguments['folder_name'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TDeleteFolderToolTest.TestFolderNameArgIsRequired;
var
  lTool: TDeleteFolderTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TDeleteFolderTool.Create('delete-folder', 'Delete a mailbox folder.');
  try
    AssertTrue('InputSchema.Required must be non-empty',
      Length(lTool.InputSchema.Required) > 0);
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'folder_name' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('folder_name argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

{ TRenameFolderToolTest }

procedure TRenameFolderToolTest.TestInstantiation;
var
  lTool: TRenameFolderTool;
begin
  lTool := TRenameFolderTool.Create('rename-folder', 'Rename a mailbox folder.');
  try
    AssertNotNull('TRenameFolderTool should be instantiated', lTool);
    AssertEquals('Tool name should be rename-folder', 'rename-folder', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TRenameFolderToolTest.TestInheritsFromTIMAPMailTool;
var
  lTool: TRenameFolderTool;
begin
  lTool := TRenameFolderTool.Create('rename-folder', 'Rename a mailbox folder.');
  try
    AssertTrue('TRenameFolderTool should inherit from TIMAPMailTool',
      lTool is TIMAPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TRenameFolderToolTest.TestInheritsFromTMCPTool;
var
  lTool: TRenameFolderTool;
begin
  lTool := TRenameFolderTool.Create('rename-folder', 'Rename a mailbox folder.');
  try
    AssertTrue('TRenameFolderTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TRenameFolderToolTest.TestDescriptionIsSet;
var
  lTool: TRenameFolderTool;
begin
  lTool := TRenameFolderTool.Create('rename-folder', 'Rename a mailbox folder.');
  try
    AssertEquals('Description should match constructor argument',
      'Rename a mailbox folder.', lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TRenameFolderToolTest.TestInputSchemaHasFolderNameArg;
var
  lTool: TRenameFolderTool;
begin
  lTool := TRenameFolderTool.Create('rename-folder', 'Rename a mailbox folder.');
  try
    AssertNotNull('InputSchema should have a folder_name argument',
      lTool.InputSchema.Arguments['folder_name']);
  finally
    lTool.Free;
  end;
end;

procedure TRenameFolderToolTest.TestFolderNameArgHasStringType;
var
  lTool: TRenameFolderTool;
begin
  lTool := TRenameFolderTool.Create('rename-folder', 'Rename a mailbox folder.');
  try
    AssertEquals('folder_name argument schema type should be string',
      'string', lTool.InputSchema.Arguments['folder_name'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TRenameFolderToolTest.TestFolderNameArgIsRequired;
var
  lTool: TRenameFolderTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TRenameFolderTool.Create('rename-folder', 'Rename a mailbox folder.');
  try
    AssertTrue('InputSchema.Required must be non-empty',
      Length(lTool.InputSchema.Required) > 0);
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'folder_name' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('folder_name argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

procedure TRenameFolderToolTest.TestInputSchemaHasNewNameArg;
var
  lTool: TRenameFolderTool;
begin
  lTool := TRenameFolderTool.Create('rename-folder', 'Rename a mailbox folder.');
  try
    AssertNotNull('InputSchema should have a new_name argument',
      lTool.InputSchema.Arguments['new_name']);
  finally
    lTool.Free;
  end;
end;

procedure TRenameFolderToolTest.TestNewNameArgHasStringType;
var
  lTool: TRenameFolderTool;
begin
  lTool := TRenameFolderTool.Create('rename-folder', 'Rename a mailbox folder.');
  try
    AssertEquals('new_name argument schema type should be string',
      'string', lTool.InputSchema.Arguments['new_name'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TRenameFolderToolTest.TestNewNameArgIsRequired;
var
  lTool: TRenameFolderTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TRenameFolderTool.Create('rename-folder', 'Rename a mailbox folder.');
  try
    AssertTrue('InputSchema.Required must be non-empty',
      Length(lTool.InputSchema.Required) > 0);
    lFound := False;
    for i := 0 to High(lTool.InputSchema.Required) do
      if lTool.InputSchema.Required[i] = 'new_name' then
      begin
        lFound := True;
        Break;
      end;
    AssertTrue('new_name argument must be in InputSchema.Required', lFound);
  finally
    lTool.Free;
  end;
end;

initialization
  RegisterTests([TIMAPConnectionManagerTest, TIMAPMailToolTest,
    TListFoldersToolTest, TSelectFolderToolTest,
    TCountMessagesToolTest, TCountUnreadToolTest, TCountDeletedToolTest,
    TGetHeadersToolTest,
    TGetMailToolTest, TMarkReadToolTest, TMarkUnreadToolTest,
    TMoveMailToolTest, TMarkDeletedToolTest, TMarkUndeletedToolTest,
    TExpungeFolderToolTest,
    TCreateFolderToolTest, TDeleteFolderToolTest, TRenameFolderToolTest]);
end.

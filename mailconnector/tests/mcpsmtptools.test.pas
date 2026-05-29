unit mcpsmtptools.test;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson,
  mcp.types, mcp.tools, mcpsmtptools;

type

  { TTestSMTPMailTool - concrete subclass for testing abstract TSMTPMailTool }

  TTestSMTPMailTool = class(TSMTPMailTool)
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    function ExposedGetSMTPConfig: TSMTPConfig;
  end;

  { TSMTPConfigTest }

  TSMTPConfigTest = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestSMTPConfigStoresHost;
    procedure TestSMTPConfigStoresPort;
    procedure TestSMTPConfigStoresUser;
    procedure TestSMTPConfigStoresPassword;
    procedure TestSMTPConfigStoresTLS;
    procedure TestSMTPConfigDefaultValues;
  end;

  { TSMTPMailToolTest }

  TSMTPMailToolTest = class(TTestCase)
  published
    procedure TestGetSMTPConfigReturnsGlobal;
    procedure TestToolInheritsFromTMCPTool;
  end;

  { TSendMailToolTest }

  TSendMailToolTest = class(TTestCase)
  published
    procedure TestInstantiation;
    procedure TestInheritsFromTSMTPMailTool;
    procedure TestInheritsFromTMCPTool;
    procedure TestDescriptionIsSet;
    procedure TestInputSchemaHasRecipientsArg;
    procedure TestRecipientsArgIsRequired;
    procedure TestInputSchemaHasBodyArg;
    procedure TestBodyArgHasStringType;
    procedure TestBodyArgIsRequired;
    procedure TestInputSchemaHasAttachmentsArg;
    procedure TestAttachmentsArgIsRequired;
    procedure TestRecipientsArgHasArrayType;
    procedure TestAttachmentsArgHasArrayType;
    procedure TestEmptyRecipientsRaisesException;
    procedure TestMissingAttachmentRaisesException;
  end;

implementation

{ TTestSMTPMailTool }

procedure TTestSMTPMailTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
begin
  // No-op for testing
end;

function TTestSMTPMailTool.ExposedGetSMTPConfig: TSMTPConfig;
begin
  Result := GetSMTPConfig;
end;

{ TSMTPConfigTest }

procedure TSMTPConfigTest.SetUp;
begin
  inherited SetUp;
  // Reset global config between tests
  SMTPConfig.Host := '';
  SMTPConfig.Port := '';
  SMTPConfig.User := '';
  SMTPConfig.Password := '';
  SMTPConfig.TLS := False;
end;

procedure TSMTPConfigTest.TestSMTPConfigStoresHost;
begin
  SMTPConfig.Host := 'smtp.test.com';
  AssertEquals('Host should be stored', 'smtp.test.com', SMTPConfig.Host);
end;

procedure TSMTPConfigTest.TestSMTPConfigStoresPort;
begin
  SMTPConfig.Port := '587';
  AssertEquals('Port should be stored', '587', SMTPConfig.Port);
end;

procedure TSMTPConfigTest.TestSMTPConfigStoresUser;
begin
  SMTPConfig.User := 'user@test.com';
  AssertEquals('User should be stored', 'user@test.com', SMTPConfig.User);
end;

procedure TSMTPConfigTest.TestSMTPConfigStoresPassword;
begin
  SMTPConfig.Password := 'secret123';
  AssertEquals('Password should be stored', 'secret123', SMTPConfig.Password);
end;

procedure TSMTPConfigTest.TestSMTPConfigStoresTLS;
begin
  SMTPConfig.TLS := True;
  AssertTrue('TLS should be stored as True', SMTPConfig.TLS);
end;

procedure TSMTPConfigTest.TestSMTPConfigDefaultValues;
begin
  AssertEquals('Host should default to empty', '', SMTPConfig.Host);
  AssertEquals('Port should default to empty', '', SMTPConfig.Port);
  AssertEquals('User should default to empty', '', SMTPConfig.User);
  AssertEquals('Password should default to empty', '', SMTPConfig.Password);
  AssertFalse('TLS should default to False', SMTPConfig.TLS);
end;

{ TSMTPMailToolTest }

procedure TSMTPMailToolTest.TestGetSMTPConfigReturnsGlobal;
var
  lTool: TTestSMTPMailTool;
  lConfig: TSMTPConfig;
begin
  SMTPConfig.Host := 'smtp.example.com';
  SMTPConfig.Port := '465';
  SMTPConfig.User := 'test@example.com';
  SMTPConfig.Password := 'pass';
  SMTPConfig.TLS := True;

  lTool := TTestSMTPMailTool.Create('test-smtp-tool', 'Test SMTP tool');
  try
    lConfig := lTool.ExposedGetSMTPConfig;
    AssertEquals('GetSMTPConfig should return global Host',
      'smtp.example.com', lConfig.Host);
    AssertEquals('GetSMTPConfig should return global Port',
      '465', lConfig.Port);
    AssertEquals('GetSMTPConfig should return global User',
      'test@example.com', lConfig.User);
    AssertEquals('GetSMTPConfig should return global Password',
      'pass', lConfig.Password);
    AssertTrue('GetSMTPConfig should return global TLS',
      lConfig.TLS);
  finally
    lTool.Free;
  end;
end;

procedure TSMTPMailToolTest.TestToolInheritsFromTMCPTool;
var
  lTool: TTestSMTPMailTool;
begin
  lTool := TTestSMTPMailTool.Create('test-smtp-tool', 'Test SMTP tool');
  try
    AssertTrue('TSMTPMailTool should inherit from TMCPTool',
      lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

{ TSendMailToolTest }

procedure TSendMailToolTest.TestInstantiation;
var
  lTool: TSendMailTool;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    AssertEquals('Name should be send-mail', 'send-mail', lTool.Name);
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestInheritsFromTSMTPMailTool;
var
  lTool: TSendMailTool;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    AssertTrue('TSendMailTool should inherit from TSMTPMailTool', lTool is TSMTPMailTool);
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestInheritsFromTMCPTool;
var
  lTool: TSendMailTool;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    AssertTrue('TSendMailTool should inherit from TMCPTool', lTool is TMCPTool);
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestDescriptionIsSet;
var
  lTool: TSendMailTool;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    AssertEquals('Description should match',
      'Send an email with recipients, body, and optional file attachments.',
      lTool.Description);
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestInputSchemaHasRecipientsArg;
var
  lTool: TSendMailTool;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    AssertNotNull('InputSchema should have recipients argument',
      lTool.InputSchema.Arguments['recipients']);
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestRecipientsArgIsRequired;
var
  lTool: TSendMailTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    lFound := False;
    for i := 0 to Length(lTool.InputSchema.Required) - 1 do
      if lTool.InputSchema.Required[i] = 'recipients' then
        lFound := True;
    AssertTrue('recipients argument should be required', lFound);
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestInputSchemaHasBodyArg;
var
  lTool: TSendMailTool;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    AssertNotNull('InputSchema should have body argument',
      lTool.InputSchema.Arguments['body']);
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestBodyArgHasStringType;
var
  lTool: TSendMailTool;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    AssertEquals('body argument should have string type',
      'string', lTool.InputSchema.Arguments['body'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestBodyArgIsRequired;
var
  lTool: TSendMailTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    lFound := False;
    for i := 0 to Length(lTool.InputSchema.Required) - 1 do
      if lTool.InputSchema.Required[i] = 'body' then
        lFound := True;
    AssertTrue('body argument should be required', lFound);
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestInputSchemaHasAttachmentsArg;
var
  lTool: TSendMailTool;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    AssertNotNull('InputSchema should have attachments argument',
      lTool.InputSchema.Arguments['attachments']);
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestAttachmentsArgIsRequired;
var
  lTool: TSendMailTool;
  i: Integer;
  lFound: Boolean;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    lFound := False;
    for i := 0 to Length(lTool.InputSchema.Required) - 1 do
      if lTool.InputSchema.Required[i] = 'attachments' then
        lFound := True;
    AssertTrue('attachments argument should be required', lFound);
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestRecipientsArgHasArrayType;
var
  lTool: TSendMailTool;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    AssertEquals('recipients argument should have array type',
      'array', lTool.InputSchema.Arguments['recipients'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestAttachmentsArgHasArrayType;
var
  lTool: TSendMailTool;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  try
    AssertEquals('attachments argument should have array type',
      'array', lTool.InputSchema.Arguments['attachments'].Get('type', ''));
  finally
    lTool.Free;
  end;
end;

procedure TSendMailToolTest.TestEmptyRecipientsRaisesException;
var
  lTool: TSendMailTool;
  lInput: TJSONObject;
  lResult: TJSONObject;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  lInput := TJSONObject.Create;
  lResult := TJSONObject.Create;
  try
    lInput.Add('recipients', TJSONArray.Create);
    lInput.Add('body', 'Test body');
    lInput.Add('attachments', TJSONArray.Create);
    try
      lTool.Execute(lInput, lResult);
      Fail('Expected EMCPException when recipients is empty');
    except
      on E: EMCPException do
        AssertEquals('Exception message should match',
          'recipients must not be empty', E.Message);
    end;
  finally
    lTool.Free;
    lInput.Free;
    lResult.Free;
  end;
end;

procedure TSendMailToolTest.TestMissingAttachmentRaisesException;
var
  lTool: TSendMailTool;
  lInput: TJSONObject;
  lResult: TJSONObject;
  lRecipients: TJSONArray;
  lAttachments: TJSONArray;
begin
  lTool := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
  lInput := TJSONObject.Create;
  lResult := TJSONObject.Create;
  try
    lRecipients := TJSONArray.Create;
    lRecipients.Add('test@example.com');
    lInput.Add('recipients', lRecipients);
    lInput.Add('body', 'Test body');
    lAttachments := TJSONArray.Create;
    lAttachments.Add('/nonexistent/path/does-not-exist.txt');
    lInput.Add('attachments', lAttachments);
    try
      lTool.Execute(lInput, lResult);
      Fail('Expected EMCPException when attachment file does not exist');
    except
      on E: EMCPException do
        AssertTrue('Exception message should mention file not found',
          Pos('Attachment file not found', E.Message) > 0);
    end;
  finally
    lTool.Free;
    lInput.Free;
    lResult.Free;
  end;
end;

initialization
  RegisterTests([TSMTPConfigTest, TSMTPMailToolTest, TSendMailToolTest]);
end.

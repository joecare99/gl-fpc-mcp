{
    This file is part of the Free Component Library

    Mail handling MCP Server
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

program mcpmailserver;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  jsonparser,
  fpjson,
  sysutils,
  classes,
  inifiles,
  dateutils,
  mcp.application.stdio,
  mcp.types,
  mcp.logging,
  mcp.tools,
  mcpmailtools,
  mcpsmtptools;

const
  sIMAP = 'IMAP';
  sSMTP = 'SMTP';
  keyHost = 'Host';
  keyPort = 'Port';
  keyUser = 'User';
  keyPassword = 'Password';
  keyTLS = 'TLS';
  keyConfig = 'config';
  keyAllowWrite = 'allow-write';
  keyAllowSend = 'allow-send';
  keyHelp = 'help';
  keyVerbose = 'verbose';
  keyQuiet = 'quiet';

  LongOptions: array of string = (
    keyConfig+':', keyAllowWrite, keyAllowSend,
    keyHelp, keyVerbose, keyQuiet);

type

  { TApplication }

  TApplication = class(TMCPStdioApplication)
  private
    FAllowWrite: Boolean;
    FAllowSend: Boolean;
    procedure DoMCPLog(aType: TMCPLogType; const aMessage: string);
    procedure RegisterTools;
  protected
    procedure DoRun; override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure ParseOptions;
    procedure Usage(aMsg: string);
  end;

{ TApplication }

procedure TApplication.DoRun;
var
  S: String;
begin
  Terminate;
  S := CheckOptions('c:wshvq', LongOptions);
  if (S <> '') or HasOption('h', keyHelp) then
  begin
    Usage(S);
    Exit;
  end;
  ParseOptions;
  RegisterTools;
  inherited DoRun;
end;

procedure TApplication.ParseOptions;
var
  lIni: TCustomIniFile;
  lConfigFile: String;
begin
  if not HasOption('c', keyConfig) then
    raise EMCPException.Create('Configuration file is required. Use -c or --config option.');

  lConfigFile := GetOptionValue('c', keyConfig);
  lIni := TMemIniFile.Create(lConfigFile);
  try
    // IMAP config
    TIMAPConnectionManager.Instance.SetConfig(
      lIni.ReadString(sIMAP, keyHost, ''),
      lIni.ReadString(sIMAP, keyPort, '993'),
      lIni.ReadString(sIMAP, keyUser, ''),
      lIni.ReadString(sIMAP, keyPassword, ''),
      lIni.ReadBool(sIMAP, keyTLS, True)
    );

    // SMTP config
    SMTPConfig.Host := lIni.ReadString(sSMTP, keyHost, '');
    SMTPConfig.Port := lIni.ReadString(sSMTP, keyPort, '587');
    SMTPConfig.User := lIni.ReadString(sSMTP, keyUser, '');
    SMTPConfig.Password := lIni.ReadString(sSMTP, keyPassword, '');
    SMTPConfig.TLS := lIni.ReadBool(sSMTP, keyTLS, True);
  finally
    lIni.Free;
  end;

  // Permission flags
  FAllowWrite := HasOption('w', keyAllowWrite);
  FAllowSend := HasOption('s', keyAllowSend);

  // Logging level
  if HasOption('v', keyVerbose) then
    MCPLogger.LogLevels := [Low(TMCPLogType)..High(TMCPLogType)];
  if HasOption('q', keyQuiet) then
    MCPLogger.LogLevels := [mltError];
end;

procedure TApplication.RegisterTools;
var
  T: TMCPTool;
begin
  // Always-registered read tools
  T := TListFoldersTool.Create('list-folders', 'List all available mailbox folders.');
  T.Register;
  T := TSelectFolderTool.Create('select-folder', 'Select a mailbox folder for use by subsequent commands.');
  T.Register;
  T := TCountMessagesTool.Create('count-messages', 'Get the total number of messages in the selected folder.');
  T.Register;
  T := TCountUnreadTool.Create('count-unread', 'Get the number of unread messages in the selected folder.');
  T.Register;
  T := TCountDeletedTool.Create('count-deleted', 'Get the number of messages marked for deletion in the selected folder.');
  T.Register;
  T := TGetHeadersTool.Create('get-headers', 'Get message headers for a range of messages by zero-based index.');
  T.Register;
  T := TSearchTool.Create('search', 'Search the selected folder by a flag criterion and/or raw IMAP query; returns matching zero-based message indices.');
  T.Register;
  T := TGetFlagsTool.Create('get-flags', 'Get message flags (seen, answered, flagged, deleted, draft, recent) for a range of messages by zero-based index.');
  T.Register;
  T := TGetMailTool.Create('get-mail', 'Get the full body of a message by mail ID.');
  T.Register;
  T := TMarkReadTool.Create('mark-read', 'Mark a message as read (set Seen flag).');
  T.Register;
  T := TMarkUnreadTool.Create('mark-unread', 'Mark a message as unread (remove Seen flag).');
  T.Register;

  // Conditionally register write tools
  if FAllowWrite then
  begin
    T := TMoveMailTool.Create('move-mail', 'Move a message to another folder.');
    T.Register;
    T := TMarkDeletedTool.Create('mark-deleted', 'Mark a message for deletion (set Deleted flag).');
    T.Register;
    T := TMarkUndeletedTool.Create('mark-undeleted', 'Remove deletion mark from a message (clear Deleted flag).');
    T.Register;
    T := TExpungeFolderTool.Create('expunge-folder', 'Permanently remove all messages marked for deletion in the selected folder.');
    T.Register;
    T := TCreateFolderTool.Create('create-folder', 'Create a new mailbox folder.');
    T.Register;
    T := TDeleteFolderTool.Create('delete-folder', 'Delete a mailbox folder.');
    T.Register;
    T := TRenameFolderTool.Create('rename-folder', 'Rename a mailbox folder.');
    T.Register;
  end;

  // Conditionally register send tool
  if FAllowSend then
  begin
    T := TSendMailTool.Create('send-mail', 'Send an email with recipients, body, and optional file attachments.');
    T.Register;
  end;
end;

constructor TApplication.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  MCPLogger.LogLevels := [mltError, mltInfo, mltWarning];
  MCPLogger.AddLogHandler(@DoMCPLog);
  MCPLogger.Enabled := True;
  MCPLogger.LogToConsole := False;
end;

destructor TApplication.Destroy;
begin
  MCPLogger.RemoveLogHandler(@DoMCPLog);
  inherited Destroy;
end;

procedure TApplication.DoMCPLog(aType: TMCPLogType; const aMessage: string);
const
  sLogs: array[TMCPLogType] of string = ('Error', 'Warning', 'Info', 'Trace', 'Debug');
begin
  Writeln(StdErr, DateToISO8601(Now), ' [', sLogs[aType]:7, '] ', aMessage);
end;

procedure TApplication.Usage(aMsg: string);
begin
  if aMsg <> '' then
    Writeln('Error: ', aMsg);
  Writeln(StdErr, 'Usage: ', ParamStr(0), ' [options]');
  Writeln(StdErr, 'Where options is one or more of:');
  Writeln(StdErr, '-h --help             this help.');
  Writeln(StdErr, '-c --config=File      INI config file for IMAP/SMTP connection (required).');
  Writeln(StdErr, '-w --allow-write      enable write tools (move, delete, folder management).');
  Writeln(StdErr, '-s --allow-send       enable send-mail tool.');
  Writeln(StdErr, '-q --quiet            write less log messages.');
  Writeln(StdErr, '-v --verbose          write more log messages.');
  ExitCode := Ord(aMsg <> '');
end;

var
  Application: TApplication;

begin
  Application := TApplication.Create(nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.

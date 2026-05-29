{
    This file is part of the Free Component Library

    Mail MCP Server - IMAP tools foundation
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit mcpmailtools;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, mcp.types, mcp.logging, mcp.tools, imapsend,
  ssl_openssl3;

type

  { TIMAPConnectionManager }

  TIMAPConnectionManager = class(TObject)
  private
    class var _Instance: TIMAPConnectionManager;
    FConnection: TIMAPSend;
    FSelectedFolder: String;
    FHost: String;
    FPort: String;
    FUser: String;
    FPassword: String;
    FTLS: Boolean;
  protected
    procedure DoLog(aType: TMCPLogType; const aMessage: String);
    procedure DoLog(aType: TMCPLogType; const aFmt: String; const aArgs: array of const);
  public
    constructor Create;
    destructor Destroy; override;
    class constructor Init;
    class destructor Done;
    procedure SetConfig(const aHost, aPort, aUser, aPassword: String; aTLS: Boolean);
    function GetConnection: TIMAPSend;
    procedure SelectFolder(const aFolder: String);
    function SelectedFolder: String;
    procedure RequireFolder;
    class property Instance: TIMAPConnectionManager read _Instance;
  end;

  { TIMAPMailTool }

  TIMAPMailTool = class abstract (TMCPTool)
  protected
    function ConnMgr: TIMAPConnectionManager;
    procedure RequireFolder;
  end;

  { TListFoldersTool }

  TListFoldersTool = class(TIMAPMailTool)
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TSelectFolderTool }

  TSelectFolderTool = class(TIMAPMailTool)
  public
    constructor Create(const aName, aDescription: string); override;
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TCountMessagesTool }

  TCountMessagesTool = class(TIMAPMailTool)
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TCountUnreadTool }

  TCountUnreadTool = class(TIMAPMailTool)
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TCountDeletedTool }

  TCountDeletedTool = class(TIMAPMailTool)
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TGetHeadersTool }

  TGetHeadersTool = class(TIMAPMailTool)
  public
    constructor Create(const aName, aDescription: string); override;
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TGetMailTool }

  TGetMailTool = class(TIMAPMailTool)
  public
    constructor Create(const aName, aDescription: string); override;
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TMarkReadTool }

  TMarkReadTool = class(TIMAPMailTool)
  public
    constructor Create(const aName, aDescription: string); override;
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TMarkUnreadTool }

  TMarkUnreadTool = class(TIMAPMailTool)
  public
    constructor Create(const aName, aDescription: string); override;
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TMoveMailTool }

  TMoveMailTool = class(TIMAPMailTool)
  public
    constructor Create(const aName, aDescription: string); override;
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TMarkDeletedTool }

  TMarkDeletedTool = class(TIMAPMailTool)
  public
    constructor Create(const aName, aDescription: string); override;
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TMarkUndeletedTool }

  TMarkUndeletedTool = class(TIMAPMailTool)
  public
    constructor Create(const aName, aDescription: string); override;
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TExpungeFolderTool }

  TExpungeFolderTool = class(TIMAPMailTool)
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TCreateFolderTool }

  TCreateFolderTool = class(TIMAPMailTool)
  public
    constructor Create(const aName, aDescription: string); override;
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TDeleteFolderTool }

  TDeleteFolderTool = class(TIMAPMailTool)
  public
    constructor Create(const aName, aDescription: string); override;
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

  { TRenameFolderTool }

  TRenameFolderTool = class(TIMAPMailTool)
  public
    constructor Create(const aName, aDescription: string); override;
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  end;

function IMAPConnectionManager: TIMAPConnectionManager;

implementation

function IMAPConnectionManager: TIMAPConnectionManager;
begin
  Result := TIMAPConnectionManager.Instance;
end;

{ TIMAPConnectionManager }

class constructor TIMAPConnectionManager.Init;
begin
  _Instance := TIMAPConnectionManager.Create;
end;

class destructor TIMAPConnectionManager.Done;
begin
  FreeAndNil(_Instance);
end;

constructor TIMAPConnectionManager.Create;
begin
  inherited Create;
  FConnection := nil;
  FSelectedFolder := '';
end;

destructor TIMAPConnectionManager.Destroy;
begin
  if Assigned(FConnection) then
  begin
    DoLog(mltInfo, 'Closing IMAP connection');
    FConnection.Logout;
    FreeAndNil(FConnection);
  end;
  inherited Destroy;
end;

procedure TIMAPConnectionManager.DoLog(aType: TMCPLogType; const aMessage: String);
begin
  MCPLogger.Log(aType, aMessage);
end;

procedure TIMAPConnectionManager.DoLog(aType: TMCPLogType; const aFmt: String;
  const aArgs: array of const);
begin
  MCPLogger.Log(aType, aFmt, aArgs);
end;

procedure TIMAPConnectionManager.SetConfig(const aHost, aPort, aUser,
  aPassword: String; aTLS: Boolean);
begin
  FHost := aHost;
  FPort := aPort;
  FUser := aUser;
  FPassword := aPassword;
  FTLS := aTLS;
end;

function TIMAPConnectionManager.GetConnection: TIMAPSend;
begin
  if not Assigned(FConnection) then
  begin
    DoLog(mltInfo, 'Creating IMAP connection to %s:%s', [FHost, FPort]);
    FConnection := TIMAPSend.Create;
    FConnection.TargetHost := FHost;
    FConnection.TargetPort := FPort;
    FConnection.UserName := FUser;
    FConnection.Password := FPassword;
    FConnection.FullSSL := FTLS;
    if not FConnection.Login then
      raise EMCPException.Create('Failed to connect/login to IMAP server ' + FHost + ':' + FPort);
    DoLog(mltInfo, 'IMAP connection established to %s:%s', [FHost, FPort]);
  end;
  Result := FConnection;
end;

procedure TIMAPConnectionManager.SelectFolder(const aFolder: String);
begin
  FSelectedFolder := aFolder;
end;

function TIMAPConnectionManager.SelectedFolder: String;
begin
  Result := FSelectedFolder;
end;

procedure TIMAPConnectionManager.RequireFolder;
begin
  if FSelectedFolder = '' then
    raise EMCPException.Create('No folder selected. Use select-folder first.');
end;

{ TIMAPMailTool }

function TIMAPMailTool.ConnMgr: TIMAPConnectionManager;
begin
  Result := TIMAPConnectionManager.Instance;
end;

procedure TIMAPMailTool.RequireFolder;
begin
  ConnMgr.RequireFolder;
end;

{ TListFoldersTool }

procedure TListFoldersTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lFolders: TStringList;
  lArr: TJSONArray;
  i: Integer;
begin
  DoLog(mltTrace, 'list-folders: invoked');
  lConn := ConnMgr.GetConnection;
  lFolders := TStringList.Create;
  try
    if not lConn.List('', lFolders) then
      raise EMCPException.Create('Failed to list folders: ' + lConn.ResultString);
    lArr := TJSONArray.Create;
    try
      for i := 0 to lFolders.Count - 1 do
        lArr.Add(lFolders[i]);
    except
      lArr.Free;
      raise;
    end;
    aResult.Add('folders', lArr);
    DoLog(mltInfo, 'list-folders: returned %d folders', [lFolders.Count]);
  finally
    lFolders.Free;
  end;
end;

{ TSelectFolderTool }

constructor TSelectFolderTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('folder',
    TJSONObject.Create(['type', 'string']),
    True);
end;

procedure TSelectFolderTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lFolder: String;
begin
  lFolder := aInput.Get('folder', '');
  DoLog(mltTrace, 'select-folder: folder=%s', [lFolder]);
  lConn := ConnMgr.GetConnection;
  if not lConn.SelectFolder(lFolder) then
    raise EMCPException.CreateFmt('Folder "%s" not found or could not be selected. %s',
      [lFolder, lConn.ResultString]);
  ConnMgr.SelectFolder(lFolder);
  aResult.Add('folder', lFolder);
  DoLog(mltInfo, 'select-folder: selected "%s"', [lFolder]);
end;

{ TCountMessagesTool }

procedure TCountMessagesTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
begin
  DoLog(mltTrace, 'count-messages: invoked');
  RequireFolder;
  lConn := ConnMgr.GetConnection;
  aResult.Add('count', lConn.SelectedCount);
  DoLog(mltInfo, 'count-messages: %d messages in "%s"', [lConn.SelectedCount, ConnMgr.SelectedFolder]);
end;

{ TCountUnreadTool }

procedure TCountUnreadTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lFound: TStringList;
begin
  DoLog(mltTrace, 'count-unread: invoked');
  RequireFolder;
  lConn := ConnMgr.GetConnection;
  lFound := TStringList.Create;
  try
    if not lConn.SearchMess('UNSEEN', lFound) then
      raise EMCPException.Create('Failed to search for unread messages: ' + lConn.ResultString);
    aResult.Add('count', lFound.Count);
    DoLog(mltInfo, 'count-unread: %d unread in "%s"', [lFound.Count, ConnMgr.SelectedFolder]);
  finally
    lFound.Free;
  end;
end;

{ TCountDeletedTool }

procedure TCountDeletedTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lFound: TStringList;
begin
  DoLog(mltTrace, 'count-deleted: invoked');
  RequireFolder;
  lConn := ConnMgr.GetConnection;
  lFound := TStringList.Create;
  try
    if not lConn.SearchMess('DELETED', lFound) then
      raise EMCPException.Create('Failed to search for deleted messages: ' + lConn.ResultString);
    aResult.Add('count', lFound.Count);
    DoLog(mltInfo, 'count-deleted: %d deleted in "%s"', [lFound.Count, ConnMgr.SelectedFolder]);
  finally
    lFound.Free;
  end;
end;

{ TGetHeadersTool }

constructor TGetHeadersTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('from_index', TJSONObject.Create(['type', 'integer']), True);
  InputSchema.AddArgument('to_index', TJSONObject.Create(['type', 'integer']), True);
end;

procedure TGetHeadersTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lFrom, lTo, i: Integer;
  lHeaders: TStringList;
  lArr: TJSONArray;
  lMsg: TJSONObject;
begin
  lFrom := aInput.Get('from_index', 0);
  lTo := aInput.Get('to_index', 0);
  DoLog(mltTrace, 'get-headers: from=%d to=%d', [lFrom, lTo]);
  RequireFolder;
  if lTo < lFrom then
    raise EMCPException.Create('to_index must be >= from_index');
  lConn := ConnMgr.GetConnection;
  lArr := TJSONArray.Create;
  try
    for i := lFrom to lTo do
    begin
      lHeaders := TStringList.Create;
      try
        if not lConn.FetchHeader(i + 1, lHeaders) then
          raise EMCPException.CreateFmt('Failed to fetch headers for message %d: %s',
            [i, lConn.ResultString]);
        lMsg := TJSONObject.Create;
        lMsg.Add('index', i);
        lMsg.Add('headers', lHeaders.Text);
        lArr.Add(lMsg);
      finally
        lHeaders.Free;
      end;
    end;
  except
    lArr.Free;
    raise;
  end;
  aResult.Add('messages', lArr);
  DoLog(mltInfo, 'get-headers: returned %d message headers', [lArr.Count]);
end;

{ TGetMailTool }

constructor TGetMailTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('mail_id', TJSONObject.Create(['type', 'integer']), True);
end;

procedure TGetMailTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lMailId: Integer;
  lMess: TStringList;
begin
  lMailId := aInput.Get('mail_id', 0);
  DoLog(mltTrace, 'get-mail: mail_id=%d', [lMailId]);
  RequireFolder;
  lConn := ConnMgr.GetConnection;
  lMess := TStringList.Create;
  try
    if not lConn.FetchMess(lMailId + 1, lMess) then
      raise EMCPException.CreateFmt('Failed to fetch message %d: %s',
        [lMailId, lConn.ResultString]);
    aResult.Add('body', lMess.Text);
    DoLog(mltInfo, 'get-mail: fetched message %d from "%s"', [lMailId, ConnMgr.SelectedFolder]);
  finally
    lMess.Free;
  end;
end;

{ TMarkReadTool }

constructor TMarkReadTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('mail_id', TJSONObject.Create(['type', 'integer']), True);
end;

procedure TMarkReadTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lMailId: Integer;
begin
  lMailId := aInput.Get('mail_id', 0);
  DoLog(mltTrace, 'mark-read: mail_id=%d', [lMailId]);
  RequireFolder;
  lConn := ConnMgr.GetConnection;
  if not lConn.AddFlagsMess(lMailId + 1, '\Seen') then
    raise EMCPException.CreateFmt('Failed to mark message %d as read: %s',
      [lMailId, lConn.ResultString]);
  aResult.Add('mail_id', lMailId);
  aResult.Add('status', 'read');
  DoLog(mltInfo, 'mark-read: message %d marked as read in "%s"', [lMailId, ConnMgr.SelectedFolder]);
end;

{ TMarkUnreadTool }

constructor TMarkUnreadTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('mail_id', TJSONObject.Create(['type', 'integer']), True);
end;

procedure TMarkUnreadTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lMailId: Integer;
begin
  lMailId := aInput.Get('mail_id', 0);
  DoLog(mltTrace, 'mark-unread: mail_id=%d', [lMailId]);
  RequireFolder;
  lConn := ConnMgr.GetConnection;
  if not lConn.DelFlagsMess(lMailId + 1, '\Seen') then
    raise EMCPException.CreateFmt('Failed to mark message %d as unread: %s',
      [lMailId, lConn.ResultString]);
  aResult.Add('mail_id', lMailId);
  aResult.Add('status', 'unread');
  DoLog(mltInfo, 'mark-unread: message %d marked as unread in "%s"', [lMailId, ConnMgr.SelectedFolder]);
end;

{ TMoveMailTool }

constructor TMoveMailTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('mail_id', TJSONObject.Create(['type', 'integer']), True);
  InputSchema.AddArgument('target_folder', TJSONObject.Create(['type', 'string']), True);
end;

procedure TMoveMailTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lMailId: Integer;
  lTargetFolder: String;
begin
  lMailId := aInput.Get('mail_id', 0);
  lTargetFolder := aInput.Get('target_folder', '');
  DoLog(mltTrace, 'move-mail: mail_id=%d target_folder=%s', [lMailId, lTargetFolder]);
  RequireFolder;
  lConn := ConnMgr.GetConnection;
  if not lConn.CopyMess(lMailId + 1, lTargetFolder) then
    raise EMCPException.CreateFmt('Failed to move message %d to "%s": %s',
      [lMailId, lTargetFolder, lConn.ResultString]);
  if not lConn.DeleteMess(lMailId + 1) then
    raise EMCPException.CreateFmt('Failed to mark message %d as deleted after copy: %s',
      [lMailId, lConn.ResultString]);
  aResult.Add('mail_id', lMailId);
  aResult.Add('target_folder', lTargetFolder);
  aResult.Add('status', 'moved');
  DoLog(mltInfo, 'move-mail: moved message %d from "%s" to "%s"',
    [lMailId, ConnMgr.SelectedFolder, lTargetFolder]);
end;

{ TMarkDeletedTool }

constructor TMarkDeletedTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('mail_id', TJSONObject.Create(['type', 'integer']), True);
end;

procedure TMarkDeletedTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lMailId: Integer;
begin
  lMailId := aInput.Get('mail_id', 0);
  DoLog(mltTrace, 'mark-deleted: mail_id=%d', [lMailId]);
  RequireFolder;
  lConn := ConnMgr.GetConnection;
  if not lConn.AddFlagsMess(lMailId + 1, '\Deleted') then
    raise EMCPException.CreateFmt('Failed to mark message %d as deleted: %s',
      [lMailId, lConn.ResultString]);
  aResult.Add('mail_id', lMailId);
  aResult.Add('status', 'deleted');
  DoLog(mltInfo, 'mark-deleted: message %d marked as deleted in "%s"',
    [lMailId, ConnMgr.SelectedFolder]);
end;

{ TMarkUndeletedTool }

constructor TMarkUndeletedTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('mail_id', TJSONObject.Create(['type', 'integer']), True);
end;

procedure TMarkUndeletedTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lMailId: Integer;
begin
  lMailId := aInput.Get('mail_id', 0);
  DoLog(mltTrace, 'mark-undeleted: mail_id=%d', [lMailId]);
  RequireFolder;
  lConn := ConnMgr.GetConnection;
  if not lConn.DelFlagsMess(lMailId + 1, '\Deleted') then
    raise EMCPException.CreateFmt('Failed to mark message %d as undeleted: %s',
      [lMailId, lConn.ResultString]);
  aResult.Add('mail_id', lMailId);
  aResult.Add('status', 'undeleted');
  DoLog(mltInfo, 'mark-undeleted: message %d marked as undeleted in "%s"',
    [lMailId, ConnMgr.SelectedFolder]);
end;

{ TCreateFolderTool }

constructor TCreateFolderTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('folder_name', TJSONObject.Create(['type', 'string']), True);
end;

procedure TCreateFolderTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lFolderName: String;
begin
  lFolderName := aInput.Get('folder_name', '');
  DoLog(mltTrace, 'create-folder: folder_name=%s', [lFolderName]);
  lConn := ConnMgr.GetConnection;
  if not lConn.CreateFolder(lFolderName) then
    raise EMCPException.CreateFmt('Failed to create folder "%s": %s',
      [lFolderName, lConn.ResultString]);
  aResult.Add('folder_name', lFolderName);
  aResult.Add('status', 'created');
  DoLog(mltInfo, 'create-folder: created folder "%s"', [lFolderName]);
end;

{ TDeleteFolderTool }

constructor TDeleteFolderTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('folder_name', TJSONObject.Create(['type', 'string']), True);
end;

procedure TDeleteFolderTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lFolderName: String;
begin
  lFolderName := aInput.Get('folder_name', '');
  DoLog(mltTrace, 'delete-folder: folder_name=%s', [lFolderName]);
  lConn := ConnMgr.GetConnection;
  if not lConn.DeleteFolder(lFolderName) then
    raise EMCPException.CreateFmt('Failed to delete folder "%s": %s',
      [lFolderName, lConn.ResultString]);
  aResult.Add('folder_name', lFolderName);
  aResult.Add('status', 'deleted');
  DoLog(mltInfo, 'delete-folder: deleted folder "%s"', [lFolderName]);
end;

{ TRenameFolderTool }

constructor TRenameFolderTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('folder_name', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('new_name', TJSONObject.Create(['type', 'string']), True);
end;

procedure TRenameFolderTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
  lFolderName: String;
  lNewName: String;
begin
  lFolderName := aInput.Get('folder_name', '');
  lNewName := aInput.Get('new_name', '');
  DoLog(mltTrace, 'rename-folder: folder_name=%s new_name=%s', [lFolderName, lNewName]);
  lConn := ConnMgr.GetConnection;
  if not lConn.RenameFolder(lFolderName, lNewName) then
    raise EMCPException.CreateFmt('Failed to rename folder "%s" to "%s": %s',
      [lFolderName, lNewName, lConn.ResultString]);
  aResult.Add('folder_name', lFolderName);
  aResult.Add('new_name', lNewName);
  aResult.Add('status', 'renamed');
  DoLog(mltInfo, 'rename-folder: renamed folder "%s" to "%s"', [lFolderName, lNewName]);
end;

{ TExpungeFolderTool }

procedure TExpungeFolderTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConn: TIMAPSend;
begin
  DoLog(mltTrace, 'expunge-folder: invoked');
  RequireFolder;
  lConn := ConnMgr.GetConnection;
  if not lConn.ExpungeFolder then
    raise EMCPException.CreateFmt('Failed to expunge folder "%s": %s',
      [ConnMgr.SelectedFolder, lConn.ResultString]);
  aResult.Add('folder', ConnMgr.SelectedFolder);
  aResult.Add('status', 'expunged');
  DoLog(mltInfo, 'expunge-folder: expunged deleted messages from "%s"',
    [ConnMgr.SelectedFolder]);
end;

end.

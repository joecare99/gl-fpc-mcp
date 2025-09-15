{
    This file is part of the Free Component Library

    Database handling MCP Server
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

program mcpdbconnector;

{ $define usesocket}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  jsonparser,
  fpjson,
  sysutils,
  classes,
  inifiles,
  strutils,
  dateutils,
  sqldb,
  {$ifdef usesocket}
  mcp.application.socket,
  {$else}
  mcp.application.stdio,
  {$endif}
  mcp.types,
  mcp.logging,
  mcp.tools,
  mcp.resources,
  mcp.prompts, mcpsqldbtools, mcpsqldbsupport;

const
  sDatabase = 'Database';
  KeyHost = 'host';
  KeyDatabase = 'database';
  KeyUser = 'user';
  keyPort = 'port';
  keyPassword = 'password';
  keyOption = 'option';
  keyParams = 'params';
  keyConfig = 'config';
  keyWrite = 'write';
  keyHelp = 'help';
  keyType = 'type';
  keyQuiet = 'quiet';
  keyVerbose = 'verbose';

  LongOptions : array of string = (
      keyConfig+':', KeyHost+':', KeyDatabase+':', KeyUser+':',
      keyPassword+':', keyPort+':', keyOption+':', keyWrite,
      keyHelp,keyType+':',keyQuiet,keyVerbose);


Type

  { TApplication }
{$IFDEF usesocket}
  TApplication = class (TMCPSocketApplication)
{$ELSE}
  TApplication = class (TMCPStdioApplication)
{$endif}
  private
    function DefaultDBtype: String;
    procedure DoMCPLog(aType: TMCPLogType; const aMessage: string);
    procedure ReadDBConfig(aInfo: TMCPDBConnectionInfo; aConfigFile: string);
    procedure RegisterTools;
  protected
    procedure DoRun; override;
  public
    constructor Create(aOwner : TComponent); override;
    destructor destroy; override;
    procedure parseoptions;
    procedure Usage(aMsg : string);
  end;

{ TApplication }

procedure TApplication.DoRun;
var
  S : String;
begin
  S:=CheckOptions('c:H:d:u:p:P:o:whvq',LongOptions);
  if (s<>'') or HasOption('h',keyHelp) then
    begin
    Usage(S);
    Terminate;
    exit;
    end;
  ParseOptions;
  RegisterTools;
  inherited DoRun;
end;

procedure TApplication.RegisterTools;
var
  T : TMCPTool;
begin
  T:=TListTablesTool.Create('list-tables','lists the tables in the database');
  T.Register;
  T:=TExecuteSQLTool.Create('execute-query','Executes a query in the database.');
  T.Register;
  T:=TGetTableInfoTool.Create('describe-table','Gets the detailed schema (columns, types) of a specific table.');
  T.Register;
end;

constructor TApplication.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  MCPLogger.LogLevels:=[mltError,mltInfo,mltWarning];
  MCPLogger.AddLogHandler(@DoMCPLog);
  MCPLogger.Enabled:=True;
  MCPLogger.LogToConsole:=False;
end;

destructor TApplication.destroy;
begin
  MCPLogger.RemoveLogHandler(@DoMCPLog);
  inherited destroy;
end;

function TApplication.DefaultDBtype: String;
begin
  Result:=TMCPToolConnectionManager.DefaultDBType;
end;

procedure TApplication.DoMCPLog(aType: TMCPLogType; const aMessage: string);

const
  sLogs : array [TMCPLogType] of string = ('Error','Warning','Info','Trace','Debug');

begin
  Writeln(StdErr,DateToISO8601(Now),' [',sLogs[aType]:7,'] ',aMessage);
end;

procedure TApplication.ReadDBConfig(aInfo : TMCPDBConnectionInfo; aConfigFile : string);

var
  lIni : TCustomIniFile;
  S : String;

begin
  lIni:=TMemIniFile.Create(aConfigFile);
  try
    With lIni do
      begin
      aInfo.DBType:=ReadString(sDatabase,KeyHost,'');
      aInfo.HostName:=ReadString(sDatabase,KeyHost,'localhost');
      aInfo.DatabaseName:=ReadString(sDatabase,KeyDatabase,'');
      aInfo.Port:=ReadInteger(sDatabase,KeyPort,0);
      aInfo.UserName:=ReadString(sDatabase,KeyUser,'');
      aInfo.Password:=ReadString(sDatabase,keyPassword,'');
      S:=ReadString(sDatabase,keyParams,'');
      if S<>'' then
        aInfo.Params:=SplitString(S,',');
      end;
  finally
    lIni.Free
  end;
end;

procedure TApplication.parseoptions;
var
  lInfo : TMCPDBConnectionInfo;
begin
  lInfo:=TMCPDBConnectionInfo.Create;
  if HasOption('c',keyConfig) then
    ReadDBConfig(lInfo,GetOptionValue('c',keyConfig))
  else
    begin
    lInfo.DBType:=GetOptionValue('t',KeyType);
    lInfo.HostName:=GetOptionValue('H',Keyhost);
    lInfo.DatabaseName:=GetOptionValue('d',KeyDatabase);
    lInfo.Port:=StrToIntDef(GetOptionValue('P',keyPort),0);
    lInfo.UserName:=GetOptionValue('u',keyUser);
    lInfo.Password:=GetOptionValue('p',keyPassword);
    lInfo.Params:=GetOptionValues('o',keyOption);
    end;
  if HasOption('v','verbose') then
    MCPLogger.LogLevels:=[Low(TMCPLogType)..High(TMCPLogType)];
  if HasOption('q','quiet') then
    MCPLogger.LogLevels:=[mltError];
  TMCPToolConnectionManager.Instance.SetDefaultConnection(lInfo);
  TMCPToolConnectionManager.Instance.AllowModify:=HasOption('w',keyWrite);
end;

procedure TApplication.Usage(aMsg: string);
var
  l : TStrings;
  S : string;
begin
  if (aMsg<>'') then
    Writeln('Error: ',aMsg);
  Writeln(stdErr,'Usage: ',Paramstr(0),' [options]');
  Writeln(stdErr,'Where options is one or more of:');
  Writeln(stdErr,'-h --help             this help.');
  Writeln(stdErr,'-c --config=File      config file for database connection.');
  Writeln(stdErr,'-d --database=DBName  set connection database name.');
  Writeln(stdErr,'-H --host=HOST        set connection host.');
  Writeln(stdErr,'-p --password=PASSWD  set connection password.');
  Writeln(stdErr,'-P --port=NNN         set connection port ');
  Writeln(stdErr,'-q --quiet            Write less log messages.');
  Writeln(stdErr,'-t --type=DBTYPE      type connection. Allowed types:');
  l:=TStringList.Create;
  try
    GetConnectionList(l);
    if L.Count=0 then
      Writeln(stdErr,'                      No types defined. Recompile this tool with DB support! ');
    for S in L do
      Writeln(stdErr,'                      - ',S);
  finally
    l.Free;
  end;
  Writeln(stdErr,'-u --user=USER        set connection username.');
  Writeln(stdErr,'-v --verbose          Write more log messages.');
  Writeln(stdErr,'-w --write            allow SQL statements that modify the database.');
  ExitCode:=Ord(aMsg<>'');
end;

var
  Application : TApplication;

begin
  Application:=TApplication.Create(Nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.

end.


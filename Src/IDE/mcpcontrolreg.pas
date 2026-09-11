{
    This file is part of the Free Component Library

    MCP Lazarus tool & resource registrations
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcpcontrolreg;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Controls, Classes, LazIDEIntf, ProjectIntf, CompOptsIntf,
  SrcEditorIntf, IDEMsgIntf, IDEExternToolIntf, fpjson, mcp.types,
  mcp.tools, mcp.ide.tooldata, mcp.dispatcher.serversocket, mcp.stdhandlers,
  mcp.controller, mcp.logging;

type

  { TMCPToolController }

  TMCPToolController = class(TComponent)
  private
    FLog : TFileStream;
    FServer: TMCPServerTCPSocketDispatcher;
    procedure DoMCPLog(aType: TMCPLogLevel; const Msg: string);
  protected
    function CreateJSONResult(const aContent: Array of const): TMCPToolResultArray;
    function JSONToResult(aJSON: TJSONObject): TMCPToolResultArray;
    procedure MCPAddExistingUnit(aInput: TJSONData; var aOutput: TMCPToolResultArray);
    procedure MCPAddNewUnit(aInput: TJSONData; var aOutput: TMCPToolResultArray);
    procedure MCPCompileProject(aInput: TJSONData; var aOutput: TMCPToolResultArray);
    procedure MCPGetWorkspaceInfo(aInput: TJSONData; var aOutput: TMCPToolResultArray);
    procedure MCPListProjectFiles(aInput: TJSONData; var aOutput: TMCPToolResultArray);
    procedure MCPListOpenEditors(aInput: TJSONData; var aOutput: TMCPToolResultArray);
    procedure MCPGetActiveEditor(aInput: TJSONData; var aOutput: TMCPToolResultArray);
    procedure MCPReadEditorText(aInput: TJSONData; var aOutput: TMCPToolResultArray);
    procedure MCPGetBuildMessages(aInput: TJSONData; var aOutput: TMCPToolResultArray);
    procedure MCPOpenProject(aInput: TJSONData; var aOutput: TMCPToolResultArray);
    procedure MCPNewProject(aInput: TJSONData; var aOutput: TMCPToolResultArray);
  Public
    constructor create(aOwner: TComponent); override;
    Destructor destroy; override;
    Procedure StartController;
    Procedure RegisterTools;
    Procedure Terminate;
  end;

procedure register;

implementation

var
  _ToolController : TMCPToolController;

procedure CreateMCPController;

begin
  _ToolController:=TMCPToolController.Create(Nil);
  _ToolController.RegisterTools;
  _ToolController.StartController;
end;

procedure register;
begin
  CreateMCPController;
end;

type
   TLazCmd = class(TObject)
     ExecuteResult : boolean;
   end;
   { TAddUnit }

   TAddUnitCmd = Class(TLazCmd)
     FFileName: string;
     IsNew : Boolean;
     Constructor Create(aFileName : string; aisNew : Boolean);
     Procedure Execute;
   end;

   { TOpenProjectCmd }

   TOpenProjectCmd = Class(TLazCmd)
     FFileName: string;
     Constructor Create(aFileName : string);
     Procedure Execute;
   end;

   { TCompileProject }

   TCompileProjectCmd = Class(TLazCmd)
     Reason : TCompileReason;
     constructor Create(aReason : TCompileReason);
     procedure execute;
   end;

   TWorkspaceInfoCmd = Class(TLazCmd)
     Result: TJSONObject;
     Procedure Execute;
   end;

   TProjectFilesCmd = Class(TLazCmd)
     Result: TJSONArray;
     Procedure Execute;
   end;

   TEditorsCmd = Class(TLazCmd)
     Result: TJSONArray;
     Procedure Execute;
   end;

   TActiveEditorCmd = Class(TLazCmd)
     Result: TJSONObject;
     Procedure Execute;
   end;

   TEditorTextCmd = Class(TLazCmd)
     FileName: String;
     StartLine: Integer;
     EndLine: Integer;
     Result: TJSONObject;
     Procedure Execute;
   end;

   TBuildMessagesCmd = Class(TLazCmd)
     Result: TJSONArray;
     Procedure Execute;
   end;

{ TOpenProjectCmd }

constructor TOpenProjectCmd.Create(aFileName: string);
begin
  FFileName:=aFileName;
end;

procedure TOpenProjectCmd.Execute;
var
  ldesc : TProjectDescriptor;
begin
  if FFileName='' then
    begin
    ldesc:=ProjectDescriptors.FindByName(ProjDescNameSimpleProgram);
    ExecuteResult:=Assigned(ldesc) and (mrOK=LazarusIDE.DoNewProject(lDesc));
    end
  else
    ExecuteResult:=mrOK=LazarusIDE.DoOpenProjectFile(FFileName,[ofOnlyIfExists,ofAddToRecent]);
end;

{ TCompileProject }

constructor TCompileProjectCmd.Create(aReason : TCompileReason);
begin
  Reason:=aReason;
end;

procedure TCompileProjectCmd.execute;
begin
  ExecuteResult:=LazarusIDE.DoBuildProject(Reason,[],True)=mrOK;
end;

procedure TWorkspaceInfoCmd.Execute;
var
  P: TLazProject;
begin
  Result:=TJSONObject.Create;
  P:=LazarusIDE.ActiveProject;
  Result.Add('hasProject',Assigned(P));
  if Assigned(P) then
    begin
    Result.Add('projectFile',P.ProjectInfoFile);
    Result.Add('directory',P.Directory);
    Result.Add('fileCount',P.FileCount);
    if Assigned(P.MainFile) then
      Result.Add('mainFile',P.MainFile.GetFullFilename)
    else
      Result.Add('mainFile','');
    end;
end;

procedure TProjectFilesCmd.Execute;
var
  P: TLazProject;
  I: Integer;
  F: TLazProjectFile;
begin
  Result:=TJSONArray.Create;
  P:=LazarusIDE.ActiveProject;
  if not Assigned(P) then Exit;
  for I:=0 to P.FileCount-1 do
    begin
    F:=P.Files[I];
    Result.Add(TJSONObject.Create([
      'filename',F.GetFullFilename,
      'unitName',F.Unit_Name,
      'isMain',F=P.MainFile,
      'isPartOfProject',F.IsPartOfProject
    ]));
    end;
end;

procedure TEditorsCmd.Execute;
var
  I: Integer;
  E: TSourceEditorInterface;
begin
  Result:=TJSONArray.Create;
  if not Assigned(SourceEditorManagerIntf) then Exit;
  for I:=0 to SourceEditorManagerIntf.UniqueSourceEditorCount-1 do
    begin
    E:=SourceEditorManagerIntf.UniqueSourceEditors[I];
    Result.Add(TJSONObject.Create([
      'filename',E.FileName,
      'pageName',E.PageName,
      'modified',E.Modified,
      'readOnly',E.ReadOnly,
      'active',E=SourceEditorManagerIntf.ActiveEditor
    ]));
    end;
end;

procedure TActiveEditorCmd.Execute;
var
  E: TSourceEditorInterface;
begin
  Result:=TJSONObject.Create;
  E:=nil;
  if Assigned(SourceEditorManagerIntf) then
    E:=SourceEditorManagerIntf.ActiveEditor;
  Result.Add('hasEditor',Assigned(E));
  if not Assigned(E) then Exit;
  Result.Add('filename',E.FileName);
  Result.Add('pageName',E.PageName);
  Result.Add('modified',E.Modified);
  Result.Add('readOnly',E.ReadOnly);
  Result.Add('line',E.CursorTextXY.Y);
  Result.Add('column',E.CursorTextXY.X);
  Result.Add('selection',E.Selection);
end;

procedure TEditorTextCmd.Execute;
var
  E: TSourceEditorInterface;
  P: TLazProject;
  I, LastLine: Integer;
  Lines: TJSONArray;
begin
  Result:=TJSONObject.Create;
  if not Assigned(SourceEditorManagerIntf) then
    raise EMCPException.Create('Source editor manager unavailable');
  E:=SourceEditorManagerIntf.SourceEditorIntfWithFilename(FileName);
  if not Assigned(E) then
    raise EMCPException.Create('File is not open in the Lazarus editor');
  P:=LazarusIDE.ActiveProject;
  if not Assigned(P) or (E.GetProjectFile=nil) then
    raise EMCPException.Create('File is not part of the active project');
  if not SameIDEFile(E.GetProjectFile.GetFullFilename,FileName) then
    raise EMCPException.Create('File is not part of the active project');
  if not NormalizeEditorRange(StartLine,EndLine,E.LineCount,
    StartLine,LastLine) then
    raise EMCPException.Create('Invalid editor range; maximum range is 500 lines');
  Lines:=TJSONArray.Create;
  for I:=StartLine-1 to LastLine-1 do
    Lines.Add(E.Lines[I]);
  Result.Add('filename',E.FileName);
  Result.Add('startLine',StartLine);
  Result.Add('endLine',LastLine);
  Result.Add('lines',Lines);
end;

procedure TBuildMessagesCmd.Execute;
var
  I, J, Count: Integer;
  V: TExtToolView;
  M: TMessageLine;
begin
  Result:=TJSONArray.Create;
  if not Assigned(IDEMessagesWindow) then Exit;
  Count:=0;
  for I:=0 to IDEMessagesWindow.ViewCount-1 do
    begin
    V:=IDEMessagesWindow.Views[I];
    for J:=0 to V.Lines.Count-1 do
      begin
      if Count>=1000 then Exit;
      M:=V.Lines[J];
      Result.Add(TJSONObject.Create([
        'view',V.Caption,
        'severity',MessageLineUrgencyNames[M.Urgency],
        'message',M.Msg,
        'filename',M.GetFullFilename,
        'line',M.Line,
        'column',M.Column
      ]));
      Inc(Count);
      end;
    end;
end;

{ TAddUnit }

constructor TAddUnitCmd.Create(aFileName: string; aisNew : Boolean);
begin
  FFileName:=aFileName;
  IsNew:=aIsNew;
end;

procedure TAddUnitCmd.Execute;
begin
  if IsNew then
    begin
    ExecuteResult:=mrOK=LazarusIDE.DoNewEditorFile(FileDescriptorUnit,'','',
      [nfQuiet,nfAddToRecent,nfIsPartOfProject]);
    end
  else
    begin
    ExecuteResult:=mrOK=LazarusIDE.DoOpenEditorFile(FFileName,0,0,
      [ofQuiet,ofAddToProject,ofAddToRecent,ofOnlyIfExists]);
    end
end;

{ TMCPToolController }

procedure TMCPToolController.DoMCPLog(aType: TMCPLogLevel; const Msg: string);
var
  S : String;
begin
  WriteStr(S,aType);
  S:='['+S+'] '+Msg+sLineBreak;
  FLog.WriteBuffer(S[1],Length(S));
end;

function TMCPToolController.CreateJSONResult(const aContent: array of const): TMCPToolResultArray;
var
  lObj : TJSONObject;
begin
  lObj:=TJSONObject.Create(aContent);
  try
    Result:=JSONToResult(lObj);
  finally
    lObj.Free;
  end;
end;

function TMCPToolController.JSONToResult(aJSON: TJSONObject): TMCPToolResultArray;
begin
  Result:=[];
  SetLength(Result,1);
  Result[0]:=TMCPToolResult.CreateText(aJSON);
end;

procedure TMCPToolController.MCPAddExistingUnit(aInput: TJSONData; var aOutput: TMCPToolResultArray);
var
  OK: Boolean;
  lFilename : string;
  lRes : TJSONObject;
begin
  lFileName:=(aInput as TJSONObject).Get('projectfile','');
  if lFileName='' then lFileName:=(aInput as TJSONObject).Get('filename','');
  if lFileName='' then
    Raise EMCPException.Create('Need a filename');
  With TAddUnitCmd.Create(lFileName,False) do
    begin
    TThread.Synchronize(TThread.CurrentThread,@Execute);
    OK:=ExecuteResult;
    Free;
    end;
  lRes:=TJSONObject.Create(['Success',OK]);
  aOutput:=JSONToResult(lRes)
end;

procedure TMCPToolController.MCPAddNewUnit(aInput: TJSONData; var aOutput: TMCPToolResultArray);
var
  OK: Boolean;
begin
  With TAddUnitCmd.Create('',True) do
    begin
    TThread.Synchronize(TThread.CurrentThread,@Execute);
    OK:=ExecuteResult;
    Free;
    end;
  aOutput:=CreateJSONResult(['Success',OK]);
end;

procedure TMCPToolController.MCPCompileProject(aInput: TJSONData; var aOutput: TMCPToolResultArray);
var
  lReason : TCompileReason;
  Ok : Boolean;
begin
  if (aInput as TJSONObject).Get('build',False) then
    lReason:=TCompileReason.crCompile
  else
    lReason:=TCompileReason.crBuild;
  With TCompileProjectCmd.Create(lReason) do
    begin
    TThread.Synchronize(TThread.CurrentThread,@Execute);
    OK:=ExecuteResult;
    Free;
    end;
  aOutput:=CreateJSONResult(['Success',OK]);
end;

procedure TMCPToolController.MCPGetWorkspaceInfo(aInput: TJSONData;
  var aOutput: TMCPToolResultArray);
var
  C: TWorkspaceInfoCmd;
begin
  C:=TWorkspaceInfoCmd.Create;
  try
    TThread.Synchronize(TThread.CurrentThread,@C.Execute);
    aOutput:=JSONToResult(C.Result);
    C.Result:=nil;
  finally
    C.Free;
  end;
end;

procedure TMCPToolController.MCPListProjectFiles(aInput: TJSONData;
  var aOutput: TMCPToolResultArray);
var
  C: TProjectFilesCmd;
begin
  C:=TProjectFilesCmd.Create;
  try
    TThread.Synchronize(TThread.CurrentThread,@C.Execute);
    aOutput:=JSONToResult(TJSONObject.Create(['files',C.Result]));
    C.Result:=nil;
  finally
    C.Free;
  end;
end;

procedure TMCPToolController.MCPListOpenEditors(aInput: TJSONData;
  var aOutput: TMCPToolResultArray);
var
  C: TEditorsCmd;
begin
  C:=TEditorsCmd.Create;
  try
    TThread.Synchronize(TThread.CurrentThread,@C.Execute);
    aOutput:=JSONToResult(TJSONObject.Create(['editors',C.Result]));
    C.Result:=nil;
  finally
    C.Free;
  end;
end;

procedure TMCPToolController.MCPGetActiveEditor(aInput: TJSONData;
  var aOutput: TMCPToolResultArray);
var
  C: TActiveEditorCmd;
begin
  C:=TActiveEditorCmd.Create;
  try
    TThread.Synchronize(TThread.CurrentThread,@C.Execute);
    aOutput:=JSONToResult(C.Result);
    C.Result:=nil;
  finally
    C.Free;
  end;
end;

procedure TMCPToolController.MCPReadEditorText(aInput: TJSONData;
  var aOutput: TMCPToolResultArray);
var
  C: TEditorTextCmd;
  O: TJSONObject;
begin
  C:=TEditorTextCmd.Create;
  C.FileName:=(aInput as TJSONObject).Get('filename','');
  C.StartLine:=(aInput as TJSONObject).Get('startLine',1);
  C.EndLine:=(aInput as TJSONObject).Get('endLine',C.StartLine+99);
  if C.FileName='' then
    raise EMCPException.Create('Need a filename');
  try
    TThread.Synchronize(TThread.CurrentThread,@C.Execute);
    O:=TJSONObject.Create(['text',C.Result]);
    C.Result:=nil;
    aOutput:=JSONToResult(O);
  finally
    C.Free;
  end;
end;

procedure TMCPToolController.MCPGetBuildMessages(aInput: TJSONData;
  var aOutput: TMCPToolResultArray);
var
  C: TBuildMessagesCmd;
begin
  C:=TBuildMessagesCmd.Create;
  try
    TThread.Synchronize(TThread.CurrentThread,@C.Execute);
    aOutput:=JSONToResult(TJSONObject.Create(['messages',C.Result]));
    C.Result:=nil;
  finally
    C.Free;
  end;
end;

procedure TMCPToolController.MCPOpenProject(aInput: TJSONData; var aOutput: TMCPToolResultArray);
var
  lFileName : string;
  OK : Boolean;

begin
  lFileName:=(aInput as TJSONObject).Get('projectfile','');
  if lFileName='' then lFileName:=(aInput as TJSONObject).Get('filename','');
  if lFileName='' then
    Raise EMCPException.Create('Need a filename');
  With TOpenProjectCmd.Create(lFileName) do
    begin
    TThread.Synchronize(TThread.CurrentThread,@Execute);
    OK:=ExecuteResult;
    Free;
    end;
  aOutput:=CreateJSONResult(['Success',OK]);
end;

procedure TMCPToolController.MCPNewProject(aInput: TJSONData; var aOutput: TMCPToolResultArray);
var
  OK : Boolean;
begin
  With TOpenProjectCmd.Create('') do
    begin
    TThread.Synchronize(TThread.CurrentThread,@Execute);
    OK:=ExecuteResult;
    Free;
    end;
  aOutput:=CreateJSONResult(['Success',OK]);
end;

constructor TMCPToolController.create(aOwner: TComponent);
begin
  inherited create(aOwner);
  FLog:=TFileStream.Create(GetTempDir(False)+'lazmcplog.log',fmCreate or fmShareDenyNone);
  FServer:=TMCPServerTCPSocketDispatcher.Create(Self);
  FServer.Controller:=TMCPController.Instance;
end;

destructor TMCPToolController.destroy;
begin
  DoMCPLog(mltTrace,'Shutting down');
  FreeAndNil(FLog);
  inherited destroy;
end;

procedure DoRunLoop;
begin
  _ToolController.FServer.RunLoop;
end;

procedure TMCPToolController.StartController;
begin
  MCPLogger.LogToConsole:=False;
  MCPLogger.LogLevels:=[Low(TMCPLogLevel)..High(TMCPLogLevel)];
  MCPLogger.AddLogHandler(@DoMCPLog);
  MCPLogger.Enabled:=True;
  RegisterStandardHandlers;
    FServer.Controller.ServiceName := 'lazarus-ide';
  FServer.Controller.ServiceVersion := '1.0.0';
    FServer.SingleConnect := False;
    // Keep the controller and its registries single-threaded. A disconnected
    // client is handled as a normal end-of-stream and the accept loop continues.
    FServer.ThreadMode := tmNone;
    FServer.ConnectionTimeout := 300000;
  FServer.Port:=10987;
  FServer.InitSocket;
  TThread.CreateAnonymousThread(@DoRunLoop).Start;
end;

procedure TMCPToolController.RegisterTools;
begin
  With TMCPEventTool.create('openproject','Open a lazarus project',@MCPOpenProject) do
    begin
    InputSchema.AddArgument('projectfile',TJSONObject.Create(['type','string']),True);
    Register;
    end;
  With TMCPEventTool.create('newproject','Create a new lazarus project',@MCPNewProject) do
    begin
    Register;
    end;
  With TMCPEventTool.create('newnunit','Add a new unit to the project',@MCPAddNewUnit) do
    begin
    InputSchema.AddArgument('filename',TJSONObject.Create(['type','string']),True);
    Register;
    end;
  With TMCPEventTool.create('addnunit','Add an existing unit to the project',@MCPAddExistingUnit) do
    begin
    InputSchema.AddArgument('filename',TJSONObject.Create(['type','string']),True);
    Register;
    end;
  With TMCPEventTool.create('compile','compile project',@MCPCompileProject) do
    begin
    InputSchema.AddArgument('build',TJSONObject.Create(['type','boolean']),True);
    Register;
    end;
  With TMCPEventTool.create('getWorkspaceInfo','Inspect the active Lazarus project',@MCPGetWorkspaceInfo) do
    Register;
  With TMCPEventTool.create('listProjectFiles','List files in the active Lazarus project',@MCPListProjectFiles) do
    Register;
  With TMCPEventTool.create('listOpenEditors','List open Lazarus source editors',@MCPListOpenEditors) do
    Register;
  With TMCPEventTool.create('getActiveEditor','Inspect the active Lazarus source editor',@MCPGetActiveEditor) do
    Register;
  With TMCPEventTool.create('readEditorText','Read a bounded range from an open project editor',@MCPReadEditorText) do
    begin
    InputSchema.AddArgument('filename',TJSONObject.Create(['type','string']),True);
    InputSchema.AddArgument('startLine',TJSONObject.Create(['type','integer']),False);
    InputSchema.AddArgument('endLine',TJSONObject.Create(['type','integer']),False);
    Register;
    end;
  With TMCPEventTool.create('getBuildMessages','Read messages from the Lazarus build window',@MCPGetBuildMessages) do
    Register;
end;

procedure TMCPToolController.Terminate;
begin
  FServer.Terminate;
end;

finalization
  if assigned(_ToolController) then
    _ToolController.Terminate;
  FreeAndNil(_ToolController);
end.

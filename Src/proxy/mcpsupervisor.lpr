{
    This file is part of the Free Component Library

    MCP supervising proxy: a stdio MCP server that launches/stops a target
    GUI-control application and forwards every other MCP call to that app's
    embedded HTTP MCP server.
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{
  WHY THIS EXISTS
  ---------------
  An MCP GUI-control server lives *inside* the application under test, so its
  lifetime is the app's, not Claude's. But an MCP client enumerates its servers
  at its OWN startup - when the app is usually not running yet (and during a
  build/debug loop it is repeatedly stopped, recompiled and restarted).

  This program inverts the dependency. It is a tiny, headless STDIO MCP server
  that the client spawns at startup (always available, no display needed to
  exist). It exposes four lifecycle tools - start, stop, restart, status - and
  forwards every other MCP request to the target app's HTTP MCP endpoint.

  It does NOT hardcode the app's tool set: tools/list is answered with the four
  lifecycle tools PLUS, when the app is running, the app's own live tools/list
  fetched over HTTP. start/stop emit notifications/tools/list_changed so the
  client refreshes and the app's tools appear/disappear.
}
program mcpsupervisor;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes, fpjson, jsonparser, fphttpclient, process, custapp,
  mcp.controller, mcp.transport.stdio;

const
  DefaultURL        = 'http://127.0.0.1:18900/MCP';
  DefaultProtocol   = '2024-11-05';
  ReadyTimeoutMs    = 20000; // how long start() waits for the app to answer
  ReadyPollMs       = 300;
  ForwardTimeoutMs  = 15000;

type

  { TPipeDrainThread }

  // Keeps the child's merged stdout/stderr pipe empty so the child can never
  // block (or die with RTE 101 "Disk full") on a write to it. Reads to EOF and
  // discards everything.
  TPipeDrainThread = class(TThread)
  private
    FPipe : TStream;
  protected
    procedure Execute; override;
  public
    constructor Create(aPipe : TStream);
  end;

  { TMCPSupervisorApp }

  TMCPSupervisorApp = class(TCustomApplication)
  private
    FTarget : String;       // path to the application binary to launch
    FURL : String;          // the app's MCP HTTP endpoint
    FController : TMCPController;
    FText : TMCPSTDIOTransport;
    FProc : TProcess;        // the launched app (nil when not running)
    FDrain : TThread;        // drains the launched app's stdout/stderr pipe
    FAppId : Integer;        // id counter for proxy->app requests
    FTargetLocked : Boolean; // True when --target was given: binary is fixed, setBinary refused
    FAllow : TStringList;    // whitelist entries loaded from the config file (may be empty)
    procedure LoadAllowList;
    function IsAllowed(const aPath : String) : Boolean;
    procedure DoSetBinary(const aPath : String; out aText : String; out aIsError : Boolean);
    function AppRunning : Boolean;
    procedure StopApp;
    function PostToApp(const aBody : String; aTimeoutMs : Integer; out aResponse : String) : Boolean;
    function ForwardRaw(aRequest : TJSONObject) : TJSONObject;
    function ProbeReady : Boolean;
    procedure DoStart(out aText : String);
    procedure DoStop(out aText : String);
    procedure NotifyToolsChanged;
    function LifecycleTools : TJSONArray;
    function MakeResponse(aRequest : TJSONObject) : TJSONObject;
    function ToolResult(aRequest : TJSONObject; const aJSONText : String; aIsError : Boolean = False) : TJSONObject;
    procedure HandleInitialize(aRequest : TJSONObject; out aResponse : TJSONObject);
    procedure HandleToolsList(aRequest : TJSONObject; out aResponse : TJSONObject);
    procedure HandleToolsCall(aRequest : TJSONObject; out aResponse : TJSONObject);
    procedure HandleRequest(aRequest : TJSONObject; var aResponse : TJSONObject);
  protected
    procedure DoRun; override;
  public
    destructor Destroy; override;
  end;

function JStr(const aValue : String) : TJSONString;

begin
  Result := TJSONString.Create(aValue);
end;


function ToolDef(const aName, aDescription : String) : TJSONObject;

var
  lSchema : TJSONObject;

begin
  lSchema := TJSONObject.Create;
  lSchema.Add('type', 'object');
  lSchema.Add('properties', TJSONObject.Create);
  Result := TJSONObject.Create;
  Result.Add('name', aName);
  Result.Add('description', aDescription);
  Result.Add('inputSchema', lSchema);
end;


// Like ToolDef, but declares one required string argument in the input schema.
function ToolDefArg(const aName, aDescription, aArgName, aArgDescription : String) : TJSONObject;

var
  lSchema, lProps, lProp : TJSONObject;
  lRequired : TJSONArray;

begin
  lProp := TJSONObject.Create;
  lProp.Add('type', 'string');
  lProp.Add('description', aArgDescription);
  lProps := TJSONObject.Create;
  lProps.Add(aArgName, lProp);
  lRequired := TJSONArray.Create;
  lRequired.Add(aArgName);
  lSchema := TJSONObject.Create;
  lSchema.Add('type', 'object');
  lSchema.Add('properties', lProps);
  lSchema.Add('required', lRequired);
  Result := TJSONObject.Create;
  Result.Add('name', aName);
  Result.Add('description', aDescription);
  Result.Add('inputSchema', lSchema);
end;


// True when the path has a parent-directory (..) segment, which could escape a
// whitelisted folder prefix.
function HasDotDot(const aPath : String) : Boolean;

begin
  Result := (Pos('/../', aPath) > 0)
         or (Copy(aPath, 1, 3) = '../')
         or ((Length(aPath) >= 3) and (Copy(aPath, Length(aPath) - 2, 3) = '/..'));
end;


{ TPipeDrainThread }

constructor TPipeDrainThread.Create(aPipe : TStream);

begin
  FPipe := aPipe;
  FreeOnTerminate := False; // the supervisor WaitFor's it, so it must survive
  inherited Create(False);
end;


procedure TPipeDrainThread.Execute;

var
  lBuf : array[0..4095] of Byte;
  lCount : LongInt;

begin
  // Read blocks while the child lives and is silent; it returns 0 once the
  // child exits and the pipe's write end closes, ending the loop.
  repeat
    lCount := FPipe.Read(lBuf, SizeOf(lBuf));
  until Terminated or (lCount <= 0);
end;


{ TMCPSupervisorApp }

destructor TMCPSupervisorApp.Destroy;

begin
  // Never orphan the launched app when the client disconnects.
  StopApp;
  FreeAndNil(FText);
  FreeAndNil(FController);
  FreeAndNil(FAllow);
  inherited Destroy;
end;


// Terminates the launched app and reaps its drain thread, in that order: the
// child must die first so the pipe's write end closes and the drain's blocking
// Read returns, before we free the pipe the thread is reading.
procedure TMCPSupervisorApp.StopApp;

begin
  if not Assigned(FProc) then
    Exit;
  if FProc.Running then
    FProc.Terminate(0);
  if Assigned(FDrain) then
    begin
    FDrain.Terminate;
    FDrain.WaitFor;
    FreeAndNil(FDrain);
    end;
  FreeAndNil(FProc);
end;


function TMCPSupervisorApp.AppRunning : Boolean;

begin
  Result := Assigned(FProc) and FProc.Running;
end;


// Loads the whitelist from the first config file that exists: the user file
// (~/.config/mcpsupervisor.conf) then the system file (/etc/mcpsupervisor.conf).
// The file is JSON: { "allow": [ "/path", "/dir/*", "/dir/**" ] }. A missing,
// unreadable or malformed file leaves the whitelist empty.
procedure TMCPSupervisorApp.LoadAllowList;

var
  lPaths : array[0..1] of String;
  lFile, lHome, lRaw : String;
  I, J : Integer;
  lSL : TStringList;
  lData, lAllow : TJSONData;
  lArr : TJSONArray;

begin
  FAllow.Clear;
  lHome := GetEnvironmentVariable('HOME');
  lPaths[0] := '';
  if lHome <> '' then
    lPaths[0] := IncludeTrailingPathDelimiter(lHome) + '.config/mcpsupervisor.conf';
  lPaths[1] := '/etc/mcpsupervisor.conf';
  lFile := '';
  for I := 0 to High(lPaths) do
    if (lPaths[I] <> '') and FileExists(lPaths[I]) then
      begin
      lFile := lPaths[I];
      Break; // first existing file wins - no merge
      end;
  if lFile = '' then
    Exit;

  lRaw := '';
  lSL := TStringList.Create;
  try
    try
      lSL.LoadFromFile(lFile);
      lRaw := lSL.Text;
    except
      lRaw := '';
    end;
  finally
    lSL.Free;
  end;
  if lRaw = '' then
    Exit;

  lData := nil;
  try
    try
      lData := GetJSON(lRaw);
    except
      on E : Exception do
        begin
        Writeln(StdErr, 'mcpsupervisor: ignoring config ', lFile, ': invalid JSON (', E.Message, ')');
        lData := nil;
        end;
    end;
    if lData is TJSONObject then
      begin
      lAllow := TJSONObject(lData).Find('allow');
      if lAllow is TJSONArray then
        begin
        lArr := TJSONArray(lAllow);
        for J := 0 to lArr.Count - 1 do
          if lArr.Items[J].JSONType = jtString then
            FAllow.Add(lArr.Items[J].AsString);
        end
      else
        Writeln(StdErr, 'mcpsupervisor: config ', lFile, ' has no "allow" array; whitelist is empty');
      end
    else if lData <> nil then
      Writeln(StdErr, 'mcpsupervisor: config ', lFile, ' is not a JSON object; whitelist is empty');
  finally
    lData.Free;
  end;
end;


// True when aPath is permitted by the whitelist. Entry forms:
//   exact    - aPath equals the entry
//   /dir/*   - aPath's directory is exactly /dir (direct children only)
//   /dir/**  - aPath is anywhere under /dir (any depth)
// Matching is lexical: symlinks and '.' segments are not resolved, so the config
// file is the trust boundary - only trusted administrators should be able to edit it.
function TMCPSupervisorApp.IsAllowed(const aPath : String) : Boolean;

var
  I : Integer;
  lEntry, lBase : String;

begin
  Result := False;
  for I := 0 to FAllow.Count - 1 do
    begin
    lEntry := FAllow[I];
    if (Length(lEntry) >= 3) and (Copy(lEntry, Length(lEntry) - 2, 3) = '/**') then
      begin
      lBase := Copy(lEntry, 1, Length(lEntry) - 3);
      Result := Copy(aPath, 1, Length(lBase) + 1) = lBase + '/';
      end
    else if (Length(lEntry) >= 2) and (Copy(lEntry, Length(lEntry) - 1, 2) = '/*') then
      begin
      lBase := Copy(lEntry, 1, Length(lEntry) - 2);
      Result := ExtractFileDir(aPath) = lBase;
      end
    else
      Result := aPath = lEntry;
    if Result then
      Exit;
    end;
end;


// Validates aPath and, if acceptable, makes it the binary that start() launches.
// Checks in order: not locked, non-empty, absolute, no '..' segment, exists,
// whitelisted. On any failure aIsError is True and FTarget is left unchanged.
procedure TMCPSupervisorApp.DoSetBinary(const aPath : String; out aText : String; out aIsError : Boolean);

begin
  aIsError := True;
  if FTargetLocked then
    aText := '{"ok":false,"error":"a fixed target is configured (--target); setBinary is not allowed"}'
  else if aPath = '' then
    aText := '{"ok":false,"error":"path is required"}'
  else if aPath[1] <> '/' then
    aText := '{"ok":false,"error":"path must be absolute"}'
  else if HasDotDot(aPath) then
    aText := '{"ok":false,"error":"path must not contain a parent (..) segment"}'
  else if not FileExists(aPath) then
    aText := Format('{"ok":false,"error":"binary not found","path":%s}', [JStr(aPath).AsJSON])
  else if not IsAllowed(aPath) then
    aText := Format('{"ok":false,"error":"binary not allowed by whitelist configuration","path":%s}', [JStr(aPath).AsJSON])
  else
    begin
    FTarget := aPath;
    aText := Format('{"ok":true,"binary":%s}', [JStr(aPath).AsJSON]);
    aIsError := False;
    end;
end;


function TMCPSupervisorApp.PostToApp(const aBody : String; aTimeoutMs : Integer; out aResponse : String) : Boolean;

var
  lClient : TFPHTTPClient;

begin
  Result := False;
  aResponse := '';
  lClient := TFPHTTPClient.Create(nil);
  try
    lClient.ConnectTimeout := aTimeoutMs;
    lClient.IOTimeout := aTimeoutMs;
    lClient.AddHeader('Content-Type', 'application/json');
    lClient.AddHeader('Accept', 'application/json, text/event-stream');
    lClient.RequestBody := TStringStream.Create(aBody);
    try
      aResponse := lClient.Post(FURL);
      Result := True;
    except
      on E : Exception do
        Result := False;
    end;
  finally
    lClient.RequestBody.Free;
    lClient.Free;
  end;
end;


// Forwards a JSON-RPC request to the app verbatim and returns the parsed
// response object (caller owns it), or nil when the app is unreachable.
function TMCPSupervisorApp.ForwardRaw(aRequest : TJSONObject) : TJSONObject;

var
  lRaw : String;
  lData : TJSONData;

begin
  Result := nil;
  if not PostToApp(aRequest.AsJSON, ForwardTimeoutMs, lRaw) then
    Exit;
  try
    lData := GetJSON(lRaw);
    if lData is TJSONObject then
      Result := TJSONObject(lData)
    else
      lData.Free;
  except
    on E : Exception do
      Result := nil;
  end;
end;


// Sends an initialize to the app; True once it answers with a JSON-RPC result.
function TMCPSupervisorApp.ProbeReady : Boolean;

var
  lRaw : String;
  lData : TJSONData;

begin
  Result := False;
  Inc(FAppId);
  if not PostToApp(Format('{"jsonrpc":"2.0","id":%d,"method":"initialize",'
      + '"params":{"protocolVersion":"%s","capabilities":{},'
      + '"clientInfo":{"name":"mcp-supervisor","version":"1.0"}}}', [FAppId, DefaultProtocol]),
      ReadyPollMs * 3, lRaw) then
    Exit;
  lData := nil;
  try
    try
      lData := GetJSON(lRaw);
      Result := (lData is TJSONObject) and (TJSONObject(lData).Find('result') <> nil);
    except
      Result := False;
    end;
  finally
    lData.Free;
  end;
end;


procedure TMCPSupervisorApp.DoStart(out aText : String);

var
  lElapsed : Integer;

begin
  if AppRunning then
    begin
    aText := Format('{"ok":true,"alreadyRunning":true,"pid":%d,"url":%s}',
                    [FProc.ProcessID, JStr(FURL).AsJSON]);
    Exit;
    end;
  if FTarget = '' then
    begin
    aText := '{"ok":false,"error":"no binary set - call setBinary first"}';
    Exit;
    end;
  if not FileExists(FTarget) then
    begin
    aText := Format('{"ok":false,"error":"target binary not found","target":%s}', [JStr(FTarget).AsJSON]);
    Exit;
    end;
  StopApp; // reap any stale process/drain from a previous run
  FProc := TProcess.Create(nil);
  FProc.Executable := FTarget;
  FProc.CurrentDirectory := ExtractFileDir(FTarget);
  // Capture the child's stdout+stderr instead of inheriting OURS. poUsePipes
  // redirects both onto supervisor-owned pipes (so the child can no longer
  // write to our stdout - the MCP JSON-RPC channel); poStderrToOutPut merges
  // stderr into that one pipe, which the drain thread keeps empty. Without
  // this an undrained stderr fills its pipe and the child blocks, then fails
  // RTE 101 "Disk full" on its next write. Environment is still inherited.
  FProc.Options := [poUsePipes, poStderrToOutPut];
  FProc.Execute;
  FDrain := TPipeDrainThread.Create(FProc.Output);

  lElapsed := 0;
  while lElapsed < ReadyTimeoutMs do
    begin
    if not FProc.Running then
      begin
      aText := '{"ok":false,"error":"target exited during startup"}';
      StopApp;
      Exit;
      end;
    if ProbeReady then
      begin
      aText := Format('{"ok":true,"pid":%d,"url":%s}', [FProc.ProcessID, JStr(FURL).AsJSON]);
      NotifyToolsChanged;
      Exit;
      end;
    Sleep(ReadyPollMs);
    Inc(lElapsed, ReadyPollMs);
    end;
  aText := '{"ok":false,"error":"target did not become ready before timeout"}';
end;


procedure TMCPSupervisorApp.DoStop(out aText : String);

begin
  if not AppRunning then
    begin
    StopApp; // clears any stale process/drain
    aText := '{"ok":true,"alreadyStopped":true}';
    Exit;
    end;
  StopApp;
  aText := '{"ok":true}';
  NotifyToolsChanged;
end;


procedure TMCPSupervisorApp.NotifyToolsChanged;

var
  lMsg : TJSONObject;

begin
  lMsg := TJSONObject.Create;
  try
    lMsg.Add('jsonrpc', '2.0');
    lMsg.Add('method', 'notifications/tools/list_changed');
    FText.SendMessage(lMsg);
  finally
    lMsg.Free;
  end;
end;


function TMCPSupervisorApp.LifecycleTools : TJSONArray;

begin
  Result := TJSONArray.Create;
  Result.Add(ToolDef('start',
    'Launch the target application (which hosts the GUI-control MCP server). '
    + 'Idempotent; waits until the app answers. After this, the app''s own tools appear in tools/list.'));
  Result.Add(ToolDef('stop', 'Terminate the target application.'));
  Result.Add(ToolDef('restart', 'Stop then start the target application (use after a rebuild).'));
  Result.Add(ToolDef('status', 'Report whether the target app is running, its pid and MCP url, the selected binary, whether that binary choice is locked by --target, and whether the binary exists on disk.'));
  Result.Add(ToolDefArg('setBinary',
    'Choose the application binary to launch (absolute path). Only allowed when no --target '
    + 'was given on the command line, and only for paths permitted by the supervisor whitelist config. '
    + 'Call this before start() when the supervisor was started without --target.',
    'path', 'Absolute path to the application binary to launch.'));
end;


function TMCPSupervisorApp.MakeResponse(aRequest : TJSONObject) : TJSONObject;

var
  lId : TJSONData;

begin
  Result := TJSONObject.Create;
  Result.Add('jsonrpc', '2.0');
  lId := aRequest.Find('id');
  if lId <> nil then
    Result.Add('id', lId.Clone);
end;


function TMCPSupervisorApp.ToolResult(aRequest : TJSONObject; const aJSONText : String; aIsError : Boolean = False) : TJSONObject;

var
  lContent : TJSONArray;
  lItem, lResult : TJSONObject;

begin
  lItem := TJSONObject.Create;
  lItem.Add('type', 'text');
  lItem.Add('text', aJSONText);
  lContent := TJSONArray.Create;
  lContent.Add(lItem);
  lResult := TJSONObject.Create;
  lResult.Add('content', lContent);
  if aIsError then
    lResult.Add('isError', True);
  Result := MakeResponse(aRequest);
  Result.Add('result', lResult);
end;


procedure TMCPSupervisorApp.HandleInitialize(aRequest : TJSONObject; out aResponse : TJSONObject);

var
  lResult, lCaps, lToolsCap, lServerInfo : TJSONObject;
  lParams : TJSONData;
  lProtocol : String;

begin
  lProtocol := DefaultProtocol;
  lParams := aRequest.Find('params');
  if lParams is TJSONObject then
    lProtocol := TJSONObject(lParams).Get('protocolVersion', DefaultProtocol);

  lToolsCap := TJSONObject.Create;
  lToolsCap.Add('listChanged', True);
  lCaps := TJSONObject.Create;
  lCaps.Add('tools', lToolsCap);
  lServerInfo := TJSONObject.Create;
  lServerInfo.Add('name', 'mcp-app-supervisor');
  lServerInfo.Add('version', '1.0');

  lResult := TJSONObject.Create;
  lResult.Add('protocolVersion', lProtocol);
  lResult.Add('serverInfo', lServerInfo);
  lResult.Add('capabilities', lCaps);
  lResult.Add('instructions',
    'Call start() to launch the target app; then its GUI-control tools become available. '
    + 'Use restart() after rebuilding, stop() to terminate.');

  aResponse := MakeResponse(aRequest);
  aResponse.Add('result', lResult);
end;


procedure TMCPSupervisorApp.HandleToolsList(aRequest : TJSONObject; out aResponse : TJSONObject);

var
  lTools : TJSONArray;
  lResult, lAppResp : TJSONObject;
  lAppTools : TJSONData;
  lAppReq : TJSONObject;
  I : Integer;

begin
  lTools := LifecycleTools;
  if AppRunning then
    begin
    Inc(FAppId);
    lAppReq := TJSONObject.Create;
    try
      lAppReq.Add('jsonrpc', '2.0');
      lAppReq.Add('id', FAppId);
      lAppReq.Add('method', 'tools/list');
      lAppResp := ForwardRaw(lAppReq);
    finally
      lAppReq.Free;
    end;
    if Assigned(lAppResp) then
      try
        lAppTools := lAppResp.FindPath('result.tools');
        if lAppTools is TJSONArray then
          for I := 0 to TJSONArray(lAppTools).Count - 1 do
            lTools.Add(TJSONArray(lAppTools).Items[I].Clone);
      finally
        lAppResp.Free;
      end;
    end;
  lResult := TJSONObject.Create;
  lResult.Add('tools', lTools);
  aResponse := MakeResponse(aRequest);
  aResponse.Add('result', lResult);
end;


procedure TMCPSupervisorApp.HandleToolsCall(aRequest : TJSONObject; out aResponse : TJSONObject);

var
  lParams, lArgs : TJSONData;
  lName, lText, lPath : String;
  lIsError : Boolean;

begin
  aResponse := nil;
  lName := '';
  lParams := aRequest.Find('params');
  if lParams is TJSONObject then
    lName := TJSONObject(lParams).Get('name', '');

  if lName = 'start' then
    begin
    DoStart(lText);
    aResponse := ToolResult(aRequest, lText);
    end
  else if lName = 'stop' then
    begin
    DoStop(lText);
    aResponse := ToolResult(aRequest, lText);
    end
  else if lName = 'restart' then
    begin
    DoStop(lText);
    DoStart(lText);
    aResponse := ToolResult(aRequest, lText);
    end
  else if lName = 'setBinary' then
    begin
    lPath := '';
    if lParams is TJSONObject then
      begin
      lArgs := TJSONObject(lParams).Find('arguments');
      if lArgs is TJSONObject then
        lPath := TJSONObject(lArgs).Get('path', '');
      end;
    DoSetBinary(lPath, lText, lIsError);
    aResponse := ToolResult(aRequest, lText, lIsError);
    end
  else if lName = 'status' then
    begin
    if AppRunning then
      lText := Format('{"running":true,"pid":%d,"url":%s,"binary":%s,"locked":%s,"binaryExists":%s}',
                 [FProc.ProcessID, JStr(FURL).AsJSON, JStr(FTarget).AsJSON,
                  BoolToStr(FTargetLocked, 'true', 'false'), BoolToStr((FTarget <> '') and FileExists(FTarget), 'true', 'false')])
    else
      lText := Format('{"running":false,"url":%s,"binary":%s,"locked":%s,"binaryExists":%s}',
                 [JStr(FURL).AsJSON, JStr(FTarget).AsJSON,
                  BoolToStr(FTargetLocked, 'true', 'false'), BoolToStr((FTarget <> '') and FileExists(FTarget), 'true', 'false')]);
    aResponse := ToolResult(aRequest, lText);
    end
  else
    begin
    // Not a lifecycle tool: forward to the app.
    if not AppRunning then
      aResponse := ToolResult(aRequest,
        '{"ok":false,"error":"target app is not running - call start() first"}', True)
    else
      begin
      aResponse := ForwardRaw(aRequest);
      if aResponse = nil then
        aResponse := ToolResult(aRequest,
          '{"ok":false,"error":"target app did not respond"}', True);
      end;
    end;
end;


procedure TMCPSupervisorApp.HandleRequest(aRequest : TJSONObject; var aResponse : TJSONObject);

var
  lMethod : String;

begin
  aResponse := nil;
  lMethod := aRequest.Get('method', '');

  if lMethod = 'initialize' then
    HandleInitialize(aRequest, aResponse)
  else if lMethod = 'tools/list' then
    HandleToolsList(aRequest, aResponse)
  else if lMethod = 'tools/call' then
    HandleToolsCall(aRequest, aResponse)
  else if lMethod = 'ping' then
    begin
    aResponse := MakeResponse(aRequest);
    aResponse.Add('result', TJSONObject.Create);
    end
  else if Copy(lMethod, 1, 14) = 'notifications/' then
    aResponse := nil // notifications get no reply
  else if AppRunning then
    // Anything else (resources/*, prompts/*, ...) is forwarded when possible.
    aResponse := ForwardRaw(aRequest);
end;


// Scans the command line for --long/-short VALUE and --long=VALUE forms.
function ArgValue(const aShort, aLong, aDefault : String) : String;

var
  I : Integer;
  lArg, lPrefix : String;

begin
  Result := aDefault;
  lPrefix := '--' + aLong + '=';
  I := 1;
  while I <= ParamCount do
    begin
    lArg := ParamStr(I);
    if ((lArg = '--' + aLong) or (lArg = '-' + aShort)) and (I < ParamCount) then
      begin
      Result := ParamStr(I + 1);
      Inc(I);
      end
    else if Copy(lArg, 1, Length(lPrefix)) = lPrefix then
      Result := Copy(lArg, Length(lPrefix) + 1, MaxInt);
    Inc(I);
    end;
end;


procedure TMCPSupervisorApp.DoRun;

begin
  Terminate; // single pass: RunMessageLoop blocks until stdin closes
  FTarget := ArgValue('t', 'target', '');
  FURL := ArgValue('u', 'url', DefaultURL);
  FTargetLocked := FTarget <> ''; // --target fixes the binary; setBinary is then refused
  FAllow := TStringList.Create;
  if not FTargetLocked then
    LoadAllowList; // the whitelist only matters when the client picks the binary via setBinary

  FController := TMCPController.Create(Self);
  FText := TMCPSTDIOTransport.Create(@Input, @Output, @StdErr);
  FController.RegisterTransport(FText);
  FText.RunMessageLoop(@HandleRequest);
end;


var
  Application : TMCPSupervisorApp;

begin
  Application := TMCPSupervisorApp.Create(nil);
  Application.Title := 'MCP application supervisor proxy';
  Application.Run;
  Application.Free;
end.

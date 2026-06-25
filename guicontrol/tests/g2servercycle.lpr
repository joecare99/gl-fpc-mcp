{
    This file is part of the Free Component Library

    MCP LCL control - G2 spike: start/stop the embedded server and round-trip tools/list
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{
  PURPOSE (Story 1.2 runnable check)
  ----------------------------------
  Prove the embedded MCP server lifecycle end-to-end, headless and unattended:
    - StartGUIControlServer binds on loopback and serves the MCP route.
    - A bare tools/list JSON-RPC POST round-trips and lists a registered tool.
    - The server defaults to read-only (AllowControl = False).
    - StopGUIControlServer fully tears down the thread and releases the socket,
      proven by re-starting on the same port and successfully serving again.

  No LCL message loop is needed: tools/list touches only the global tool
  registry on the server thread (no main-thread marshalling), so this runs
  display-free in the automator/CI.

  EXIT CODES (for the automator)
  ------------------------------
    0  PASS  - full start -> tools/list -> stop -> re-bind -> stop cycle succeeded
    1  FAIL  - the cycle ran but an assertion did not hold (see stdout)
    2  TIMEOUT/DEADLOCK - the watchdog fired before the check finished
}

program g2servercycle;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads, // must be first: enables thread support on Unix
  {$ENDIF}
  Classes, SysUtils, fpjson, jsonparser, fphttpclient,
  mcp.tools, mcp.lcl.control;

type

  { TProbeTool }

  // Trivial tool registered only so tools/list returns a non-empty array; it is
  // listed, never executed.
  TProbeTool = class(TMCPTool)
  protected
    procedure DoExecute(aInput : TJSONObject; aResult : TJSONObject); override;
  end;

  { TWatchdogThread }

  TWatchdogThread = class(TThread)
  protected
    procedure Execute; override;
  end;

const
  WatchdogMs   = 10000; // hard ceiling before declaring a deadlock
  TestPort     = 18765; // fixed high loopback port for the unattended check
  RetryCount   = 40;    // ~2s total of connect retries (RetryCount * RetryDelayMs)
  RetryDelayMs = 50;

var
  GFinished : PRTLEvent;
  GTestFinished : Boolean;


{ TProbeTool }

procedure TProbeTool.DoExecute(aInput : TJSONObject; aResult : TJSONObject);

begin
  aResult.Add('probe', True);
end;


{ TWatchdogThread }

procedure TWatchdogThread.Execute;

begin
  RTLEventWaitFor(GFinished, WatchdogMs);
  if not GTestFinished then
    begin
    Writeln('G2 SPIKE: TIMEOUT - the start/stop check did not finish (DEADLOCK).');
    Flush(Output);
    Halt(2);
    end;
end;


// POSTs a bare tools/list JSON-RPC request to the server on aPort, tolerating the
// startup race (the socket binds only later, inside the worker thread) with a
// bounded connect-retry loop. Returns True and the response body on success.
function PostToolsList(aPort : Word; out aResponse : String) : Boolean;

var
  lClient : TFPHTTPClient;
  lAttempt : Integer;

begin
  Result := False;
  aResponse := '';
  lClient := TFPHTTPClient.Create(nil);
  try
    lClient.AddHeader('Content-Type', 'application/json');
    lClient.RequestBody := TStringStream.Create('{"jsonrpc":"2.0","id":1,"method":"tools/list"}');
    for lAttempt := 1 to RetryCount do
      try
        aResponse := lClient.Post('http://127.0.0.1:' + IntToStr(aPort) + '/MCP');
        Result := True;
        Break;
      except
        on E: Exception do
          if lAttempt = RetryCount then
            Writeln('G2 SPIKE: FAIL - tools/list POST never connected: ', E.Message)
          else
            Sleep(RetryDelayMs);
      end;
  finally
    lClient.RequestBody.Free;
    lClient.Free;
  end;
end;


// Asserts the tools/list response is a success envelope whose result.tools array
// lists the probe tool. Writes the reason and returns False on any mismatch.
function ToolsListListsProbe(const aResponse : String) : Boolean;

var
  lJSON : TJSONData;
  lTools : TJSONData;
  lArr : TJSONArray;
  I : Integer;

begin
  Result := False;
  lJSON := nil;
  try
    lJSON := GetJSON(aResponse);
    if not (lJSON is TJSONObject) then
      begin
      Writeln('G2 SPIKE: FAIL - response is not a JSON object: ', aResponse);
      Exit;
      end;
    // AC #1 envelope: jsonrpc "2.0" with the request id echoed back.
    if TJSONObject(lJSON).Get('jsonrpc', '') <> '2.0' then
      begin
      Writeln('G2 SPIKE: FAIL - response is not a jsonrpc 2.0 envelope: ', aResponse);
      Exit;
      end;
    if TJSONObject(lJSON).Get('id', 0) <> 1 then
      begin
      Writeln('G2 SPIKE: FAIL - response did not echo the request id (1): ', aResponse);
      Exit;
      end;
    if TJSONObject(lJSON).Find('error') <> nil then
      begin
      Writeln('G2 SPIKE: FAIL - response carries an error member: ', aResponse);
      Exit;
      end;
    lTools := lJSON.FindPath('result.tools');
    if not (lTools is TJSONArray) then
      begin
      Writeln('G2 SPIKE: FAIL - result.tools is missing or not an array: ', aResponse);
      Exit;
      end;
    lArr := TJSONArray(lTools);
    if lArr.Count < 1 then
      begin
      Writeln('G2 SPIKE: FAIL - result.tools is empty.');
      Exit;
      end;
    for I := 0 to lArr.Count - 1 do
      if (lArr.Objects[I].Find('name') <> nil)
         and (lArr.Objects[I].Get('name', '') = 'probe') then
        begin
        Result := True;
        Break;
        end;
    if not Result then
      Writeln('G2 SPIKE: FAIL - the probe tool was not listed by tools/list.');
  finally
    lJSON.Free;
  end;
end;


// Performs the start -> tools/list -> stop -> re-bind -> stop cycle. Returns True
// on success; on any failed assertion writes the reason and returns False.
function RunCheck : Boolean;

var
  lResponse : String;

begin
  Result := False;

  StartGUIControlServer(TestPort); // no second arg -> AllowControl = False
  try
    // AC #2: read-only by default. Verified in-process (no control tool exists yet).
    if GUIControlAllowsControl then
      begin
      Writeln('G2 SPIKE: FAIL - server defaulted to control-enabled (expected read-only).');
      Exit;
      end;

    // AC #1: a bare tools/list POST round-trips and lists the probe tool.
    if not PostToolsList(TestPort, lResponse) then
      Exit;
    if not ToolsListListsProbe(lResponse) then
      Exit;
  finally
    StopGUIControlServer;
  end;

  // AC #3: prove the socket was released by re-starting on the same port and
  // serving again. Waiting for the POST to succeed confirms the re-bind and also
  // keeps the following stop free of the start/stop race.
  StartGUIControlServer(TestPort);
  try
    if not PostToolsList(TestPort, lResponse) then
      begin
      Writeln('G2 SPIKE: FAIL - re-start on the same port did not serve (socket not released?).');
      Exit;
      end;
    if not ToolsListListsProbe(lResponse) then
      Exit;
  finally
    StopGUIControlServer;
  end;

  Result := True;
end;


var
  lWatchdog : TWatchdogThread;

begin
  GFinished := RTLEventCreate;
  lWatchdog := TWatchdogThread.Create(False);
  try
    // Register the probe tool before starting; the registry is global.
    With TProbeTool.Create('probe', 'Probe tool for the lifecycle check') do
      Register;
    if RunCheck then
      begin
      Writeln('G2 SPIKE: PASS - start/stop lifecycle and tools/list round-trip verified.');
      ExitCode := 0;
      end
    else
      ExitCode := 1;
  finally
    GTestFinished := True;
    RTLEventSetEvent(GFinished);
    lWatchdog.WaitFor;
    lWatchdog.Free;
    RTLEventDestroy(GFinished);
  end;
  Flush(Output);
end.

{
    Quick mail test program.
    Uses the actual MCP tool classes from mcpmailtools to test
    the implemented MCP functionalities without an agent.
    Reads the same .ini file as the MCP mail server.
}
program mailtest;

{$mode objfpc}{$H+}

uses
  {$ifdef unix}
  cthreads,
  {$endif}
  Classes, SysUtils, IniFiles, fpjson, jsonparser,
  mcp.types, mcp.logging, mcp.tools,
  mcpmailtools, ssl_openssl3;

function ExtractToolResult(aOutput: TJSONObject): TJSONObject;
{ Execute wraps tool output as: {"content":[{"type":"text","text":"<json>"}]}
  This extracts and parses the inner JSON object. Caller must free result. }
var
  ContentArr: TJSONArray;
  Inner: String;
begin
  ContentArr := aOutput.Arrays['content'];
  Inner := ContentArr.Objects[0].Get('text', '');
  Result := GetJSON(Inner) as TJSONObject;
end;

procedure Run;
var
  Ini: TMemIniFile;
  ConfigFile: String;
  Tool: TMCPTool;
  Input, Output, ToolData: TJSONObject;
  Arr: TJSONArray;
  i, Count, MaxIndex: Integer;
  HeaderText, FromVal, SubjectVal, Line: String;
  HeaderLines: TStringList;
begin
  if ParamCount < 1 then
  begin
    Writeln(StdErr, 'Usage: mailtest <config.ini>');
    Halt(1);
  end;
  ConfigFile := ParamStr(1);
  if not FileExists(ConfigFile) then
  begin
    Writeln(StdErr, 'Config file not found: ', ConfigFile);
    Halt(1);
  end;

  // Load config using the same pattern as mcpmailserver
  Ini := TMemIniFile.Create(ConfigFile);
  try
    TIMAPConnectionManager.Instance.SetConfig(
      Ini.ReadString('IMAP', 'Host', ''),
      Ini.ReadString('IMAP', 'Port', '993'),
      Ini.ReadString('IMAP', 'User', ''),
      Ini.ReadString('IMAP', 'Password', ''),
      Ini.ReadBool('IMAP', 'TLS', True)
    );
  finally
    Ini.Free;
  end;

  Writeln('Connecting to IMAP server...');

  // Select INBOX
  Tool := TSelectFolderTool.Create('select-folder', 'Select folder');
  try
    Input := TJSONObject.Create(['folder', 'INBOX']);
    Output := TJSONObject.Create;
    try
      Tool.Execute(Input, Output);
      ToolData := ExtractToolResult(Output);
      try
        Writeln('Selected folder: ', ToolData.Get('folder', ''));
      finally
        ToolData.Free;
      end;
    finally
      Input.Free;
      Output.Free;
    end;
  finally
    Tool.Free;
  end;

  // Count total messages
  Count := 0;
  Tool := TCountMessagesTool.Create('count-messages', 'Count messages');
  try
    Input := TJSONObject.Create;
    Output := TJSONObject.Create;
    try
      Tool.Execute(Input, Output);
      ToolData := ExtractToolResult(Output);
      try
        Count := ToolData.Get('count', 0);
      finally
        ToolData.Free;
      end;
    finally
      Input.Free;
      Output.Free;
    end;
  finally
    Tool.Free;
  end;
  Writeln;
  Writeln('Total messages in INBOX: ', Count);

  // Count unread messages
  Tool := TCountUnreadTool.Create('count-unread', 'Count unread');
  try
    Input := TJSONObject.Create;
    Output := TJSONObject.Create;
    try
      Tool.Execute(Input, Output);
      ToolData := ExtractToolResult(Output);
      try
        Writeln('Unread messages:         ', ToolData.Get('count', 0));
      finally
        ToolData.Free;
      end;
    finally
      Input.Free;
      Output.Free;
    end;
  finally
    Tool.Free;
  end;

  // Get headers for first 50 messages (tool uses 0-based indexing)
  MaxIndex := Count;
  if MaxIndex > 50 then
    MaxIndex := 50;
  Writeln;
  Writeln('--- Headers (first ', MaxIndex, ' messages) ---');

  if MaxIndex > 0 then
  begin
    Tool := TGetHeadersTool.Create('get-headers', 'Get headers');
    try
      Input := TJSONObject.Create(['from_index', 0, 'to_index', MaxIndex - 1]);
      Output := TJSONObject.Create;
      try
        Tool.Execute(Input, Output);
        ToolData := ExtractToolResult(Output);
        try
          Arr := ToolData.Get('messages', TJSONArray(nil));
          if Assigned(Arr) then
          begin
            for i := 0 to Arr.Count - 1 do
            begin
              HeaderText := Arr.Objects[i].Get('headers', '');
              FromVal := '';
              SubjectVal := '';
              HeaderLines := TStringList.Create;
              try
                HeaderLines.Text := HeaderText;
                for Line in HeaderLines do
                begin
                  if Pos('From:', Line) = 1 then
                    FromVal := Trim(Copy(Line, 6, Length(Line)))
                  else if Pos('Subject:', Line) = 1 then
                    SubjectVal := Trim(Copy(Line, 9, Length(Line)));
                end;
              finally
                HeaderLines.Free;
              end;
              Writeln('[', Arr.Objects[i].Get('index', 0), '] From:    ', FromVal);
              Writeln('    Subject: ', SubjectVal);
            end;
          end;
        finally
          ToolData.Free;
        end;
      finally
        Input.Free;
        Output.Free;
      end;
    finally
      Tool.Free;
    end;
  end;

  // Get body of first message (0-based mail_id)
  if Count > 0 then
  begin
    Writeln;
    Writeln('--- Body of message 0 ---');
    Tool := TGetMailTool.Create('get-mail', 'Get mail');
    try
      Input := TJSONObject.Create(['mail_id', 0]);
      Output := TJSONObject.Create;
      try
        Tool.Execute(Input, Output);
        ToolData := ExtractToolResult(Output);
        try
          Writeln(ToolData.Get('body', ''));
        finally
          ToolData.Free;
        end;
      finally
        Input.Free;
        Output.Free;
      end;
    finally
      Tool.Free;
    end;
  end;

  Writeln;
  Writeln('Done.');
end;

begin
  MCPLogger.Enabled := True;
  MCPLogger.LogToConsole := True;
  MCPLogger.LogLevels := [mltError, mltInfo, mltWarning];
  try
    Run;
  except
    on E: Exception do
      Writeln(StdErr, 'Error: ', E.Message);
  end;
end.

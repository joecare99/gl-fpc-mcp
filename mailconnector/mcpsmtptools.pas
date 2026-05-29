{
    This file is part of the Free Component Library

    Mail MCP Server - SMTP tools foundation
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit mcpsmtptools;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, mcp.types, mcp.logging, mcp.tools, smtpsend,
  mimemess, mimepart, ssl_openssl3;

type

  { TSMTPConfig }

  TSMTPConfig = record
    Host: String;
    Port: String;
    User: String;
    Password: String;
    TLS: Boolean;
  end;

var
  SMTPConfig: TSMTPConfig;

type

  { TSMTPMailTool }

  TSMTPMailTool = class abstract (TMCPTool)
  protected
    function GetSMTPConfig: TSMTPConfig;
  end;

  { TSendMailTool }

  TSendMailTool = class(TSMTPMailTool)
  protected
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    constructor Create(const aName, aDescription: string); override;
  end;

implementation

{ TSMTPMailTool }

function TSMTPMailTool.GetSMTPConfig: TSMTPConfig;
begin
  Result := SMTPConfig;
end;

{ TSendMailTool }

constructor TSendMailTool.Create(const aName, aDescription: string);
begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('recipients',
    TJSONObject.Create(['type', 'array', 'items', TJSONObject.Create(['type', 'string'])]), True);
  InputSchema.AddArgument('body', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('attachments',
    TJSONObject.Create(['type', 'array', 'items', TJSONObject.Create(['type', 'string'])]), True);
end;

procedure TSendMailTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
var
  lConfig: TSMTPConfig;
  lSMTP: TSMTPSend;
  lMsg: TMimeMess;
  lBodyLines: TStringList;
  lMultiPart: TMimePart;
  lRecipients: TJSONArray;
  lAttachments: TJSONArray;
  lBody: String;
  lFrom: String;
  lLoggedIn: Boolean;
  lAttachCount: Integer;
  i: Integer;
begin
  // Validate recipients (AC #4)
  lRecipients := aInput.Arrays['recipients'];
  if (lRecipients = nil) or (lRecipients.Count = 0) then
    raise EMCPException.Create('recipients must not be empty');

  lBody := aInput.Get('body', '');
  lAttachments := aInput.Arrays['attachments'];

  // Validate attachment file paths exist before connecting (AC #3)
  if lAttachments <> nil then
    for i := 0 to lAttachments.Count - 1 do
      if not FileExists(lAttachments.Strings[i]) then
        raise EMCPException.CreateFmt('Attachment file not found: "%s"', [lAttachments.Strings[i]]);

  lConfig := GetSMTPConfig;
  lFrom := lConfig.User;
  if lAttachments <> nil then lAttachCount := lAttachments.Count else lAttachCount := 0;
  DoLog(mltTrace, 'send-mail: recipients=%d attachments=%d', [lRecipients.Count, lAttachCount]);

  lMsg := TMimeMess.Create;
  lBodyLines := TStringList.Create;
  lSMTP := TSMTPSend.Create;
  lLoggedIn := False;
  try
    // Build MIME message headers
    lMsg.Header.From := lFrom;
    for i := 0 to lRecipients.Count - 1 do
      lMsg.Header.ToList.Add(lRecipients.Strings[i]);

    // Build body and attachments (AC #1, #2)
    lBodyLines.Text := lBody;
    if (lAttachments <> nil) and (lAttachments.Count > 0) then
    begin
      lMultiPart := lMsg.AddPartMultipart('mixed', lMsg.MessagePart);
      lMsg.AddPartText(lBodyLines, lMultiPart);
      for i := 0 to lAttachments.Count - 1 do
        lMsg.AddPartBinaryFromFile(lAttachments.Strings[i], lMultiPart);
    end
    else
      lMsg.AddPartText(lBodyLines, lMsg.MessagePart);

    lMsg.EncodeMessage;

    // Configure SMTP connection
    lSMTP.TargetHost := lConfig.Host;
    lSMTP.TargetPort := lConfig.Port;
    lSMTP.Username := lConfig.User;
    lSMTP.Password := lConfig.Password;
    if lConfig.TLS then
      lSMTP.AutoTLS := True;

    // Connect and authenticate (AC #5)
    if not lSMTP.Login then
      raise EMCPException.CreateFmt('SMTP connection failed (%s:%s): %s',
        [lConfig.Host, lConfig.Port, lSMTP.ResultString]);
    lLoggedIn := True;

    // Send message (AC #1, #2)
    if not lSMTP.MailFrom(lFrom, 0) then
      raise EMCPException.CreateFmt('SMTP MAIL FROM failed: %s', [lSMTP.ResultString]);

    for i := 0 to lRecipients.Count - 1 do
      if not lSMTP.MailTo(lRecipients.Strings[i]) then
        raise EMCPException.CreateFmt('SMTP RCPT TO failed for "%s": %s',
          [lRecipients.Strings[i], lSMTP.ResultString]);

    if not lSMTP.MailData(lMsg.Lines) then
      raise EMCPException.CreateFmt('SMTP DATA failed: %s', [lSMTP.ResultString]);

    lSMTP.Logout;
    lLoggedIn := False;

    aResult.Add('status', 'sent');
    aResult.Add('recipients', lRecipients.Count);
    DoLog(mltInfo, 'send-mail: sent to %d recipient(s)', [lRecipients.Count]);
  finally
    if lLoggedIn then
      lSMTP.Logout;
    lBodyLines.Free;
    lMsg.Free;
    lSMTP.Free;
  end;
end;

end.

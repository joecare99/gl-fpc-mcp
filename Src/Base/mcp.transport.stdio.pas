{
    This file is part of the Free Component Library

    MCP standard I/O transport class
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.transport.stdio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, mcp.transport.base;

Type
  PText = ^Text;

  { TLSPTextTransport }
  TJSONRequestHandler = procedure(aRequest : TJSONObject; var aResponse : TJSONObject) of object;

  { TMCPSTDIOTransport }

  TMCPSTDIOTransport = class(TMCPMessageTransport)
  private
    FInput : PText;
    FOutput : PText;
    FError : PText;
    function ReadRequest: TJSONObject;
  Protected
    Procedure DoSendMessage(aMessage: TJSONData); override;
    Procedure DoSendDiagnostic(const aMessage: UTF8String); override;
    Procedure EmitMessage(aMessage: TJSONStringType);
  Public
    constructor Create(aInput,aOutput,aError : PText); reintroduce;
    // specific
    Procedure SetupTextLoop(var aInput,aOutput,aError : Text);
    Procedure RunMessageLoop(aOnRequest : TJSONRequestHandler);
  end;



implementation

uses mcp.logging;

procedure TMCPSTDIOTransport.SetupTextLoop(var aInput, aOutput, aError: Text);

begin
  TJSONData.CompressedJSON := True;
  SetTextLineEnding(aInput, #13#10);
  SetTextLineEnding(aOutput, #13#10);
  SetTextLineEnding(aError, #13#10);
  FInput:=@AInput;
  FOutput:=@AOutput;
  FError:=@aError;
end;

function TMCPSTDIOTransport.ReadRequest: TJSONObject;

Var
  lContent : TJSONStringType;
  lData : TJSONData;

begin
  Result:=Nil;
  MCPLogger.Debug('Reading request');
  ReadLn(FInput^,lContent);
  MCPLogger.Debug('Read request: %s',[lContent]);
  if lContent<>'' then
    try
      lData:=GetJSON(lContent, True);
      if not (lData is TJSONObject) then
        Raise EJSON.CreateFmt('%s is not a JSON object',[lData.AsJSON]);
      Result:=lData as TJSONObject;
    except
      on E : Exception do
        begin
        MCPLogger.LogException(E,'Reading request from STDIN');
        SendDiagnostic('Exception %s while reading request from STDIN: %s',[E.ClassName,E.Message]);
        end;
    end;
end;


procedure TMCPSTDIOTransport.RunMessageLoop(aOnRequest: TJSONRequestHandler);

var
  lRequest,
  lResponse: TJSONObject;

begin
  lResponse:=Nil;
  lRequest:=Nil;
  try
    while not EOF(FInput^) do
      begin
      lRequest:=ReadRequest;
      if Assigned(lRequest) then
        begin
        try
          aOnRequest(lRequest,lResponse);
        except
          On e : exception do
            begin
            MCPLogger.LogException(E,'Handling request: "%s"',[lRequest.AsJSON]);
            SendDiagnostic('Exception %s (Message: "%s") handling request: %s',[E.ClassName,E.Message,lRequest.AsJSON]);
            end;
        end;
        if Assigned(lResponse) then
          SendMessage(lResponse);
        FreeAndNil(lRequest);
        FreeAndNil(lResponse);
        end;
      end;
  finally
    lResponse.free;
    lRequest.Free;
  end;
end;

{ TTextLSPContext }

constructor TMCPStdioTransport.Create(aInput, aOutput, aError: PText);
begin
  FOutput:=aOutput;
  FError:=aError;
  FInput:=aInput;
end;

procedure TMCPStdioTransport.EmitMessage(aMessage: TJSONStringType);
begin
  Try
    WriteLn(Foutput^,aMessage);
    Flush(Foutput^);
  except
    on e : exception do
      MCPLogger.LogException(E,'EmitMessage');
  end;
end;

procedure TMCPStdioTransport.DoSendMessage(aMessage: TJSONData);

Var
  Content : TJSONStringType;

begin
  Content:=aMessage.AsJSON;
  EmitMessage(Content);
end;

procedure TMCPStdioTransport.DoSendDiagnostic(const aMessage: UTF8String);
begin
  Try
    WriteLn(FError^,aMessage);
    Flush(FError^);
  except
    on e : exception do
      MCPLogger.LogException(E,'diagnostic output');
  end;
end;



end.


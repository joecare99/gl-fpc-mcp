{
    This file is part of the Free Component Library

    MCP client component
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit MCP.Client.Base;

{$mode objfpc}
{$H+}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, contnrs, fpjson, mcp.types;

Type


  TMCPCustomClient = class;
  TMCPCall = class;
  TRequestID = {$IFDEF CPU64}Int64{$ELSE}Integer{$ENDIF};
  TRequestSID = TJSONStringType;

  { Forward declarations for interfaces }

  { TMCPClientRequest }
  TMCPClientErrorEvent = Procedure(Sender : TObject; aRequest : TMCPCall; const aError : TRPCError) of object;

  { Forward declarations }


  { TMCPClientCall }

  { TMCPCall }

  TMCPCall = class(TObject)
  private
    fClient: TMCPCustomClient;
    FCurrentCall : TRequestID;
  protected
    Procedure Reply(aData : TJSONObject); virtual;
    Procedure HandleError(aError : TRPCError); virtual;
  Public
    constructor create(aClient : TMCPCustomClient);
    destructor Destroy; override;
    class function MethodName: string; virtual; abstract ;
    function Call(aArguments : TJSONObject) : TRequestID;
    property Client : TMCPCustomClient Read FClient;
  end;


  { TMCPClientCustomTransport }
  TDiagnosticOutputEvent = procedure (Sender : TObject; Const aOutput : UTF8String) of Object;
  TMCPClientCustomTransport = class(TComponent)
  Private
    FConnected: Boolean;
    FLastMessage : TJSONStringType;
    FOnClientLog,
    FOnDiagnostic: TDiagnosticOutputEvent;
    procedure SetConnected(AValue: Boolean);
  Protected
    procedure DoConnect; virtual; abstract;
    procedure DoDisconnect; virtual; abstract;
    procedure DoCloseSendChannel; virtual;
    Procedure DoSendMessage(J : TJSONStringType) ; virtual; abstract;
    function  DoGetMessage(out J : TJSONStringType) : Boolean; virtual; abstract;
    function  DoCheckDiagnostic(out aMsg : UTF8String) : Boolean; virtual;
  Public
    Destructor Destroy; override;
    Function HaveMessage : Boolean;
    Function GetMessage : TJSONObject; virtual;
    Procedure Connect;
    Procedure DisConnect(SkipDiagnostics : Boolean = False);
    Procedure SendMessage(aMessage : TJSONObject); virtual;
    Procedure CloseSendChannel;
    function CheckDiagnostic : Boolean;
  Published
    Property Connected : Boolean Read FConnected Write SetConnected;
    Property OnDiagnostic : TDiagnosticOutputEvent Read FOnDiagnostic Write FOnDiagnostic;
  end;



  TMCPNotificationEvent = Procedure(Sender : TObject; const aMethod : string; aParams : TJSONObject) of object;

  { TMCPCustomClient }
  TMCPClientEventType = (cetTransport,cetWarning,cetError,cetInfo);
  TMCPClientLogEvent = Procedure (Sender : TObject; aType : TMCPClientEventType; Msg : TJSONStringType) of object;

  TMCPCLientOption = (coKeepRequests,coIgnoredMethodNoError,coRoots,coElicitation,coSampling);
  TMCPCLientOptions = set of TMCPCLientOption;

  TMCPCustomClient = class(TComponent)
  Private
    FClientName: string;
    FClientVersion: string;
    FOnServerNotification: TMCPNotificationEvent;
    FOptions: TMCPClientOptions;
    FProtocolVersion: string;
    FRequests : TComponent;
    FCalls : TFPObjectHashTable;
    FTransport: TMCPClientCustomTransport;
    FNextRequestID : Integer;
    procedure SetOptions(AValue: TMCPClientOptions);
    procedure SetTransport(AValue: TMCPClientCustomTransport);
  Protected
    // General
    function GetRequestID : Integer;
    function FindCall(const aID: TRequestID): TMCPCall; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    // Handle results
    function DispatchIncomingNotification(const aMethod: String; aParams: TJSONObject): Boolean; virtual;
    function HandleServerMessage(J: TJSONObject): Boolean; virtual;
    function DoServerError(const aID: TJSONStringType; aError: TJSONData): Boolean;
    function DoServerResponse(const aID: TJSONStringType; aResult: TJSONData): Boolean; virtual;
    // Handle sending messages
    Procedure RemoveCall(ID : TRequestID);
    procedure DoRequest(aRequest: TMCPCall; aRequestID: TRequestID; aArgs: TJSONObject); virtual;
    Function Request(aRequest : TMCPCall; aArguments : TJSONObject) : TRequestID;
    procedure SendError(aID: TJSONStringType; const aError: TRPCError);virtual;
    procedure SendError(aID: TJSONStringType; aCode: Integer; const aMessage: String);
  Public
    Constructor Create(aOwner : TComponent); override;
    Destructor Destroy; override;
    // Check whether messages arrived and dispatch them
    Function CheckMessages : integer;
    // List available tools
    function ListTools(aOnReply: TListToolsResponseEvent): TMCPCall;virtual; abstract;
    // List available prompts
    function ListPrompts(aOnReply: TPromptListResponseEvent): TMCPCall; virtual; abstract;
    // List available resources
    function ListResources(aOnReply: TResourceListResponseEvent): TMCPCall; virtual; abstract;
    // Get a specific resource by URI
    function GetResource(const aURI: String; aOnReply: TGetResourceResponseEvent): TMCPCall; virtual; abstract;
    // Get completion suggestions
    function CompletePromptArgument(const aPromptName: string;
                                   const aArgumentName: string;
                                   const aPartialValue: string;
                                   aOnReply: TCompletionCompleteEvent;
                                   aContext: TJSONObject = nil): TMCPCall; virtual; abstract;
    function CompleteResourceArgument(const aResourcePattern: string;
                                     const aArgumentName: string;
                                     const aPartialValue: string;
                                     aOnReply: TCompletionCompleteEvent;
                                     aContext: TJSONObject = nil): TMCPCall; virtual; abstract;
    // Set logging level
    function SetLogLevel(const aLevel: string;
                        aOnReply: TSetLogLevelEvent): TMCPCall; virtual; abstract;

    // Convenience methods for setting log levels
    function SetErrorLogLevel(aOnReply: TSetLogLevelEvent): TMCPCall;
    function SetWarnLogLevel(aOnReply: TSetLogLevelEvent): TMCPCall;
    function SetInfoLogLevel(aOnReply: TSetLogLevelEvent): TMCPCall;
    function SetDebugLogLevel(aOnReply: TSetLogLevelEvent): TMCPCall;

    // Call a tool
    function CallTool(const aToolName: string; aArguments: TJSONObject;
                     aOnReply: TToolCallEvent): TMCPCall; virtual; abstract;
    function CallTool(const aToolName: string; const aArguments: array of string;
                     aOnReply: TToolCallEvent): TMCPCall; virtual; abstract;
    // protocol version to report to server
    property Protocolversion : string read FProtocolVersion write FProtocolVersion;
    // Options
    Property Options : TMCPClientOptions Read FOptions Write SetOptions;
    // Transport to use.
    Property Transport : TMCPClientCustomTransport Read FTransport Write SetTransport;
    // Client version to report to server
    property ClientVersion : string read FClientVersion write FClientVersion;
    // Client name to report to server
    property ClientName : string read FClientName Write FClientName;
    // Called before all other installed handlers are called.
    Property OnServerNotification : TMCPNotificationEvent Read FOnServerNotification Write FOnServerNotification;
  end;


Const
  // Custom error codes.
  SErrJSONUnhandled = -32000;

implementation

uses mcp.logging, fpjsonrpc, mcp.client.calls;

resourcestring
  SLogReadHeader = 'Read header %s: %s';
  SErrNotJSONObject = 'Not a JSON object : %s';
  SErrNotConnected = 'Not connected to MCP server';
  SErrNoTransportAvailable = 'Cannot send message without transport';
  SWarnNoRequestFound = 'Got response without request %s';
  SWarnNoRequestFoundForError = 'Server reported error for unknown request %s. Error code: %d, message: %s ';
  SServerErrorReport = 'Server reported error for request %s. Error code: %d, message: %s ';
  SErrorDuringServerErrorReport = 'Error %s during handling of server error (Error code: %d, message: %s) for request %s: %s ';
  SErrDestreamingResponse = 'Exception %s while destreaming request %s result: %s (%s)';
  SErrHandlingResponse = 'Exception %s while handling request %s result: %s (%s)';
  SErrNoClassForMethod = 'No implementation class found for request %s, method: %s';
  SErrSendingError = 'Error %s trying to send error response (code:%d, message: "%s") to server: %s';
  SErrDestreamingRequest = 'Exception %s while destreaming incoming request %s params: %s (%s)';
  SErrHandlingRequest = 'Exception %s while handling incoming request %s: %s (%s)';
  SErrUnhandledMethod = 'Unhandled method %s';
  SWarnUnhandledMethod = 'Unhandled request %s with method %s, params: %s';
  SErrUnknownMethod = 'Unknown method %s';

constructor TMCPCall.create(aClient: TMCPCustomClient);
begin
  FClient:=aClient;
  FCurrentCall:=0;
end;


destructor TMCPCall.Destroy;
begin
  if (FClient<>Nil) and (FCurrentCall<>0) then
    FClient.RemoveCall(FCurrentCall);
  inherited Destroy;
end;

procedure TMCPCall.Reply(aData: TJSONObject);
begin
  if aData<>Nil then ;
  FCurrentCall:=0;
end;

procedure TMCPCall.HandleError(aError: TRPCError);
begin
  FCurrentCall:=0;
end;

function TMCPCall.Call(aArguments: TJSONObject): TRequestID;
begin
  if FCurrentCall<>0 then
    begin
    aArguments.Free;
    Raise EMCPClient.CreateFmt('Call %d still in progress',[FCurrentCall]);
    end;
  FCurrentCall:=FClient.Request(Self,aArguments);
  Result:=FCurrentCall;
end;


{ TMCPClientCustomTransport }

procedure TMCPClientCustomTransport.SetConnected(AValue: Boolean);
begin
  if FConnected=AValue then Exit;
  if aValue then
    Connect
  else
    Disconnect;
end;


procedure TMCPClientCustomTransport.DoCloseSendChannel;
begin
  // Do nothing
end;

function TMCPClientCustomTransport.DoCheckDiagnostic(out aMsg: UTF8String): Boolean;
begin
  Result:=False;
end;

destructor TMCPClientCustomTransport.Destroy;
begin
  Disconnect(True);
  inherited Destroy;
end;

function TMCPClientCustomTransport.HaveMessage: Boolean;
begin
  Result:=FLastMessage<>'';
  if Not Result then
    Result:=DoGetMessage(FLastMessage);
end;

function TMCPClientCustomTransport.GetMessage: TJSONObject;

var
  Msg : TJSONStringType;
  Data : TJSONData;

begin
  Result:=Nil;
  if not HaveMessage then
    exit;
  Msg:=FLastMessage;
  FLastMessage:='';
  Data:=GetJSON(Msg);
  if Data is TJSONObject then
    Result:=data as TJSONObject
  else
    begin
    Data.Free;
    raise EJSON.Create(Format(SErrNotJSONObject, [Msg]));
    end;
end;

procedure TMCPClientCustomTransport.Connect;
begin
  if FConnected then
    exit;
  DoConnect;
  FConnected:=True;
end;

procedure TMCPClientCustomTransport.DisConnect(SkipDiagnostics: Boolean);
begin
  if not FConnected then
    exit;
  FConnected:=False;
  // Consume any leftover diagnostic messages first
  if not SkipDiagnostics then
    While CheckDiagnostic do
      ;
  DoDisConnect;
end;

procedure TMCPClientCustomTransport.SendMessage(aMessage: TJSONObject);

Var
  J : TJSONStringType;
begin
  if not Connected then
    EMCPClient.Create(SErrNotConnected);
  J:=aMessage.AsJSON;
  DoSendMessage(J);
end;

procedure TMCPClientCustomTransport.CloseSendChannel;
begin
  DoCloseSendChannel;
end;

function TMCPClientCustomTransport.CheckDiagnostic: Boolean;

var
  aMsg : UTF8string;

begin
  Result:=DoCheckDiagnostic(aMsg);
  if Result and Assigned(FOnDiagnostic) then
    FOnDiagnostic(Self,aMsg);
end;

{ TMCPCustomClient }

procedure TMCPCustomClient.SetTransport(AValue: TMCPClientCustomTransport);
begin
  if FTransport=AValue then Exit;
  if Assigned(FTransport) then
    FTransport.RemoveFreeNotification(Self);
  FTransport:=AValue;
  if Assigned(FTransport) then
    FTransport.FreeNotification(Self);
end;


procedure TMCPCustomClient.SetOptions(AValue: TMCPClientOptions);
begin
  if FOptions=AValue then Exit;
  FOptions:=AValue;
end;


function TMCPCustomClient.GetRequestID: Integer;
begin
  Result:=InterlockedIncrement(FNextRequestID);
end;

function TMCPCustomClient.FindCall(const aID: TRequestID): TMCPCall;
begin
  Result:=TMCPCall(FCalls.Items[IntToStr(aID)]);
end;

procedure TMCPCustomClient.DoRequest(aRequest: TMCPCall; aRequestID : TRequestID; aArgs : TJSONObject);

var
  Msg : TJSONObject;

begin
  try
    Msg:=TJSONObject.Create([
      'jsonrpc','2.0',
      'id',aRequestID,
      'method',aRequest.MethodName
    ]);
    if assigned(aArgs) then
      msg.add('params',aArgs);
    aArgs:=nil;
    Transport.SendMessage(Msg);
  finally
    aArgs.Free;
    Msg.Free;
  end;
end;

procedure TMCPCustomClient.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation=opRemove) and (aComponent=FTransport) then
    FTransport:=Nil;
end;

constructor TMCPCustomClient.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FCalls:=TFPObjectHashTable.Create(false);
  FClientVersion:='2025';
end;

destructor TMCPCustomClient.Destroy;
begin
  FreeAndNil(FCalls);
  inherited Destroy;
end;


function TMCPCustomClient.Request(aRequest: TMCPCall; aArguments: TJSONObject
  ): TRequestID;
begin
  if not Assigned(Transport) then
    Raise EMCPClient.Create(SErrNoTransportAvailable);
  Transport.Connected:=True;
  Result:=GetRequestID;
  FCalls.Add(IntTostr(Result),aRequest);
  DoRequest(aRequest,Result,aArguments);
end;


function TMCPCustomClient.DoServerError(const aID : TJSONStringType; aError : TJSONData) : Boolean;

var
  Err : TRPCError;
  aRequest : TMCPCall;

begin
  Result:=False;
  Err.FromJSON(aError as TJSONObject);
  aRequest:=FindCall(StrToIntDef(aID,0));
  if (aRequest=Nil) then
    begin
    MCPLogger.Warning(SWarnNoRequestFoundForError,[aID,Err.Code,Err.Message]);
    Exit;
    end;
  try
    MCPLogger.Error(SServerErrorReport,[aID,Err.Code,Err.Message]);
    aRequest.HandleError(Err);
  except
    On E : Exception do
      MCPLogger.Error(SErrorDuringServerErrorReport,[E.ClassName,Err.Code,Err.Message,aID,E.Message]);
  end;
end;

function TMCPCustomClient.DoServerResponse(const aID : TJSONStringType; aResult : TJSONData) : Boolean;

var
  aRequest : TMCPCall;
  Streamed : Boolean;
  Msg : string;

begin
  Result:=False;
  Streamed:=False;
  aRequest:=FindCall(StrToIntDef(aID,0));
  if (aRequest=Nil) then
    begin
    MCPLogger.Warning(SWarnNoRequestFound,[aID]);
    Exit;
    end;
  try
    Msg:=aResult.AsJSON;
    aRequest.Reply(aResult as TJSONObject);
    Result:=True;
  except
    On E : Exception do
      begin
      if not Streamed then
        Msg:=SErrDestreamingResponse
      else
        Msg:=SErrHandlingResponse;
      MCPLOgger.Error(Format(Msg,[E.ClassName,aID,E.Message,aResult.AsJSON]));
      end;
  end;
end;


procedure TMCPCustomClient.RemoveCall(ID: TRequestID);
begin
  FCalls.Delete(IntToStr(ID));
end;

function TMCPCustomClient.DispatchIncomingNotification(const aMethod : String; aParams: TJSONObject): Boolean;

var
  i : integer;

begin
  Result:=False;
  if Assigned(FOnServerNotification) then
    FOnServerNotification(Self,aMethod, aParams);
end;

procedure TMCPCustomClient.SendError(aID : TJSONStringType; const aError : TRPCError);

Var
  Err,Msg : TJSONObject;

begin
  try
    Err:=TJSONObject.Create;
    try
      aError.ToJSON(Err);
      Msg:=TJSONObject.Create([
        'jsonrpc','2.0',
        'id',aID,
        'error',Err]);
      Transport.SendMessage(Msg);
      Err:=Nil;
    Finally
      Err.Free;
      Msg.Free;
    end;
  except
    on E : Exception do
      MCPLogger.Error(SErrSendingError,[E.ClassName,aError.Code,aError.Message,E.Message]);
  end;
end;

procedure TMCPCustomClient.SendError(aID: TJSONStringType; aCode: Integer;
  const aMessage: String);

var
  Err : TRPCError;

begin
  Err.Code:=aCode;
  Err.Message:=aMessage;
  Err.Data:='';
  SendError(aID,Err);
end;

function TMCPCustomClient.HandleServerMessage(J : TJSONObject) : Boolean;

var
  aMethod : String;
  aParams,aError,Data : TJSONData;
  aID : String;


begin
  Result:=False;
  if J.Get('jsonrpc','')<>'2.0' then exit;
  aMethod:=J.Get('method','');
  Data:=J.Find('id');
  if Assigned(Data) then
    aID:=Data.AsString
  else
    aID:='';
  // Check notification,response
  Data:=Nil;
  aError:=nil;
  if (aMethod<>'') then
    begin
    if aID<>'' then
      MCPLogger.Warning('Received notification with ID: %s',[aID]);
    // notification
    aParams:=J.Find('params');
    if not (aParams is TJSONObject) then
      MCPLogger.Warning('Received notification with wrong data: %s',[aID,aParams.AsJSON])
    else
      Result:=DispatchIncomingNotification(aMethod,TJSONObject(aParams));
    end
  else
    begin
    /// Result of our call
    aError:=J.Find('error');
    Data:=J.Find('result');
    if aError<>Nil then
      Result:=DoServerError(aID,aError)
    else
      Result:=DoServerResponse(aID,Data);
    end;
end;

function TMCPCustomClient.CheckMessages: integer;
var
  J : TJSONObject;
  S : String;
begin
  Result:=0;
  While Transport.HaveMessage do
    begin
    J:=Transport.GetMessage;
    try
      Inc(Result);
      S:=J.AsJSON;
      HandleServerMessage(J);
      S:=J.AsJSON;
    finally
      J.Free;
    end;
    end;
end;


function TMCPCustomClient.SetErrorLogLevel(aOnReply: TSetLogLevelEvent): TMCPCall;
begin
  Result := SetLogLevel('error', aOnReply);
end;

function TMCPCustomClient.SetWarnLogLevel(aOnReply: TSetLogLevelEvent): TMCPCall;
begin
  Result := SetLogLevel('warn', aOnReply);
end;

function TMCPCustomClient.SetInfoLogLevel(aOnReply: TSetLogLevelEvent): TMCPCall;
begin
  Result := SetLogLevel('info', aOnReply);
end;

function TMCPCustomClient.SetDebugLogLevel(aOnReply: TSetLogLevelEvent): TMCPCall;
begin
  Result := SetLogLevel('debug', aOnReply);
end;


end.


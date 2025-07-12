unit mcp.dispatcher;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, fpjsonrpc, mcp.Handler, mcp.types, mcp.controller, mcp.transport.base;

Type
  {
    A dispatcher is responsible for handling a request and returning the result.
    It is 'Transport-Aware'
  }
  TMCPBaseDispatcher = class(TObject)
  protected
    Function GetTransport : TMCPMessageTransport; virtual; abstract;
  Public
    Function ExecuteRequest(aRequest : TJSONData): TJSONData; virtual; abstract;
    Property Transport : TMCPMessageTransport Read GetTransport;
  end;


  { TJSONRPCDispatcher }
  { Wrapper class for TCustomJSONRPCDispatcher, does 2 things:
    - handles a bug in fpc's 3.2.2. JSON-rpc
    - Adds transport
  }

  TJSONRPCDispatcher = class(TCustomJSONRPCDispatcher)
  private
    FTransport: TMCPMessageTransport;
  protected
    function ExecuteHandler(H: TCustomJSONRPCHandler; Params, ID: TJSONData; AContext: TJSONRPCCallContext): TJSONData; override;
    function ExecuteMethod(const AClassName, AMethodName: TJSONStringType;  Params, ID: TJSONData; AContext: TJSONRPCCallContext): TJSONData; override;
  public
    constructor Create(AOwner: TComponent); override;
    Property Transport : TMCPMessageTransport Read FTransport Write FTransport;
  end;

  {
   TMCPLocalDispatcher
   // Dispatches the request locally through a TJSONRPCDispatcher instance.
  }

  TClientMethodResultEvent = procedure (Sender : TObject; aResponse : TObject; const aID : String; aResult : TJSONData) of object;
  TClientMethodErrorEvent = procedure (Sender : TObject; aResponse : TObject; const aID : String; aError : TJSONData) of object;

  TMCPLocalDispatcher = class(TMCPBaseDispatcher)
  Private
    FJSONDispatcher : TJSONRPCDispatcher;
    FOnMethodError : TClientMethodErrorEvent;
    FOnMethodResult : TClientMethodResultEvent;
    FController : TMCPController;
    FTransport : TMCPMessageTransport;
  Protected
    procedure ProcessClientMethodResult(aResponse: TJSONObject; const aID : String; aResult: TJSONData); virtual;
    procedure ProcessClientMethodError(aResponse: TJSONObject; const aID : String; aResult: TJSONData); virtual;
    function GetTransport: TMCPMessageTransport; override;
  Public
    Constructor Create(aController : TMCPController);
    Destructor Destroy; override;
    function ExecuteRequest(aRequest : TJSONData): TJSONData; override;
    // Called when client (acting as server) returned a result.
    Property OnMethodResult : TClientMethodResultEvent Read FOnMethodResult Write FOnMethodResult;
    // Called when client (acting as server) returned a result.
    Property OnMethodError : TClientMethodErrorEvent Read FOnMethodError Write FOnMethodError;
  end;


implementation

{ ---------------------------------------------------------------------
  TJSONRPCDispatcher
  ---------------------------------------------------------------------}

constructor TJSONRPCDispatcher.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Options := [jdoSearchRegistry, jdoJSONRPC2, jdoNotifications, jdoStrictNotifications];
end;


function TJSONRPCDispatcher.ExecuteHandler(H: TCustomJSONRPCHandler; Params,
  ID: TJSONData; AContext: TJSONRPCCallContext): TJSONData;
begin
  if H is TMCPBaseHandler then
    TMCPBaseHandler(H).Transport:=Self.FTransport;
  Result:=Inherited ExecuteHandler(H,Params,ID,AContext);
end;

function TJSONRPCDispatcher.ExecuteMethod(const AClassName, AMethodName: TJSONStringType;
    Params, ID: TJSONData; AContext: TJSONRPCCallContext): TJSONData;

{$IFDEF VER3_2}
Var
  lID : TJSONData;
{$ENDIF}

begin
  try
{$IFDEF VER3_2}
    lID:=ID;
    if lID=Nil then
      lID:=TJSONIntegerNumber.Create(0);
    try
      Result := inherited ExecuteMethod(AClassName, AMethodName, Params, lID, AContext);
    finally
      if lID<>ID then
        lID.Free;
    end;
{$ELSE}
   Result := inherited ExecuteMethod(AClassName, AMethodName, Params, ID, AContext);
{$ENDIF}
  except
    on E: EMCPException do // handle errors specific to MCP
      Exit(CreateJSON2Error(E.Message, E.Code, ID.Clone, TransactionProperty))
    else raise;
  end;
end;

{ ---------------------------------------------------------------------
  TMCPLocalDispatcher
  ---------------------------------------------------------------------}

function TMCPLocalDispatcher.GetTransport: TMCPMessageTransport;
begin
  Result:=FTransport;
end;

constructor TMCPLocalDispatcher.Create(aController: TMCPController);
begin
  FController:=aController;
  FJSONDispatcher:=TJSONRPCDispatcher.Create(Nil);
  FJSONDispatcher.Transport:=Self.Transport;
end;

destructor TMCPLocalDispatcher.Destroy;
begin
  FreeAndNil(FJSONDispatcher);
  inherited Destroy;
end;

procedure TMCPLocalDispatcher.ProcessClientMethodResult(aResponse: TJSONObject;const aID : String;  aResult: TJSONData);
begin
  if Assigned(OnMethodResult) then
    OnMethodResult(Self,aResponse,aID,aResult);
end;

procedure TMCPLocalDispatcher.ProcessClientMethodError(aResponse: TJSONObject;
  const aID: String; aResult: TJSONData);

begin
  if Assigned(OnMethodError) then
    OnMethodError(Self,aResponse,aID,aResult);
end;

function TMCPLocalDispatcher.ExecuteRequest(aRequest: TJSONData): TJSONData;
var
  Obj: TJSONObject absolute aRequest;
  Idx: Integer;
  rID: String;
  Ctx : TMCPContext;

begin
  Result:=nil;
  if Not (aRequest is TJSONObject) then
    Exit;
  if (Obj.Get('method','')='') then
    begin
    // We have a reply from the client to a method we executed.
    rID:='';
    Idx:=Obj.IndexOfName('id');
    if Idx<>-1 then
      rID:=Obj.Items[Idx].AsString;
    Idx:=Obj.IndexOfName('result');
    if (Idx<>-1) then
      ProcessClientMethodResult(Obj,rID,Obj.Items[Idx])
    else
      begin
      Idx:=Obj.IndexOfName('error');
      ProcessClientMethodError(Obj,rID,Obj.Items[Idx]);
      end;
    end
  else
    begin
    // We have a method call from the client to which we must reply
    Ctx:=TMCPContext.Create(TMCPController.Instance);
    try
      Result:=FJSONDispatcher.Execute(aRequest,Ctx);
    finally
      Ctx.Free;
    end;
    end;
end;

end.


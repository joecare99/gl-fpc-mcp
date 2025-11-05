unit mcp.application.http;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpapp, mcp.transport.http;

type

  { TMCPServerApplication }

  { TMCPHTTPServerApplication }

  TMCPHTTPServerApplication = class(THTTPApplication)
  private
    FAllowSSE: Boolean;
    FEndpointPath: String;
    procedure SetALlowSSE(AValue: Boolean);
    procedure SetEndPointPath(AValue: String);
  Public
    constructor Create(AOwner: TComponent); override;
    procedure Initialize; override;
    // This must be set before calling Initialize. Defaults to /MCP
    Property EndpointPath : String Read FEndpointPath Write SetEndPointPath;
    // This can be set any time. Will initiate a SSE stream when client has the capability.
    Property AllowSSE : Boolean Read FAllowSSE Write SetALlowSSE;
    // If set, then a session ID is required.

  end;

implementation

uses mcp.stdhandlers;

{ TMCPServerApplication }

procedure TMCPHTTPServerApplication.SetEndPointPath(AValue: String);
begin
  if FEndpointPath=AValue then Exit;
  if Assigned(TMCPRoute.Instance) then
    Raise EMCPHTTP.Create('MCP Server already initialized');
  FEndpointPath:=AValue;
end;

constructor TMCPHTTPServerApplication.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  {$IFNDEF VER3_2}
  ALlowSSE:=True;
  Address:='127.0.0.1';
  {$ENDIF}
end;

procedure TMCPHTTPServerApplication.SetALlowSSE(AValue: Boolean);
begin
  if FAllowSSE=AValue then Exit;
  FAllowSSE:=AValue;
  if Assigned(TMCPRoute.Instance) then
    TMCPRoute.Instance.AllowSSE:=True;
end;

procedure TMCPHTTPServerApplication.Initialize;
var
  lPath : String;
begin
  inherited Initialize;
  RegisterStandardHandlers;
  lPath:=EndpointPath;
  if lPath='' then
    lPath:='/MCP';
  TMCPRoute.Init(lPath);
  TMCPRoute.Instance.AllowSSE:=FallowSSE;
end;

end.


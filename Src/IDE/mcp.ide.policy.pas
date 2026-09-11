unit mcp.ide.policy;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TMCPToolPolicy = (mtpDisabled, mtpAllowed, mtpAsk);

const
  MCPToolNames: array[0..10] of string = (
    'openproject', 'newproject', 'newnunit', 'addnunit', 'compile',
    'getWorkspaceInfo', 'listProjectFiles', 'listOpenEditors',
    'getActiveEditor', 'readEditorText', 'getBuildMessages'
  );

function MCPToolPolicyName(APolicy: TMCPToolPolicy): string;
function MCPToolDescription(const AToolName: string): string;
function MCPToolPolicyFromName(const AName: string;
  ADefault: TMCPToolPolicy): TMCPToolPolicy;
function MCPDefaultToolPolicy(const AToolName: string): TMCPToolPolicy;
function MCPToolArgumentSummary(AInput: TObject): string;

type
  TMCPToolPolicies = class
  private
    FValues: TStringList;
    function GetPolicy(const AToolName: string): TMCPToolPolicy;
    procedure SetPolicy(const AToolName: string; AValue: TMCPToolPolicy);
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadDefaults;
    property Policies[const AToolName: string]: TMCPToolPolicy
      read GetPolicy write SetPolicy; default;
  end;

var
  MCPToolPolicies: TMCPToolPolicies;

implementation

uses
  fpjson;

function MCPToolPolicyName(APolicy: TMCPToolPolicy): string;
begin
  case APolicy of
    mtpDisabled: Result:='Disabled';
    mtpAllowed: Result:='Allowed';
    mtpAsk: Result:='Ask';
  else
    Result:='Ask';
  end;
end;

function MCPToolDescription(const AToolName: string): string;
begin
  if SameText(AToolName,'openproject') then
    Result:='Open an existing Lazarus project.'
  else if SameText(AToolName,'newproject') then
    Result:='Create a new Lazarus project.'
  else if SameText(AToolName,'newnunit') then
    Result:='Create and add a new unit to the active project.'
  else if SameText(AToolName,'addnunit') then
    Result:='Open and add an existing unit to the active project.'
  else if SameText(AToolName,'compile') then
    Result:='Compile or build the active Lazarus project.'
  else if SameText(AToolName,'getWorkspaceInfo') then
    Result:='Inspect the active project and its main file.'
  else if SameText(AToolName,'listProjectFiles') then
    Result:='List files belonging to the active project.'
  else if SameText(AToolName,'listOpenEditors') then
    Result:='List open source editors and their state.'
  else if SameText(AToolName,'getActiveEditor') then
    Result:='Inspect the active editor, cursor, and selection.'
  else if SameText(AToolName,'readEditorText') then
    Result:='Read a bounded range from an open project editor.'
  else if SameText(AToolName,'getBuildMessages') then
    Result:='Read messages from the Lazarus build window.'
  else
    Result:='';
end;

function MCPToolPolicyFromName(const AName: string;
  ADefault: TMCPToolPolicy): TMCPToolPolicy;
begin
  if SameText(AName,'Disabled') then
    Result:=mtpDisabled
  else if SameText(AName,'Allowed') then
    Result:=mtpAllowed
  else if SameText(AName,'Ask') then
    Result:=mtpAsk
  else
    Result:=ADefault;
end;

function MCPDefaultToolPolicy(const AToolName: string): TMCPToolPolicy;
begin
  if SameText(AToolName,'getWorkspaceInfo') or
     SameText(AToolName,'listProjectFiles') or
     SameText(AToolName,'listOpenEditors') or
     SameText(AToolName,'getActiveEditor') or
     SameText(AToolName,'readEditorText') or
     SameText(AToolName,'getBuildMessages') then
    Result:=mtpAllowed
  else
    Result:=mtpAsk;
end;

function MCPToolArgumentSummary(AInput: TObject): string;
var
  O: TJSONObject;
  S: string;
begin
  if not (AInput is TJSONObject) then Exit('{}');
  O:=TJSONObject(AInput);
  S:=O.AsJSON;
  if Length(S)>400 then
    S:=Copy(S,1,397)+'...';
  Result:=S;
end;

constructor TMCPToolPolicies.Create;
begin
  inherited Create;
  FValues:=TStringList.Create;
  LoadDefaults;
end;

destructor TMCPToolPolicies.Destroy;
begin
  FValues.Free;
  inherited Destroy;
end;

procedure TMCPToolPolicies.LoadDefaults;
var
  I: Integer;
begin
  FValues.Clear;
  for I:=Low(MCPToolNames) to High(MCPToolNames) do
    FValues.Values[MCPToolNames[I]]:=MCPToolPolicyName(
      MCPDefaultToolPolicy(MCPToolNames[I]));
end;

function TMCPToolPolicies.GetPolicy(const AToolName: string): TMCPToolPolicy;
begin
  Result:=MCPToolPolicyFromName(FValues.Values[AToolName],
    MCPDefaultToolPolicy(AToolName));
end;

procedure TMCPToolPolicies.SetPolicy(const AToolName: string;
  AValue: TMCPToolPolicy);
begin
  FValues.Values[AToolName]:=MCPToolPolicyName(AValue);
end;

initialization
  MCPToolPolicies:=TMCPToolPolicies.Create;

finalization
  FreeAndNil(MCPToolPolicies);

end.

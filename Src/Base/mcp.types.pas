{
    This file is part of the Free Component Library

    MCP basic types
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.types;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}

interface

uses
  SysUtils,Types,  Contnrs, fpjson;

Type
  TMCPLogType = (mltError,mltWarning,mltInfo,mltTrace,mltDebug);
  TMCPLogTypes = set of TMCPLogType;

  TMCPLogEvent = procedure(Sender : TObject; aType : TMCPLogType; Const aMessage: string) of object;

  TMCPResourceKind = (rkUnknown,rkText,rkData);
  EMCPException = class(Exception)
    code: integer;
  end;

  TMCPPromptKind = (pkText,pkImage,pkAudio,pkResourceLink,pkEmbeddedResource);

  { TMCPPromptKindHelper }

  TMCPPromptKindHelper = type helper for TMCPPromptKind
  private
    procedure SetAsString(AValue: String);
  public
    function toString : String;
    property AsString : String Read ToString Write SetAsString;
  end;

  TMCPRole = (prUser,prAssistant);
  TMCPRoles = set of TMCPRole;

  { TMCPRoleHelper }

  TMCPRoleHelper = type helper for TMCPRole
  private
    function ToString: String;
    procedure SetAsString(AValue: String);
  public
    property AsString : String Read ToString Write SetAsString;
  end;

  { TMCPAnnotation }

  TMCPAnnotation = record
  private
    _Roles : TMCPRoles;
    _priority : Boolean;
    _Lastmodified : TDateTime;
    _Initialized : boolean;
    procedure SetLastModified(AValue: TDateTime);
    procedure SetPriority(AValue: Boolean);
    procedure SetRoles(AValue: TMCPRoles);
  public
    class operator initialize (var rec : TMCPAnnotation);
    property Roles : TMCPRoles read _Roles write SetRoles;
    property priority : Boolean read _priority write SetPriority;
    property Lastmodified : TDateTime read _Lastmodified write SetLastModified;
    property Initialized : boolean read _Initialized;
    procedure ToJSON(aObject : TJSONObject);
    function ToJSON : TJSONObject;
    procedure FromJSON(aJSON: TJSONObject);
  end;

  { TMCPTool }

  { TMCPSchema }

  TMCPSchema = Class
  Private
    FArguments : TFPObjectHashTable;
    FRequired: TStringDynArray;
    FRequred: TStringDynArray;
    function GetArgument(aName : string): TJSONObject;
  protected
    Procedure ToJSON(aJSON : TJSONObject);
    procedure AddRequired(const aName : string);
  Public
    Constructor Create;
    Destructor Destroy; override;
    Procedure AddArgument(aName : string; aSchema : TJSONObject; aRequired : Boolean = true); virtual;
    Function ToJSON : TJSONObject;
    Property Arguments [aName : string]  : TJSONObject Read GetArgument;
    Property Required : TStringDynArray Read FRequired;
  end;


implementation

uses typinfo,dateutils;

{ TMCPPromptKindHelper }

procedure TMCPPromptKindHelper.SetAsString(AValue: String);
var
  K : TMCPPromptKind;
begin
  if ToString=AValue then Exit;
  for K in TMCPPromptKind do
    if K.AsString=aValue then
      begin
      Self:=k ;
      exit;
      end;
end;

function TMCPPromptKindHelper.toString: String;
const
  names : Array[TMCPPromptKind] of string = ('text','image','audio','resource_link','resource');

begin
  Result:=Names[self];
end;

{ TMCPRoleHelper }

function TMCPRoleHelper.ToString: String;
begin
  Case Self of
    prUser : Result:='user';
    prAssistant : Result:='assistant';

  end;
end;

procedure TMCPRoleHelper.SetAsString(AValue: String);
begin
  case aValue of
  'user' : Self:=prUser;
  'assistant' : self:=prAssistant;
  else
    Raise EMCPException.CreateFmt('Invalid role: %s',[aValue]);
  end;
end;

{ TMCPAnnotation }

procedure TMCPAnnotation.SetPriority(AValue: Boolean);
begin
  if _priority=AValue then Exit;
  _priority:=AValue;
  _Initialized:=True;
end;

procedure TMCPAnnotation.SetLastModified(AValue: TDateTime);
begin
  if _Lastmodified=AValue then Exit;
  _Lastmodified:=AValue;
  _initialized:=True;
end;

procedure TMCPAnnotation.SetRoles(AValue: TMCPRoles);
begin
  if _Roles=AValue then Exit;
  _Roles:=AValue;
  _Initialized:=True;
end;

class operator TMCPAnnotation.initialize(var rec: TMCPAnnotation);
begin
  Rec:=Default(TMCPAnnotation);
end;

procedure TMCPAnnotation.ToJSON(aObject: TJSONObject);
var
  arr : TJSONArray;
  lRole : TMCPRole;

begin
  if _Roles<>[] then
    begin
    arr:=TJSONArray.Create;
    aObject.Add('roles',arr);
    for lRole in _Roles do
      Arr.Add(lRole.ToString);
    end;
  aObject.Add('priority',Ord(_priority));
  if _Lastmodified<>0 then
    aObject.Add('lastModified',DateToISO8601(_Lastmodified));
end;

function TMCPAnnotation.ToJSON: TJSONObject;
begin
  Result:=Nil;
  if Initialized then
    try
      Result:=TJSONObject.Create;
      ToJSON(Result);
    except
      Result.Free;
      Raise;
    end;
end;

procedure TMCPAnnotation.FromJSON(aJSON: TJSONObject);
var
  lArr : TJSONArray;
  lRole : TMCPRole;
  lDate : string;
  I : Integer;
begin
  _Initialized:=True;
  if not assigned(aJSON) then
    exit;
  lArr:=aJSON.Get('roles',TJSONArray(Nil));
  if assigned(lArr) then
    begin
    for I:=0 to lArr.Count-1 do
      begin
      lRole.AsString:=lArr.Items[i].AsString;
      Include(_roles,lRole);
      end;
    end;
  priority:=aJSON.get('priority',1)=1;
  lDate:=aJSON.get('lastModified');
  if lDate<>'' then
    _Lastmodified:=ISO8601ToDate(lDate);
end;

{ TMCPSchema }

function TMCPSchema.GetArgument(aName : string): TJSONObject;
begin
  Result:=FArguments[aName] as TJSONObject;
end;

type
  { TResourceLister }

  { TArgumentLister }

  TArgumentLister = class(TObject)
    FJSON : TJSONObject;
    constructor Create(aJSON : TJSONObject) ;
    procedure ListArg(Item: TObject; const Key: string; var Continue: Boolean);
  end;

{ TArgumentLister }

constructor TArgumentLister.Create(aJSON: TJSONObject);
begin
  FJSON:=aJSON;
end;

procedure TArgumentLister.ListArg(Item: TObject; const Key: string;
  var Continue: Boolean);
begin
  Continue:=True;
  FJSON.Add(Key,TJSONData(Item).Clone);
end;


procedure TMCPSchema.ToJSON(aJSON: TJSONObject);
var
  lList : TArgumentLister;
  lProps : TJSONObject;
  lReq: TJSONArray;
  S : String;
begin
  aJSON.Add('type','object');
  lProps:=TJSONObject.Create;
  lList:=TArgumentLister.Create(lProps);
  try
    FArguments.Iterate(@lList.ListArg);
  finally
    lList.Free;
  end;
  if lProps.Count=0 then
    lProps.Free
  else
    begin
    aJSON.Add('properties',lProps);
    if Length(FRequired)>0 then
      begin
      lReq:=TJSONArray.Create;
      aJSON.Add('required',lReq);
      For S in FRequired do
        lReq.Add(s);
      end;
    end;
end;

constructor TMCPSchema.Create;
begin
  FArguments:=TFPObjectHashTable.Create(True);
end;

destructor TMCPSchema.Destroy;
begin
  FreeAndNil(FArguments);
  inherited Destroy;
end;

procedure TMCPSchema.AddArgument(aName: string; aSchema: TJSONObject;
  aRequired: Boolean);
begin
  FArguments.Add(aName,aSchema);
  if aRequired then
    AddRequired(aName);
end;

procedure TMCPSchema.AddRequired(const aName: string);
var
  S : String;
  Len: Integer;
begin
  For S in FRequired do
    if aName=S then
      exit;
   len:=Length(FRequired);
   SetLength(FRequired,Len+1);
   FRequired[len]:=aName;
end;

function TMCPSchema.ToJSON: TJSONObject;
begin
  Result:=TJSONObject.Create();
  try
    ToJSON(Result);
  except
    Result.Free;
    Raise;
  end;
end;

end.


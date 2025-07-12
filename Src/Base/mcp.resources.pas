{
    This file is part of the Free Component Library

    MCP Resource definitions
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.resources;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, Contnrs, fpjson, mcp.types, mcp.utils;

Type
  TMCPResource = class;
  TMCPResourceRegistry = class;
  TMCPResourceRegistryClass = Class of TMCPResourceRegistry;
  TMCPResourceArray = array of TMCPResource;

  TMCPResourceGetDataCallBack = Procedure (aResource : TMCPResource) of object;

  { TMCPResource }

  TMCPResource = Class(TObject)
  private
    FData: TBytes;
    FKind: TMCPResourceKind;
    FMimeType: string;
    FName: string;
    FOnData: TMCPResourceGetDataCallBack;
    FText: String;
    FTitle: string;
    FUri: String;
    FSIze : Integer;
    function GetSize: Integer;
    procedure SetData(AValue: TBytes);
    procedure SetSize(AValue: Integer);
    procedure SetText(AValue: String);
    procedure SetUri(AValue: String);
  protected
    function GetData: TBytes; virtual;
    function GetText: String; virtual;
    function GetKind : TMCPResourceKind; virtual;
  Public
    constructor Create(const aURI,aName : String);
    constructor Create(const aURI,aName : String; aText : String);
    constructor Create(const aURI,aName : String; aData : TBytes);
    constructor Create(const aURI,aName : String; aKind : TMCPResourceKind; aCallBack : TMCPResourceGetDataCallBack);
    procedure Register(aRegistry : TMCPResourceRegistry = Nil);
    procedure ToJSON(aJSON : TJSONObject; withData : Boolean); virtual;
    function ToJSON(withData : Boolean) : TJSONObject;
    Property Uri : String read FUri Write SetUri;
    property Title : string Read FTitle Write FTitle;
    Property Description : string read FTitle Write FTitle;
    Property MimeType: string read FMimeType Write FMimeType;
    Property Name : string Read FName Write FName;
    Property Text : String Read GetText Write SetText;
    Property Data : TBytes Read GetData Write SetData;
    Property Size : Integer Read GetSize Write SetSize;
    Property Kind: TMCPResourceKind Read FKind;
    // Allow to dynamically update  the data.
    Property OnData : TMCPResourceGetDataCallBack Read FOnData Write FOnData;
  end;

  { TMCPResourceRegistry }

  TMCPResourceRegistry = Class(TObject)
  private
    class var _instance : TMCPResourceRegistry;
    class function GetInstance: TMCPResourceRegistry; static;
  private
    FList :  TThreadSafeObjectHash;
    FOnChange: TNotifyEvent;
  protected
    function GetCount: Integer; virtual;
    procedure DoChange; virtual;
  Public
    constructor Create; virtual;
    destructor destroy; override;
    // Add a resource. Once added, the registry owns the resource
    Procedure Add(aResource : TMCPResource); virtual;
    // Remove a resource. The object will be freed.
    procedure Remove(const aURI : String); virtual;
    procedure Remove(aResource : TMCPResource);
    procedure LockList(aList : TFPList);
    procedure LockList(var aList : TMCPResourceArray);
    procedure UnlockList;
    function Find(const aURI : String) : TMCPResource; virtual;
    function Get(const aURI : String) : TMCPResource; virtual;
    property Resources[aName : string] : TMCPResource Read Get; default;
    Property Count : Integer Read GetCount;
    property OnChange : TNotifyEvent Read FOnChange Write FOnChange;
    class procedure Init(aClass: TMCPResourceRegistryClass);
    class procedure Done;
    class property Instance : TMCPResourceRegistry read GetInstance;
  end;

Function ResourceRegistry : TMCPResourceRegistry;

implementation

uses mcp.strings;

function ResourceRegistry: TMCPResourceRegistry;
begin
  Result:=TMCPResourceRegistry.Instance;
end;

{ TMCPResource }

procedure TMCPResource.SetData(AValue: TBytes);
begin
  if FData=AValue then Exit;
  FData:=AValue;
  FText:='';
  FKind:=rkData;
end;

function TMCPResource.GetSize: Integer;
begin
  Result:=0;
  if FSize<>0 then
    Result:=FSize
  else if Kind=rkData then
    Result:=Length(FData)
  else if kind=rkText then
    Result:=Length(FText);
end;

procedure TMCPResource.SetSize(AValue: Integer);
begin
  FSIze:=aValue;
end;

function TMCPResource.GetData: TBytes;
begin
  Result:=FData;
end;

function TMCPResource.GetText: String;
begin
  Result:=FText;
end;

function TMCPResource.GetKind: TMCPResourceKind;
begin
  Result:=FKind;
end;

constructor TMCPResource.Create(const aURI, aName: String);
begin
  Uri:=aURI;
  Name:=aName;
end;


constructor TMCPResource.Create(const aURI,aName: String; aText: String);
begin
  Create(aURI,aName);
  Text:=aText;
end;

constructor TMCPResource.Create(const aURI,aName: String; aData: TBytes);
begin
   Create(aURI,aName);
   Data:=aData;
end;

constructor TMCPResource.Create(const aURI,aName: String; aKind: TMCPResourceKind;
  aCallBack: TMCPResourceGetDataCallBack);
begin
  Create(aURI,aName);
  FKind:=aKind;
  FOnData:=aCallBack;
end;

procedure TMCPResource.Register(aRegistry : TMCPResourceRegistry = Nil);
begin
  if aRegistry=nil then
    aRegistry:=TMCPResourceRegistry.Instance;
  aRegistry.Add(Self);
end;

function TMCPResource.ToJSON(withData : boolean): TJSONObject;
begin
  Result:=TJSONObject.Create;
  try
    ToJSON(Result,WithData);
  Except
    Result.Free;
    Raise;
  end;
end;

procedure TMCPResource.SetText(AValue: String);
begin
  if FText=AValue then Exit;
  FText:=AValue;
  FData:=Nil;
  FKind:=rkText;
end;

procedure TMCPResource.SetUri(AValue: String);
begin
  if FUri=AValue then Exit;
  if aValue='' then
    Raise EMCPException.Create(SErrUriCannotBeEmpty);
  FUri:=AValue;
end;

procedure TMCPResource.ToJSON(aJSON: TJSONObject; WithData : Boolean);

  Procedure MaybeAdd(const aName,aValue : string);
  begin
    if aValue<>'' then
      aJSON.Add(aName,aValue);
  end;
var
  lData : string;

begin
  aJSON.Add('uri',FUri);
  aJSON.Add('name',Name);
  aJSON.Add('title',Title);
  aJSON.Add('description',Description);
  aJSON.Add('mimetype',MimeType);
  if not WithData then
    exit;

  case Kind of
  rkText:
    lData:=Text;
  rkData:
    lData:=EncodeBytes(Self.Data);
  end;

  aJSON.Add('text',lData);
end;

  { TMCPResourceRegistry }

class function TMCPResourceRegistry.GetInstance: TMCPResourceRegistry; static;
begin
  if _instance=nil then
    _Instance:=TMCPResourceRegistry.Create;
  Result:=_Instance
end;

function TMCPResourceRegistry.GetCount: Integer;
begin
  Result:=FList.Count;
end;

procedure TMCPResourceRegistry.DoChange;
begin
  if assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TMCPResourceRegistry.Create;
begin
  FList:=TThreadSafeObjectHash.Create(True);
end;

destructor TMCPResourceRegistry.destroy;
begin
  FList.Destroy;
  inherited destroy;
end;

procedure TMCPResourceRegistry.Add(aResource: TMCPResource);
begin
  FList.Add(aResource.Uri,aResource);
  DoChange;
end;

procedure TMCPResourceRegistry.Remove(const aURI: String);
begin
  if FList.Get(aURI)=nil then
    exit;
  FList.Remove(aURI);
  DoChange;
end;

procedure TMCPResourceRegistry.Remove(aResource: TMCPResource);
begin
  Remove(aResource.URI);
end;

procedure TMCPResourceRegistry.LockList(aList: TFPList);
begin
  FList.GetObjectList(aList);
  // do not unlock.
end;

procedure TMCPResourceRegistry.LockList(var aList: TMCPResourceArray);
var
  llist : TFPList;
  I : Integer;
begin
  lList:=TFPList.Create;
  try
    FList.GetObjectList(lList);
    SetLength(aList,lList.Count);
    For I:=0 to lList.Count-1 do
      aList[i]:=TMCPResource(lList[i]);
  finally
    lList.free;
  end;
  // do not unlock.
end;

procedure TMCPResourceRegistry.UnlockList;
begin
  FList.Unlock;
end;

function TMCPResourceRegistry.Find(const aURI: String): TMCPResource;
begin
  Result:=TMCPResource(FList.Get(aURI));
end;

function TMCPResourceRegistry.Get(const aURI: String): TMCPResource;
begin
  Result:=Find(aURI);
  if Result=Nil then
    Raise EMCPException.CreateFmt(SErrUnknownResource,[aURI]);
end;

class procedure TMCPResourceRegistry.Init(aClass: TMCPResourceRegistryClass);
begin
  if assigned(_instance) then
    Raise EMCPException.Create(SErrRegistryAlreadyInstantiated);
  if aClass=Nil then
    Raise EMCPException.Create(SErrRegistryClassEmpty);
  _Instance:=aClass.Create;
end;

class procedure TMCPResourceRegistry.Done;
begin
  FreeAndNil(_instance);
end;

finalization
  TMCPResourceRegistry.Done;
end.


{
    This file is part of the Free Component Library

    MCP tool definitions
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.tools;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpJSON, contnrs, syncobjs, mcp.utils, mcp.types;

type
  TMCPToolRegistry = class;
  TMCPToolRegistryClass = class of TMCPToolRegistry;
  TToolInvocationEvent = Procedure (aInput : TJSONData; aOutput : TJSONObject) of object;


  { TMCPTool }

  TMCPTool = class abstract (TObject)
  private
    FAnnotations: TMCPAnnotation;
    FDescription: String;
    FInputSchema: TMCPSchema;
    FMeta: TJSONObject;
    FName: String;
    FOutputSchema: TMCPSchema;
    procedure SetMeta(AValue: TJSONObject);
  protected
    Procedure DoExecute(aInput : TJSONObject; aResult : TJSONObject); virtual; abstract;
  public
    constructor create(const aName : string; const aDescription : string); virtual;
    destructor destroy; override;
    procedure Register(aRegistry : TMCPToolRegistry = Nil);
    procedure Execute(aInput : TJSONObject; aResult : TJSONObject);
    Property Name : String read FName;
    property Description : String Read FDescription;
    Property InputSchema : TMCPSchema Read FInputSchema;
    Property OutputSchema: TMCPSchema Read FOutputSchema;
    Property Annotations : TMCPAnnotation Read FAnnotations Write FAnnotations;
    procedure ToJSON(aJSON : TJSONObject); virtual;
    function ToJSON() : TJSONObject;
    // Owned by the tool
    Property _Meta : TJSONObject Read FMeta Write SetMeta;
  end;
  TMCPToolArray = Array of TMCPTool;

  { TMCPEventTool }

  TMCPEventTool = class(TMCPTool)
  private
    FOnExecute: TToolInvocationEvent;
  protected
    procedure DoExecute(aInput : TJSONObject; aResult: TJSONObject); override;
    property OnExecute : TToolInvocationEvent read FOnExecute Write FOnExecute;
  Public
    constructor create(const aName,aDescription : String; aOnExecute : TToolInvocationEvent); reintroduce; virtual;
  end;

  { TMCPToolRegistry }

  TMCPToolRegistry = Class(TObject)
  private
    class var _instance : TMCPToolRegistry;
    class function GetInstance: TMCPToolRegistry; static;
  private
    FList :  TThreadSafeObjectHash;
    FOnChange: TNotifyEvent;
  protected
    function GetCount: Integer; virtual;
    procedure DoChange; virtual;
  Public
    constructor Create; virtual;
    destructor destroy; override;
    // Add a Tool. Once added, the registry owns the Tool
    Procedure Add(aTool : TMCPTool); virtual;
    // Remove a Tool. The object will be freed.
    procedure Remove(const aName : String); virtual;
    procedure Remove(aTool : TMCPTool);
    procedure LockList(aList : TFPList);
    procedure LockList(var aList : TMCPToolArray);
    procedure UnlockList;
    function Find(const aName : String) : TMCPTool;
    function Get(const aName : String) : TMCPTool;
    property Tools[aName : string] : TMCPTool Read Get; default;
    Property Count : Integer Read GetCount;
    property OnChange : TNotifyEvent Read FOnChange Write FOnChange;
    class procedure Init(aClass: TMCPToolRegistryClass);
    class procedure Done;
    class property Instance : TMCPToolRegistry read GetInstance;
  end;

Function ToolRegistry : TMCPToolRegistry;

implementation

uses mcp.strings;

function ToolRegistry: TMCPToolRegistry;
begin
  Result:=TMCPToolRegistry.Instance;
end;

{ TMCPTool }

procedure TMCPTool.SetMeta(AValue: TJSONObject);
begin
  if FMeta=AValue then Exit;
  FreeAndNil(FMeta);
  FMeta:=AValue;
end;

constructor TMCPTool.create(const aName: string; const aDescription: string);
begin
  FInputSchema:=TMCPSchema.Create;
  FOutputSchema:=TMCPSchema.Create;
  FName:=aName;
  FDescription:=aDescription;
end;

destructor TMCPTool.destroy;
begin
  _Meta:=Nil;
  FreeAndNil(FInputSchema);
  FreeAndNil(FOutputSchema);
  inherited destroy;
end;

procedure TMCPTool.Register(aRegistry: TMCPToolRegistry);
begin
  if aRegistry=Nil then
    aRegistry:=TMCPToolRegistry.Instance;
  aRegistry.Add(Self);
end;

procedure TMCPTool.Execute(aInput: TJSONObject; aResult : TJSONObject);

begin
  DoExecute(aInput,aResult);
end;

procedure TMCPTool.ToJSON(aJSON: TJSONObject);
var
  Anns : TJSONObject;
begin
  aJSON.Add('name',Name);
  aJSON.Add('description',Description);
  Anns:=Annotations.ToJSON;
  if assigned(Anns) then
    aJSON.Add('annotations',Anns);
  aJSON.Add('inputSchema',InputSchema.ToJSON);
  aJSON.Add('outputSchema',InputSchema.ToJSON);
end;

function TMCPTool.ToJSON: TJSONObject;
begin
  Result:=TJSONObject.Create;
  try
    ToJSON(Result);
  except
    Result.Free;
    Raise;
  end;
end;

{ TMCPEventTool }

procedure TMCPEventTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
begin
  FOnExecute(aInput,aResult);
end;

constructor TMCPEventTool.create(const aName, aDescription: String;
  aOnExecute: TToolInvocationEvent);
begin
  Inherited Create(aName,aDescription);
  if aOnExecute=Nil then
    Raise EMCPException.Create('Invocation event cannot be nil');
  FOnExecute:=AOnExecute;
end;

{ TMCPToolRegistry }

class function TMCPToolRegistry.GetInstance: TMCPToolRegistry; static;
begin
  if _instance=nil then
    _Instance:=TMCPToolRegistry.Create;
  Result:=_Instance
end;

function TMCPToolRegistry.GetCount: Integer;
begin
  Result:=FList.Count;
end;

procedure TMCPToolRegistry.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TMCPToolRegistry.Create;
begin
  FList:=TThreadSafeObjectHash.Create(True);
end;

destructor TMCPToolRegistry.destroy;
begin
  FList.Destroy;
  inherited destroy;
end;

procedure TMCPToolRegistry.Add(aTool: TMCPTool);
begin
  FList.Add(aTool.Name,aTool);
  DoChange;
end;

procedure TMCPToolRegistry.Remove(const aName: String);
begin
  if FList.Get(aName)=Nil then
    exit;
  FList.Remove(aName);
  DoChange;
end;

procedure TMCPToolRegistry.Remove(aTool: TMCPTool);
begin
  Remove(aTool.Name);
end;


procedure TMCPToolRegistry.LockList(aList: TFPList);
begin
  FList.GetObjectList(aList);
end;

procedure TMCPToolRegistry.LockList(var aList: TMCPToolArray);
var
  llist : TFPList;
  I : Integer;
begin
  lList:=TFPList.Create;
  try
    FList.GetObjectList(lList);
    SetLength(aList,lList.Count);
    For I:=0 to lList.Count-1 do
      aList[i]:=TMCPTool(lList[i]);
  finally
    lList.free;
  end;
  // do not unlock.
end;

procedure TMCPToolRegistry.UnlockList;
begin
  FList.Unlock;
end;

function TMCPToolRegistry.Find(const aName: String): TMCPTool;
begin
  Result:=TMCPTool(FList.Get(aName));
end;

function TMCPToolRegistry.Get(const aName: String): TMCPTool;
begin
  Result:=Find(aName);
  if Result=Nil then
    Raise EMCPException.CreateFmt(SErrUnknownTool,[aName]);
end;

class procedure TMCPToolRegistry.Init(aClass: TMCPToolRegistryClass);
begin
  if assigned(_instance) then
    Raise EMCPException.Create(SErrRegistryALreadyInstantiated);
  if aClass=Nil then
    Raise EMCPException.Create(SErrRegistryClassEmpty);
  _Instance:=aClass.Create;
end;

class procedure TMCPToolRegistry.Done;
begin
  FreeAndNil(_instance);
end;

finalization
  TMCPToolRegistry.Done;
end.


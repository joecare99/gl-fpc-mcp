{
    This file is part of the Free Component Library

    MCP client side call definitions
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit MCP.Client.Calls;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}

interface

uses
  sysutils, fpjson, types, classes, mcp.types, mcp.utils, mcp.client.base;

type
  { TServerInfo }

  TServerInfo = record
    name : string;
    version : string;
    procedure fromJSON(aJSON : TJSONObject);
  end;

  TServerFeature = (sfLogging,sfCompletions,sfPrompts,sfResources,sfTools,sfPromptChanges,sfResourceChanges,sfResourceSubscribe,sfToolChanges);
  TServerFeatures = set of TServerFeature;

  { TInitializeResponse }

  TMCPInitializeResponse = record
    Info : TServerInfo;
    protocol : string;
    Features : TServerFeatures;
    procedure FromJson(aJSON : TJSONObject);
  end;

  TOnInitializeEvent = procedure(const aResponse : TMCPInitializeResponse; aError : TRPCError) of object;

  TMCPInitialize = class(TMCPCall)
  private
    FOnReply: TOnInitializeEvent;
  protected
    procedure Reply(aData: TJSONObject); override;
    procedure HandleReply(aResponse: TMCPInitializeResponse); virtual;
  public
    class function methodname : string; override;
    function Call() : TRequestID; reintroduce;
    property OnReply : TOnInitializeEvent Read FOnReply Write FOnReply;
  end;


  TResourceListResponseEvent = procedure (aSender : TObject; aList : TMCPResourceInfoList) of object;

   { TMCPReadResourceList }

  TMCPReadResourceList = class(TMCPCall)
  private
    FOnReply: TResourceListResponseEvent;
  protected
    procedure Reply(aData: TJSONObject); override;
    procedure HandleReply(ResourceList: TMCPResourceInfoList); virtual;
    procedure HandleError(aError: TRPCError); override;
  public
    class function methodname : string; override;
    procedure Call(); reintroduce;
    property OnReply : TResourceListResponseEvent Read FOnReply Write FOnReply;
  end;

  TMCPReadResourceResponse  = record
    resource : TMCPResourceInfo;
  end;


  TOnResourceReadEvent = procedure(aInfo : TMCPReadResourceResponse; aError : TRPCError) of object;

  { TMCPReadResource }

  TMCPReadResource = class(TMCPCall)
  private
    FOnReply: TOnResourceReadEvent;
  protected
    procedure Reply(aData: TJSONObject); override;
    procedure HandleReply(const aResponse: TMCPReadResourceResponse); virtual;
    Procedure HandleError(aError: TRPCError); override;
  public
    class function methodname : string; override;
    procedure Call(Const aURI : String); reintroduce;
    property OnReply : TOnResourceReadEvent Read FOnReply Write FOnReply;
  end;


  { TMCPGetResource }

  TMCPGetResource = class(TMCPCall)
  private
    FOnReply: TGetResourceResponseEvent;
  protected
    procedure Reply(aData: TJSONObject); override;
    procedure HandleReply(Resource: TMCPResourceInfo); virtual;
    procedure HandleError(aError: TRPCError); override;
  public
    class function methodname : string; override;
    procedure Call(const aURI: String); reintroduce;
    property OnReply : TGetResourceResponseEvent Read FOnReply Write FOnReply;
  end;

  TPromptListResponseEvent = procedure (aSender : TObject; aList : TMCPPromptInfoList) of object;
  { TMCPReadPromptList }

  TMCPReadPromptList = class(TMCPCall)
  private
    FOnReply: TPromptListResponseEvent;
  protected
    procedure Reply(aData: TJSONObject); override;
    procedure HandleReply(PromptList: TMCPPromptInfoList); virtual;
    Procedure HandleError(aError: TRPCError); override;
  public
    class function methodname : string; override;
    procedure Call(); reintroduce;
    property OnReply : TPromptListResponseEvent Read FOnReply Write FOnReply;
  end;

  { TMCPPromptList }

  { TMCPPromptMessage }

  { TMCPContentBlock }

  TMCPContentBlock = record
    kind : TMCPPromptKind;
    text : string;
    data : TBytes;
    mimetype : string;
    annotations : TMCPAnnotation;
    procedure FromJSON(aJSON : TJSONObject);
  end;

  TMCPPromptMessage = record
    role : TMCProle;
    content : TMCPContentBlock;
    procedure FromJSON(aJSON : TJSONObject);
  end;
  TMCPPromptMessageArray = array of TMCPPromptMessage;

  { TMCPPromptResponse }

  TMCPGetPromptResponse = record
    description : string;
    messages : TMCPPromptMessageArray;
    procedure FromJSON(aJSON : TJSONObject);
  end;

  TOnGetPromptEvent = procedure(aInfo: TMCPGetPromptResponse; aError: TRPCError) of object;

  { TMCPGetPrompt }

  TMCPGetPrompt = class(TMCPCall)
  private
    FOnReply: TOnGetPromptEvent;
  protected
    procedure Reply(aData: TJSONObject); override;
    procedure HandleReply(const aResponse: TMCPGetPromptResponse); virtual;
    Procedure HandleError(aError: TRPCError); override;
  public
    class function methodname : string; override;
    procedure Call(Const aName : String; aArguments : TStrings); reintroduce; overload;
    procedure Call(Const aName : String; aArguments : Array of string); reintroduce; overload;
    procedure Call(Const aName : String; aArguments : TJSONObject); reintroduce; overload;
    property OnReply : TOnGetPromptEvent Read FOnReply Write FOnReply;
  end;


  { TMCPListTools }

  TMCPListTools = class(TMCPCall)
  private
    FOnReply: TListToolsResponseEvent;
  protected
    procedure Reply(aData: TJSONObject); override;
    procedure HandleReply(ToolList: TMCPToolInfoList); virtual;
    procedure HandleError(aError: TRPCError); override;
  public
    class function methodname: string; override;
    procedure Call(); reintroduce;
    property OnReply: TListToolsResponseEvent read FOnReply write FOnReply;
  end;

  { Completion Types }

  { TMCPCompletionRefType }

  TMCPCompletionRefType = (
    crtPrompt,      // ref/prompt
    crtResource     // ref/resource
  );

  TMCPCompletionRefTypeHelper = type helper for TMCPCompletionRefType
    function AsString: string;
    procedure AsString(const aValue: string);
  end;

  { TMCPCompletionRef }

  TMCPCompletionRef = record
    RefType: TMCPCompletionRefType;  // "type" field in JSON
    Name: string;                    // Reference name (prompt name or resource URI pattern)
    procedure ToJSON(aJSON: TJSONObject);
    procedure FromJSON(aJSON: TJSONObject);
    function ToJSON: TJSONObject;
  end;

  { TMCPCompletionArgument }

  TMCPCompletionArgument = record
    Name: string;                    // Argument name being completed
    Value: string;                   // Current partial value
    procedure ToJSON(aJSON: TJSONObject);
    procedure FromJSON(aJSON: TJSONObject);
    function ToJSON: TJSONObject;
  end;

  { TMCPCompletionContext }

  TMCPCompletionContext = record
    Arguments: TJSONObject;          // Previous completed arguments for context
    procedure ToJSON(aJSON: TJSONObject);
    procedure FromJSON(aJSON: TJSONObject);
    function ToJSON: TJSONObject;
    procedure Initialize(aArguments: TJSONObject = nil);
    procedure Clear;
  end;

  { TMCPCompletionResult }

  TMCPCompletionResult = record
    Values: TStringDynArray;         // Array of completion suggestions
    Total: Integer;                  // Total number of available completions
    HasMore: Boolean;                // Whether there are more completions available
    procedure FromJSON(aJSON: TJSONObject);
    procedure Clear;
  end;

  { TMCPCompletionResponse }

  TMCPCompletionResponse = record
    Completion: TMCPCompletionResult;
    procedure FromJSON(aJSON: TJSONObject);
    procedure Clear;
  end;

  { Event Types }

  TOnCompletionCompleteEvent = procedure(aResponse: TMCPCompletionResponse; aError: TRPCError) of object;

  { TMCPCompletionComplete }

  TMCPCompletionComplete = class(TMCPCall)
  private
    FOnReply: TOnCompletionCompleteEvent;
  protected
    procedure Reply(aData: TJSONObject); override;
    procedure HandleReply(const aResponse: TMCPCompletionResponse); virtual;
    procedure HandleError(aError: TRPCError); override;
  public
    class function MethodName: string; override;

    // Main completion method
    procedure Call(const aRef: TMCPCompletionRef;
                  const aArgument: TMCPCompletionArgument;
                  const aContext: TMCPCompletionContext); reintroduce; overload;

    // Simplified method without context
    procedure Call(const aRef: TMCPCompletionRef;
                  const aArgument: TMCPCompletionArgument); reintroduce; overload;

    // Convenience methods for common scenarios
    procedure CallForPrompt(const aPromptName: string;
                           const aArgumentName: string;
                           const aPartialValue: string;
                           aContext: TJSONObject = nil); reintroduce; overload;

    procedure CallForResource(const aResourcePattern: string;
                             const aArgumentName: string;
                             const aPartialValue: string;
                             aContext: TJSONObject = nil); reintroduce; overload;

    property OnReply: TOnCompletionCompleteEvent read FOnReply write FOnReply;
  end;

  { Client Integration Types }

  TCompletionCompleteEvent = procedure(aSender: TObject; aResponse: TMCPCompletionResponse) of object;

{ Logging/SetLevel Types }

  { TMCPProtocolLogLevel }

  TMCPProtocolLogLevel = (
    mclError,    // error
    mclWarn,     // warn
    mclInfo,     // info
    mclDebug     // debug
  );

  { Type helper for TMCPProtocolLogLevel }

  TMCPProtocolLogLevelHelper = type helper for TMCPProtocolLogLevel
    function AsString: string;
    class function FromString(const aStr: string): TMCPProtocolLogLevel; static;
  end;

  { TMCPSetLogLevelRequest }

  TMCPSetLogLevelRequest = record
    Level: TMCPProtocolLogLevel;
    procedure Initialize(aLevel: TMCPProtocolLogLevel);
    procedure ToJSON(aJSON: TJSONObject);
    procedure FromJSON(aJSON: TJSONObject);
    procedure Clear;
  end;

  { TMCPSetLogLevelResponse }

  TMCPSetLogLevelResponse = record
    procedure Initialize;
    procedure FromJSON(aJSON: TJSONObject);
    procedure Clear;
  end;

  { Event Types }

  TOnSetLogLevelEvent = procedure(aResponse: TMCPSetLogLevelResponse; aError: TRPCError) of object;

  { TMCPSetLogLevel }

  TMCPSetLogLevel = class(TMCPCall)
  private
    FOnReply: TOnSetLogLevelEvent;
  protected
    procedure Reply(aData: TJSONObject); override;
    procedure HandleReply(const aResponse: TMCPSetLogLevelResponse); virtual;
    procedure HandleError(aError: TRPCError); override;
  public
    class function MethodName: string; override;

    // Call methods
    procedure Call(aLevel: TMCPProtocolLogLevel); reintroduce; overload;
    procedure Call(const aRequest: TMCPSetLogLevelRequest); reintroduce; overload;

    // Convenience methods for each level
    procedure SetErrorLevel;
    procedure SetWarnLevel;
    procedure SetInfoLevel;
    procedure SetDebugLevel;

    property OnReply: TOnSetLogLevelEvent read FOnReply write FOnReply;
  end;

  { Client Integration Types }

  TSetLogLevelEvent = procedure(aSender: TObject; const aResponse: TJSONObject) of object;

{ Tools/Call Types }

  { TMCPToolCallArguments }

  TMCPToolCallArguments = record
    Arguments: TJSONObject;
    procedure Initialize(aArguments: TJSONObject = nil);
    procedure Clear;
    procedure ToJSON(aJSON: TJSONObject);
    procedure FromJSON(aJSON: TJSONObject);
    function ToJSON: TJSONObject;
  end;

  { TMCPToolCallResponse }

  TMCPToolCallResponse = record
    Content: TMCPToolResultArray;
    IsError: Boolean;
    Meta: TJSONObject;
    procedure Initialize;
    procedure Clear;
    procedure FromJSON(aJSON: TJSONObject);
    procedure ToJSON(aJSON: TJSONObject);
    function ToJSON: TJSONObject;
  end;

  { Event Types }

  TOnToolCallEvent = procedure(aResponse: TMCPToolCallResponse; aError: TRPCError) of object;

  { TMCPToolCall }

  TMCPToolCall = class(TMCPCall)
  private
    FOnReply: TOnToolCallEvent;
  protected
    procedure Reply(aData: TJSONObject); override;
    procedure HandleReply(const aResponse: TMCPToolCallResponse); virtual;
    procedure HandleError(aError: TRPCError); override;
  public
    class function MethodName: string; override;

    // Main tool call method
    procedure Call(const aToolName: string; const aArguments: TMCPToolCallArguments); reintroduce; overload;
    // Simplified method with TJSONObject arguments
    procedure Call(const aToolName: string; aArguments: TJSONObject); reintroduce; overload;
    // Convenience method with string array arguments
    procedure Call(const aToolName: string; const aArguments: array of string); reintroduce; overload;
    // Reply is returned in callback.
    property OnReply: TOnToolCallEvent read FOnReply write FOnReply;
  end;

  { Client Integration Types }

  TToolCallEvent = procedure(aSender: TObject; aResponse: TMCPToolCallResponse) of object;

{ Helper Functions }

function CreateCompletionRef(aRefType: TMCPCompletionRefType; const aName: string): TMCPCompletionRef;
function CreateCompletionArgument(const aName, aValue: string): TMCPCompletionArgument;
function CreateCompletionContext(aArguments: TJSONObject = nil): TMCPCompletionContext;
function CreateCompletionResponseFromJSON(aJSON: TJSONObject): TMCPCompletionResponse;

// Logging/SetLevel helper functions
function CreateSetLogLevelRequest(aLevel: TMCPProtocolLogLevel): TMCPSetLogLevelRequest;
function CreateSetLogLevelResponseFromJSON(aJSON: TJSONObject): TMCPSetLogLevelResponse;

// Tools/Call helper functions
function CreateToolCallArguments(aArguments: TJSONObject = nil): TMCPToolCallArguments;
function CreateToolCallResponseFromJSON(aJSON: TJSONObject): TMCPToolCallResponse;

implementation

{ TServerInfo }

procedure TServerInfo.fromJSON(aJSON: TJSONObject);
begin
  with aJSON do
    begin
    name:=get('name','');
    version:=get('version','');
    end;
end;

{ TInitializeResponse }

procedure TMCPInitializeResponse.FromJson(aJSON: TJSONObject);

  function checkavailable(aCaps : TJSONObject; aFeature : string; aAvailable : TServerFeature; aChanges : TServerFeature) : boolean;
  var
    lTmp : TJSONObject;
  begin
    Result:=assigned(aCaps);
    if result then
      ltmp:=aCaps.get(aFeature,TJSONObject(Nil));
    Result:=Result and Assigned(lTmp);
    if result then
      begin
      Include(Features,aAvailable);
      if lTmp.Get('listChanged',false) then
        Include(Features,aChanges);
      end;
  end;

var
  lCaps : TJSONObject;

begin
  lCaps:=aJSON.get('serverInfo',TJSONObject(nil));
  if assigned(lCaps) then
    Info.fromJSON(lCaps);
  protocol:=aJSON.Get('protocol','');
  lCaps:=aJSON.get('capabilities',TJSONObject(nil));
  checkavailable(lCaps,'prompts',sfPrompts,sfPromptChanges);
  if checkavailable(lCaps,'resources',sfResources,sfResourceChanges) then
    if lCaps.Get('resources',TJSONObject(Nil)).Get('subscribe',false) then
      include(Features,sfResourceSubscribe);
  checkAvailable(lCaps,'tools',sfTools,sfToolChanges);
  checkAvailable(lCaps,'logging',sfLogging,sfLogging);
  checkAvailable(lCaps,'completions',sfCompletions,sfCompletions);
end;

{ TMCPInitialize }

procedure TMCPInitialize.Reply(aData: TJSONObject);
var
  lResp: TMCPInitializeResponse;

begin
  inherited Reply(aData);
  lResp.FromJSON(aData);
  HandleReply(lResp);
end;

procedure TMCPInitialize.HandleReply(aResponse: TMCPInitializeResponse);
begin
  if assigned(FOnReply) then
    FonReply(aResponse,Default(TRPCError));
end;

class function TMCPInitialize.methodname: string;
begin
  result:='initialization'
end;

function TMCPInitialize.Call() : TRequestID;
var
  args : TJSONObject;
  tmp : TJSONObject;
begin
  args:=TJSONObject.Create;
  tmp:=TJSONObject.create;
  args.Add('capabilities',tmp);
  if coRoots in Client.Options then
   tmp.add('roots',TJSONObject.create(['list_changed',True]));
  if coSampling in Client.Options then
   tmp.add('sampling',TJSONObject.create);
  if coElicitation in Client.Options then
   tmp.add('elicitation',TJSONObject.create);
  args.add('protocolversion',client.protocolversion);
  tmp:=TJSONObject.create();
  tmp.add('name',client.clientname);
  tmp.add('version',client.clientversion);
  args.add('clientInfo',tmp);
  Result:=Inherited call(args);
end;


{ TMCPReadResourceList }

procedure TMCPReadResourceList.Reply(aData: TJSONObject);
var
  ResourceList: TMCPResourceInfoList;
  lResources: TJSONArray;
  I: Integer;
  ResourceInfo: mcp.types.TMCPResourceInfo;
begin
  inherited Reply(aData);

  // Create TMCPResourceInfoList and populate it directly
  ResourceList:=TMCPResourceInfoList.Create(True);
  try
    // Parse resources array from JSON response
    lResources:=aData.Get('resources', TJSONArray(nil));
    if Assigned(lResources) then
    begin
      for I:=0 to lResources.Count - 1 do
        if lResources.Types[I] = jtObject then
        begin
          ResourceInfo:=mcp.types.TMCPResourceInfo.Create('temp', 'temp');
          try
            ResourceInfo.FromJSON(lResources.Objects[I]);
            ResourceList.Add(ResourceInfo);
          except
            ResourceInfo.Free;
            raise;
          end;
        end;
    end;

    HandleReply(ResourceList);
  except
    ResourceList.Free;
    raise;
  end;
end;

procedure TMCPReadResourceList.HandleReply(ResourceList: TMCPResourceInfoList);
begin
  if Assigned(FOnReply) then
  begin
    // Call the event handler - it's responsible for freeing the list
    FOnReply(Self, ResourceList);
  end
  else
  begin
    // If no handler, free the list to prevent memory leak
    ResourceList.Free;
  end;
end;

procedure TMCPReadResourceList.HandleError(aError: TRPCError);
begin
  inherited HandleError(aError);
  if Assigned(FOnReply) then
    FOnReply(Self, nil); // Pass nil list on error
end;

class function TMCPReadResourceList.methodname: string;
begin
  result:='resources/list'
end;

procedure TMCPReadResourceList.Call();
begin
  inherited call(TJSONObject.Create());
end;

{ TMCPReadResource }

procedure TMCPReadResource.Reply(aData: TJSONObject);
var
  lInfo : TMCPReadResourceResponse;
begin
  inherited Reply(aData);
  lInfo.Resource.FromJSON(aData);
  HandleReply(lInfo);
end;

procedure TMCPReadResource.HandleReply(const aResponse: TMCPReadResourceResponse);
begin
  if Assigned(FOnReply) then
    FOnReply(aResponse,Default(TRPCError));
end;

procedure TMCPReadResource.HandleError(aError: TRPCError);
begin
  inherited HandleError(aError);
  if Assigned(FOnReply) then
    FOnReply(Default(TMCPReadResourceResponse),aError);
end;

class function TMCPReadResource.methodname: string;
begin
  result:='resources/read';
end;

procedure TMCPReadResource.Call(const aURI: String);
var
  lArgs : TJSONObject;
begin
  lArgs:=TJSONObject.Create;
  lArgs.Add('uri', aUri);
  inherited call(lArgs);
end;

procedure TMCPGetPrompt.Call(const aName: String; aArguments: TJSONObject);
var
  lObj: TJSONObject;
begin
  lObj:=TJSONObject.Create;
  lObj.Add('name', aName);
  if Assigned(aArguments) then
    lObj.Add('arguments', aArguments.Clone);
  inherited Call(lObj);
end;

{ TMCPGetResource }

procedure TMCPGetResource.Reply(aData: TJSONObject);
var
  Resource: TMCPResourceInfo;
begin
  inherited Reply(aData);
  Resource:=TMCPResourceInfo.Create('temp', 'temp');
  try
    Resource.FromJSON(aData);
    HandleReply(Resource);
  except
    Resource.Free;
    raise;
  end;
end;

procedure TMCPGetResource.HandleReply(Resource: TMCPResourceInfo);
begin
  if Assigned(FOnReply) then
  begin
    // Call the event handler - it's responsible for freeing the resource
    FOnReply(Self, Resource);
  end
  else
  begin
    // If no handler, free the resource to prevent memory leak
    Resource.Free;
  end;
end;

procedure TMCPGetResource.HandleError(aError: TRPCError);
begin
  inherited HandleError(aError);
  if Assigned(FOnReply) then
    FOnReply(Self, nil); // Pass nil resource on error
end;

class function TMCPGetResource.methodname: string;
begin
  result:='resources/read';
end;

procedure TMCPGetResource.Call(const aURI: String);
var
  lArgs: TJSONObject;
begin
  lArgs:=TJSONObject.Create;
  lArgs.Add('uri', aURI);
  inherited call(lArgs);
end;

{ TMCPReadPromptList }

procedure TMCPReadPromptList.Reply(aData: TJSONObject);
var
  PromptList: TMCPPromptInfoList;
  lPrompts: TJSONArray;
  I: Integer;
  PromptInfo: mcp.types.TMCPPromptInfo;
begin
  inherited Reply(aData);

  // Create TMCPPromptInfoList and populate it directly
  PromptList:=TMCPPromptInfoList.Create(True);
  try
    // Parse prompts array from JSON response
    lPrompts:=aData.Get('prompts', TJSONArray(nil));
    if Assigned(lPrompts) then
    begin
      for I:=0 to lPrompts.Count - 1 do
        if lPrompts.Types[I] = jtObject then
        begin
          PromptInfo:=mcp.types.TMCPPromptInfo.Create('temp', 'temp');
          try
            PromptInfo.FromJSON(lPrompts.Objects[I]);
            PromptList.Add(PromptInfo);
          except
            PromptInfo.Free;
            raise;
          end;
        end;
    end;

    HandleReply(PromptList);
  except
    PromptList.Free;
    raise;
  end;
end;

procedure TMCPReadPromptList.HandleReply(PromptList: TMCPPromptInfoList);
begin
  if Assigned(FOnReply) then
  begin
    // Call the event handler - it's responsible for freeing the list
    FOnReply(Self, PromptList);
  end
  else
  begin
    // If no handler, free the list to prevent memory leak
    PromptList.Free;
  end;
end;

procedure TMCPReadPromptList.HandleError(aError: TRPCError);
begin
  inherited HandleError(aError);
  if Assigned(FOnReply) then
    FOnReply(Self, nil); // Pass nil list on error
end;

class function TMCPReadPromptList.methodname: string;
begin
  result:='prompts/list'
end;

procedure TMCPReadPromptList.Call();
begin
  Inherited Call(TJSONObject.Create())
end;

{ TMCPContentBlock }

procedure TMCPContentBlock.FromJSON(aJSON: TJSONObject);
begin
  if aJSON=Nil then exit;
  with aJSON do
    begin
    kind.AsString:=Get('type','text');
    text:=aJSON.get('text','');
    data:=DecodeBytes(aJSON.Get('data',''));
    mimetype:=get('mimeType','');
    Annotations.FromJSON(get('annotations',TJSONObject(Nil)));
    end;
end;

{ TMCPPromptMessage }

procedure TMCPPromptMessage.FromJSON(aJSON: TJSONObject);
begin
  With aJSON do
    begin
    Role.AsString:=Get('role','user');
    content.FromJSON(Get('content',TJSONObject(Nil)));
    end;
end;

{ TMCPGetPromptResponse }

procedure TMCPGetPromptResponse.FromJSON(aJSON: TJSONObject);
var
  lMessages : TJSONArray;
  i : Integer;
begin
  With aJSON do
    begin
    Description:=get('description','');
    lMessages:=Get('messages',TJSONArray(nil));
    if Assigned(lMessages) then
      begin
      SetLength(messages,lMessages.count);
      for i:=0 to lMessages.count-1 do
        if lMessages.types[i]=jtObject then
          Messages[i].FromJSON(lMessages.Objects[i]);
      end;
    end;
end;

{ TMCPGetPrompt }

procedure TMCPGetPrompt.Reply(aData: TJSONObject);
var
  lResponse: TMCPGetPromptResponse;
begin
  inherited Reply(aData);
  lResponse.FromJSON(aData);
  HandleReply(lResponse);
end;

procedure TMCPGetPrompt.HandleReply(const aResponse: TMCPGetPromptResponse);
begin
  if Assigned(FOnReply) then
    FOnReply(aResponse,Default(TRPCError));
end;

procedure TMCPGetPrompt.HandleError(aError: TRPCError);
begin
  inherited HandleError(aError);
  if Assigned(FOnReply) then
    FOnReply(Default(TMCPGetPromptResponse),aError)
end;

class function TMCPGetPrompt.methodname: string;
begin
  Result:='prompts/get'
end;

procedure TMCPGetPrompt.Call(const aName: String; aArguments : TStrings);
var
  lObj,lArgs : TJSONObject;
  I : Integer;
  N,V : String;

begin
  lObj:=TJSONObject.Create;
  lObj.Add('name',aName);
  if aArguments.Count>0 then
    begin
    lArgs:=TJSONObject.Create;
    lObj.Add('arguments',lArgs);
    for I:=0 to aArguments.Count-1 do
      begin
      aArguments.GetNameValue(I,N,V);
      if N<>'' then
        lArgs.Add(N,V);
      end;

    end;
  Inherited Call(lObj);
end;

procedure TMCPGetPrompt.Call(const aName: String; aArguments: array of string);

var
  L : TStrings;
  I : Integer;
begin
  if ((Length(aArguments) mod 2)=1) then
    Raise EMCPClient.Create('Number of arguments must be even');
  I:=0;
  L:=TstringList.Create;
  try
    While I<Length(aArguments) do
      begin
      L.Values[aArguments[i]]:=aArguments[I+1];
      inc(i,2);
      end;
    Call(aName,L);
  finally
    l.Free;
  end;
end;


{ TMCPListTools }

procedure TMCPListTools.Reply(aData: TJSONObject);
var
  ToolList: TMCPToolInfoList;
  lTools: TJSONArray;
  I: Integer;
  ToolInfo: mcp.types.TMCPToolInfo;
begin
  inherited Reply(aData);

  // Create TMCPToolInfoList and populate it directly
  ToolList:=TMCPToolInfoList.Create(True);
  try
    // Parse tools array from JSON response
    lTools:=aData.Get('tools', TJSONArray(nil));
    if Assigned(lTools) then
    begin
      for I:=0 to lTools.Count - 1 do
        if lTools.Types[I] = jtObject then
        begin
          ToolInfo:=mcp.types.TMCPToolInfo.Create('', '');
          try
            ToolInfo.FromJSON(lTools.Objects[I]);
            ToolList.Add(ToolInfo);
          except
            ToolInfo.Free;
            raise;
          end;
        end;
    end;

    HandleReply(ToolList);
  except
    ToolList.Free;
    raise;
  end;
end;

procedure TMCPListTools.HandleReply(ToolList: TMCPToolInfoList);
begin
  if Assigned(FOnReply) then
  begin
    // Call the event handler - it's responsible for freeing the list
    FOnReply(Self, ToolList);
  end
  else
  begin
    // If no handler, free the list to prevent memory leak
    ToolList.Free;
  end;
end;

procedure TMCPListTools.HandleError(aError: TRPCError);
begin
  inherited HandleError(aError);
  if Assigned(FOnReply) then
    FOnReply(Self, nil); // Pass nil list on error
end;

class function TMCPListTools.methodname: string;
begin
  Result:='tools/list';
end;

procedure TMCPListTools.Call();
begin
  inherited Call(TJSONObject.Create());
end;

{ TMCPCompletionRefTypeHelper }

function TMCPCompletionRefTypeHelper.AsString: string;
begin
  case Self of
    crtPrompt: Result:='ref/prompt';
    crtResource: Result:='ref/resource';
  else
    Result:='';
  end;
end;

procedure TMCPCompletionRefTypeHelper.AsString(const aValue: string);
begin
  if aValue = 'ref/prompt' then
    Self:=crtPrompt
  else if aValue = 'ref/resource' then
    Self:=crtResource
  else
    Self:=crtPrompt; // Default
end;

{ TMCPCompletionRef }

procedure TMCPCompletionRef.ToJSON(aJSON: TJSONObject);
begin
  if Assigned(aJSON) then
  begin
    aJSON.Add('type', RefType.AsString);
    aJSON.Add('name', Name);
  end;
end;

procedure TMCPCompletionRef.FromJSON(aJSON: TJSONObject);
begin
  if Assigned(aJSON) then
  begin
    RefType.AsString(aJSON.Get('type', ''));
    Name:=aJSON.Get('name', '');
  end;
end;

function TMCPCompletionRef.ToJSON: TJSONObject;
begin
  Result:=TJSONObject.Create;
  ToJSON(Result);
end;

{ TMCPCompletionArgument }

procedure TMCPCompletionArgument.ToJSON(aJSON: TJSONObject);
begin
  if Assigned(aJSON) then
  begin
    aJSON.Add('name', Name);
    aJSON.Add('value', Value);
  end;
end;

procedure TMCPCompletionArgument.FromJSON(aJSON: TJSONObject);
begin
  if Assigned(aJSON) then
  begin
    Name:=aJSON.Get('name', '');
    Value:=aJSON.Get('value', '');
  end;
end;

function TMCPCompletionArgument.ToJSON: TJSONObject;
begin
  Result:=TJSONObject.Create;
  ToJSON(Result);
end;

{ TMCPCompletionContext }

procedure TMCPCompletionContext.Initialize(aArguments: TJSONObject);
begin
  if Assigned(aArguments) then
    Arguments:=aArguments.Clone as TJSONObject
  else
    Arguments:=TJSONObject.Create;
end;

procedure TMCPCompletionContext.Clear;
begin
  Arguments.Free;
  Arguments:=nil;
end;

procedure TMCPCompletionContext.ToJSON(aJSON: TJSONObject);
begin
  if Assigned(aJSON) and Assigned(Arguments) then
  begin
    aJSON.Add('arguments', Arguments.Clone);
  end;
end;

procedure TMCPCompletionContext.FromJSON(aJSON: TJSONObject);
var
  ArgsJSON: TJSONObject;
begin
  Arguments.Free;
  if Assigned(aJSON) then
  begin
    ArgsJSON:=aJSON.Get('arguments', TJSONObject(nil));
    if Assigned(ArgsJSON) then
      Arguments:=ArgsJSON.Clone as TJSONObject
    else
      Arguments:=TJSONObject.Create;
  end
  else
    Arguments:=TJSONObject.Create;
end;

function TMCPCompletionContext.ToJSON: TJSONObject;
begin
  Result:=TJSONObject.Create;
  ToJSON(Result);
end;

{ TMCPCompletionResult }

procedure TMCPCompletionResult.FromJSON(aJSON: TJSONObject);
var
  ValuesArray: TJSONArray;
  i: Integer;
begin
  Writeln('Deserializing : ',  aJSON.AsJSON);
  SetLength(Values, 0);
  Total:=0;
  HasMore:=False;

  if Assigned(aJSON) then
  begin
    ValuesArray:=aJSON.Get('values', TJSONArray(nil));
    if Assigned(ValuesArray) then
    begin
      SetLength(Values, ValuesArray.Count);
      for i:=0 to ValuesArray.Count - 1 do
      begin
        if ValuesArray.Types[i] = jtString then
          Values[i]:=ValuesArray.Strings[i];
      end;
    end;

    Total:=aJSON.Get('total', Length(Values));
    HasMore:=aJSON.Get('hasMore', False);
  end;
end;

procedure TMCPCompletionResult.Clear;
begin
  SetLength(Values, 0);
end;

{ TMCPCompletionResponse }

procedure TMCPCompletionResponse.FromJSON(aJSON: TJSONObject);
var
  CompletionJSON: TJSONObject;
begin
  if Assigned(aJSON) then
  begin
    CompletionJSON:=aJSON.Get('completion', TJSONObject(nil));
    if Assigned(CompletionJSON) then
      Completion.FromJSON(CompletionJSON);
  end;
end;

procedure TMCPCompletionResponse.Clear;
begin
  Completion.Clear;
end;

{ TMCPCompletionComplete }

class function TMCPCompletionComplete.MethodName: string;
begin
  Result:='completion/complete';
end;

procedure TMCPCompletionComplete.Reply(aData: TJSONObject);
var
  lResponse: TMCPCompletionResponse;
begin
  inherited Reply(aData);
  lResponse.FromJSON(aData);
  HandleReply(lResponse);
  lResponse.Clear;
end;

procedure TMCPCompletionComplete.HandleReply(const aResponse: TMCPCompletionResponse);
begin
  if Assigned(FOnReply) then
    FOnReply(aResponse, Default(TRPCError));
end;

procedure TMCPCompletionComplete.HandleError(aError: TRPCError);
begin
  inherited HandleError(aError);
  if Assigned(FOnReply) then
    FOnReply(Default(TMCPCompletionResponse), aError);
end;

procedure TMCPCompletionComplete.Call(const aRef: TMCPCompletionRef;
                                     const aArgument: TMCPCompletionArgument;
                                     const aContext: TMCPCompletionContext);
var
  lObj: TJSONObject;
begin
  lObj:=TJSONObject.Create;
  try
    lObj.Add('ref', aRef.ToJSON);
    lObj.Add('argument', aArgument.ToJSON);
    if Assigned(aContext.Arguments) and (aContext.Arguments.Count > 0) then
      lObj.Add('context', aContext.ToJSON);

    inherited Call(lObj);
  except
    lObj.Free;
    raise;
  end;
end;

procedure TMCPCompletionComplete.Call(const aRef: TMCPCompletionRef;
                                     const aArgument: TMCPCompletionArgument);
var
  EmptyContext: TMCPCompletionContext;
begin
  EmptyContext:=CreateCompletionContext(nil);
  try
    Call(aRef, aArgument, EmptyContext);
  finally
    EmptyContext.Clear;
  end;
end;

procedure TMCPCompletionComplete.CallForPrompt(const aPromptName: string;
                                              const aArgumentName: string;
                                              const aPartialValue: string;
                                              aContext: TJSONObject);
var
  Ref: TMCPCompletionRef;
  Arg: TMCPCompletionArgument;
  Context: TMCPCompletionContext;
begin
  Ref:=CreateCompletionRef(crtPrompt, aPromptName);
  Arg:=CreateCompletionArgument(aArgumentName, aPartialValue);
  Context:=CreateCompletionContext(aContext);
  try
    Call(Ref, Arg, Context);
  finally
    Context.Clear;
  end;
end;

procedure TMCPCompletionComplete.CallForResource(const aResourcePattern: string;
                                                const aArgumentName: string;
                                                const aPartialValue: string;
                                                aContext: TJSONObject);
var
  Ref: TMCPCompletionRef;
  Arg: TMCPCompletionArgument;
  Context: TMCPCompletionContext;
begin
  Ref:=CreateCompletionRef(crtResource, aResourcePattern);
  Arg:=CreateCompletionArgument(aArgumentName, aPartialValue);
  Context:=CreateCompletionContext(aContext);
  try
    Call(Ref, Arg, Context);
  finally
    Context.Clear;
  end;
end;

{ Helper Functions }

function CreateCompletionRef(aRefType: TMCPCompletionRefType; const aName: string): TMCPCompletionRef;
begin
  Result.RefType:=aRefType;
  Result.Name:=aName;
end;

function CreateCompletionArgument(const aName, aValue: string): TMCPCompletionArgument;
begin
  Result.Name:=aName;
  Result.Value:=aValue;
end;

function CreateCompletionContext(aArguments: TJSONObject): TMCPCompletionContext;
begin
  Result.Initialize(aArguments);
end;

function CreateCompletionResponseFromJSON(aJSON: TJSONObject): TMCPCompletionResponse;
begin
  Result.FromJSON(aJSON);
end;

{ TMCPProtocolLogLevelHelper }

function TMCPProtocolLogLevelHelper.AsString: string;
begin
  case Self of
    mclError: Result:='error';
    mclWarn: Result:='warn';
    mclInfo: Result:='info';
    mclDebug: Result:='debug';
  else
    Result:='error'; // Default fallback
  end;
end;

class function TMCPProtocolLogLevelHelper.FromString(const aStr: string): TMCPProtocolLogLevel;
var
  lStr: string;
begin
  lStr:=LowerCase(aStr);
  if lStr = 'error' then Result:=mclError
  else if lStr = 'warn' then Result:=mclWarn
  else if lStr = 'info' then Result:=mclInfo
  else if lStr = 'debug' then Result:=mclDebug
  else Result:=mclError; // Default fallback
end;

{ TMCPSetLogLevelRequest }

procedure TMCPSetLogLevelRequest.Initialize(aLevel: TMCPProtocolLogLevel);
begin
  Level:=aLevel;
end;

procedure TMCPSetLogLevelRequest.ToJSON(aJSON: TJSONObject);
begin
  if Assigned(aJSON) then
    aJSON.Add('level', Level.AsString);
end;

procedure TMCPSetLogLevelRequest.FromJSON(aJSON: TJSONObject);
begin
  if Assigned(aJSON) then
    Level:=TMCPProtocolLogLevel.FromString(aJSON.Get('level', 'error'));
end;

procedure TMCPSetLogLevelRequest.Clear;
begin
  Level:=mclError;
end;

{ TMCPSetLogLevelResponse }

procedure TMCPSetLogLevelResponse.Initialize;
begin
  //
end;

procedure TMCPSetLogLevelResponse.FromJSON(aJSON: TJSONObject);
begin

end;

procedure TMCPSetLogLevelResponse.Clear;
begin
  // Nothing to clear for empty record
end;

{ TMCPSetLogLevel }

class function TMCPSetLogLevel.MethodName: string;
begin
  Result:='logging/setLevel';
end;

procedure TMCPSetLogLevel.Reply(aData: TJSONObject);
var
  lResponse: TMCPSetLogLevelResponse;
begin
  inherited Reply(aData);
  lResponse.FromJSON(aData);
  HandleReply(lResponse);
  lResponse.Clear;
end;

procedure TMCPSetLogLevel.HandleReply(const aResponse: TMCPSetLogLevelResponse);
begin
  if Assigned(FOnReply) then
    FOnReply(aResponse, Default(TRPCError));
end;

procedure TMCPSetLogLevel.HandleError(aError: TRPCError);
begin
  inherited HandleError(aError);
  if Assigned(FOnReply) then
    FOnReply(Default(TMCPSetLogLevelResponse), aError);
end;

procedure TMCPSetLogLevel.Call(aLevel: TMCPProtocolLogLevel);
var
  Request: TMCPSetLogLevelRequest;
begin
  Request.Initialize(aLevel);
  Call(Request);
end;

procedure TMCPSetLogLevel.Call(const aRequest: TMCPSetLogLevelRequest);
var
  Args: TJSONObject;
begin
  Args:=TJSONObject.Create;
  try
    aRequest.ToJSON(Args);
    inherited Call(Args);
  finally
    Args.Free;
  end;
end;

procedure TMCPSetLogLevel.SetErrorLevel;
begin
  Call(mclError);
end;

procedure TMCPSetLogLevel.SetWarnLevel;
begin
  Call(mclWarn);
end;

procedure TMCPSetLogLevel.SetInfoLevel;
begin
  Call(mclInfo);
end;

procedure TMCPSetLogLevel.SetDebugLevel;
begin
  Call(mclDebug);
end;

{ Logging/SetLevel Helper Functions }

function CreateSetLogLevelRequest(aLevel: TMCPProtocolLogLevel): TMCPSetLogLevelRequest;
begin
  Result.Initialize(aLevel);
end;

function CreateSetLogLevelResponseFromJSON(aJSON: TJSONObject): TMCPSetLogLevelResponse;
begin
  Result.FromJSON(aJSON);
end;

{ TMCPToolCallArguments }

procedure TMCPToolCallArguments.Initialize(aArguments: TJSONObject);
begin
  if Assigned(aArguments) then
    Arguments:=aArguments.Clone as TJSONObject
  else
    Arguments:=TJSONObject.Create;
end;

procedure TMCPToolCallArguments.Clear;
begin
  FreeAndNil(Arguments);
end;

procedure TMCPToolCallArguments.ToJSON(aJSON: TJSONObject);
begin
  if Assigned(aJSON) and Assigned(Arguments) then
    aJSON.Add('arguments', Arguments.Clone);
end;

procedure TMCPToolCallArguments.FromJSON(aJSON: TJSONObject);
var
  ArgsJSON: TJSONObject;
begin
  Arguments.Free;
  if Assigned(aJSON) then
    begin
    ArgsJSON:=aJSON.Get('arguments', TJSONObject(nil));
    if Assigned(ArgsJSON) then
      Arguments:=ArgsJSON.Clone as TJSONObject
    else
      Arguments:=TJSONObject.Create;
    end
  else
    Arguments:=TJSONObject.Create;
end;

function TMCPToolCallArguments.ToJSON: TJSONObject;
begin
  Result:=TJSONObject.Create;
  ToJSON(Result);
end;

{ TMCPToolCallResponse }

procedure TMCPToolCallResponse.Initialize;
begin
  SetLength(Content, 0);
  IsError:=False;
  Meta:=TJSONObject.Create;
end;

procedure TMCPToolCallResponse.Clear;
var
  i: Integer;
begin
  for i:=0 to Length(Content) - 1 do
    Content[i].Clear;
  SetLength(Content, 0);
  Meta.Free;
  Meta:=nil;
end;

procedure TMCPToolCallResponse.FromJSON(aJSON: TJSONObject);
var
  ContentArray: TJSONArray;
  i: Integer;
  MetaJSON: TJSONObject;
  S : String;
begin
  S:=aJSON.AsJSON;
  Clear;
  Initialize;
  if not Assigned(aJSON) then
    exit;
  S:=aJSON.AsJSON;
  ContentArray:=aJSON.Get('content', TJSONArray(nil));
  if Assigned(ContentArray) then
    begin
    SetLength(Content, ContentArray.Count);
    for i:=0 to ContentArray.Count - 1 do
      begin
      if ContentArray.Types[i] = jtObject then
        Content[i].FromJSON(ContentArray.Objects[i]);
      end;
    end;
  IsError:=aJSON.Get('isError', False);
  MetaJSON:=aJSON.Get('_meta', TJSONObject(nil));
  if Assigned(MetaJSON) then
    begin
    Meta.Free;
    Meta:=MetaJSON.Clone as TJSONObject;
    end;
end;

procedure TMCPToolCallResponse.ToJSON(aJSON: TJSONObject);
var
  ContentArray: TJSONArray;
  i: Integer;
begin
  if not Assigned(aJSON) then
    exit;

  ContentArray:=TJSONArray.Create;
  aJSON.Add('content', ContentArray);
  for i:=0 to Length(Content) - 1 do
    ContentArray.Add(Content[i].ToJSON);
  aJSON.Add('isError', IsError);
  if Assigned(Meta) and (Meta.Count > 0) then
    aJSON.Add('_meta', Meta.Clone);
end;

function TMCPToolCallResponse.ToJSON: TJSONObject;
begin
  Result:=TJSONObject.Create;
  ToJSON(Result);
end;

{ TMCPToolCall }

class function TMCPToolCall.MethodName: string;
begin
  Result:='tools/call';
end;

procedure TMCPToolCall.Reply(aData: TJSONObject);
var
  lResponse: TMCPToolCallResponse;
begin
  inherited Reply(aData);
  lResponse:=Default(TMCPToolCallResponse);
  lResponse.FromJSON(aData);
  HandleReply(lResponse);
  lResponse.Clear;
end;

procedure TMCPToolCall.HandleReply(const aResponse: TMCPToolCallResponse);
begin
  if Assigned(FOnReply) then
    FOnReply(aResponse, Default(TRPCError));
end;

procedure TMCPToolCall.HandleError(aError: TRPCError);
begin
  inherited HandleError(aError);
  if Assigned(FOnReply) then
    FOnReply(Default(TMCPToolCallResponse), aError);
end;

procedure TMCPToolCall.Call(const aToolName: string; const aArguments: TMCPToolCallArguments);
var
  lObj: TJSONObject;
begin
  lObj:=TJSONObject.Create;
  try
    lObj.Add('name', aToolName);
    if Assigned(aArguments.Arguments) then
      lObj.Add('arguments', aArguments.Arguments.Clone);
    inherited Call(lObj);
  except
    lObj.Free;
    raise;
  end;
end;

procedure TMCPToolCall.Call(const aToolName: string; aArguments: TJSONObject);
var
  ToolArgs: TMCPToolCallArguments;
begin
  ToolArgs.Initialize(aArguments);
  try
    Call(aToolName, ToolArgs);
  finally
    ToolArgs.Clear;
  end;
end;

procedure TMCPToolCall.Call(const aToolName: string; const aArguments: array of string);
var
  ArgsObj: TJSONObject;
  i: Integer;
begin
  if ((Length(aArguments) mod 2) = 1) then
    raise EMCPClient.Create('Number of arguments must be even');

  ArgsObj:=TJSONObject.Create;
  try
    i:=0;
    while i < Length(aArguments) do
      begin
      ArgsObj.Add(aArguments[i], aArguments[i + 1]);
      inc(i, 2);
      end;
    Call(aToolName, ArgsObj);
  finally
    ArgsObj.Free;
  end;
end;

// Tools/Call helper functions
function CreateToolCallArguments(aArguments: TJSONObject): TMCPToolCallArguments;
begin
  Result.Initialize(aArguments);
end;

function CreateToolCallResponseFromJSON(aJSON: TJSONObject): TMCPToolCallResponse;
begin
  Result.FromJSON(aJSON);
end;

end.


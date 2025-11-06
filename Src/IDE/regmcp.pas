{
    This file is part of the Free Component Library

    MCP class registration
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit regmcp;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  ProjectIntf,
  system.uitypes,
  frmmcptoolopts,
  mcp.dispatcher.base;

Type
  { TMCPToolDef }

  TMCPToolDef = class(TFileDescPascalUnit)
  private
    FToolName : String;
    FToolDescr : String;
    FToolClassName : string;
    FToolRegister : boolean;
    FToolResult : TToolReturn;
    function GetResultParam: String;
  public
    function Init(var {%H-}NewFilename: string; {%H-}NewOwner: TObject;
                  var {%H-}NewSource: string; {%H-}Quiet: boolean): TModalResult; override;
    function ShowOptionDialog : TModalResult;
    function GetInterfaceUsesSection: string; override;
    function GetInterfaceSource(const {%H-}aFilename, {%H-}aSourceName,
                                {%H-}aResourceName: string): string; override;
    function GetImplementationSource(const {%H-}aFilename, {%H-}aSourceName,
                                     {%H-}aResourceName: string): string; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
  end;


procedure Register;

implementation

uses
  sysutils,
  forms,
  NewItemIntf,
  mcpstrings,
  mcp.handler,
  mcp.dispatcher.serversocket,
  mcp.dispatcher.clientsocket,
  mcp.controller,
  mcp.transport.http,
  mcp.transport.stdio;

{$R mcp_icons.res}

var
  MCPToolDef : TMCPToolDef;
  MCPCat : TNewIDEItemCategory;
procedure Register;

begin
  RegisterComponents(rsAITab,[TMCPSocketServer,TMCPClientSocketDispatcher,TMCPSTDIOTransport,TMCPHTTPTransport,TMCPController]);
  MCPToolDef:=TMCPToolDef.Create;
  MCPToolDef.Name:=cMCPToolName;
  MCPCat:=TNewIDEItemCategory.Create(rsMCPCategory);
  RegisterNewItemCategory(MCPCat);
  RegisterProjectFileDescriptor(MCPToolDef,rsMCPCategory);
end;

{ TMCPToolDef }

function TMCPToolDef.Init(var NewFilename: string; NewOwner: TObject;
  var NewSource: string; Quiet: boolean): TModalResult;
begin
  if not Quiet then
    Result:=ShowOptionDialog
  else
    begin
    FToolName:=rsDefaultToolName;
    FToolClassName:=cDefaultToolClassName;
    FToolDescr:=rsDefaultToolDescription;
    FToolRegister:=True;
    end;
end;

function TMCPToolDef.ShowOptionDialog: TModalResult;
var
  Frm : TMCPToolOptionsForm;
begin
  frm:=TMCPToolOptionsForm.Create(Application);
  try
    Result:=frm.ShowModal;
    if Result=mrOK then
      begin
      FToolName:=frm.ToolName;
      FToolClassName:=frm.ToolClassName;
      FToolDescr:=frm.ToolDescription;
      FToolRegister:=frm.ToolRegister;
      end;
  finally
    frm.Free;
  end;
end;

function TMCPToolDef.GetInterfaceUsesSection: string;
begin
  Result:=inherited GetInterfaceUsesSection;
  Result:=Result+', fpjson, mcp.tools, mcp.types';
end;

function TMCPToolDef.GetInterfaceSource(const aFilename, aSourceName,
  aResourceName: string): string;
var
  l : TStrings;
begin
  l:=TStringList.Create;
  try
    with l do
      begin
      Add('');
      Add('type');
      Add('');
      Add('  %s = class(TMCPTool)',[FToolClassName]);
      Add('  protected');
      Add('    Procedure DoExecute(aInput : TJSONObject; %s); override;',[GetResultParam]);
      Add('  public');
      Add('    constructor create; reintroduce;');
      Add('  end;');
      Add('');
      end;
    Result:=l.Text;
  finally
    L.free;
  end;

end;

function TMCPToolDef.GetResultParam : String;
begin
  case FToolResult of
    trSingle : Result:='out aResult : TMCPToolResult';
    trMultiple : Result:='var aResult : TMCPToolResultArray';
    trRaw : Result:='aResult : TJSONObject';
  end;
end;

function TMCPToolDef.GetImplementationSource(const aFilename, aSourceName,
  aResourceName: string): string;

  function MakeConst(aString : string) : string;
  begin
    Result:=StringReplace(aString,'''','''''',[rfReplaceAll]);
  end;
var
  l : TStrings;
begin
  l:=TStringList.Create;
  try
    with l do
      begin
      Add('');
      Add('const');
      Add('  cToolName = ''%s'';',[MakeConst(FToolName)]);
      Add('  cToolDescr = ''%s'';',[MakeConst(FToolDescr)]);
      Add('');
      if FToolRegister then
        begin
        Add('var');
        Add('  Tool : %s;',[FToolClassName]);
        Add('');
        end;
      Add('constructor %s.create;',[FToolClassName]);
      Add('');
      Add('begin');
      Add('  inherited create(cToolName,cToolDescr);');
      Add('end;');
      Add('');
      Add('Procedure %s.DoExecute(aInput : TJSONObject; %s);',[FToolClassName,GetResultParam]);
      Add('');
      Add('begin');
      Case FToolResult of
        trSingle :   Add('  aResult:=Default(TMCPToolResult);');
        trMultiple : Add('  SetLength(aResult,1);');
        trRaw :      Add('  // add key,data to aResult...');
      end;
      Add('end;');
      Add('');
      if FToolRegister then
        begin
        Add('initialization');
        Add('  Tool:=%s.Create;',[FToolClassName]);
        Add('  Tool.Register;');
        end;
      end;
    Result:=l.Text;
  finally
    l.Free;
  end;

end;

function TMCPToolDef.GetLocalizedName: string;
begin
  Result:='MCP Tool';
end;

function TMCPToolDef.GetLocalizedDescription: string;
begin
  Result:='Unit containing a single MCP tool class';
end;

initialization

end.


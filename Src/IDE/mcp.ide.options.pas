unit mcp.ide.options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls,
  IDEOptionsIntf, IDEOptEditorIntf, LazConfigStorage,
  BaseIDEIntf, mcp.ide.policy;

type
  TMCPOptionsFrame = class(TAbstractIDEOptionsEditor)
  private
    FCombos: array[Low(MCPToolNames)..High(MCPToolNames)] of TComboBox;
    FScrollBox: TScrollBox;
    procedure ComboChanged(Sender: TObject);
    procedure LoadPolicies(AConfig: TConfigStorage);
    procedure SavePolicies(AConfig: TConfigStorage);
  public
    constructor Create(AOwner: TComponent); override;
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{$R *.lfm}

const
  MCPOptionsFileName = 'mcp-options.xml';

constructor TMCPOptionsFrame.Create(AOwner: TComponent);
var
  I: Integer;
  L: TLabel;
begin
  inherited Create(AOwner);
  Align:=alClient;
  FScrollBox:=TScrollBox.Create(Self);
  FScrollBox.Parent:=Self;
  FScrollBox.Align:=alClient;
  FScrollBox.BorderStyle:=bsNone;
  for I:=Low(MCPToolNames) to High(MCPToolNames) do
    begin
    L:=TLabel.Create(Self);
    L.Parent:=FScrollBox;
    L.Caption:=MCPToolNames[I];
    L.Left:=12;
    L.Top:=12+I*42;
    L.AutoSize:=True;
    FCombos[I]:=TComboBox.Create(Self);
    FCombos[I].Parent:=FScrollBox;
    FCombos[I].Style:=csDropDownList;
    FCombos[I].Items.Add('Disabled');
    FCombos[I].Items.Add('Allowed');
    FCombos[I].Items.Add('Ask');
    FCombos[I].ItemIndex:=2;
    FCombos[I].Left:=180;
    FCombos[I].Top:=8+I*42;
    FCombos[I].Width:=120;
    FCombos[I].Tag:=I;
    FCombos[I].OnChange:=@ComboChanged;
    L:=TLabel.Create(Self);
    L.Parent:=FScrollBox;
    L.Caption:=MCPToolDescription(MCPToolNames[I]);
    L.Left:=320;
    L.Top:=12+I*42;
    L.Width:=360;
    L.Height:=34;
    L.AutoSize:=False;
    L.WordWrap:=True;
    end;
end;

procedure TMCPOptionsFrame.ComboChanged(Sender: TObject);
begin
  DoOnChange;
end;

procedure TMCPOptionsFrame.LoadPolicies(AConfig: TConfigStorage);
var
  I: Integer;
begin
  for I:=Low(MCPToolNames) to High(MCPToolNames) do
    FCombos[I].ItemIndex:=Ord(MCPToolPolicyFromName(
      AConfig.GetValue('Tools/'+MCPToolNames[I],MCPToolPolicyName(
        MCPDefaultToolPolicy(MCPToolNames[I]))),
      MCPDefaultToolPolicy(MCPToolNames[I])));
end;

procedure TMCPOptionsFrame.SavePolicies(AConfig: TConfigStorage);
var
  I: Integer;
begin
  for I:=Low(MCPToolNames) to High(MCPToolNames) do
    AConfig.SetValue('Tools/'+MCPToolNames[I],
      MCPToolPolicyName(TMCPToolPolicy(FCombos[I].ItemIndex)));
  AConfig.WriteToDisk;
end;

function TMCPOptionsFrame.GetTitle: String;
begin
  Result:='MCP Tools';
end;

procedure TMCPOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
end;

procedure TMCPOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
var
  Cfg: TConfigStorage;
begin
  Cfg:=GetIDEConfigStorage(MCPOptionsFileName,True);
  try
    LoadPolicies(Cfg);
  finally
    Cfg.Free;
  end;
end;

procedure TMCPOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
var
  Cfg: TConfigStorage;
  I: Integer;
begin
  for I:=Low(MCPToolNames) to High(MCPToolNames) do
    MCPToolPolicies[MCPToolNames[I]]:=
      TMCPToolPolicy(FCombos[I].ItemIndex);
  Cfg:=GetIDEConfigStorage(MCPOptionsFileName,False);
  try
    SavePolicies(Cfg);
  finally
    Cfg.Free;
  end;
end;

class function TMCPOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result:=nil;
end;

initialization
  RegisterIDEOptionsEditor(GroupEnvironment,TMCPOptionsFrame,
    GetFreeIDEOptionsIndex(GroupEnvironment,1000));

end.

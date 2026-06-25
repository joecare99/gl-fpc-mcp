{
  TODO demo - main form.

  Stores tasks in a TBufDataset that is persisted to a binary file next to the
  executable. Built in code (no .lfm); every control has an explicit Name so the
  MCP locator can address it, e.g. "TodoMainForm.TaskEdit" / "TodoMainForm.AddButton".
}
unit todoMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, DBGrids, DB, BufDataset;

type

  { TTodoMainForm }

  TTodoMainForm = class(TForm)
  private
    FDataset : TBufDataset;
    FSource : TDataSource;
    FGrid : TDBGrid;
    FTaskEdit : TEdit;
    FStatusLabel : TLabel;
    procedure BuildUI;
    procedure OpenDataset;
    procedure RefreshStatus;
    function DataFileName : String;
    procedure DoAddClick(aSender : TObject);
    procedure DoToggleDoneClick(aSender : TObject);
    procedure DoFormClose(aSender : TObject; var aCloseAction : TCloseAction);
  public
    // Creates the main form, its named controls and the backing dataset.
    constructor CreateNew(aOwner : TComponent; aDummy : Integer = 0); override;
  end;

var
  TodoMainForm : TTodoMainForm;

implementation

const
  FieldTitleLen = 200;

constructor TTodoMainForm.CreateNew(aOwner : TComponent; aDummy : Integer = 0);

begin
  inherited CreateNew(aOwner, aDummy);
  BuildUI;
  OpenDataset;
  RefreshStatus;
end;


function TTodoMainForm.DataFileName : String;

begin
  Result := ExtractFilePath(ParamStr(0)) + 'todo.dat';
end;


procedure TTodoMainForm.BuildUI;

var
  lTaskLabel : TLabel;
  lAddButton, lDoneButton : TButton;

begin
  Name := 'TodoMainForm';
  Caption := 'TODO';
  Position := poScreenCenter;
  ClientWidth := 520;
  ClientHeight := 360;

  lTaskLabel := TLabel.Create(Self);
  lTaskLabel.Name := 'TaskLabel';
  lTaskLabel.Parent := Self;
  lTaskLabel.SetBounds(16, 18, 60, 20);
  lTaskLabel.Caption := 'Task:';

  FTaskEdit := TEdit.Create(Self);
  FTaskEdit.Name := 'TaskEdit';
  FTaskEdit.Parent := Self;
  FTaskEdit.SetBounds(70, 14, 290, 26);
  FTaskEdit.Text := '';

  lAddButton := TButton.Create(Self);
  lAddButton.Name := 'AddButton';
  lAddButton.Parent := Self;
  lAddButton.SetBounds(370, 13, 60, 28);
  lAddButton.Caption := 'Add';
  lAddButton.OnClick := @DoAddClick;

  lDoneButton := TButton.Create(Self);
  lDoneButton.Name := 'DoneButton';
  lDoneButton.Parent := Self;
  lDoneButton.SetBounds(438, 13, 66, 28);
  lDoneButton.Caption := 'Done';
  lDoneButton.OnClick := @DoToggleDoneClick;

  FGrid := TDBGrid.Create(Self);
  FGrid.Name := 'TodoGrid';
  FGrid.Parent := Self;
  FGrid.SetBounds(16, 52, 488, 274);
  FGrid.ReadOnly := True;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Name := 'StatusLabel';
  FStatusLabel.Parent := Self;
  FStatusLabel.SetBounds(16, 332, 488, 20);
  FStatusLabel.Caption := '';

  OnClose := @DoFormClose;
end;


procedure TTodoMainForm.OpenDataset;

begin
  FDataset := TBufDataset.Create(Self);
  FDataset.Name := 'TodoDataset';
  FDataset.FileName := DataFileName;

  if FileExists(DataFileName) then
    FDataset.Open
  else
    begin
    FDataset.FieldDefs.Add('Title', ftString, FieldTitleLen);
    FDataset.FieldDefs.Add('Done', ftBoolean);
    FDataset.FieldDefs.Add('Created', ftDateTime);
    FDataset.CreateDataset;
    end;

  FSource := TDataSource.Create(Self);
  FSource.Name := 'TodoSource';
  FSource.DataSet := FDataset;
  FGrid.DataSource := FSource;
end;


procedure TTodoMainForm.RefreshStatus;

begin
  FStatusLabel.Caption := Format('%d task(s)', [FDataset.RecordCount]);
end;


procedure TTodoMainForm.DoAddClick(aSender : TObject);

begin
  if Trim(FTaskEdit.Text) = '' then
    begin
    FStatusLabel.Caption := 'Enter a task before adding.';
    Exit;
    end;
  FDataset.Append;
  FDataset.FieldByName('Title').AsString := Trim(FTaskEdit.Text);
  FDataset.FieldByName('Done').AsBoolean := False;
  FDataset.FieldByName('Created').AsDateTime := Now;
  FDataset.Post;
  FDataset.SaveToFile(DataFileName);
  FTaskEdit.Text := '';
  RefreshStatus;
end;


procedure TTodoMainForm.DoToggleDoneClick(aSender : TObject);

begin
  if FDataset.IsEmpty then
    Exit;
  FDataset.Edit;
  FDataset.FieldByName('Done').AsBoolean := not FDataset.FieldByName('Done').AsBoolean;
  FDataset.Post;
  FDataset.SaveToFile(DataFileName);
end;


procedure TTodoMainForm.DoFormClose(aSender : TObject; var aCloseAction : TCloseAction);

begin
  if FDataset.Active then
    FDataset.SaveToFile(DataFileName);
end;


end.

{
  TODO demo - login form.

  Built entirely in code (no .lfm) so the whole demo is self-contained. Every
  control is given an explicit Name so the MCP locator can address it by a
  dotted path, e.g. "LoginForm.UserNameEdit".
}
unit todoLogin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls;

type

  { TLoginForm }

  TLoginForm = class(TForm)
  private
    FUserNameEdit : TEdit;
    FPasswordEdit : TEdit;
    FMessageLabel : TLabel;
    procedure BuildUI;
    procedure DoLoginClick(aSender : TObject);
  public
    // Creates the login form and all of its named child controls.
    constructor CreateNew(aOwner : TComponent; aDummy : Integer = 0); override;
  end;

// Shows the login form modally; returns True only when valid credentials were accepted.
function ExecuteLogin : Boolean;

implementation

uses
  todoAuth;

constructor TLoginForm.CreateNew(aOwner : TComponent; aDummy : Integer = 0);

begin
  inherited CreateNew(aOwner, aDummy);
  BuildUI;
end;


procedure TLoginForm.BuildUI;

var
  lUserLabel, lPasswordLabel : TLabel;
  lLoginButton, lCancelButton : TButton;

begin
  Name := 'LoginForm';
  Caption := 'TODO - Login';
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  ClientWidth := 320;
  ClientHeight := 170;

  lUserLabel := TLabel.Create(Self);
  lUserLabel.Name := 'UserNameLabel';
  lUserLabel.Parent := Self;
  lUserLabel.SetBounds(16, 18, 80, 20);
  lUserLabel.Caption := 'Username:';

  FUserNameEdit := TEdit.Create(Self);
  FUserNameEdit.Name := 'UserNameEdit';
  FUserNameEdit.Parent := Self;
  FUserNameEdit.SetBounds(110, 14, 190, 26);
  FUserNameEdit.Text := '';

  lPasswordLabel := TLabel.Create(Self);
  lPasswordLabel.Name := 'PasswordLabel';
  lPasswordLabel.Parent := Self;
  lPasswordLabel.SetBounds(16, 56, 80, 20);
  lPasswordLabel.Caption := 'Password:';

  FPasswordEdit := TEdit.Create(Self);
  FPasswordEdit.Name := 'PasswordEdit';
  FPasswordEdit.Parent := Self;
  FPasswordEdit.SetBounds(110, 52, 190, 26);
  FPasswordEdit.PasswordChar := '*';
  FPasswordEdit.Text := '';

  FMessageLabel := TLabel.Create(Self);
  FMessageLabel.Name := 'MessageLabel';
  FMessageLabel.Parent := Self;
  FMessageLabel.SetBounds(16, 92, 284, 20);
  FMessageLabel.Caption := '';

  lLoginButton := TButton.Create(Self);
  lLoginButton.Name := 'LoginButton';
  lLoginButton.Parent := Self;
  lLoginButton.SetBounds(110, 124, 90, 30);
  lLoginButton.Caption := 'Login';
  lLoginButton.Default := True;
  lLoginButton.OnClick := @DoLoginClick;

  lCancelButton := TButton.Create(Self);
  lCancelButton.Name := 'CancelButton';
  lCancelButton.Parent := Self;
  lCancelButton.SetBounds(210, 124, 90, 30);
  lCancelButton.Caption := 'Cancel';
  lCancelButton.Cancel := True;
  lCancelButton.ModalResult := mrCancel;
end;


procedure TLoginForm.DoLoginClick(aSender : TObject);

begin
  if ValidateLogin(FUserNameEdit.Text, FPasswordEdit.Text) then
    ModalResult := mrOk
  else
    begin
    FMessageLabel.Caption := 'Invalid username or password.';
    FPasswordEdit.Text := '';
    end;
end;


function ExecuteLogin : Boolean;

var
  lForm : TLoginForm;

begin
  lForm := TLoginForm.CreateNew(nil);
  try
    Result := lForm.ShowModal = mrOk;
  finally
    lForm.Free;
  end;
end;


end.

{
  TODO demo - credential check.

  Validates a username/password pair against a plain .ini file. This is a test
  fixture for exercising the MCP GUI-control server, so credentials are stored
  in clear text on purpose; do not use this scheme in real software.
}
unit todoAuth;

{$mode objfpc}{$H+}

interface

// Full path of the credentials .ini file (sits next to the executable).
function CredentialsFileName : String;
// True only when aUserName/aPassword match the [Login] section of the .ini file.
function ValidateLogin(const aUserName, aPassword : String) : Boolean;

implementation

uses
  SysUtils, IniFiles;

function CredentialsFileName : String;

begin
  Result := ExtractFilePath(ParamStr(0)) + 'todo.ini';
end;


function ValidateLogin(const aUserName, aPassword : String) : Boolean;

var
  lIni : TIniFile;
  lUser, lPassword : String;

begin
  Result := False;
  if not FileExists(CredentialsFileName) then
    Exit;
  lIni := TIniFile.Create(CredentialsFileName);
  try
    lUser := lIni.ReadString('Login', 'User', '');
    lPassword := lIni.ReadString('Login', 'Password', '');
  finally
    lIni.Free;
  end;
  Result := (lUser <> '') and (aUserName = lUser) and (aPassword = lPassword);
end;


end.

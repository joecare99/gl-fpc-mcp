{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit mcpclient;

{$warn 5023 off : no warning about unused units}
interface

uses
  mcp.client.base, MCP.Client.Process, mcp.client.stdio, mcp.client.calls, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('mcpclient', @Register);
end.

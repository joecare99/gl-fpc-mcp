program guicontroltest;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms,
  mcp.lcl.mainthread, mcp.lcl.serverthread, mcp.lcl.tools.demo;

begin
  Application.Initialize;
  StartMCPControlServer(3000);
  Application.Run;
  StopMCPControlServer;
end.

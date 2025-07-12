{
    This file is part of the Free Component Library

    MCP demo server application
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

program weather;

{$define usesocket}

uses
  jsonparser,
  fpjson,
  {$ifdef usesocket}
  mcp.application.socket,
  {$else}
  mcp.application.stdio,
  {$endif}
  mcp.tools,
  mcp.resources,
  mcp.prompts;

Type

  { TApplication }
{$IFDEF usesocket}
  TApplication = class (TMCPSocketApplication)
{$ELSE}
  TApplication = class (TMCPStdioApplication)
{$endif}
    procedure DoRun; override;
  private
    procedure GetForecast(aInput: TJSONData; aOutput: TJSONObject);
  end;

  { TGetWeatherTool }

  TGetWeatherTool = class(TMCPTool)
  protected
    Procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    constructor create(const aName: string; const aDescription: string); override;
  end;


var
  Application : TApplication;

{ TGetWeatherTool }

procedure TGetWeatherTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
begin
  With aResult do
    begin
    Add('City', aInput.get('location',''));
    Add('Forecast', 'Rainy');
    Add('Temperature', '25-30 degrees C');
    Add('Humidity', '60%');
    end;

end;

constructor TGetWeatherTool.create(const aName: string; const aDescription: string);
begin
  inherited create(aName, aDescription);
  InputSchema.AddArgument('location',TJSONObject.Create(['type','string']),True);
  OutputSchema.AddArgument('City',TJSONObject.Create(['type','string']),True);
  OutputSchema.AddArgument('Forecast',TJSONObject.Create(['type','string']),True);
  OutputSchema.AddArgument('Temperature',TJSONObject.Create(['type','string']),True);
  OutputSchema.AddArgument('Humidity',TJSONObject.Create(['type','string']),True);
end;

{ TApplication }

procedure TApplication.DoRun;
begin
  With TMCPResource.Create('file://weather.map','map','some map data') do
    Register;
  With TGetWeatherTool.create('getweather','Get current weather') do
    Register;
  With TMCPEventTool.create('getforecast','Get tomorrow''s weather',@GetForecast) do
    begin
    InputSchema.AddArgument('location',TJSONObject.Create(['type','string']),True);
    InputSchema.AddArgument('location',TJSONObject.Create(['type','string']),True);
    OutputSchema.AddArgument('City',TJSONObject.Create(['type','string']),True);
    OutputSchema.AddArgument('Forecast',TJSONObject.Create(['type','string']),True);
    OutputSchema.AddArgument('Temperature',TJSONObject.Create(['type','string']),True);
    OutputSchema.AddArgument('Humidity',TJSONObject.Create(['type','string']),True);
    Register;
    end;
  // Show help for the server
  if ParamStr(1) = '-h' then
    begin
    writeln('Model Context Protocol Server [',{$INCLUDE %DATE%},']: '+Title);
    Halt;
    end;
  inherited DoRun;
end;

procedure TApplication.GetForecast(aInput: TJSONData; aOutput: TJSONObject);
begin
  With aOutput do
    begin
    Add('City',(aInput as TJSONObject).get('location',''));
    Add('Forecast','Sunny');
    Add('T','30-35 degrees C');
    Add('Humidity','80%');
    end;
end;

begin
  Application:=TApplication.Create(Nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.


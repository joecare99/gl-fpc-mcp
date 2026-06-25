{
    This file is part of the Free Component Library

    MCP LCL control - security gate tests (read-only default)
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.security.test;

{$mode objfpc}{$H+}

interface

{$IFDEF MCP_GUICONTROL}
uses
  TestRegistry, Classes, SysUtils, fpjson, fpcunit,
  mcp.types, mcp.lcl.strings, mcp.lcl.control, mcp.lcl.security;

type

  { TMCPSecurityGateTest }

  TMCPSecurityGateTest = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestDeniedByDefaultRaises;
    procedure TestAllowedWhenEnabledProceeds;
    procedure TestInspectionToolUnaffectedByGate;
  end;

implementation

uses
  mcp.tools;

type

  { TTestControlTool }

  // Concrete mutating tool: records that its body ran so the gate's effect is observable.
  TTestControlTool = class(TMCPControlTool)
  protected
    procedure DoExecute(aInput : TJSONObject; aResult : TJSONObject); override;
  public
    BodyRan : Boolean;
  end;

  { TTestInspectTool }

  // Trivial inspection tool (descends TMCPTool): must run regardless of the gate.
  TTestInspectTool = class(TMCPTool)
  protected
    procedure DoExecute(aInput : TJSONObject; aResult : TJSONObject); override;
  public
    BodyRan : Boolean;
  end;


procedure TTestControlTool.DoExecute(aInput : TJSONObject; aResult : TJSONObject);

begin
  BodyRan := True;
  aResult.Add('ran', True);
end;


procedure TTestInspectTool.DoExecute(aInput : TJSONObject; aResult : TJSONObject);

begin
  BodyRan := True;
  aResult.Add('ran', True);
end;


{ TMCPSecurityGateTest }

procedure TMCPSecurityGateTest.SetUp;

begin
  inherited SetUp;
  // Reset to the read-only default so no test leaks the global into the next.
  SetGUIControlAllowed(False);
end;


procedure TMCPSecurityGateTest.TearDown;

begin
  SetGUIControlAllowed(False);
  inherited TearDown;
end;


procedure TMCPSecurityGateTest.TestDeniedByDefaultRaises;

var
  lTool : TTestControlTool;
  lInput, lResult : TJSONObject;
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #1: with control disabled (default), the gate raises EMCPException with
  // SErrControlDisabled BEFORE any subclass body runs.
  lTool := Nil;
  lInput := Nil;
  lResult := Nil;
  lRaised := False;
  lMessage := '';
  try
    lTool := TTestControlTool.Create('control', 'mutating test tool');
    lInput := TJSONObject.Create;
    lResult := TJSONObject.Create;
    try
      lTool.Execute(lInput, lResult);
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
    AssertTrue('Disabled control must raise EMCPException', lRaised);
    AssertEquals('Message must be SErrControlDisabled', SErrControlDisabled, lMessage);
    AssertFalse('Subclass body must NOT run when control is disabled', lTool.BodyRan);
  finally
    lInput.Free;
    lResult.Free;
    lTool.Free;
  end;
end;


procedure TMCPSecurityGateTest.TestAllowedWhenEnabledProceeds;

var
  lTool : TTestControlTool;
  lInput, lResult : TJSONObject;

begin
  // AC #2: once control is enabled the same tool proceeds normally - its body
  // runs and produces a result.
  lTool := Nil;
  lInput := Nil;
  lResult := Nil;
  try
    SetGUIControlAllowed(True);
    lTool := TTestControlTool.Create('control', 'mutating test tool');
    lInput := TJSONObject.Create;
    lResult := TJSONObject.Create;
    lTool.Execute(lInput, lResult);
    AssertTrue('Subclass body must run when control is enabled', lTool.BodyRan);
    AssertNotNull('Execute must populate the content array', lResult.Find('content'));
  finally
    lInput.Free;
    lResult.Free;
    lTool.Free;
  end;
end;


procedure TMCPSecurityGateTest.TestInspectionToolUnaffectedByGate;

var
  lTool : TTestInspectTool;
  lInput, lResult : TJSONObject;

begin
  // AC #3: an inspection tool (descends TMCPTool, not TMCPControlTool) runs even
  // with control disabled - the gate lives only on the control branch.
  lTool := Nil;
  lInput := Nil;
  lResult := Nil;
  try
    SetGUIControlAllowed(False);
    lTool := TTestInspectTool.Create('inspect', 'read-only test tool');
    lInput := TJSONObject.Create;
    lResult := TJSONObject.Create;
    lTool.Execute(lInput, lResult);
    AssertTrue('Inspection tool must run regardless of the gate', lTool.BodyRan);
    AssertNotNull('Execute must populate the content array', lResult.Find('content'));
  finally
    lInput.Free;
    lResult.Free;
    lTool.Free;
  end;
end;

{$ENDIF}

initialization
{$IFDEF MCP_GUICONTROL}
  RegisterTests([TMCPSecurityGateTest]);
{$ENDIF}
end.

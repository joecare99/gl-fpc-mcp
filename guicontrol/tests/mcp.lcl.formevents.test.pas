{
    This file is part of the Free Component Library

    MCP LCL control - live form open/close event push tests (GUI runner)
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.formevents.test;

{$mode objfpc}{$H+}

interface

{$IFDEF MCP_GUICONTROL}

uses
  TestRegistry, Classes, SysUtils, fpjson, httpdefs, Forms, fpcunit,
  mcp.transport.base, mcp.controller, mcp.lcl.formevents;

{$IF DECLARED(THTTPServerEvent)}
{$DEFINE USE_EVENTS}
{$ENDIF}

type

  { TSpyTransport }

  // Captures emissions without a live socket. It records the plain message string
  // passed to DoSendDiagnostic; the notifications/message JSON envelope is the http
  // transport's already-tested responsibility (TMCPHTTPTransport.DoSendDiagnostic) -
  // the spy proves the broadcast fired with the right form identity.
  TSpyTransport = class(TMCPMessageTransport)
  protected
    procedure DoSendMessage(aMessage: TJSONData); override;        // unused; empty body
    procedure DoSendDiagnostic(const aMessage: UTF8String); override; // capture here
  public
    DiagnosticCount: Integer;
    LastDiagnostic: string;
  end;

  { TMCPFormEventsTest }

  TMCPFormEventsTest = class(TTestCase)
  private
    FSpy : TSpyTransport;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    {$IFDEF USE_EVENTS}
    procedure TestFormOpenEmitsNotification;
    procedure TestFormCloseEmitsNotification;
    procedure TestHooksRemovedNoEmission;
    procedure TestInstallIsIdempotent;
    {$ENDIF}
    procedure TestHookProcsAreCallable;
  end;

{$ENDIF}

implementation

{$IFDEF MCP_GUICONTROL}

{$IFDEF USE_EVENTS}
type
  // A distinctly-named fixture: the LCL calls Screen.AddForm inside CreateNew (before
  // any Name/LFM streaming is applied), so at open time the form has no instance Name
  // and FormIdentity falls back to ClassName. Asserting on this unique class name proves
  // the open emission carries the form's class identity (AC #1's "...and class").
  TEvtOpenForm = class(TForm)
  end;
{$ENDIF}

{ TSpyTransport }

procedure TSpyTransport.DoSendMessage(aMessage: TJSONData);

begin
  // Unused by these tests: notifications go out via DoSendDiagnostic.
end;


procedure TSpyTransport.DoSendDiagnostic(const aMessage: UTF8String);

begin
  LastDiagnostic := aMessage;
  Inc(DiagnosticCount);
end;


{ TMCPFormEventsTest }

procedure TMCPFormEventsTest.SetUp;

begin
  inherited SetUp;
  FSpy := TSpyTransport.Create(nil);
  TMCPController.Instance.RegisterTransport(FSpy);
end;


procedure TMCPFormEventsTest.TearDown;

begin
  TMCPController.Instance.UnRegisterTransport(FSpy);
  // Defensive: ensure no test leaves the Screen hooks installed.
  RemoveFormEventHooks;
  FreeAndNil(FSpy);
  inherited TearDown;
end;


{$IFDEF USE_EVENTS}
procedure TMCPFormEventsTest.TestFormOpenEmitsNotification;

var
  lForm : TEvtOpenForm;

begin
  lForm := Nil;
  InstallFormEventHooks;
  FSpy.DiagnosticCount := 0;
  try
    // Creation itself fires snFormAdded (Screen.AddForm is called in CreateNew).
    lForm := TEvtOpenForm.CreateNew(nil);
    AssertTrue('A diagnostic must fire on form open', FSpy.DiagnosticCount >= 1);
    AssertTrue('Diagnostic identifies the opened form by class',
      Pos('TEvtOpenForm', FSpy.LastDiagnostic) > 0);
    AssertTrue('Diagnostic marks the form as opened',
      Pos('opened', FSpy.LastDiagnostic) > 0);
  finally
    RemoveFormEventHooks;
    lForm.Free;
  end;
end;


procedure TMCPFormEventsTest.TestFormCloseEmitsNotification;

var
  lForm : TForm;

begin
  lForm := Nil;
  InstallFormEventHooks;
  try
    lForm := TForm.CreateNew(nil);
    lForm.Name := 'EvtCloseForm';
    FSpy.DiagnosticCount := 0;
    FreeAndNil(lForm);
    AssertTrue('A diagnostic must fire on form close', FSpy.DiagnosticCount >= 1);
    AssertTrue('Diagnostic identifies the closed form by name',
      Pos('EvtCloseForm', FSpy.LastDiagnostic) > 0);
    AssertTrue('Diagnostic marks the form as closed',
      Pos('closed', FSpy.LastDiagnostic) > 0);
  finally
    RemoveFormEventHooks;
    lForm.Free;
  end;
end;


procedure TMCPFormEventsTest.TestHooksRemovedNoEmission;

var
  lForm : TForm;

begin
  lForm := Nil;
  InstallFormEventHooks;
  RemoveFormEventHooks;
  FSpy.DiagnosticCount := 0;
  try
    lForm := TForm.CreateNew(nil);
    lForm.Name := 'EvtRemovedForm';
    FreeAndNil(lForm);
    // No handler may still be firing: removal must leave no dangling reference.
    AssertEquals('No diagnostic after hooks removed', 0, FSpy.DiagnosticCount);
  finally
    lForm.Free;
  end;
end;


procedure TMCPFormEventsTest.TestInstallIsIdempotent;

var
  lForm : TForm;

begin
  lForm := Nil;
  InstallFormEventHooks;
  InstallFormEventHooks;   // second call must not double-register
  FSpy.DiagnosticCount := 0;
  try
    lForm := TForm.CreateNew(nil);
    lForm.Name := 'EvtIdempotentForm';
    AssertEquals('Exactly one diagnostic despite double install', 1, FSpy.DiagnosticCount);
  finally
    RemoveFormEventHooks;
    lForm.Free;
  end;
end;
{$ENDIF}


procedure TMCPFormEventsTest.TestHookProcsAreCallable;

begin
  // Unconditional: on 3.2.2 proves the no-op shells are callable; on trunk proves
  // install/remove are safe back-to-back.
  InstallFormEventHooks;
  RemoveFormEventHooks;
  AssertTrue('Install/Remove hooks are callable without raising', True);
end;

{$ENDIF}

initialization
{$IFDEF MCP_GUICONTROL}
  RegisterTest(TMCPFormEventsTest);
{$ENDIF}
end.

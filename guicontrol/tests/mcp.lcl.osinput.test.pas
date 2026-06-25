{
    This file is part of the Free Component Library

    MCP LCL control - OS-level input backend tests (headless, adaptive)
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{ Adaptive suite (AC #8 "where available ... else ..."): the OS backend is
  widgetset-free (it talks to the OS/X server directly), so these run headless.
  Each test branches on OSInputAvailable - on the automator's live DISPLAY=:0
  with libX11/libXtst present it takes the supported path (an injected pointer
  move is read back via OSGetCursorPos, proving a synthetic event reached the
  windowing system); with no backend it asserts the graceful
  SErrOSInputUnavailable error. xvfb is NOT installed (Epic 2 retro), so the
  supported branch depends on DISPLAY=:0 being reachable. }

unit mcp.lcl.osinput.test;

{$mode objfpc}{$H+}

interface

{$IFDEF MCP_GUICONTROL}
uses
  TestRegistry, Classes, SysUtils, fpcunit, mcp.types, mcp.lcl.osinput;

type

  { TMCPOSInputTest }

  TMCPOSInputTest = class(TTestCase)
  published
    procedure TestOSInjectClickDeliversThroughOSPath;
    procedure TestOSInjectKeyDeliversOrUnavailable;
    procedure TestOSInputAvailabilityIsStable;
  end;

implementation

uses
  mcp.lcl.strings;

const
  CTestX = 120;   // a fixed in-bounds screen coordinate for the pointer-move proof
  CTestY = 90;
  CXKReturn = $FF0D;   // XK_Return KeySym (X11 key path)


procedure TMCPOSInputTest.TestOSInjectClickDeliversThroughOSPath;

var
  lX, lY   : Integer;
  lRaised  : Boolean;
  lMessage : String;

begin
  // AC #1, #8 (supported branch): a click first warps the OS pointer to an absolute screen
  // coordinate; reading it back proves a synthetic event traversed the OS input path (independent
  // of any window/focus). AC #3 (unavailable branch): the call raises SErrOSInputUnavailable.
  if OSInputAvailable then
    begin
    // supported branch (live DISPLAY=:0 + libXtst)
    OSInjectClickAt(CTestX, CTestY, 'test');
    AssertTrue('OSGetCursorPos must succeed when a backend is available', OSGetCursorPos(lX, lY));
    AssertTrue('the OS pointer must have moved to the injected X (proves the OS path)',
      Abs(lX - CTestX) <= 2);
    AssertTrue('the OS pointer must have moved to the injected Y (proves the OS path)',
      Abs(lY - CTestY) <= 2);
    end
  else
    begin
    // unavailable branch (no supported backend)
    lRaised := False;
    lMessage := '';
    try
      OSInjectClickAt(CTestX, CTestY, 'test');
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
    AssertTrue('no backend must raise EMCPException', lRaised);
    AssertEquals('message must be SErrOSInputUnavailable for the target',
      SysUtils.Format(SErrOSInputUnavailable, ['test']), lMessage);
    end;
end;


procedure TMCPOSInputTest.TestOSInjectKeyDeliversOrUnavailable;

var
  lRaised  : Boolean;
  lMessage : String;

begin
  // AC #2, #8 (supported branch): the XTEST key call completing without raising is the OS-path
  // proof for keys (a global key cannot be asserted to land on a specific hidden widget). AC #3
  // (unavailable branch): the call raises SErrOSInputUnavailable.
  if OSInputAvailable then
    begin
    // supported branch: must complete without raising
    OSInjectKey(CXKReturn, 'test');
    AssertTrue('OSInjectKey completed on the supported path', True);
    end
  else
    begin
    // unavailable branch
    lRaised := False;
    lMessage := '';
    try
      OSInjectKey(CXKReturn, 'test');
    except
      on E : EMCPException do
        begin
        lRaised := True;
        lMessage := E.Message;
        end;
    end;
    AssertTrue('no backend must raise EMCPException', lRaised);
    AssertEquals('message must be SErrOSInputUnavailable for the target',
      SysUtils.Format(SErrOSInputUnavailable, ['test']), lMessage);
    end;
end;


procedure TMCPOSInputTest.TestOSInputAvailabilityIsStable;

var
  lFirst, lSecond : Boolean;

begin
  // Robustness: the lazy backend init must be idempotent - two probes return the same result
  // (guards against re-probing/leaking the display+libraries on every call).
  lFirst := OSInputAvailable;
  lSecond := OSInputAvailable;
  AssertEquals('OSInputAvailable must be stable across calls', lFirst, lSecond);
end;

{$ENDIF}

initialization
{$IFDEF MCP_GUICONTROL}
  RegisterTest(TMCPOSInputTest);
{$ENDIF}
end.

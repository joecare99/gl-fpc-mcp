{
    This file is part of the Free Component Library

    MCP LCL control - OS-level input backend (platform-gated)
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{ OS-level mouse/key injection: 
  synthesizes real OS input events that traverse the windowing system 
  as a physical device would - SendInput on Windows, XTEST on X11 - 
  the higher-fidelity sibling of the LCL-level LCLMessageGlue path 

  Platform isolation: 
  all platform-conditional code lives here (Windows / Linux-X11 / unsupported-fallback). 
  The control tools stay platform-agnostic 
  - they call OSInjectKey/OSInjectClickAt and never see SendInput/XTEST.

  Widgetset-free (headless-safe): it talks to the OS directly via the Windows
  API or dynamically-loaded libX11/libXtst (no Controls/Forms/Graphics), so it
  links into the no-widgetset binaries exactly like mcp.lcl.accessors. The LCL
  part (resolve target, compute screen coords, focus) lives in the tool, which
  is already visual.

  X11 entry points are loaded dynamically (dynlibs) rather than via the FPC x11  package: 
  
  that adds no FPC-package dependency, builds identically on FPC 3.2.2 and 3.3.1.

  Threading contract: the backend is initialized lazily and used only on the GUI
  main thread, inside tool *OnMain methods. 
  }

unit mcp.lcl.osinput;

{$mode objfpc}{$H+}

interface


uses
  Classes, SysUtils;

// True when a working OS input backend is available on this platform
// (Windows: always; Linux: libX11+libXtst loaded AND a display opened).
function OSInputAvailable: Boolean;
// Synthesizes an OS-level key press+release for aKey (Windows: a VK code;
// X11: an X KeySym, mapped to a keycode via XKeysymToKeycode). Raises
// EMCPException(SErrOSInputUnavailable, aWhat) when no backend is available.
procedure OSInjectKey(aKey: Integer; const aWhat: string);
// Moves the OS pointer to absolute screen (aScreenX, aScreenY) and synthesizes
// a left button press+release there. Raises EMCPException(SErrOSInputUnavailable, aWhat)
// when no backend is available.
procedure OSInjectClickAt(aScreenX, aScreenY: Integer; const aWhat: string);
// Reads the current OS pointer position. Returns False when no backend is
// available (used by the supported-path test to prove a move was delivered).
function OSGetCursorPos(out aX, aY: Integer): Boolean;

implementation

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  {$IF defined(LINUX)}
  ctypes, dynlibs,
  {$ENDIF}
  mcp.types, mcp.lcl.strings;

{$IFDEF WINDOWS}

{ Windows arm - SendInput. Compile-verified on Windows only; the Linux automator
  never parses this branch. }

function OSInputAvailable: Boolean;

begin
  Result := True;
end;


procedure OSInjectKey(aKey: Integer; const aWhat: string);

var
  lInputs : array[0..1] of TInput;

begin
  if not OSInputAvailable then
    raise EMCPException.CreateFmt(SErrOSInputUnavailable, [aWhat]);
  FillChar(lInputs, SizeOf(lInputs), 0);
  lInputs[0].Itype := INPUT_KEYBOARD;
  lInputs[0].ki.wVk := Word(aKey);
  lInputs[1].Itype := INPUT_KEYBOARD;
  lInputs[1].ki.wVk := Word(aKey);
  lInputs[1].ki.dwFlags := KEYEVENTF_KEYUP;
  SendInput(2, lInputs[0], SizeOf(TInput));
end;


procedure OSInjectClickAt(aScreenX, aScreenY: Integer; const aWhat: string);

var
  lInputs : array[0..1] of TInput;

begin
  if not OSInputAvailable then
    raise EMCPException.CreateFmt(SErrOSInputUnavailable, [aWhat]);
  SetCursorPos(aScreenX, aScreenY);
  FillChar(lInputs, SizeOf(lInputs), 0);
  lInputs[0].Itype := INPUT_MOUSE;
  lInputs[0].mi.dwFlags := MOUSEEVENTF_LEFTDOWN;
  lInputs[1].Itype := INPUT_MOUSE;
  lInputs[1].mi.dwFlags := MOUSEEVENTF_LEFTUP;
  SendInput(2, lInputs[0], SizeOf(TInput));
end;


function OSGetCursorPos(out aX, aY: Integer): Boolean;

var
  lPt : TPoint;

begin
  aX := 0;
  aY := 0;
  Result := Windows.GetCursorPos(lPt);
  if Result then
    begin
    aX := lPt.X;
    aY := lPt.Y;
    end;
end;

{$ELSE}
{$IF defined(LINUX)}

{ Linux arm - X11/XTEST, dynamically loaded (no FPC x11/xtst package, no -lX11). }

type
  TXOpenDisplay        = function(name: PChar): Pointer; cdecl;
  TXCloseDisplay       = function(dpy: Pointer): cint; cdecl;
  TXFlush              = function(dpy: Pointer): cint; cdecl;
  TXKeysymToKeycode    = function(dpy: Pointer; ks: culong): cuchar; cdecl;
  TXDefaultRootWindow  = function(dpy: Pointer): culong; cdecl;
  TXQueryPointer       = function(dpy: Pointer; w: culong; root, child: pculong;
                                  rx, ry, wx, wy: pcint; mask: pcuint): cint; cdecl;
  TXTestFakeKeyEvent   = function(dpy: Pointer; keycode: cuint; is_press: cint; delay: culong): cint; cdecl;
  TXTestFakeButtonEvent= function(dpy: Pointer; button: cuint; is_press: cint; delay: culong): cint; cdecl;
  TXTestFakeMotionEvent= function(dpy: Pointer; screen: cint; x, y: cint; delay: culong): cint; cdecl;

var
  GBackendTried : Boolean = False;
  GAvailable    : Boolean = False;
  GLibX11       : TLibHandle = NilHandle;
  GLibXtst      : TLibHandle = NilHandle;
  GDisplay      : Pointer = nil;
  _XOpenDisplay        : TXOpenDisplay;
  _XCloseDisplay       : TXCloseDisplay;
  _XFlush              : TXFlush;
  _XKeysymToKeycode    : TXKeysymToKeycode;
  _XDefaultRootWindow  : TXDefaultRootWindow;
  _XQueryPointer       : TXQueryPointer;
  _XTestFakeKeyEvent   : TXTestFakeKeyEvent;
  _XTestFakeButtonEvent: TXTestFakeButtonEvent;
  _XTestFakeMotionEvent: TXTestFakeMotionEvent;

// Closes the X display (if opened) and unloads both libraries (if loaded). Used both for
// partial-init failure cleanup and for finalization; safe to call when nothing is loaded.
procedure FreeBackend;

begin
  if (GDisplay <> nil) and Assigned(_XCloseDisplay) then
    _XCloseDisplay(GDisplay);
  GDisplay := nil;
  if GLibXtst <> NilHandle then
    begin
    UnloadLibrary(GLibXtst);
    GLibXtst := NilHandle;
    end;
  if GLibX11 <> NilHandle then
    begin
    UnloadLibrary(GLibX11);
    GLibX11 := NilHandle;
    end;
  GAvailable := False;
end;


// Lazy, idempotent backend init: load both libs, resolve every symbol, open the default
// display. Any failure degrades gracefully to unavailable (frees what loaded). Guarded by
// GBackendTried so a missing library/display is probed once, not on every call.
procedure InitBackend;

begin
  if GBackendTried then
    Exit;
  GBackendTried := True;
  GLibX11 := LoadLibrary('libX11.so.6');
  GLibXtst := LoadLibrary('libXtst.so.6');
  if (GLibX11 = NilHandle) or (GLibXtst = NilHandle) then
    begin
    FreeBackend;
    Exit;
    end;
  Pointer(_XOpenDisplay)         := GetProcedureAddress(GLibX11, 'XOpenDisplay');
  Pointer(_XCloseDisplay)        := GetProcedureAddress(GLibX11, 'XCloseDisplay');
  Pointer(_XFlush)               := GetProcedureAddress(GLibX11, 'XFlush');
  Pointer(_XKeysymToKeycode)     := GetProcedureAddress(GLibX11, 'XKeysymToKeycode');
  Pointer(_XDefaultRootWindow)   := GetProcedureAddress(GLibX11, 'XDefaultRootWindow');
  Pointer(_XQueryPointer)        := GetProcedureAddress(GLibX11, 'XQueryPointer');
  Pointer(_XTestFakeKeyEvent)    := GetProcedureAddress(GLibXtst, 'XTestFakeKeyEvent');
  Pointer(_XTestFakeButtonEvent) := GetProcedureAddress(GLibXtst, 'XTestFakeButtonEvent');
  Pointer(_XTestFakeMotionEvent) := GetProcedureAddress(GLibXtst, 'XTestFakeMotionEvent');
  if not (Assigned(_XOpenDisplay) and Assigned(_XCloseDisplay) and Assigned(_XFlush)
      and Assigned(_XKeysymToKeycode) and Assigned(_XDefaultRootWindow) and Assigned(_XQueryPointer)
      and Assigned(_XTestFakeKeyEvent) and Assigned(_XTestFakeButtonEvent)
      and Assigned(_XTestFakeMotionEvent)) then
    begin
    FreeBackend;
    Exit;
    end;
  GDisplay := _XOpenDisplay(nil);
  if GDisplay = nil then
    begin
    FreeBackend;
    Exit;
    end;
  GAvailable := True;
end;


function OSInputAvailable: Boolean;

begin
  InitBackend;
  Result := GAvailable;
end;


procedure OSInjectKey(aKey: Integer; const aWhat: string);

var
  lKeycode : cuchar;

begin
  if not OSInputAvailable then
    raise EMCPException.CreateFmt(SErrOSInputUnavailable, [aWhat]);
  lKeycode := _XKeysymToKeycode(GDisplay, culong(aKey));   // aKey is an X KeySym on Linux
  _XTestFakeKeyEvent(GDisplay, cuint(lKeycode), 1, 0);
  _XTestFakeKeyEvent(GDisplay, cuint(lKeycode), 0, 0);
  _XFlush(GDisplay);
end;


procedure OSInjectClickAt(aScreenX, aScreenY: Integer; const aWhat: string);

begin
  if not OSInputAvailable then
    raise EMCPException.CreateFmt(SErrOSInputUnavailable, [aWhat]);
  _XTestFakeMotionEvent(GDisplay, -1, aScreenX, aScreenY, 0);   // screen -1 = current/default
  _XFlush(GDisplay);
  _XTestFakeButtonEvent(GDisplay, 1, 1, 0);                     // button 1 = left
  _XTestFakeButtonEvent(GDisplay, 1, 0, 0);
  _XFlush(GDisplay);
end;


function OSGetCursorPos(out aX, aY: Integer): Boolean;

var
  lRoot, lChild     : culong;
  lRx, lRy, lWx, lWy: cint;
  lMask             : cuint;

begin
  aX := 0;
  aY := 0;
  Result := False;
  if not OSInputAvailable then
    Exit;
  if _XQueryPointer(GDisplay, _XDefaultRootWindow(GDisplay), @lRoot, @lChild,
       @lRx, @lRy, @lWx, @lWy, @lMask) <> 0 then
    begin
    aX := lRx;
    aY := lRy;
    Result := True;
    end;
end;

{$ELSE}

{ Unsupported-platform arm (e.g. Darwin) - no backend; the inject procs raise the AC #3 error. }

function OSInputAvailable: Boolean;

begin
  Result := False;
end;


procedure OSInjectKey(aKey: Integer; const aWhat: string);

begin
  raise EMCPException.CreateFmt(SErrOSInputUnavailable, [aWhat]);
end;


procedure OSInjectClickAt(aScreenX, aScreenY: Integer; const aWhat: string);

begin
  raise EMCPException.CreateFmt(SErrOSInputUnavailable, [aWhat]);
end;


function OSGetCursorPos(out aX, aY: Integer): Boolean;

begin
  aX := 0;
  aY := 0;
  Result := False;
end;

{$ENDIF}
{$ENDIF}


finalization
{$IFDEF UNIX}
  FreeBackend;
{$ENDIF}
end.

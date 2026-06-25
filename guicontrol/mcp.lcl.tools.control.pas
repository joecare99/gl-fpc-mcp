{
    This file is part of the Free Component Library

    MCP LCL control - Various control tools (TMCPControlTool): 
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.tools.control;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, mcp.types, mcp.tools, mcp.lcl.security;

type

  { TSetPropertyTool }

  // Mutating tool: sets a published property of a component addressed by a locator. Descends
  // from TMCPControlTool so the security gate (array-form DoExecute) runs before any mutation.
  TSetPropertyTool = class(TMCPControlTool)
  private
    FResult   : TJSONObject;
    FTarget   : string;
    FProperty : string;
    FValue    : TJSONData;
  protected
    // Resolves FTarget via the shared locator and writes FValue into FProperty. Always runs on
    // the main thread (reached only via RunOnMainThread); virtual so tests can observe the hop.
    procedure SetValue; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    // Declares the setProperty schema (target, property, value - all required).
    constructor Create(const aName, aDescription: string); override;
  end;

  { TInvokeActionTool }

  // Mutating tool: invokes a located control's OnClick handler, or - if none - its bound TAction.
  // Descends from TMCPControlTool so the security gate (array-form DoExecute) runs before any
  // invocation.
  TInvokeActionTool = class(TMCPControlTool)
  private
    FResult : TJSONObject;
    FTarget : string;
  protected
    // Resolves FTarget via the shared locator and fires its OnClick handler or bound action.
    // Always runs on the main thread (reached only via RunOnMainThread); virtual so tests can
    // observe the hop.
    procedure InvokeOnMain; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    // Declares the invokeAction schema (target - required).
    constructor Create(const aName, aDescription: string); override;
  end;

  { TInjectKeyTool }

  // Mutating tool: injects a key (down+up) into a located TWinControl via LCLMessageGlue, driving
  // the real widget event path so the target's OnKeyDown/OnKeyUp handlers fire. Descends from
  // TMCPControlTool so the security gate (array-form DoExecute) runs before any injection.
  TInjectKeyTool = class(TMCPControlTool)
  private
    FResult : TJSONObject;
    FTarget : string;
    FKey    : Integer;
  protected
    // Resolves FTarget via the shared locator and posts CN_KEYDOWN/CN_KEYUP messages to it.
    // Always runs on the main thread (reached only via RunOnMainThread); virtual so tests can
    // observe the hop.
    procedure InjectOnMain; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    // Declares the injectKey schema (target, key - both required).
    constructor Create(const aName, aDescription: string); override;
  end;

  { TInjectClickTool }

  // Mutating tool: injects a left mouse click (down+up) at a located control's centre via
  // LCLMessageGlue, driving the real widget event path so the target's OnMouseDown/OnMouseUp
  // handlers fire. Descends from TMCPControlTool so the security gate runs before any injection.
  TInjectClickTool = class(TMCPControlTool)
  private
    FResult : TJSONObject;
    FTarget : string;
  protected
    // Resolves FTarget via the shared locator and posts LM_LBUTTONDOWN/LM_LBUTTONUP messages at
    // the control's centre. Always runs on the main thread (reached only via RunOnMainThread);
    // virtual so tests can observe the hop.
    procedure InjectOnMain; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    // Declares the injectClick schema (target - required).
    constructor Create(const aName, aDescription: string); override;
  end;

  { TInjectOsKeyTool }

  // Mutating tool: injects an OS-level key (down+up) through the OS input path (SendInput on
  // Windows, XTEST on X11) after best-effort focus of a located TWinControl, so input fidelity
  // matches a real user. Descends from TMCPControlTool so the security gate runs before any
  // injection; raises SErrOSInputUnavailable when no OS backend is available.
  TInjectOsKeyTool = class(TMCPControlTool)
  private
    FResult : TJSONObject;
    FTarget : string;
    FKey    : Integer;
  protected
    // Resolves FTarget, best-effort focuses it, then injects FKey via the OS input backend.
    // Always runs on the main thread (reached only via RunOnMainThread); virtual so tests can
    // observe the hop and prove no OS call ran when the gate denied control.
    procedure InjectOnMain; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    // Declares the injectOsKey schema (target, key - both required).
    constructor Create(const aName, aDescription: string); override;
  end;

  { TInjectOsClickTool }

  // Mutating tool: injects an OS-level left mouse click (down+up) at a located control's screen
  // centre through the OS input path (SendInput on Windows, XTEST on X11), so input fidelity
  // matches a real user. Descends from TMCPControlTool so the security gate runs before any
  // injection; raises SErrOSInputUnavailable when no OS backend is available.
  TInjectOsClickTool = class(TMCPControlTool)
  private
    FResult : TJSONObject;
    FTarget : string;
  protected
    // Resolves FTarget, computes its screen-space centre, then injects a click there via the OS
    // input backend. Always runs on the main thread (reached only via RunOnMainThread); virtual
    // so tests can observe the hop and prove no OS call ran when the gate denied control.
    procedure InjectOnMain; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    // Declares the injectOsClick schema (target - required).
    constructor Create(const aName, aDescription: string); override;
  end;

  { TWaitForPropertyTool }

  // Synchronization tool: polls a located component's published property until it equals an
  // expected value, or raises SErrWaitTimeout after timeoutMs. Descends from TMCPControlTool so
  // the security gate (array-form DoExecute) runs before any poll - even though the body only
  // reads, the architecture places waitForProperty on the control side of the boundary.
  TWaitForPropertyTool = class(TMCPControlTool)
  private
    FResult    : TJSONObject;
    FTarget    : string;
    FProperty  : string;
    FExpected  : string;
    FTimeoutMs : Integer;
    FMatched   : Boolean;
  protected
    // Resolves FTarget, reads FProperty and compares it to FExpected, setting FMatched. Always
    // runs on the main thread (reached only via the bounded RunOnMainThread); virtual so tests
    // can observe the hop and prove no poll ran when the gate denied control.
    procedure PollOnce; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    // Declares the waitForProperty schema (target, property, value, timeoutMs - all required).
    constructor Create(const aName, aDescription: string); override;
  end;

  { TWriteAccessorTool }

  // Mutating tool: writes a host-registered named accessor (non-published state) on a component
  // addressed by a locator. Descends from TMCPControlTool so the security gate (array-form
  // DoExecute) runs before any mutation.
  TWriteAccessorTool = class(TMCPControlTool)
  private
    FResult : TJSONObject;
    FTarget : string;
    FName   : string;
    FValue  : string;
  protected
    // Resolves FTarget via the shared locator and writes FValue through the named accessor. Always
    // runs on the main thread (reached only via RunOnMainThread); virtual so tests can observe the hop.
    procedure WriteOnMain; virtual;
    procedure DoExecute(aInput: TJSONObject; aResult: TJSONObject); override;
  public
    // Declares the writeAccessor schema (target, name, value - all required).
    constructor Create(const aName, aDescription: string); override;
  end;

// Registers the control tools (setProperty, invokeAction, injectKey, injectClick, waitForProperty,
// writeAccessor, injectOsKey, injectOsClick) into the global tool registry.
// Call ONCE from the host app (e.g. before StartGUIControlServer).
procedure RegisterControlTools;

implementation


uses
  mcp.lcl.mainthread, mcp.lcl.locator, mcp.lcl.serialize, mcp.lcl.strings, mcp.lcl.accessors,
  mcp.lcl.osinput, Controls, LCLMessageGlue, Types;

const
  CWaitPollIntervalMs = 25;   // gap between polls; small but not a busy-spin

type
  // Cracker: exposes the protected OnClick of TControl so the tool can detect/fire it.
  TControlAccess = class(TControl);

{ TSetPropertyTool }

constructor TSetPropertyTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('property', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('value', TJSONObject.Create(['type', 'string']), True);
end;


procedure TSetPropertyTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: read input, then marshal the LCL access to the main thread. The
// gate is inherited from TMCPControlTool's array-form DoExecute, which runs ahead of this body.

begin
  FTarget   := aInput.Get('target', '');
  FProperty := aInput.Get('property', '');
  FValue    := aInput.Find('value');   // borrowed ref into aInput; do NOT free
  FResult   := aResult;
  RunOnMainThread(@SetValue);
end;


procedure TSetPropertyTool.SetValue;   // runs on the GUI main thread

var
  lComp : TComponent;

begin
  lComp := ResolveTarget(FTarget);                       // raises SErrLocatorNotFound
  WritePublishedProperty(lComp, FProperty, FValue);      // raises SErrNoProperty / SErrPropertyType
  FResult.Add('ok', True);
end;


{ TInvokeActionTool }

constructor TInvokeActionTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
end;


procedure TInvokeActionTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: read input, then marshal the LCL access to the main thread. The
// gate is inherited from TMCPControlTool's array-form DoExecute, which runs ahead of this body.

begin
  FTarget := aInput.Get('target', '');
  FResult := aResult;
  RunOnMainThread(@InvokeOnMain);
end;


procedure TInvokeActionTool.InvokeOnMain;   // runs on the GUI main thread

var
  lComp : TComponent;

begin
  lComp := ResolveTarget(FTarget);                         // raises SErrLocatorNotFound
  if lComp is TControl then
    begin
    if Assigned(TControlAccess(lComp).OnClick) then
      TControlAccess(lComp).OnClick(lComp)                 // fire handler, Sender = control
    else if Assigned(TControl(lComp).Action) then
      TControl(lComp).Action.Execute                       // bound action
    else
      raise EMCPException.CreateFmt(SErrNotActionable, [FTarget]);
    end
  else
    raise EMCPException.CreateFmt(SErrNotActionable, [FTarget]);
  FResult.Add('ok', True);
end;


{ TInjectKeyTool }

constructor TInjectKeyTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('key', TJSONObject.Create(['type', 'integer']), True);
end;


procedure TInjectKeyTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: read input, then marshal the LCL access to the main thread. The
// gate is inherited from TMCPControlTool's array-form DoExecute, which runs ahead of this body.

begin
  FTarget := aInput.Get('target', '');
  FKey    := aInput.Get('key', 0);
  FResult := aResult;
  RunOnMainThread(@InjectOnMain);
end;


procedure TInjectKeyTool.InjectOnMain;   // runs on the GUI main thread

var
  lComp : TComponent;
  lCode : Word;

begin
  lComp := ResolveTarget(FTarget);                         // raises SErrLocatorNotFound
  if lComp is TWinControl then
    begin
    lCode := Word(FKey);
    LCLSendKeyDownEvent(TWinControl(lComp), lCode, 0, True, False);   // CN_KEYDOWN -> OnKeyDown
    lCode := Word(FKey);                                              // reset: KeyDown may zero it
    LCLSendKeyUpEvent(TWinControl(lComp), lCode, 0, True, False);     // CN_KEYUP  -> OnKeyUp
    end
  else
    raise EMCPException.CreateFmt(SErrNotInjectable, [FTarget]);
  FResult.Add('ok', True);
end;


{ TInjectClickTool }

constructor TInjectClickTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
end;


procedure TInjectClickTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: read input, then marshal the LCL access to the main thread. The
// gate is inherited from TMCPControlTool's array-form DoExecute, which runs ahead of this body.

begin
  FTarget := aInput.Get('target', '');
  FResult := aResult;
  RunOnMainThread(@InjectOnMain);
end;


procedure TInjectClickTool.InjectOnMain;   // runs on the GUI main thread

var
  lComp : TComponent;
  lX, lY : Integer;

begin
  lComp := ResolveTarget(FTarget);                         // raises SErrLocatorNotFound
  if lComp is TControl then
    begin
    lX := TControl(lComp).Width div 2;
    lY := TControl(lComp).Height div 2;
    LCLSendMouseDownMsg(TControl(lComp), lX, lY, mbLeft, []);
    LCLSendMouseUpMsg(TControl(lComp), lX, lY, mbLeft, []);
    end
  else
    raise EMCPException.CreateFmt(SErrNotInjectable, [FTarget]);
  FResult.Add('ok', True);
end;


{ TInjectOsKeyTool }

constructor TInjectOsKeyTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('key', TJSONObject.Create(['type', 'integer']), True);
end;


procedure TInjectOsKeyTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: read input, then marshal the LCL access + OS call to the main thread.
// The gate is inherited from TMCPControlTool's array-form DoExecute, which runs ahead of this body.

begin
  FTarget := aInput.Get('target', '');
  FKey    := aInput.Get('key', 0);
  FResult := aResult;
  RunOnMainThread(@InjectOnMain);
end;


procedure TInjectOsKeyTool.InjectOnMain;   // runs on the GUI main thread

var
  lComp : TComponent;

begin
  lComp := ResolveTarget(FTarget);                         // raises SErrLocatorNotFound
  // Best-effort focus so the OS key lands on the target where possible; this MUST NOT raise. OS
  // injection is global, so a non-window target (or one that cannot focus) simply gets no focus
  // steering - no SErrNotInjectable for keys. CanFocus alone is insufficient (LCL does not verify
  // the parent form's own visibility), so the SetFocus is also guarded against EInvalidOperation
  // (e.g. a hidden form raises "Cannot focus").
  if (lComp is TWinControl) and TWinControl(lComp).CanFocus then
    try
      TWinControl(lComp).SetFocus;
    except
      on EInvalidOperation do ;   // not focusable here; injection is global, so carry on
    end;
  OSInjectKey(FKey, FTarget);                              // raises SErrOSInputUnavailable
  FResult.Add('ok', True);
end;


{ TInjectOsClickTool }

constructor TInjectOsClickTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
end;


procedure TInjectOsClickTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: read input, then marshal the LCL access + OS call to the main thread.
// The gate is inherited from TMCPControlTool's array-form DoExecute, which runs ahead of this body.

begin
  FTarget := aInput.Get('target', '');
  FResult := aResult;
  RunOnMainThread(@InjectOnMain);
end;


procedure TInjectOsClickTool.InjectOnMain;   // runs on the GUI main thread

var
  lComp : TComponent;
  lPt   : TPoint;

begin
  lComp := ResolveTarget(FTarget);                         // raises SErrLocatorNotFound
  if lComp is TControl then
    begin
    lPt := TControl(lComp).ClientToScreen(Point(TControl(lComp).Width div 2,
                                                TControl(lComp).Height div 2));
    OSInjectClickAt(lPt.X, lPt.Y, FTarget);               // raises SErrOSInputUnavailable
    end
  else
    raise EMCPException.CreateFmt(SErrNotInjectable, [FTarget]);   // defensive; unreachable via the visual locator
  FResult.Add('ok', True);
end;


{ TWaitForPropertyTool }

constructor TWaitForPropertyTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('property', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('value', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('timeoutMs', TJSONObject.Create(['type', 'integer']), True);
end;


procedure TWaitForPropertyTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Server thread: read args, then poll the property on the main thread until it matches or the
// timeout elapses. The gate is inherited from TMCPControlTool's array-form DoExecute, which runs
// ahead of this body, so no poll happens when control is disabled.

var
  lVal      : TJSONData;
  lDeadline : QWord;
  lRemaining: Int64;

begin
  FTarget    := aInput.Get('target', '');
  FProperty  := aInput.Get('property', '');
  FTimeoutMs := aInput.Get('timeoutMs', 0);
  lVal := aInput.Find('value');                  // borrowed ref into aInput; do NOT free
  if lVal <> nil then
    FExpected := lVal.AsString                    // capture as string on the server thread
  else
    FExpected := '';
  FResult  := aResult;
  FMatched := False;
  lDeadline := GetTickCount64 + QWord(FTimeoutMs);
  repeat
    lRemaining := Int64(lDeadline) - Int64(GetTickCount64);
    if lRemaining < 1 then
      lRemaining := 1;                            // floor so the bounded bridge always gets >=1ms
    RunOnMainThread(@PollOnce, lRemaining);       // BOUNDED variant - read on the main thread
    if FMatched then
      Break;
    if GetTickCount64 >= lDeadline then
      Break;
    Sleep(CWaitPollIntervalMs);
  until False;
  if FMatched then
    FResult.Add('ok', True)
  else
    raise EMCPException.CreateFmt(SErrWaitTimeout, [FTarget + '.' + FProperty]);
end;


procedure TWaitForPropertyTool.PollOnce;   // runs on the GUI main thread

var
  lComp    : TComponent;
  lCurrent : TJSONData;

begin
  lComp := ResolveTarget(FTarget);                       // raises SErrLocatorNotFound
  lCurrent := ReadPublishedProperty(lComp, FProperty);   // raises SErrNoProperty; CALLER OWNS
  try
    FMatched := (lCurrent.AsString = FExpected);
  finally
    lCurrent.Free;                                        // ReadPublishedProperty hands ownership out
  end;
end;


{ TWriteAccessorTool }

constructor TWriteAccessorTool.Create(const aName, aDescription: string);

begin
  inherited Create(aName, aDescription);
  InputSchema.AddArgument('target', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('name', TJSONObject.Create(['type', 'string']), True);
  InputSchema.AddArgument('value', TJSONObject.Create(['type', 'string']), True);
end;


procedure TWriteAccessorTool.DoExecute(aInput: TJSONObject; aResult: TJSONObject);
// Runs on the server thread: read input, then marshal the LCL/registry access to the main thread.
// The gate is inherited from TMCPControlTool's array-form DoExecute, which runs ahead of this body.

begin
  FTarget := aInput.Get('target', '');
  FName   := aInput.Get('name', '');
  FValue  := aInput.Get('value', '');   // capture as a plain string; no borrowed-TJSONData lifetime
  FResult := aResult;
  RunOnMainThread(@WriteOnMain);
end;


procedure TWriteAccessorTool.WriteOnMain;   // runs on the GUI main thread

var
  lComp : TComponent;

begin
  lComp := ResolveTarget(FTarget);              // raises SErrLocatorNotFound
  WriteAccessor(lComp, FName, FValue);          // raises SErrNoAccessor
  FResult.Add('ok', True);
end;


procedure RegisterControlTools;

begin
  With TSetPropertyTool.Create('setProperty',
    'Set a published property of a located component (args: target, property, value)') do
    Register;
  With TInvokeActionTool.Create('invokeAction',
    'Invoke a located control''s OnClick handler or bound action (arg: target)') do
    Register;
  With TInjectKeyTool.Create('injectKey',
    'Inject a key (down+up) into a located TWinControl (args: target, key)') do
    Register;
  With TInjectClickTool.Create('injectClick',
    'Inject a left mouse click (down+up) at a located control''s centre (arg: target)') do
    Register;
  With TWaitForPropertyTool.Create('waitForProperty',
    'Wait until a located component''s published property reaches an expected value, or fail after timeoutMs (args: target, property, value, timeoutMs)') do
    Register;
  With TWriteAccessorTool.Create('writeAccessor',
    'Write a host-registered named accessor (non-published state) on a located component (args: target, name, value)') do
    Register;
  With TInjectOsKeyTool.Create('injectOsKey',
    'Inject an OS-level key (down+up) targeting a located control via the OS input path - SendInput/XTEST (args: target, key)') do
    Register;
  With TInjectOsClickTool.Create('injectOsClick',
    'Inject an OS-level left mouse click (down+up) at a located control''s screen centre via the OS input path - SendInput/XTEST (arg: target)') do
    Register;
end;

end.

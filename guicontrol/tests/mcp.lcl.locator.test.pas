{
    This file is part of the Free Component Library

    MCP LCL control - locator tests
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.locator.test;

{$mode objfpc}{$H+}

interface

{$IFDEF MCP_GUICONTROL}
uses
  TestRegistry, Classes, SysUtils, fpcunit,
  mcp.types, mcp.lcl.strings, mcp.lcl.mainthread, mcp.lcl.locator;

type

  { TMCPLocatorTest }

  TMCPLocatorTest = class(TTestCase)
  private
    FRoot         : TComponent;
    FPanel1       : TComponent;
    FOKButton     : TComponent;
    FUnnamed      : TComponent;
    FExtra        : TComponent;
    FResolved     : TComponent;
    FResolveThreadId : TThreadID;
    // Asserts ResolveTargetIn(FRoot, aLocator) raises EMCPException whose
    // message is SErrLocatorNotFound formatted with aLocator.
    procedure AssertRaisesNotFound(const aLocator: string);
    // Marshalled callback under test: resolves on whatever thread it runs on
    // and records the result plus that thread's id.
    procedure DoResolveOnMain;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestResolvesDotPathByName;
    procedure TestResolvesIndexPath;
    procedure TestResolvesMixedPath;
    procedure TestUnknownNameRaises;
    procedure TestIndexOutOfRangeRaises;
    procedure TestMalformedLocatorRaises;
    procedure TestResolvesOnMainThreadViaBridge;
  end;

implementation

type

  { TMCPLocatorWorker }

  // Worker thread that issues a bounded RunOnMainThread call and recaptures any
  // exception so the main (test) thread can assert on it after WaitFor.
  TMCPLocatorWorker = class(TThread)
  private
    FMethod    : TMCPMainThreadMethod;
    FTimeoutMs : Integer;
    FReturned  : Boolean;
    FErrClass  : TClass;
    FErrMsg    : string;
  protected
    procedure Execute; override;
  public
    constructor Create(aMethod : TMCPMainThreadMethod; aTimeoutMs : Integer);
    // True when RunOnMainThread returned normally (no exception).
    property Returned : Boolean read FReturned;
    // Class of the exception caught from RunOnMainThread, or nil if none.
    property ErrClass : TClass read FErrClass;
    // Message of the exception caught from RunOnMainThread.
    property ErrMsg : string read FErrMsg;
  end;


constructor TMCPLocatorWorker.Create(aMethod : TMCPMainThreadMethod; aTimeoutMs : Integer);

begin
  FMethod := aMethod;
  FTimeoutMs := aTimeoutMs;
  inherited Create(False);
end;


procedure TMCPLocatorWorker.Execute;

begin
  try
    RunOnMainThread(FMethod, FTimeoutMs);
    FReturned := True;
  except
    on E : Exception do
      begin
      FErrClass := E.ClassType;
      FErrMsg := E.Message;
      end;
  end;
end;


{ TMCPLocatorTest }

procedure TMCPLocatorTest.SetUp;

begin
  inherited SetUp;
  // An owner-nested TComponent tree (no LCL widgets, so the suite stays
  // headless and exercises the Components[] branch of the child model).
  // FRoot.Components[]:  0=Panel1  1=<unnamed>  2=Extra
  // FPanel1.Components[]: 0=OKButton  1=<unnamed>
  FRoot := TComponent.Create(nil);
  FRoot.Name := 'Root';
  FPanel1 := TComponent.Create(FRoot);
  FPanel1.Name := 'Panel1';
  FUnnamed := TComponent.Create(FRoot); // Name stays ''
  FExtra := TComponent.Create(FRoot);
  FExtra.Name := 'Extra';
  FOKButton := TComponent.Create(FPanel1);
  FOKButton.Name := 'OKButton';
  TComponent.Create(FPanel1); // a second, unnamed child of Panel1
  FResolved := nil;
  FResolveThreadId := 0;
end;


procedure TMCPLocatorTest.TearDown;

begin
  FRoot.Free; // frees the whole owned tree
  FRoot := nil;
  inherited TearDown;
end;


procedure TMCPLocatorTest.AssertRaisesNotFound(const aLocator: string);

var
  lClass : TClass;
  lMsg : string;

begin
  lClass := nil;
  lMsg := '';
  try
    ResolveTargetIn(FRoot, aLocator);
  except
    on E : Exception do
      begin
      lClass := E.ClassType;
      lMsg := E.Message;
      end;
  end;
  AssertNotNull('Locator "' + aLocator + '" must raise', lClass);
  AssertTrue('Locator "' + aLocator + '" must raise EMCPException', lClass.InheritsFrom(EMCPException));
  AssertEquals('Message for "' + aLocator + '"', Format(SErrLocatorNotFound, [aLocator]), lMsg);
end;


procedure TMCPLocatorTest.DoResolveOnMain;

begin
  FResolveThreadId := GetCurrentThreadID;
  FResolved := ResolveTargetIn(FRoot, 'Panel1.OKButton');
end;


procedure TMCPLocatorTest.TestResolvesDotPathByName;

begin
  // AC #1: dot-path resolves by Name, case-insensitively.
  AssertSame('Panel1.OKButton must resolve to the OK button',
    FOKButton, ResolveTargetIn(FRoot, 'Panel1.OKButton'));
  AssertSame('Name matching must be case-insensitive',
    FOKButton, ResolveTargetIn(FRoot, 'panel1.okbutton'));
end;


procedure TMCPLocatorTest.TestResolvesIndexPath;

begin
  // AC #2: a pure bracket-index path descends Components[] positionally.
  AssertSame('[0][0] must resolve to the OK button',
    FOKButton, ResolveTargetIn(FRoot, '[0][0]'));
  AssertSame('[1] must resolve to the unnamed child',
    FUnnamed, ResolveTargetIn(FRoot, '[1]'));
end;


procedure TMCPLocatorTest.TestResolvesMixedPath;

begin
  // AC #2: name and index steps interchange at any depth.
  AssertSame('Panel1[0] must resolve to the OK button',
    FOKButton, ResolveTargetIn(FRoot, 'Panel1[0]'));
  AssertSame('[0].OKButton must resolve to the OK button',
    FOKButton, ResolveTargetIn(FRoot, '[0].OKButton'));
end;


procedure TMCPLocatorTest.TestUnknownNameRaises;

begin
  // AC #3: an unknown name segment raises EMCPException(SErrLocatorNotFound).
  AssertRaisesNotFound('Nope');
end;


procedure TMCPLocatorTest.TestIndexOutOfRangeRaises;

begin
  // AC #3: an out-of-range and a negative index both raise.
  AssertRaisesNotFound('[999]');
  AssertRaisesNotFound('[-1]');
end;


procedure TMCPLocatorTest.TestMalformedLocatorRaises;

begin
  // AC #3: a malformed locator the tokenizer rejects (non-numeric index,
  // unclosed bracket, trailing separator) raises SErrLocatorNotFound too -
  // never nil, no other exception class.
  AssertRaisesNotFound('[abc]'); // non-numeric index
  AssertRaisesNotFound('[1');    // unclosed bracket
  AssertRaisesNotFound('Root.'); // trailing separator
end;


procedure TMCPLocatorTest.TestResolvesOnMainThreadViaBridge;

var
  lWorker : TMCPLocatorWorker;
  lIterations : Integer;

begin
  // AC #4: a worker marshals the resolve through the Story 1.3 bounded bridge;
  // the main thread drains it, and the resolve must run on MainThreadID.
  lWorker := TMCPLocatorWorker.Create(@DoResolveOnMain, 2000);
  try
    lIterations := 0;
    while (not lWorker.Finished) and (lIterations < 100) do // 100 * 50ms = 5s ceiling
      begin
      CheckSynchronize(50);
      Inc(lIterations);
      end;
    if not lWorker.Finished then
      Fail('Worker did not finish within the drain ceiling - possible hang');
    lWorker.WaitFor;
    AssertNull('No exception expected from a timely marshalled resolve', lWorker.ErrClass);
    AssertTrue('Worker should have returned normally', lWorker.Returned);
    AssertSame('Marshalled resolve must return the OK button', FOKButton, FResolved);
    AssertEquals('Resolve must run on the main thread', MainThreadID, FResolveThreadId);
  finally
    lWorker.Free;
  end;
end;

{$ENDIF}

initialization
{$IFDEF MCP_GUICONTROL}
  RegisterTest(TMCPLocatorTest);
{$ENDIF}
end.

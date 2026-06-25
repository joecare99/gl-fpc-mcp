{
    This file is part of the Free Component Library

    MCP LCL control - main-thread bridge tests
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.mainthread.test;

{$mode objfpc}{$H+}

interface

{$IFDEF MCP_GUICONTROL}
uses
  TestRegistry, Classes, SysUtils, syncobjs, fpcunit,
  mcp.types, mcp.lcl.strings, mcp.lcl.mainthread;

type

  { TMCPMainThreadTest }

  TMCPMainThreadTest = class(TTestCase)
  private
    FFlagSet      : Boolean;
    FFlagThreadId : TThreadID;
    // The marshalled callback under test: records that it ran and on which thread.
    procedure SetFlag;
    // Drains queued main-thread calls until the worker finishes or a hard
    // iteration ceiling is hit (so a buggy bridge fails the test, never hangs it).
    function DrainUntilFinished(aWorker : TThread; aMaxIterations : Integer) : Boolean;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRunsInlineOnMainThread;
    procedure TestCompletesWithinTimeout;
    procedure TestTimesOutWhenMainThreadBlocked;
  end;

implementation

type

  { TMCPMarshalWorker }

  // Worker thread that issues a bounded RunOnMainThread call and recaptures any
  // exception so the main (test) thread can assert on it after WaitFor.
  TMCPMarshalWorker = class(TThread)
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


constructor TMCPMarshalWorker.Create(aMethod : TMCPMainThreadMethod; aTimeoutMs : Integer);

begin
  FMethod := aMethod;
  FTimeoutMs := aTimeoutMs;
  inherited Create(False);
end;


procedure TMCPMarshalWorker.Execute;

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


{ TMCPMainThreadTest }

procedure TMCPMainThreadTest.SetUp;

begin
  inherited SetUp;
  FFlagSet := False;
  FFlagThreadId := 0;
end;


procedure TMCPMainThreadTest.TearDown;

begin
  inherited TearDown;
end;


procedure TMCPMainThreadTest.SetFlag;

begin
  FFlagSet := True;
  FFlagThreadId := GetCurrentThreadID;
end;


function TMCPMainThreadTest.DrainUntilFinished(aWorker : TThread; aMaxIterations : Integer) : Boolean;

var
  lIterations : Integer;

begin
  lIterations := 0;
  while (not aWorker.Finished) and (lIterations < aMaxIterations) do
    begin
    CheckSynchronize(50);
    Inc(lIterations);
    end;
  Result := aWorker.Finished;
end;


procedure TMCPMainThreadTest.TestRunsInlineOnMainThread;

begin
  // AC #3: called from the main thread, the bounded overload runs the method
  // inline - no queue, no draining required.
  RunOnMainThread(@SetFlag, 1000);
  AssertTrue('Method must have run inline on the main thread', FFlagSet);
  AssertEquals('Method must execute on the main thread', MainThreadID, FFlagThreadId);
end;


procedure TMCPMainThreadTest.TestCompletesWithinTimeout;

var
  lWorker : TMCPMarshalWorker;

begin
  // AC #1: a worker marshals the call; the main thread drains it within the
  // timeout, so the worker returns normally and the method ran on the main thread.
  lWorker := TMCPMarshalWorker.Create(@SetFlag, 2000);
  try
    if not DrainUntilFinished(lWorker, 100) then // 100 * 50ms = 5s hard ceiling
      Fail('Worker did not finish within the drain ceiling - possible hang');
    lWorker.WaitFor;
    AssertNull('No exception expected when the call completes in time', lWorker.ErrClass);
    AssertTrue('Worker should have returned normally', lWorker.Returned);
    AssertTrue('Marshalled method must have run', FFlagSet);
    AssertEquals('Marshalled method must run on the main thread', MainThreadID, FFlagThreadId);
  finally
    lWorker.Free;
  end;
end;


procedure TMCPMainThreadTest.TestTimesOutWhenMainThreadBlocked;

var
  lWorker : TMCPMarshalWorker;
  lIterations : Integer;

begin
  // AC #2: the main thread never drains the queue, so the bounded call must
  // time out, raise EMCPException, and the marshalled method must NOT fire.
  lWorker := TMCPMarshalWorker.Create(@SetFlag, 200);
  try
    Sleep(500); // longer than the 200ms timeout; deliberately no CheckSynchronize
    lWorker.WaitFor; // the worker ends as soon as its bounded call has timed out
    AssertNotNull('A timeout must have raised an exception', lWorker.ErrClass);
    AssertTrue('Timeout must raise EMCPException', lWorker.ErrClass.InheritsFrom(EMCPException));
    AssertEquals('Timeout message must be SErrMainThreadTimeout', SErrMainThreadTimeout, lWorker.ErrMsg);
    AssertFalse('Marshalled method must NOT run on timeout', FFlagSet);
    // Drain the now-orphaned queued call so it frees itself (no leak); it must
    // remain a no-op that never touches caller state.
    lIterations := 0;
    while lIterations < 10 do
      begin
      CheckSynchronize(50);
      Inc(lIterations);
      end;
    AssertFalse('Orphaned call must stay a no-op after a late drain', FFlagSet);
  finally
    lWorker.Free;
  end;
end;

{$ENDIF}

initialization
{$IFDEF MCP_GUICONTROL}
  RegisterTest(TMCPMainThreadTest);
{$ENDIF}
end.

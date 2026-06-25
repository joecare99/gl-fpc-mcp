{
    This file is part of the Free Component Library

    MCP LCL control - main-thread marshalling bridge
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.mainthread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TMCPMainThreadMethod = procedure of object;

  { TMCPMainThreadTask }

  // Base class for a unit of work that must run on the GUI main thread.
  // Descendants override DoRun and store their result in their own fields.
  TMCPMainThreadTask = class
  protected
    FException : Exception;
    procedure RunGuarded;
    // Performs the work. Always executed on the main (GUI) thread.
    procedure DoRun; virtual; abstract;
  public
    // Runs DoRun on the main thread and blocks until it completes.
    // Any exception raised in DoRun is re-raised on the calling thread.
    procedure Execute;
  end;

  { TMCPMethodTask }

  // Adapts an existing 'procedure of object' to a main-thread task.
  TMCPMethodTask = class(TMCPMainThreadTask)
  private
    FMethod : TMCPMainThreadMethod;
  protected
    procedure DoRun; override;
  public
    // aMethod is the callback to run on the main thread.
    constructor Create(aMethod : TMCPMainThreadMethod);
  end;

// Runs aMethod on the GUI main thread, blocking the caller until it returns.
// Safe to call from any thread; short-circuits when already on the main thread.
procedure RunOnMainThread(aMethod : TMCPMainThreadMethod); overload;
// Bounded-wait variant: runs aMethod on the main thread, giving up after
// aTimeoutMs and raising EMCPException (SErrMainThreadTimeout) instead of
// blocking forever. Short-circuits inline when already on the main thread.
procedure RunOnMainThread(aMethod : TMCPMainThreadMethod; aTimeoutMs : Integer); overload;

implementation


uses
  syncobjs,        // TEvent / TCriticalSection / TWaitResult for the bounded wait
  mcp.types,       // EMCPException
  mcp.lcl.strings; // SErrMainThreadTimeout

type

  { TMCPBoundedTask }

  // Runs a method on the GUI main thread with a bounded wait. Unlike
  // TMCPMainThreadTask (which blocks on TThread.Synchronize), it schedules the
  // work with TThread.Queue and waits on a TEvent, so the caller can give up
  // after a timeout instead of hanging forever. It is reference counted because
  // a queued call may still drain onto the main thread AFTER the waiter has
  // timed out; the orphan flag makes such a late call a no-op that never
  // touches caller state, and the last reference to drop frees the task.
  TMCPBoundedTask = class(TMCPMainThreadTask)
  private
    FMethod   : TMCPMainThreadMethod;
    FEvent    : TEvent;
    FLock     : TCriticalSection;
    FOrphaned : Boolean;
    FStarted  : Boolean;
    FRefCount : LongInt;
    procedure RunQueued;
    procedure DecRef;
  protected
    procedure DoRun; override;
  public
    // aMethod is the callback to run on the main thread.
    constructor Create(aMethod : TMCPMainThreadMethod);
    destructor Destroy; override;
    // Queues aMethod onto the main thread and waits up to aTimeoutMs for it.
    // Raises EMCPException (SErrMainThreadTimeout) if the wait expires.
    procedure ExecuteWithTimeout(aTimeoutMs : Integer);
  end;

{ TMCPMainThreadTask }

procedure TMCPMainThreadTask.RunGuarded;

begin
  try
    DoRun;
  except
    on E : Exception do
      // Capture so it survives the thread hand-off; re-raised in Execute.
      FException := Exception(AcquireExceptionObject);
  end;
end;


procedure TMCPMainThreadTask.Execute;

begin
  FException := nil;
  if GetCurrentThreadID = MainThreadID then
    RunGuarded
  else
    TThread.Synchronize(nil, @RunGuarded);
  if Assigned(FException) then
    raise FException;
end;


{ TMCPMethodTask }

constructor TMCPMethodTask.Create(aMethod : TMCPMainThreadMethod);

begin
  inherited Create;
  FMethod := aMethod;
end;


procedure TMCPMethodTask.DoRun;

begin
  FMethod();
end;


procedure RunOnMainThread(aMethod : TMCPMainThreadMethod);

var
  lTask : TMCPMethodTask;

begin
  lTask := TMCPMethodTask.Create(aMethod);
  try
    lTask.Execute;
  finally
    lTask.Free;
  end;
end;


{ TMCPBoundedTask }

constructor TMCPBoundedTask.Create(aMethod : TMCPMainThreadMethod);

begin
  inherited Create;
  FMethod := aMethod;
  FEvent := TEvent.Create(nil, True, False, ''); // manual reset, initially unset
  FLock := TCriticalSection.Create;
  FRefCount := 1; // the creator's reference
end;


destructor TMCPBoundedTask.Destroy;

begin
  FEvent.Free;
  FLock.Free;
  inherited Destroy;
end;


procedure TMCPBoundedTask.DoRun;

begin
  FMethod();
end;


procedure TMCPBoundedTask.DecRef;

begin
  if InterlockedDecrement(FRefCount) = 0 then
    Free;
end;


procedure TMCPBoundedTask.RunQueued;

var
  lRun : Boolean;

begin
  // Runs on the main thread (drained by CheckSynchronize). The orphan/run
  // decision is made atomically under the lock: if the waiter has already timed
  // out (FOrphaned), we must NOT run FMethod - doing so would write into caller
  // state the waiter has stopped expecting. Otherwise we claim the call by
  // setting FStarted, which tells a concurrently-timing-out waiter that the
  // method is already mid-flight and must be waited out, not orphaned.
  FLock.Enter;
  try
    lRun := not FOrphaned;
    if lRun then
      FStarted := True;
  finally
    FLock.Leave;
  end;
  if lRun then
    RunGuarded; // captures any exception into FException for the waiter
  FEvent.SetEvent;
  DecRef; // release the queued reference (frees the task if it was the last)
end;


procedure TMCPBoundedTask.ExecuteWithTimeout(aTimeoutMs : Integer);

var
  lExc : Exception;

begin
  FException := nil;
  if GetCurrentThreadID = MainThreadID then
    begin
    // On the main thread there is nothing to wait for: run inline and re-raise,
    // exactly like the un-timed path. Queuing to ourselves would deadlock.
    RunGuarded;
    lExc := FException;
    FException := nil;
    if Assigned(lExc) then
      raise lExc;
    Exit;
    end;
  InterlockedIncrement(FRefCount); // the queued call's reference
  TThread.Queue(nil, @RunQueued);
  if FEvent.WaitFor(aTimeoutMs) = wrSignaled then
    begin
    // The main thread drained the call in time. Re-raise anything it captured.
    lExc := FException;
    FException := nil;
    if Assigned(lExc) then
      raise lExc;
    Exit;
    end;
  // Timed out. Decide atomically with RunQueued: if the method has NOT begun, we
  // orphan it (a late drain becomes a harmless no-op that never touches caller
  // state) and fail loudly. If it has ALREADY begun on the main thread, we must
  // not return while it is still touching caller state - wait for it to finish
  // (it is running on a live main thread, so it will), then treat the call as a
  // normal completion rather than a timeout.
  FLock.Enter;
  try
    if not FStarted then
      FOrphaned := True;
  finally
    FLock.Leave;
  end;
  if FOrphaned then
    raise EMCPException.Create(SErrMainThreadTimeout);
  // Method already in flight: let it complete, then re-raise anything it captured.
  FEvent.WaitFor(INFINITE);
  lExc := FException;
  FException := nil;
  if Assigned(lExc) then
    raise lExc;
end;


procedure RunOnMainThread(aMethod : TMCPMainThreadMethod; aTimeoutMs : Integer);

var
  lTask : TMCPBoundedTask;

begin
  lTask := TMCPBoundedTask.Create(aMethod);
  try
    lTask.ExecuteWithTimeout(aTimeoutMs);
  finally
    lTask.DecRef; // release the creator's reference
  end;
end;


end.

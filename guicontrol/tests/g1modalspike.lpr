{
    This file is part of the Free Component Library

    MCP LCL control - G1 spike: validate main-thread marshalling under a modal dialog
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{
  PURPOSE (architecture gap G1)
  -----------------------------
  Prove that a non-main thread can marshal work onto the GUI main thread via
  RunOnMainThread (TThread.Synchronize) WHILE the main thread is blocked inside
  TForm.ShowModal. This is the load-bearing assumption of the GUI-control server:
  the HTTP server thread is just another non-main thread, so if an arbitrary
  worker can reach the main thread under a modal, so can the HTTP handler.

  HOW IT WORKS
  ------------
  - Main thread shows a modal form (enters the LCL modal message loop).
  - A prober thread waits until the modal is up, then calls RunOnMainThread to
    touch the LCL (count forms) and records whether it ran on the main thread.
  - The prober then closes the modal (also via RunOnMainThread) so the program
    ends on its own.
  - A watchdog thread force-exits with code 2 if anything deadlocks, so this can
    run unattended in an automator/CI without ever hanging.

  EXIT CODES (for the automator)
  ------------------------------
    0  PASS  - marshalled call ran on the main thread while the modal was open
    1  FAIL  - test ran but the assertion did not hold (see stdout)
    2  TIMEOUT/DEADLOCK - main thread never processed the marshalled call
}

program g1modalspike;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads, // must be first: enables thread support on Unix
  {$ENDIF}
  Interfaces, Classes, SysUtils, Forms, Controls,
  mcp.lcl.mainthread;

type

  { TModalForm }

  TModalForm = class(TForm)
  protected
    procedure DoShow; override;
  end;

  { TProberThread }

  TProberThread = class(TThread)
  private
    procedure DoProbe;    // runs on the main thread via RunOnMainThread
    procedure CloseModal; // runs on the main thread via RunOnMainThread
  protected
    procedure Execute; override;
  end;

  { TWatchdogThread }

  TWatchdogThread = class(TThread)
  protected
    procedure Execute; override;
  end;

const
  ModalWaitMs   = 5000;  // how long the prober waits for the modal to appear
  WatchdogMs    = 10000; // hard ceiling before declaring a deadlock

var
  GModalForm : TModalForm;
  GModalUpEvent : PRTLEvent;
  GFinishedEvent : PRTLEvent;
  GModalUp : Boolean;
  GTestFinished : Boolean;
  GProbeReturned : Boolean;
  GProbeOnMainThread : Boolean;
  GModalActiveDuringProbe : Boolean;
  GProbeFormCount : Integer;


{ TModalForm }

procedure TModalForm.DoShow;

begin
  inherited DoShow;
  GModalUp := True;
  RTLEventSetEvent(GModalUpEvent);
end;


{ TProberThread }

procedure TProberThread.DoProbe;

begin
  GProbeOnMainThread := (GetCurrentThreadID = MainThreadID);
  GModalActiveDuringProbe := (fsModal in GModalForm.FormState);
  GProbeFormCount := Screen.CustomFormCount;
end;


procedure TProberThread.CloseModal;

begin
  if Assigned(GModalForm) then
    GModalForm.ModalResult := mrOK;
end;


procedure TProberThread.Execute;

begin
  RTLEventWaitFor(GModalUpEvent, ModalWaitMs);
  if not GModalUp then
    begin
    GTestFinished := True;
    RTLEventSetEvent(GFinishedEvent);
    Exit;
    end;
  Sleep(200); // let the modal message loop settle
  // The assertion: this must return (not deadlock) and run on the main thread.
  RunOnMainThread(@DoProbe);
  GProbeReturned := True;
  // Clean shutdown: end the modal from this worker thread (proves marshalling again).
  RunOnMainThread(@CloseModal);
end;


{ TWatchdogThread }

procedure TWatchdogThread.Execute;

begin
  RTLEventWaitFor(GFinishedEvent, WatchdogMs);
  if not GTestFinished then
    begin
    Writeln('G1 SPIKE: TIMEOUT - main thread did not process the marshalled call under a modal (DEADLOCK).');
    Flush(Output);
    Halt(2);
    end;
end;


procedure RunSpike;

var
  lProber : TProberThread;
  lWatchdog : TWatchdogThread;

begin
  GModalUpEvent := RTLEventCreate;
  GFinishedEvent := RTLEventCreate;
  lWatchdog := TWatchdogThread.Create(False);
  lProber := TProberThread.Create(False);
  try
    GModalForm := TModalForm.CreateNew(nil);
    GModalForm.Caption := 'G1 modal';
    GModalForm.SetBounds(0, 0, 200, 120);
    GModalForm.ShowModal; // blocks here, pumping the modal loop, until the prober closes it
    GTestFinished := True;
    RTLEventSetEvent(GFinishedEvent);
    lProber.WaitFor;
  finally
    FreeAndNil(GModalForm);
    lProber.Free;
    lWatchdog.Free;
    RTLEventDestroy(GModalUpEvent);
    RTLEventDestroy(GFinishedEvent);
  end;
end;


procedure ReportAndSetExitCode;

begin
  Writeln('G1 SPIKE RESULTS');
  Writeln('  modal opened              : ', GModalUp);
  Writeln('  marshalled call returned  : ', GProbeReturned);
  Writeln('  ran on main thread        : ', GProbeOnMainThread);
  Writeln('  modal active during probe : ', GModalActiveDuringProbe);
  Writeln('  Screen.CustomFormCount    : ', GProbeFormCount);
  if GProbeReturned and GProbeOnMainThread and GModalActiveDuringProbe then
    begin
    Writeln('RESULT: PASS - Synchronize resolves on the main thread while a modal is open.');
    ExitCode := 0;
    end
  else
    begin
    Writeln('RESULT: FAIL - assertion did not hold (see flags above).');
    ExitCode := 1;
    end;
  Flush(Output);
end;


begin
  Application.Initialize;
  RunSpike;
  ReportAndSetExitCode;
end.

{
    This file is part of the Free Component Library

    MCP LCL control - non-published accessor registry tests (headless)
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.accessors.test;

{$mode objfpc}{$H+}

interface

{$IFDEF MCP_GUICONTROL}
uses
  TestRegistry, Classes, SysUtils, fpcunit, mcp.types, mcp.lcl.accessors;

type

  { TAccessorFixture }

  // Instance-based fixture: the getter/setter read/write its FState field, so the tests
  // prove the accessor actually receives and acts on the instance (not a global).
  TAccessorFixture = class(TComponent)
  public
    FState : string;
  end;

  { TMCPAccessorRegistryTest }

  TMCPAccessorRegistryTest = class(TTestCase)
  private
    FFixture : TAccessorFixture;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestReadAccessorReturnsGetterValue;
    procedure TestWriteAccessorInvokesSetterObservable;
    procedure TestReadAccessorUnknownNameRaises;
    procedure TestWriteAccessorUnknownNameRaises;
    procedure TestAccessorMatchesByDescendantClass;
  end;

implementation

uses
  mcp.lcl.strings;

var
  GSetterCalled : Boolean;

// Module-level getter: reads FState off the fixture instance.
function FixtureGet(aInstance: TObject): string;

begin
  Result := TAccessorFixture(aInstance).FState;
end;


// Module-level setter: writes aValue into FState on the fixture instance and flags that it ran.
procedure FixtureSet(aInstance: TObject; const aValue: string);

begin
  TAccessorFixture(aInstance).FState := aValue;
  GSetterCalled := True;
end;


{ TMCPAccessorRegistryTest }

procedure TMCPAccessorRegistryTest.SetUp;

begin
  inherited SetUp;
  ClearAccessors;
  GSetterCalled := False;
  RegisterAccessor(TAccessorFixture, 'state', @FixtureGet, @FixtureSet);
  FFixture := TAccessorFixture.Create(nil);
end;


procedure TMCPAccessorRegistryTest.TearDown;

begin
  FreeAndNil(FFixture);
  ClearAccessors;
  inherited TearDown;
end;


procedure TMCPAccessorRegistryTest.TestReadAccessorReturnsGetterValue;

begin
  // AC #1: ReadAccessor returns whatever the registered getter produces for the instance.
  FFixture.FState := 'hello';
  AssertEquals('ReadAccessor returns the getter value', 'hello', ReadAccessor(FFixture, 'state'));
end;


procedure TMCPAccessorRegistryTest.TestWriteAccessorInvokesSetterObservable;

begin
  // AC #2: WriteAccessor invokes the setter; the change is observable on the instance AND via a
  // subsequent ReadAccessor (write-then-observe).
  WriteAccessor(FFixture, 'state', 'world');
  AssertTrue('the setter must have run', GSetterCalled);
  AssertEquals('the instance reflects the written value', 'world', FFixture.FState);
  AssertEquals('a subsequent ReadAccessor returns the new value', 'world', ReadAccessor(FFixture, 'state'));
end;


procedure TMCPAccessorRegistryTest.TestReadAccessorUnknownNameRaises;

var
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #3: an unregistered name raises EMCPException (SErrNoAccessor) naming the accessor.
  lRaised := False;
  lMessage := '';
  try
    ReadAccessor(FFixture, 'nope');
  except
    on E : EMCPException do
      begin
      lRaised := True;
      lMessage := E.Message;
      end;
  end;
  AssertTrue('unknown name must raise EMCPException', lRaised);
  AssertEquals('message must be SErrNoAccessor for the name', Format(SErrNoAccessor, ['nope']), lMessage);
end;


procedure TMCPAccessorRegistryTest.TestWriteAccessorUnknownNameRaises;

var
  lRaised : Boolean;
  lMessage : String;

begin
  // AC #3: an unregistered name raises EMCPException (SErrNoAccessor) on the write path too;
  // the setter never runs.
  lRaised := False;
  lMessage := '';
  GSetterCalled := False;
  try
    WriteAccessor(FFixture, 'nope', 'x');
  except
    on E : EMCPException do
      begin
      lRaised := True;
      lMessage := E.Message;
      end;
  end;
  AssertTrue('unknown name must raise EMCPException', lRaised);
  AssertEquals('message must be SErrNoAccessor for the name', Format(SErrNoAccessor, ['nope']), lMessage);
  AssertFalse('the setter must NOT run for an unknown name', GSetterCalled);
end;


procedure TMCPAccessorRegistryTest.TestAccessorMatchesByDescendantClass;

begin
  // AC #1 (robustness): an accessor registered on an ancestor class (TComponent) matches when
  // resolved through a descendant instance (TAccessorFixture) - the "instance of OR a descendant
  // of the registered class" clause (InheritsFrom).
  RegisterAccessor(TComponent, 'ancestorState', @FixtureGet, @FixtureSet);
  FFixture.FState := 'inherited-hit';
  AssertEquals('ancestor-registered accessor matches a descendant instance', 'inherited-hit',
    ReadAccessor(FFixture, 'ancestorState'));
end;

{$ENDIF}

initialization
{$IFDEF MCP_GUICONTROL}
  RegisterTest(TMCPAccessorRegistryTest);
{$ENDIF}
end.

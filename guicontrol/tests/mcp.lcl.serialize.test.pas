{
    This file is part of the Free Component Library

    MCP LCL control - serialization tests
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.serialize.test;

{$mode objfpc}{$H+}

interface

{$IFDEF MCP_GUICONTROL}
uses
  TestRegistry, Classes, SysUtils, fpjson, fpcunit, mcp.types, mcp.lcl.serialize;

type

  { TMCPSerializeTest }

  TMCPSerializeTest = class(TTestCase)
  private
    FFixture : TComponent;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestReadStringIsJSONString;
    procedure TestReadIntegerIsJSONNumber;
    procedure TestReadInt64IsJSONNumber;
    procedure TestReadFloatIsJSONNumber;
    procedure TestReadBooleanIsJSONBoolean;
    procedure TestReadEnumIsConstantName;
    procedure TestReadWideStringIsJSONString;
    procedure TestReadUnhandledKindFallsBackToString;
    procedure TestUnknownPropertyRaisesNoProperty;
  end;

implementation

type
  TFixtureKind = (fkAlpha, fkBeta, fkGamma);
  TFixtureKinds = set of TFixtureKind;

  { TSerializeFixture }

  // A plain TComponent descendant carries published-property RTTI for free
  // (TPersistent is {$M+}), so the type matrix is exercised headlessly. SetProp
  // (a tkSet) has no dedicated branch and therefore exercises the string fall-back.
  TSerializeFixture = class(TComponent)
  private
    FStr   : string;
    FInt   : Integer;
    FBig   : Int64;
    FFloat : Double;
    FFlag  : Boolean;
    FKind  : TFixtureKind;
    FWide  : UnicodeString;
    FSet   : TFixtureKinds;
  published
    property StrProp   : string        read FStr   write FStr;
    property IntProp   : Integer       read FInt   write FInt;
    property BigProp   : Int64         read FBig   write FBig;
    property FloatProp : Double        read FFloat write FFloat;
    property FlagProp  : Boolean       read FFlag  write FFlag;
    property KindProp  : TFixtureKind  read FKind  write FKind;
    property WideProp  : UnicodeString read FWide  write FWide;
    property SetProp   : TFixtureKinds read FSet   write FSet;
  end;


procedure TMCPSerializeTest.SetUp;

begin
  inherited SetUp;
  FFixture := TSerializeFixture.Create(nil);
  TSerializeFixture(FFixture).StrProp   := 'hello';
  TSerializeFixture(FFixture).IntProp   := 42;
  TSerializeFixture(FFixture).BigProp   := Int64(5000000000);  // > MaxInt: needs 64-bit
  TSerializeFixture(FFixture).FloatProp := 3.5;
  TSerializeFixture(FFixture).FlagProp  := True;
  TSerializeFixture(FFixture).KindProp  := fkBeta;
  TSerializeFixture(FFixture).WideProp  := 'wide';
  TSerializeFixture(FFixture).SetProp   := [fkAlpha, fkGamma];
end;


procedure TMCPSerializeTest.TearDown;

begin
  FreeAndNil(FFixture);
  inherited TearDown;
end;


procedure TMCPSerializeTest.TestReadStringIsJSONString;

var
  lValue : TJSONData;

begin
  lValue := Nil;
  try
    lValue := ReadPublishedProperty(FFixture, 'StrProp');
    AssertEquals('StrProp is a JSON string', Ord(jtString), Ord(lValue.JSONType));
    AssertEquals('StrProp value', 'hello', lValue.AsString);
  finally
    lValue.Free;
  end;
end;


procedure TMCPSerializeTest.TestReadIntegerIsJSONNumber;

var
  lValue : TJSONData;

begin
  lValue := Nil;
  try
    lValue := ReadPublishedProperty(FFixture, 'IntProp');
    AssertEquals('IntProp is a JSON number', Ord(jtNumber), Ord(lValue.JSONType));
    AssertEquals('IntProp value', 42, lValue.AsInteger);
  finally
    lValue.Free;
  end;
end;


procedure TMCPSerializeTest.TestReadInt64IsJSONNumber;

var
  lValue : TJSONData;

begin
  lValue := Nil;
  try
    lValue := ReadPublishedProperty(FFixture, 'BigProp');
    AssertEquals('BigProp is a JSON number', Ord(jtNumber), Ord(lValue.JSONType));
    AssertEquals('BigProp value', Int64(5000000000), lValue.AsInt64);
  finally
    lValue.Free;
  end;
end;


procedure TMCPSerializeTest.TestReadFloatIsJSONNumber;

var
  lValue : TJSONData;

begin
  lValue := Nil;
  try
    lValue := ReadPublishedProperty(FFixture, 'FloatProp');
    AssertEquals('FloatProp is a JSON number', Ord(jtNumber), Ord(lValue.JSONType));
    AssertEquals('FloatProp value', 3.5, lValue.AsFloat, 0.0001);
  finally
    lValue.Free;
  end;
end;


procedure TMCPSerializeTest.TestReadBooleanIsJSONBoolean;

var
  lValue : TJSONData;

begin
  lValue := Nil;
  try
    lValue := ReadPublishedProperty(FFixture, 'FlagProp');
    AssertEquals('FlagProp is a JSON boolean', Ord(jtBoolean), Ord(lValue.JSONType));
    AssertEquals('FlagProp value', True, lValue.AsBoolean);
  finally
    lValue.Free;
  end;
end;


procedure TMCPSerializeTest.TestReadEnumIsConstantName;

var
  lValue : TJSONData;

begin
  lValue := Nil;
  try
    lValue := ReadPublishedProperty(FFixture, 'KindProp');
    AssertEquals('KindProp is a JSON string', Ord(jtString), Ord(lValue.JSONType));
    AssertEquals('KindProp value is the enum constant name', 'fkBeta', lValue.AsString);
  finally
    lValue.Free;
  end;
end;


procedure TMCPSerializeTest.TestReadWideStringIsJSONString;
// tkUString goes through UTF8Encode before becoming a JSON string.

var
  lValue : TJSONData;

begin
  lValue := Nil;
  try
    lValue := ReadPublishedProperty(FFixture, 'WideProp');
    AssertEquals('WideProp is a JSON string', Ord(jtString), Ord(lValue.JSONType));
    AssertEquals('WideProp value (UTF-8)', 'wide', lValue.AsString);
  finally
    lValue.Free;
  end;
end;


procedure TMCPSerializeTest.TestReadUnhandledKindFallsBackToString;
// A tkSet property has no dedicated branch: AC #1 mandates the string fall-back.

var
  lValue : TJSONData;

begin
  lValue := Nil;
  try
    lValue := ReadPublishedProperty(FFixture, 'SetProp');
    AssertEquals('SetProp falls back to a JSON string', Ord(jtString), Ord(lValue.JSONType));
    AssertTrue('fall-back string names the set members', Pos('fk', lValue.AsString) > 0);
  finally
    lValue.Free;
  end;
end;


procedure TMCPSerializeTest.TestUnknownPropertyRaisesNoProperty;

var
  lValue   : TJSONData;
  lRaised  : Boolean;

begin
  lValue := Nil;
  lRaised := False;
  try
    try
      lValue := ReadPublishedProperty(FFixture, 'NoSuchProp');
    except
      on E : EMCPException do
        begin
        lRaised := True;
        AssertTrue('error message names the missing property', Pos('NoSuchProp', E.Message) > 0);
        end;
    end;
    AssertTrue('unknown property must raise EMCPException', lRaised);
  finally
    lValue.Free;
  end;
end;

{$ENDIF}

initialization
{$IFDEF MCP_GUICONTROL}
  RegisterTest(TMCPSerializeTest);
{$ENDIF}
end.

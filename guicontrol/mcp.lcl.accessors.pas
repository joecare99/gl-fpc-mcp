{
    This file is part of the Free Component Library

    MCP LCL control - non-published accessor registry
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{ Registry of host-app-registered named accessors for state that classic RTTI
  cannot see. 
  The host registers a class -> name -> get/set triple at startup; 
  readAccessor/writeAccessor are used at run time.

  Headless-safe: keys on TClass and operates on TObject instances with string
  values only (no Controls/Forms/Graphics), so it links into the no-widgetset
  binaries exactly like serialize's classic-TypInfo core.

  Threading contract: register accessors on the main thread at startup (before
  StartGUIControlServer); the registry is read only on the main thread inside
  tool *OnMain methods. This main-thread confinement IS the guard - no lock is
  needed (TFPHTTPServer.Threaded := False serializes requests). }

unit mcp.lcl.accessors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  // Reads non-published state off aInstance, returning it as a string.
  TAccessorGetFunc = function(aInstance: TObject): string;
  // Writes aValue into non-published state on aInstance.
  TAccessorSetProc = procedure(aInstance: TObject; const aValue: string);

// Registers a class -> name -> get/set triple. Both aGetter and aSetter are required.
procedure RegisterAccessor(aClass: TClass; const aName: string; aGetter: TAccessorGetFunc; aSetter: TAccessorSetProc);
// Finds the accessor whose class aInstance is (or descends from) and whose name equals
// aName, calls its getter and returns the value. Raises SErrNoAccessor when none matches.
function ReadAccessor(aInstance: TObject; const aName: string): string;
// Same lookup as ReadAccessor, then calls the setter with aValue. Raises SErrNoAccessor when none matches.
procedure WriteAccessor(aInstance: TObject; const aName: string; const aValue: string);
// Empties the registry (for test isolation and finalization).
procedure ClearAccessors;

implementation

uses
  mcp.types, mcp.lcl.strings;

type
  TAccessorEntry = record
    RegClass : TClass;
    Name     : string;
    Getter   : TAccessorGetFunc;
    Setter   : TAccessorSetProc;
  end;

var
  Accessors : array of TAccessorEntry;

// Returns the index of the first accessor matching aInstance's class and aName, or -1 if none.
function FindAccessor(aInstance: TObject; const aName: string): Integer;

var
  I : Integer;

begin
  Result := -1;
  if aInstance = nil then
    Exit;
  for I := 0 to High(Accessors) do
    if aInstance.InheritsFrom(Accessors[I].RegClass) and SameText(Accessors[I].Name, aName) then
      Exit(I);   // first registered wins on ambiguous overlaps
end;


procedure RegisterAccessor(aClass: TClass; const aName: string; aGetter: TAccessorGetFunc; aSetter: TAccessorSetProc);

var
  lIndex : Integer;

begin
  lIndex := Length(Accessors);
  SetLength(Accessors, lIndex + 1);
  Accessors[lIndex].RegClass := aClass;
  Accessors[lIndex].Name     := aName;
  Accessors[lIndex].Getter   := aGetter;
  Accessors[lIndex].Setter   := aSetter;
end;


function ReadAccessor(aInstance: TObject; const aName: string): string;

var
  lIndex : Integer;

begin
  lIndex := FindAccessor(aInstance, aName);
  if lIndex < 0 then
    raise EMCPException.CreateFmt(SErrNoAccessor, [aName]);
  Result := Accessors[lIndex].Getter(aInstance);
end;


procedure WriteAccessor(aInstance: TObject; const aName: string; const aValue: string);

var
  lIndex : Integer;

begin
  lIndex := FindAccessor(aInstance, aName);
  if lIndex < 0 then
    raise EMCPException.CreateFmt(SErrNoAccessor, [aName]);
  Accessors[lIndex].Setter(aInstance, aValue);
end;


procedure ClearAccessors;

begin
  SetLength(Accessors, 0);
end;


finalization
  ClearAccessors;
end.

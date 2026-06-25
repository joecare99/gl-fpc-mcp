{
    This file is part of the Free Component Library

    MCP LCL control - shared dot/bracket control locator
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.locator;

{$mode objfpc}{$H+}

// The visual child model (TWinControl.Controls[]) and the Screen-based
// ResolveTarget wrapper pull in the LCL Controls/Forms units, which in turn
// reference the widgetset (WSRegister*) symbols a headless, no-widgetset binary
// cannot link. 
// They are therefore under IFDEF MCP_LOCATOR_VISUAL, which is ON
// by default. Define MCP_LOCATOR_HEADLESS to undefine it

{$IFNDEF MCP_LOCATOR_HEADLESS}
  {$DEFINE MCP_LOCATOR_VISUAL}
{$ENDIF}

interface

uses
  Classes, SysUtils{$IFDEF MCP_LOCATOR_VISUAL}, Controls{$ENDIF};

// Resolves aLocator relative to aRoot, returning the matching TComponent.
// Locator grammar: a leading name or '[index]' step, then any mix of '.name'
// and '[index]' steps (e.g. 'Panel1.OKButton', '[2][0]', 'Panel1[0].Edit1').
// An empty aLocator returns aRoot. Raises EMCPException (SErrLocatorNotFound)
// for any unresolved segment - never returns nil. MUST be called on the GUI
// main thread (it walks the LCL component tree and does not marshal itself).
function ResolveTargetIn(aRoot: TComponent; const aLocator: string): TComponent;

{$IFDEF MCP_LOCATOR_VISUAL}
// Resolves aLocator against the live application: the first name step selects a
// root form from Screen.CustomForms (case-insensitive), the remainder is
// delegated to ResolveTargetIn. Raises EMCPException (SErrLocatorNotFound) when
// the root name matches nothing. MUST be called on the GUI main thread.
function ResolveTarget(const aLocator: string): TComponent;

type
  // One control matched by FindControls: its round-trippable locator plus the few
  // descriptive fields an agent uses to pick a target.
  TFoundControl = record
    Locator   : string;    // resolves through ResolveTarget back to this exact component
    Name      : string;    // component Name ('' for unnamed/dynamic controls)
    ClassName : string;    // the component's class name
    Caption   : string;    // its published Caption, or '' when it has none
    Enabled   : Boolean;   // its published Enabled state (True when it has no such property)
  end;
  TFoundControlArray = array of TFoundControl;

  // findControls query filters (AND-combined). An empty ClassName or Caption is a
  // wildcard; set HasEnabled to also filter on the Enabled state.
  TControlQuery = record
    ClassName    : string;   // exact ClassName, matched case-insensitively; '' = any
    Caption      : string;   // case-insensitive substring of Caption; '' = any
    HasEnabled   : Boolean;  // when True, only controls whose Enabled = EnabledValue match
    EnabledValue : Boolean;
  end;

// Walks every named form in Screen.CustomForms (and each form's visual child tree) and
// returns every control matching aQuery. Each result's Locator round-trips through
// ResolveTarget back to the same component. Returns an empty array when nothing matches -
// it never raises for an empty result. MUST be called on the GUI main thread.
function FindControls(const aQuery: TControlQuery): TFoundControlArray;
{$ENDIF}

implementation

uses
  mcp.types,        // EMCPException
  mcp.lcl.strings   // SErrLocatorNotFound
  {$IFDEF MCP_LOCATOR_VISUAL}, typinfo, Forms{$ENDIF}; // Screen.CustomForms + Caption/Enabled RTTI

type
  // One parsed locator step: either a child index or a child Name.
  TLocatorStep = record
    IsIndex : Boolean;
    Name    : string;
    Index   : Integer;
  end;
  TLocatorStepArray = array of TLocatorStep;


function IsIdentStartChar(aCh: Char): Boolean;

begin
  Result := aCh in ['A'..'Z', 'a'..'z', '_'];
end;


function IsIdentChar(aCh: Char): Boolean;

begin
  Result := aCh in ['A'..'Z', 'a'..'z', '0'..'9', '_'];
end;


// Tokenizes aLocator into ordered steps. Total parser: returns False on any
// malformed input (caller turns that into SErrLocatorNotFound) rather than
// raising or asserting. A name step is only valid first or after a '.'; an
// index step '[int]' may follow any step.
function TokenizeLocator(const aLocator: string; out aSteps: TLocatorStepArray): Boolean;

var
  lPos, lLen, lCount, lStart, lClose, lVal : Integer;
  lNum : string;
  lStep : TLocatorStep;

begin
  Result := False;
  SetLength(aSteps, 0);
  lLen := Length(aLocator);
  lPos := 1;
  lCount := 0;
  while lPos <= lLen do
    begin
    case aLocator[lPos] of
      '[':
        begin
        lClose := lPos + 1;
        while (lClose <= lLen) and (aLocator[lClose] <> ']') do
          Inc(lClose);
        if lClose > lLen then
          Exit; // no closing bracket
        lNum := Copy(aLocator, lPos + 1, lClose - lPos - 1);
        if not TryStrToInt(lNum, lVal) then
          Exit;
        lStep.IsIndex := True;
        lStep.Index := lVal;
        lStep.Name := '';
        SetLength(aSteps, lCount + 1);
        aSteps[lCount] := lStep;
        Inc(lCount);
        lPos := lClose + 1;
        end;
      '.':
        begin
        if lCount = 0 then
          Exit; // leading separator
        Inc(lPos); // consume the '.'
        if (lPos > lLen) or not IsIdentStartChar(aLocator[lPos]) then
          Exit;
        lStart := lPos;
        while (lPos <= lLen) and IsIdentChar(aLocator[lPos]) do
          Inc(lPos);
        lStep.IsIndex := False;
        lStep.Name := Copy(aLocator, lStart, lPos - lStart);
        lStep.Index := 0;
        SetLength(aSteps, lCount + 1);
        aSteps[lCount] := lStep;
        Inc(lCount);
        end;
    else
      begin
      // A bare name is only valid as the very first step.
      if (lCount <> 0) or not IsIdentStartChar(aLocator[lPos]) then
        Exit;
      lStart := lPos;
      while (lPos <= lLen) and IsIdentChar(aLocator[lPos]) do
        Inc(lPos);
      lStep.IsIndex := False;
      lStep.Name := Copy(aLocator, lStart, lPos - lStart);
      lStep.Index := 0;
      SetLength(aSteps, lCount + 1);
      aSteps[lCount] := lStep;
      Inc(lCount);
      end;
    end;
    end;
  Result := True;
end;


// Number of navigable children of aParent. With MCP_LOCATOR_VISUAL a
// TWinControl exposes its visual Controls[] (the containment an agent sees);
// every other TComponent exposes its owned Components[].
function ChildCount(aParent: TComponent): Integer;

begin
{$IFDEF MCP_LOCATOR_VISUAL}
  if aParent is TWinControl then
    Result := TWinControl(aParent).ControlCount
  else
{$ENDIF}
    Result := aParent.ComponentCount;
end;


// Child of aParent at aIndex, or nil when out of range (negative or >= count).
function ChildByIndex(aParent: TComponent; aIndex: Integer): TComponent;

begin
  Result := nil;
  if (aIndex < 0) or (aIndex >= ChildCount(aParent)) then
    Exit;
{$IFDEF MCP_LOCATOR_VISUAL}
  if aParent is TWinControl then
    Result := TWinControl(aParent).Controls[aIndex]
  else
{$ENDIF}
    Result := aParent.Components[aIndex];
end;


// Child of aParent whose Name matches aName case-insensitively, or nil if none.
function ChildByName(aParent: TComponent; const aName: string): TComponent;

var
  lIndex : Integer;
  lChild : TComponent;

begin
  Result := nil;
  for lIndex := 0 to ChildCount(aParent) - 1 do
    begin
    lChild := ChildByIndex(aParent, lIndex);
    if (lChild <> nil) and (CompareText(lChild.Name, aName) = 0) then
      Exit(lChild);
    end;
end;


// Walks aSteps[aStart..] down from aNode. Raises SErrLocatorNotFound (with the
// full original aLocator) the moment a step resolves to nil.
function DescendSteps(aNode: TComponent; const aSteps: TLocatorStepArray; aStart: Integer; const aLocator: string): TComponent;

var
  lIndex : Integer;
  lNext : TComponent;

begin
  Result := aNode;
  for lIndex := aStart to High(aSteps) do
    begin
    if aSteps[lIndex].IsIndex then
      lNext := ChildByIndex(Result, aSteps[lIndex].Index)
    else
      lNext := ChildByName(Result, aSteps[lIndex].Name);
    if lNext = nil then
      raise EMCPException.CreateFmt(SErrLocatorNotFound, [aLocator]);
    Result := lNext;
    end;
end;


function ResolveTargetIn(aRoot: TComponent; const aLocator: string): TComponent;

var
  lSteps : TLocatorStepArray;

begin
  if aLocator = '' then
    Exit(aRoot);
  if not TokenizeLocator(aLocator, lSteps) then
    raise EMCPException.CreateFmt(SErrLocatorNotFound, [aLocator]);
  Result := DescendSteps(aRoot, lSteps, 0, aLocator);
end;


{$IFDEF MCP_LOCATOR_VISUAL}
function ResolveTarget(const aLocator: string): TComponent;

var
  lSteps : TLocatorStepArray;
  lRoot : TComponent;
  lIndex : Integer;

begin
  if not TokenizeLocator(aLocator, lSteps) then
    raise EMCPException.CreateFmt(SErrLocatorNotFound, [aLocator]);
  // The whole locator must start with a named root (a leading index has no form
  // to resolve against and is treated as not-found).
  if (Length(lSteps) = 0) or lSteps[0].IsIndex then
    raise EMCPException.CreateFmt(SErrLocatorNotFound, [aLocator]);
  lRoot := nil;
  for lIndex := 0 to Screen.CustomFormCount - 1 do
    if CompareText(Screen.CustomForms[lIndex].Name, lSteps[0].Name) = 0 then
      begin
      lRoot := Screen.CustomForms[lIndex];
      Break;
      end;
  if lRoot = nil then
    raise EMCPException.CreateFmt(SErrLocatorNotFound, [aLocator]);
  Result := DescendSteps(lRoot, lSteps, 1, aLocator);
end;
{$ENDIF}


{$IFDEF MCP_LOCATOR_VISUAL}
// aComp's published Caption via TypInfo, or '' when it has no such property.
function ControlCaption(aComp: TComponent): string;

begin
  if IsPublishedProp(aComp, 'Caption') then
    Result := GetStrProp(aComp, 'Caption')
  else
    Result := '';
end;


// aComp's published Enabled state, defaulting to True when it has no such property.
function ControlEnabled(aComp: TComponent): Boolean;

begin
  if IsPublishedProp(aComp, 'Enabled') then
    Result := GetOrdProp(aComp, 'Enabled') <> 0
  else
    Result := True;
end;


// True when aComp satisfies every SET filter in aQuery (AND semantics; unset = wildcard).
function MatchesQuery(aComp: TComponent; const aQuery: TControlQuery): Boolean;

begin
  Result := False;
  if (aQuery.ClassName <> '') and (CompareText(aComp.ClassName, aQuery.ClassName) <> 0) then
    Exit;
  if (aQuery.Caption <> '') and (Pos(LowerCase(aQuery.Caption), LowerCase(ControlCaption(aComp))) = 0) then
    Exit;
  if aQuery.HasEnabled and (ControlEnabled(aComp) <> aQuery.EnabledValue) then
    Exit;
  Result := True;
end;


// The locator step from aParent to its child at aIndex: '.Name' when the child has a Name
// that resolves uniquely back to it, else the positional '[aIndex]'. Falling back to the
// index whenever the name does not round-trip is what makes EVERY built locator resolve
// back to the same component (AC #2).
function StepFor(aParent, aChild: TComponent; aIndex: Integer): string;

begin
  if (aChild.Name <> '') and (ChildByName(aParent, aChild.Name) = aChild) then
    Result := '.' + aChild.Name
  else
    Result := '[' + IntToStr(aIndex) + ']';
end;


// Appends aNode (when it matches) then recurses its children, threading the locator path
// built so far (aPath resolves to aNode). Uses the SAME ChildCount/ChildByIndex model the
// locator resolves against, so each child index/name round-trips.
procedure CollectMatches(aNode: TComponent; const aPath: string; const aQuery: TControlQuery;
  var aMatches: TFoundControlArray);

var
  lIndex, lLen : Integer;
  lChild : TComponent;

begin
  if MatchesQuery(aNode, aQuery) then
    begin
    lLen := Length(aMatches);
    SetLength(aMatches, lLen + 1);
    aMatches[lLen].Locator   := aPath;
    aMatches[lLen].Name      := aNode.Name;
    aMatches[lLen].ClassName := aNode.ClassName;
    aMatches[lLen].Caption   := ControlCaption(aNode);
    aMatches[lLen].Enabled   := ControlEnabled(aNode);
    end;
  for lIndex := 0 to ChildCount(aNode) - 1 do
    begin
    lChild := ChildByIndex(aNode, lIndex);
    if lChild <> nil then
      CollectMatches(lChild, aPath + StepFor(aNode, lChild, lIndex), aQuery, aMatches);
    end;
end;


function FindControls(const aQuery: TControlQuery): TFoundControlArray;

var
  lIndex : Integer;
  lForm : TCustomForm;

begin
  SetLength(Result, 0);
  for lIndex := 0 to Screen.CustomFormCount - 1 do
    begin
    lForm := Screen.CustomForms[lIndex];
    // A form with no Name cannot be addressed (ResolveTarget needs a named root), so its
    // controls are unreachable - skip it rather than emit a non-round-trippable locator.
    if lForm.Name <> '' then
      CollectMatches(lForm, lForm.Name, aQuery, Result);
    end;
end;

{$ENDIF}

end.

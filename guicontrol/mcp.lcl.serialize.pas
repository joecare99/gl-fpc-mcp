{
    This file is part of the Free Component Library

    MCP LCL control - property/value <-> JSON serialization (classic TypInfo)
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.serialize;

{$mode objfpc}{$H+}

// WriteComponentAsTextToStream lives in the LCL unit LResources, 
// which pulls the widgetset and cannot link into a no-widgetset binary. 
// The LFM-snapshot helper is therefore under IFDEF MCP_SERIALIZE_VISUAL: 
// ON by default but disabled when MCP_LOCATOR_HEADLESS is defined - 

{$IFNDEF MCP_LOCATOR_HEADLESS}
  {$DEFINE MCP_SERIALIZE_VISUAL}
{$ENDIF}

interface

uses
  Classes, SysUtils, fpjson{$IFDEF MCP_SERIALIZE_VISUAL}, Controls{$ENDIF};

// Reads the published property aPropName off aInstance and returns it as a freshly
// created, typed TJSONData the CALLER OWNS (and must free or hand to a JSON parent).
// Uses classic TypInfo only. Raises EMCPException (SErrNoProperty) when the property
// is not published / does not exist.
function ReadPublishedProperty(aInstance: TObject; const aPropName: string): TJSONData;
// Writes aValue into the published property aPropName of aInstance. Validates the JSON
// value type against the property kind FIRST and raises EMCPException (SErrPropertyType)
// on mismatch, so a rejected write never mutates the property; raises SErrNoProperty when
// the property is not published. Uses classic TypInfo only; aValue is borrowed (not freed).
procedure WritePublishedProperty(aInstance: TObject; const aPropName: string; aValue: TJSONData);
{$IFDEF MCP_SERIALIZE_VISUAL}
// Serializes aComponent and its streamable child components to LFM text via the LCL
// component-streaming routine WriteComponentAsTextToStream. Returns a fresh string the
// CALLER OWNS. Needs the widgetset (LResources), so it is gated MCP_SERIALIZE_VISUAL.
function SnapshotComponentAsLFM(aComponent: TComponent): string;
// Renders aControl (and its child widgets) to a PNG image via TWinControl.PaintTo and
// returns the raw PNG bytes the CALLER OWNS. The bitmap is sized from aControl.Width/Height,
// so the PNG dimensions equal the control's dimensions. Needs the widgetset (Graphics,
// Controls), so it is gated MCP_SERIALIZE_VISUAL.
function ScreenshotControlAsPNG(aControl: TWinControl): TBytes;
{$ENDIF}

implementation

uses
  typinfo, Variants, mcp.types, mcp.lcl.strings
  {$IFDEF MCP_SERIALIZE_VISUAL}, LResources, Graphics{$ENDIF};

function ReadPublishedProperty(aInstance: TObject; const aPropName: string): TJSONData;

var
  lPropInfo : PPropInfo;

begin
  lPropInfo := GetPropInfo(aInstance, aPropName);   // nil = not published / unknown
  if lPropInfo = nil then
    raise EMCPException.CreateFmt(SErrNoProperty, [aPropName]);
  case lPropInfo^.PropType^.Kind of
    tkInteger:
      Result := TJSONIntegerNumber.Create(GetOrdProp(aInstance, lPropInfo));
    tkInt64, tkQWord:
      Result := TJSONInt64Number.Create(GetInt64Prop(aInstance, lPropInfo));
    tkBool:
      Result := TJSONBoolean.Create(GetOrdProp(aInstance, lPropInfo) <> 0);
    tkEnumeration:
      Result := TJSONString.Create(
        GetEnumName(lPropInfo^.PropType, Integer(GetOrdProp(aInstance, lPropInfo))));
    tkFloat:
      Result := TJSONFloatNumber.Create(GetFloatProp(aInstance, lPropInfo));
    tkSString, tkLString, tkAString:
      Result := TJSONString.Create(GetStrProp(aInstance, lPropInfo));
    tkWString, tkUString:
      Result := TJSONString.Create(UTF8Encode(GetUnicodeStrProp(aInstance, lPropInfo)));
  else
    // Anything else (set, class, method, variant, record, ...): stringify (architecture's
    // documented fall-back). VarToStr keeps it safe for non-string variants.
    Result := TJSONString.Create(VarToStr(GetPropValue(aInstance, lPropInfo, True)));
  end;
end;


procedure WritePublishedProperty(aInstance: TObject; const aPropName: string; aValue: TJSONData);

var
  lPropInfo : PPropInfo;
  lEnum : Integer;

begin
  if aValue = nil then                                // absent 'value' argument
    raise EMCPException.CreateFmt(SErrPropertyType, [aPropName]);
  lPropInfo := GetPropInfo(aInstance, aPropName);     // nil = not published / unknown
  if lPropInfo = nil then
    raise EMCPException.CreateFmt(SErrNoProperty, [aPropName]);
  // Validate the JSON type against the property kind FIRST, then set: a rejected write must
  // leave the property unchanged, and no raw EConvertError may escape.
  case lPropInfo^.PropType^.Kind of
    tkInteger:
      begin
      if aValue.JSONType <> jtNumber then
        raise EMCPException.CreateFmt(SErrPropertyType, [aPropName]);
      SetOrdProp(aInstance, lPropInfo, aValue.AsInteger);
      end;
    tkInt64, tkQWord:
      begin
      if aValue.JSONType <> jtNumber then
        raise EMCPException.CreateFmt(SErrPropertyType, [aPropName]);
      SetInt64Prop(aInstance, lPropInfo, aValue.AsInt64);
      end;
    tkBool:
      begin
      if aValue.JSONType <> jtBoolean then
        raise EMCPException.CreateFmt(SErrPropertyType, [aPropName]);
      SetOrdProp(aInstance, lPropInfo, Ord(aValue.AsBoolean));
      end;
    tkEnumeration:
      begin
      if aValue.JSONType <> jtString then
        raise EMCPException.CreateFmt(SErrPropertyType, [aPropName]);
      lEnum := GetEnumValue(lPropInfo^.PropType, aValue.AsString);   // -1 = unknown name
      if lEnum < 0 then
        raise EMCPException.CreateFmt(SErrPropertyType, [aPropName]);
      SetOrdProp(aInstance, lPropInfo, lEnum);
      end;
    tkFloat:
      begin
      if aValue.JSONType <> jtNumber then
        raise EMCPException.CreateFmt(SErrPropertyType, [aPropName]);
      SetFloatProp(aInstance, lPropInfo, aValue.AsFloat);
      end;
    tkSString, tkLString, tkAString:
      begin
      if aValue.JSONType <> jtString then
        raise EMCPException.CreateFmt(SErrPropertyType, [aPropName]);
      SetStrProp(aInstance, lPropInfo, aValue.AsString);
      end;
    tkWString, tkUString:
      begin
      if aValue.JSONType <> jtString then
        raise EMCPException.CreateFmt(SErrPropertyType, [aPropName]);
      SetUnicodeStrProp(aInstance, lPropInfo, UTF8Decode(aValue.AsString));
      end;
  else
    // set/class/method/variant/record/...: writing complex kinds from JSON is out of scope;
    // refuse rather than silently mis-set.
    raise EMCPException.CreateFmt(SErrPropertyType, [aPropName]);
  end;
end;


{$IFDEF MCP_SERIALIZE_VISUAL}
function SnapshotComponentAsLFM(aComponent: TComponent): string;

var
  lStream : TStringStream;

begin
  lStream := TStringStream.Create('');
  try
    WriteComponentAsTextToStream(lStream, aComponent);
    Result := lStream.DataString;
  finally
    lStream.Free;
  end;
end;


function ScreenshotControlAsPNG(aControl: TWinControl): TBytes;

var
  lBmp : TBitmap;
  lPng : TPortableNetworkGraphic;
  lStream : TBytesStream;

begin
  lBmp := TBitmap.Create;
  try
    lBmp.SetSize(aControl.Width, aControl.Height);
    aControl.PaintTo(lBmp.Canvas, 0, 0);              // no-op if no handle; bitmap size stands
    lPng := TPortableNetworkGraphic.Create;
    try
      lPng.Assign(lBmp);
      lStream := TBytesStream.Create(nil);
      try
        lPng.SaveToStream(lStream);
        Result := Copy(lStream.Bytes, 0, lStream.Size);  // trim to actual size, not capacity
      finally
        lStream.Free;
      end;
    finally
      lPng.Free;
    end;
  finally
    lBmp.Free;
  end;
end;
{$ENDIF MCP_SERIALIZE_VISUAL}

end.

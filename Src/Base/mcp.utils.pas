{
    This file is part of the Free Component Library

    MCP utility routines and classes
    Copyright (c) 2025 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.utils;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, base64, syncobjs, contnrs;

type

  { TThreadSafeObjectHash }

  TThreadSafeObjectHash = record
  Private
    FLock : TCriticalSection;
    FList :  TFPObjectHashTable;
  Public
    class function create(aOwnsObjects : Boolean) : TThreadSafeObjectHash;  static;
    procedure Destroy;
    Procedure GetObjectList(aList : TFPList);
    procedure Add(aKey : String; aObject: TObject);
    function Get(aKey : string) : TObject;
    procedure Remove(aKey : string);
    procedure Lock;
    procedure Unlock;
    function Count : Integer;
  end;

function EncodeBytes(data : TBytes) : string;
function DecodeBytes(data : String) : TBytes;

implementation

function EncodeBytes(data : TBytes) : string;

var
  lRes : TStringStream;
  lEnc : TBase64EncodingStream;

begin
  lEnc:=Nil;
  lRes:=TStringStream.Create('');
  try
    lEnc:=TBase64EncodingStream.Create(lRes);
    Lenc.WriteBuffer(Data[0],Length(Data));
    lEnc.Flush;
    Result:=lRes.DataString;
  finally
    lEnc.Free;
    lRes.Free;
  end;
end;

function DecodeBytes(data: String): TBytes;
var
  lRes : TMemoryStream;
  lDec : TBase64DecodingStream;

begin
  Result:=Nil;
  if Data='' then
    exit;
  lDec:=Nil;
  lRes:=TMemoryStream.Create;
  try
    lDec:=TBase64DecodingStream.Create(lRes);
    LDec.WriteBuffer(Data[1],Length(Data));
    SetLength(Result,lRes.Size);
    if lRes.Size>0 then
      Move(lRes.Memory^,Result[0],lRes.Size);
  finally
    lDec.Free;
    lRes.Free;
  end;

end;

{ TThreadSafeObjectHash }

class function TThreadSafeObjectHash.create(aOwnsObjects : Boolean): TThreadSafeObjectHash;
begin
  Result.FList:=TFPObjectHashTable.Create(aOwnsObjects);
  Result.FLock:=TCriticalSection.Create;
end;

procedure TThreadSafeObjectHash.Destroy;
begin
  FreeAndNil(FList);
  FreeAndNil(Flock);
end;

{ TResourceLister }
Type

  { TObjectLister }

  TObjectLister = class(TObject)
    FList : TFPList;
    constructor Create(aList : TFPList) ;
    procedure ListObject(Item: TObject; const Key: string; var Continue: Boolean);
  end;

{ TObjectLister }

constructor TObjectLister.Create(aList: TFPList);
begin
  FList:=aList;
end;

procedure TObjectLister.ListObject(Item: TObject; const Key: string;
  var Continue: Boolean);
begin
  Flist.Add(Item);
  Continue:=True;
end;


procedure TThreadSafeObjectHash.GetObjectList(aList: TFPList);
begin
  Lock;
  if assigned(aList) then
    With TObjectLister.Create(aList) do
      try
        Self.FList.Iterate(@ListObject);
      finally
        free;
      end;
  // do not unlock!
end;

procedure TThreadSafeObjectHash.Add(aKey: String; aObject: TObject);
begin
  Lock;
  try
    FList.Add(aKey,aObject);
  finally
    Unlock;
  end;
end;

function TThreadSafeObjectHash.Get(aKey: string): TObject;
begin
  Lock;
  try
    Result:=FList[aKey];
  finally
    Unlock;
  end;
end;

procedure TThreadSafeObjectHash.Remove(aKey: string);
begin
  Lock;
  try
    FList.Delete(aKey);
  finally
    Unlock;
  end;
end;

procedure TThreadSafeObjectHash.Lock;
begin
  FLock.Acquire;
end;

procedure TThreadSafeObjectHash.Unlock;
begin
  FLock.Release;
end;

function TThreadSafeObjectHash.Count: Integer;
begin
  Result:=FList.Count;
end;

end.


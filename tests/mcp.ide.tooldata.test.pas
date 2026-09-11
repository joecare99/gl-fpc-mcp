unit mcp.ide.tooldata.test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, mcp.ide.tooldata;

type
  TMCPIDEToolDataTest = class(TTestCase)
  published
    procedure TestSameIDEFileMatchesNormalizedPaths;
    procedure TestSameIDEFileRejectsDifferentFiles;
    procedure TestNormalizeEditorRangeKeepsValidRange;
    procedure TestNormalizeEditorRangeClampsEnd;
    procedure TestNormalizeEditorRangeRejectsInvalidStart;
    procedure TestNormalizeEditorRangeRejectsReversedRange;
    procedure TestNormalizeEditorRangeRejectsMoreThan500Lines;
    procedure TestNormalizeEditorRangeRejectsStartAfterFile;
  end;

implementation

procedure TMCPIDEToolDataTest.TestSameIDEFileMatchesNormalizedPaths;
begin
  AssertTrue(SameIDEFile('C:\work\demo\main.pas',
    'C:\work\demo\.\main.pas'));
end;

procedure TMCPIDEToolDataTest.TestSameIDEFileRejectsDifferentFiles;
begin
  AssertFalse(SameIDEFile('C:\work\demo\main.pas',
    'C:\work\demo\other.pas'));
  AssertFalse(SameIDEFile('','C:\work\demo\main.pas'));
end;

procedure TMCPIDEToolDataTest.TestNormalizeEditorRangeKeepsValidRange;
var
  StartLine, EndLine: Integer;
begin
  AssertTrue(NormalizeEditorRange(10,20,100,StartLine,EndLine));
  AssertEquals(10,StartLine);
  AssertEquals(20,EndLine);
end;

procedure TMCPIDEToolDataTest.TestNormalizeEditorRangeClampsEnd;
var
  StartLine, EndLine: Integer;
begin
  AssertTrue(NormalizeEditorRange(90,120,100,StartLine,EndLine));
  AssertEquals(90,StartLine);
  AssertEquals(100,EndLine);
end;

procedure TMCPIDEToolDataTest.TestNormalizeEditorRangeRejectsInvalidStart;
var
  StartLine, EndLine: Integer;
begin
  AssertFalse(NormalizeEditorRange(0,10,100,StartLine,EndLine));
end;

procedure TMCPIDEToolDataTest.TestNormalizeEditorRangeRejectsReversedRange;
var
  StartLine, EndLine: Integer;
begin
  AssertFalse(NormalizeEditorRange(20,10,100,StartLine,EndLine));
end;

procedure TMCPIDEToolDataTest.TestNormalizeEditorRangeRejectsMoreThan500Lines;
var
  StartLine, EndLine: Integer;
begin
  AssertFalse(NormalizeEditorRange(1,501,1000,StartLine,EndLine));
end;

procedure TMCPIDEToolDataTest.TestNormalizeEditorRangeRejectsStartAfterFile;
var
  StartLine, EndLine: Integer;
begin
  AssertFalse(NormalizeEditorRange(101,110,100,StartLine,EndLine));
end;

initialization
  RegisterTest(TMCPIDEToolDataTest);

end.

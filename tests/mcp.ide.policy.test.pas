unit mcp.ide.policy.test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, fpcunit, testregistry, mcp.ide.policy;

type
  TMCPIDEPolicyTest = class(TTestCase)
  published
    procedure TestReadOnlyToolsAreAllowedByDefault;
    procedure TestActionToolsAskByDefault;
    procedure TestPolicyParsingUsesFallback;
    procedure TestArgumentSummaryIsBounded;
  end;

implementation

procedure TMCPIDEPolicyTest.TestReadOnlyToolsAreAllowedByDefault;
begin
  AssertEquals(Ord(mtpAllowed),Ord(MCPDefaultToolPolicy('getWorkspaceInfo')));
  AssertEquals(Ord(mtpAllowed),Ord(MCPDefaultToolPolicy('readEditorText')));
end;

procedure TMCPIDEPolicyTest.TestActionToolsAskByDefault;
begin
  AssertEquals(Ord(mtpAsk),Ord(MCPDefaultToolPolicy('compile')));
  AssertEquals(Ord(mtpAsk),Ord(MCPDefaultToolPolicy('openproject')));
end;

procedure TMCPIDEPolicyTest.TestPolicyParsingUsesFallback;
begin
  AssertEquals(Ord(mtpDisabled),Ord(MCPToolPolicyFromName('Disabled',mtpAsk)));
  AssertEquals(Ord(mtpAllowed),Ord(MCPToolPolicyFromName('allowed',mtpAsk)));
  AssertEquals(Ord(mtpAsk),Ord(MCPToolPolicyFromName('unknown',mtpAsk)));
end;

procedure TMCPIDEPolicyTest.TestArgumentSummaryIsBounded;
var
  O: TJSONObject;
  I: Integer;
  S: string;
begin
  O:=TJSONObject.Create;
  try
    for I:=1 to 500 do
      O.Add('key'+IntToStr(I),StringOfChar('x',10));
    S:=MCPToolArgumentSummary(O);
    AssertTrue(Length(S)<=400);
    AssertTrue(S<>'');
  finally
    O.Free;
  end;
end;

initialization
  RegisterTest(TMCPIDEPolicyTest);

end.

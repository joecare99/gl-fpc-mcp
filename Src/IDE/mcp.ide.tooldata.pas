unit mcp.ide.tooldata;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

function SameIDEFile(const A, B: string): Boolean;
function NormalizeEditorRange(RequestStart, RequestEnd, LineCount: Integer;
  out StartLine, EndLine: Integer): Boolean;

implementation

function SameIDEFile(const A, B: string): Boolean;
begin
  Result:=(A<>'') and (B<>'') and
    SameText(ExpandFileName(A),ExpandFileName(B));
end;

function NormalizeEditorRange(RequestStart, RequestEnd, LineCount: Integer;
  out StartLine, EndLine: Integer): Boolean;
begin
  Result:=False;
  StartLine:=RequestStart;
  EndLine:=RequestEnd;
  if (LineCount<1) or (StartLine<1) or (EndLine<StartLine) then Exit;
  if (EndLine-StartLine)>=500 then Exit;
  if StartLine>LineCount then Exit;
  if EndLine>LineCount then
    EndLine:=LineCount;
  Result:=True;
end;

end.

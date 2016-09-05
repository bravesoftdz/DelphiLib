unit NGString;

interface

function NextPos(const SubStr, Str: string; After: Integer): Integer;
function Slashed(const Path: string): string;
function Unslashed(const Path: string): string;

implementation

function NextPos(const SubStr, Str: string; After: Integer): Integer;
var
  i: Integer;
begin
  i := After + 1;
  while (i <= Length(Str) - Length(SubStr) + 1) and (Copy(Str, i, Length(SubStr)) <> SubStr) do i:=i+1;
  if i > Length(Str) - Length(SubStr) + 1 then i:=0;
  Result := i;
end;

function Slashed(const Path: string): string;
begin
  Result:= Path;
  if Copy(Path, Length(Path), 1) <> '\' then
    Result:= Result + '\';
end;

function Unslashed(const Path: string): string;
begin
  Result:= Path;
  if Copy(Path, Length(Path), 1) = '\' then
    Result:= Copy(Result, 1, Length(Path)-1);
end;

end.
 
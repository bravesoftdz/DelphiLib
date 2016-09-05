unit greek_iso_oem_win;

interface

uses Windows, SysUtils;

function ISOToWinChar(ch: char): char;
function ISOToWinStr(const str: string): string;
function OEMToWinChar(ch: char): char;
function OEMToWinStr(const str: string): string;
function WinToISOChar(ch: char): char;
function WinToISOStr(const str: string): string;

implementation

// translate a character from iso-8859-7 to Windows-1253
function ISOToWinChar(ch: char): char;
begin
  if ch = '¶' then
    Result := '¢'
  else
    Result := ch;
end;

// translate a string from iso-8859-7 to Windows-1253
function ISOToWinStr(const str: string): string;
var
  i, l: Integer;
begin
  Result := str;
  i := 1;
  l := Length(Result);
  while i <= l do begin
    while (i <= l) and (Result[i] <> '¶') do i := i + 1;
    if i <= l then Result[i] := '¢';
  end;
end;

// translate a char from OEM to Windows character set
function OEMToWinChar(ch: char): char;
begin
  OemToCharA(@ch, @Result);
end;

// translate a string from OEM to Windows character set
function OEMToWinStr(const str: string): string;
var
  buf: PChar;
begin
  GetMem(buf, Length(str)+1);
  StrCopy(buf, PChar(str));
  OemToCharA(buf, buf);
  SetLength(Result, Length(str));
  Result := buf;
  FreeMem(buf);
end;

// from Windows-1253 to iso-8859-7
function WinToISOChar(ch: char): char;
begin
  if ch = '¢' then
    Result := '¶'
  else
    Result := ch;
end;

// translate a string from Windows-1253 to iso-8859-7
function WinToISOStr(const str: string): string;
var
  i, l: Integer;
begin
  Result := str;
  i := 1;
  l := Length(Result);
  while i <= l do begin
    while (i <= l) and (Result[i] <> '¢') do i := i + 1;
    if i <= l then Result[i] := '¶';
  end;
end;

end.

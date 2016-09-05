unit NGOLE;

interface

uses Windows, ActiveX;

function CLSIDFromPasString(const s: string; var c: TCLSID): Boolean;
function IsValidGUIDOLEStr(w: POLEStr): Boolean;
function IsValidGUIDStr(const s: string): Boolean;
function PasStringFromCLSID(const c: TCLSID): string;

implementation

function CLSIDFromPasString(const s: string; var c: TCLSID): Boolean;
var
  w: PWideChar;
begin
  GetMem(w, 100);
  StringToWideChar(s, w, 50);
  Result:= CLSIDFromString(w, c) = S_OK;
  FreeMem(w);
end;

function IsValidGUIDOLEStr(w: POLEStr): Boolean;
var
  c: TCLSID;
begin
  Result:= CLSIDFromString(w, c) = S_OK;
end;

function IsValidGUIDStr(const s: string): Boolean;
var
  c: TCLSID;
  w: PWideChar;
begin
  GetMem(w, (Length(s)+1)*2);
  StringToWideChar(s, w, Length(s)+1);
  Result:= CLSIDFromString(w, c) = S_OK;
  FreeMem(w);
end;

function PasStringFromCLSID(const c: TCLSID): string;
var
  w: PWideChar;
begin
  if StringFromCLSID(c, w) = S_OK then
    Result := WideCharToString(w)
  else
    Result := '';
end;

end.
 
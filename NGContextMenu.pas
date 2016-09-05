unit NGContextMenu;

interface

uses Windows, SysUtils, ComObj, ActiveX, ShellAPI, ShlObj, Classes,
     NGOLE;

type
  TNGContextMenu = class(TComObject, IShellExtInit, IContextMenu)
  private
    FFiles: TStringList;
  public
    destructor Destroy; override;
    function QueryContextMenu(hMenu: HMENU; indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HRESULT; virtual; stdcall;
    function InvokeCommand(var cm: TCMInvokeCommandInfo): HRESULT; virtual; stdcall;
    function GetCommandString(idCmd, uType: UINT; pwReserved: PUINT; pszName: LPSTR; cchMax: UINT): HResult; virtual; stdcall;
    function Initialize(pidlFolder: PItemIDList; lpdobj: IDataObject; hKeyProgID: HKEY): HResult; virtual; stdcall;
    property Files: TStringList read FFiles;
  end;

function GetMenuCLSIDFromHKey(h: HKEY; var clsidStr: String): Boolean;
function GetMenuCLSIDFromKeyName(const keyName: string; var clsidStr: String): Boolean;

implementation

function GetMenuCLSIDFromHKey(h: HKEY; var clsidStr: String): Boolean;
var
  res, bufSize, wbufSize: Integer;
  buf: PAnsiChar;
  wbuf: PWideChar;
begin
  res:=RegQueryValueEx(h, nil, nil, nil, nil, @bufSize);
  Result:=False;
  if res = ERROR_SUCCESS then begin
    GetMem(buf, bufsize);
    res:= RegQueryValueEx(h, nil, nil, nil, PByte(buf), @bufSize);
    if res = ERROR_SUCCESS then begin
      clsidStr:= buf;
      wbufSize:= MultiByteToWideChar(CP_ACP, 0, buf, -1, nil, 0) * sizeof(widechar);
      GetMem(wbuf, wBufSize);
      MultiByteToWideChar(CP_ACP, 0, buf, -1, wbuf, wBufSize);
      Result:= IsValidGUIDOLEStr(wbuf);
      FreeMem(wbuf);
    end;
    FreeMem(buf);
  end;
end;

function GetMenuCLSIDFromKeyName(const keyName: string; var clsidStr: String): Boolean;
var
  h: HKEY;
begin
  if RegOpenKeyEx(HKEY_CLASSES_ROOT, PChar(keyname), 0,
                  KEY_ALL_ACCESS, h) = ERROR_SUCCESS then
    Result:=GetMenuCLSIDFromHKey(h, clsidstr)
  else
    Result:=False;
  RegCloseKey(h);
end;

destructor TNGContextMenu.Destroy;
begin
  FFiles.Free;
  inherited;
end;

function TNGContextMenu.QueryContextMenu(hMenu: HMENU; indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HRESULT;
begin
  Result:=0;
end;

function TNGContextMenu.InvokeCommand(var cm: TCMInvokeCommandInfo): HRESULT;
begin
  Result:= E_INVALIDARG;
end;

function TNGContextMenu.GetCommandString(idCmd, uType: UINT; pwReserved: PUINT; pszName: LPSTR; cchMax: UINT): HResult;
begin
  Result:=E_INVALIDARG;
end;

function TNGContextMenu.Initialize(pidlFolder: PItemIDList; lpdobj: IDataObject; hKeyProgID: HKEY): HResult;
var
  Buffer: array [0..MAX_PATH] of Char;
  medium: TStgMedium;
  fe: TFormatEtc;
  n, NumFiles: Integer;
begin
  with fe do
  begin
    cfFormat := CF_HDROP;
    ptd := Nil;
    dwAspect := DVASPECT_CONTENT;
    lindex := -1;
    tymed := TYMED_HGLOBAL;
  end;
  // Fail the call if lpdobj is Nil.
  if lpdobj = nil then
  begin
    Result := E_FAIL;
    Exit;
  end;
  // Render the data referenced by the IDataObject pointer to an HGLOBAL
  // storage medium in CF_HDROP format.
  Result := lpdobj.GetData(fe, medium);
  if Failed(Result) then Exit;
  // If only one file is selected, retrieve the file name and store it in
  // szFile. Otherwise fail the call.
  NumFiles:= DragQueryFile(medium.hGlobal, $FFFFFFFF, nil, 0);
  if NumFiles > 0 then
    try
      if FFiles<>nil then FFiles.Free;
      FFiles:=TStringList.Create;
      for N := 0 to NumFiles - 1 do
      begin
        DragQueryFile(medium.hGlobal, N, Buffer, MAX_PATH);
        FFiles.Add(StrPas(Buffer));
      end;
      Result := NOERROR;
    except
      Result := E_FAIL;
    end
  else
    Result := E_FAIL;
  ReleaseStgMedium(medium);
end;

end.

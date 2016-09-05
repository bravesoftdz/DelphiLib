Unit FileDlgs;

interface

Uses Windows, CommDlg, NGObjects;

const
  MaxFilterLength = 250;
  OpenFlags = OFN_EXPLORER Or OFN_PATHMUSTEXIST Or OFN_FILEMUSTEXIST Or OFN_HIDEREADONLY;
  SaveFlags = OFN_EXPLORER Or OFN_OVERWRITEPROMPT Or OFN_HIDEREADONLY;

type
  TFileDlgType = (dtOpen, dtSave);
  TFileName    = Array[0..MAX_PATH] Of Char;

  TFileDlg = class
  private
    Parent: HWnd;
    FDefExt, FTitle: PChar;
    FileList: TPointerList;
    procedure CreateFileList(MultiFiles: PChar);
    procedure FormatFilter;
    function GetCount: LongInt;
    function GetFiles(i: Integer): PChar;
    procedure SetDefExt(Value : PChar);
    procedure SetTitle(Value: PChar);
  public
    DialogType: TFileDlgType;
    FileName, FileTitle: TFileName;
    FilterIndex, Flags: Longint;
    Filter: Array[0..MaxFilterLength] Of Char;
    Hook: Pointer;
    TemplateName: Array[0..10] Of Char;
    constructor Create(AParent: HWnd; DlgType: TFileDlgType);
    destructor Destroy; override;
    function GetDialogType: TFileDlgType;
    function GetFileName: PChar;
    function GetFileTitle: PChar;
    function GetFilter: PChar;
    function Execute: Boolean;
    procedure LoadFilterFromRes(inst: THandle; ResID: Integer);
    procedure SetDialogType(Value: TFileDlgType);
    procedure SetFileName(Value : PChar);
    procedure SetFileTitle(Value : PChar);
    procedure SetFilter(Value : PChar);

    property Count: LongInt read GetCount;
    property DefExt: PChar read FDefExt write SetDefExt;
    property Files[i: Integer]: PChar read GetFiles;
    property Title: PChar read FTitle write SetTitle;
  end;

implementation

constructor TFileDlg.Create;
begin
  FileList:=TPointerList.Create;

  LStrCpy(FileName, '');
  LStrCpy(FileTitle, '');
  LStrCpy(Filter, '');
  LStrCpy(TemplateName, '');
  Hook:=nil;
  FTitle:=nil;
  FDefExt:=nil;
  Flags:=0;
  Parent:=AParent;
  FilterIndex:=1;
  DialogType:=DlgType;
end;

destructor TFileDlg.Destroy;
begin
  FileList.Free;
  FreeMem(Title, LStrLen(Title)+1);
  FreeMem(DefExt, LStrLen(DefExt)+1);
  inherited;
end;

function TFileDlg.GetCount: Longint;
begin
  If Flags And OFN_ALLOWMULTISELECT>0 Then
    GetCount:=FileList.Count
  else
    GetCount:=-1;
end;

function TFileDlg.GetDialogType: TFileDlgType;
begin
  GetDialogType:=DialogType;
end;

function TFileDlg.GetFileName: PChar;
begin
  GetFileName:=FileName;
end;

function TFileDlg.GetFiles(i: Integer): PChar;
begin
  try
    Result:=FileList.Get(i);
  except
    Result:=nil;
  end;
end;

function TFileDlg.GetFileTitle: PChar;
begin
  GetFileTitle:=FileTitle;
end;

function TFileDlg.GetFilter: PChar;
begin
  GetFilter:=Filter;
end;

function TFileDlg.Execute;
var
  OpenFN: TOpenFileName;
begin
  FormatFilter;

  FillChar(OpenFN, SizeOf(TOpenFileName), #0);
  with OpenFN do
  begin
    hInstance     := System.MainInstance;
    hwndOwner     := Parent;
    lpstrDefExt   := DefExt;
    lpstrFile     := FileName;
    lpstrFilter   := Filter;
    lpstrFileTitle:= FileTitle;
    lpstrTitle    := Title;
    lStructSize   := sizeof(TOpenFileName);
    nFilterIndex  := FilterIndex;
    nMaxFile      := MAX_PATH;
    lpfnHook      := Hook;
    lpTemplateName:= TemplateName;
  end;
  OpenFN.Flags:=Flags;
  If DialogType=dtOpen Then
    begin
      If GetOpenFileName(OpenFN) Then
        begin
          Execute:=True;
          If (Flags And OFN_ALLOWMULTISELECT)>0 Then CreateFileList(FileName);
        end
      else
        Execute:=False;
    end
  else
    Execute:=GetSaveFileName(OpenFN);
end;

procedure TFileDlg.LoadFilterFromRes;
begin
  LoadString(inst, ResID, Filter, MaxFilterLength);
end;

procedure TFileDlg.SetDefExt;
begin
  If FDefExt<>nil Then FreeMem(FDefExt, LStrLen(FDefExt)+1);
  GetMem(FDefExt, LStrLen(Value)+1);
  LStrCpy(FDefExt,Value);
end;

procedure TFileDlg.SetDialogType;
begin
  DialogType:=Value;
end;

procedure TFileDlg.SetFileName;
begin
  LStrCpy(FileName,Value);
end;

procedure TFileDlg.SetFileTitle;
begin
  LStrCpy(FileTitle,Value);
end;

procedure TFileDlg.SetFilter;
begin
  LStrCpy(Filter,Value);
end;

procedure TFileDlg.SetTitle;
begin
  If FTitle<>nil Then FreeMem(FTitle, LStrLen(FTitle)+1);
  GetMem(FTitle, LStrLen(Value)+1);
  LStrCpy(FTitle,Value);
end;

procedure TFileDlg.CreateFileList(MultiFiles: PChar);
var
  CurrDir, Temp: PChar;
  l: Integer;
begin
  FileList.DeleteAll;
  GetMem(CurrDir, MAX_PATH);
  LStrCpy(CurrDir, MultiFiles);
  l:=LStrLen(MultiFiles);
  While MultiFiles[l+1]<>#0 Do
    Begin
      GetMem(Temp, MAX_PATH);
      Inc(LongInt(MultiFiles), l+1);
      l:=LStrLen(MultiFiles);
      LStrCpy(Temp, CurrDir);
      LStrCat(Temp, '\');
      LStrCat(Temp, MultiFiles);
      FileList.Add(Temp);
    End;
  If FileList.Count=0 Then FileList.Add(CurrDir) else FreeMem(CurrDir);
end;

procedure TFileDlg.FormatFilter;
Var
  i: Byte;
begin
  i:=0;
  While Filter[i]<>#0 Do
    begin
      If Filter[i]='|' Then Filter[i]:=#0;
      Inc(i);
    end;
end;

end.
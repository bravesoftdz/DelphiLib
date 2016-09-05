
{*******************************************************}
{                                                       }
{       NGUnits: File Formats                           }
{       Resource file (*.res) support                   }
{                                                       }
{       Written by Nick Georgiou (1998)                 }
{                                                       }
{*******************************************************}

unit ResFile;

interface

uses Windows, SysUtils, Classes, Graphics;

type
  TDescription = string[100];

  TResName = string;
  TResValue = 1..32767;
  TResIDKind = (riValue, riName);
  TResID = record
    Kind: TResIDKind;
    Value: TResValue;
    Name: TResName;
  end;

  TResource = class;
  TResourceClass = class of TResource;
  TResourceList = class;

  PAssociation = ^TAssociation;
  TAssociation = record
    ResID: TResID;
    ResClass: TResourceClass;
    Description: TDescription;
  end;

  TEnumResIDProc = procedure (const AResID: TResID);
  TEnumResTypesProc = procedure (AResList: TResourceList; const AResID: TResID; const ADesc: TDescription);
  TEnumResItemProc = procedure (AResItem: TResource);

  TResource = class(TPersistent)
  private
    FResList: TResourceList;
    FResID, FResType: TResID;
    FSize: Integer;
  public
    constructor Create(AResList: TResourceList; const AResType, AResID: TResID);
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure SaveToStream(Stream: TStream); virtual;
    property ResList: TResourceList read FResList;
    property ResID: TResID read FResID write FResID;
    property ResType: TResID read FResType;
    property Size: Integer read FSize write FSize;
  end;

  TResourceList = class(TList)
  private
    function GetResItems(Index: Integer): TResource;
    procedure SetResItems(Index: Integer; Value: TResource);
  public
    destructor Destroy; override;
    procedure CleanUp; virtual;
    procedure LoadFromStream(Stream: TStream); virtual; abstract;
    procedure SaveToStream(Stream: TStream); virtual; abstract;
    procedure LoadFromFile(const FileName: String);
    procedure SaveToFile(const FileName: String);

    function ReadStreamResID(Stream: TStream): TResID; virtual; abstract;
    procedure WriteStreamResID(Stream: TStream; const AResID: TResID); virtual; abstract;

    procedure EnumResTypes(EProc: TEnumResTypesProc);
    procedure EnumResItemsOfType(EProc: TEnumResItemProc; const AType: TResID);

    property ResItems[Index: Integer]: TResource read GetResItems write SetResItems;
  end;

  TResourceList16 = class(TResourceList)
  public
    function ReadStreamResID(Stream: TStream): TResID; override;
    procedure WriteStreamResID(Stream: TStream; const AResID: TResID); override;

    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end;

  TResourceList32 = class(TResourceList)
    function ReadStreamResID(Stream: TStream): TResID; override;
    procedure WriteStreamResID(Stream: TStream; const AResID: TResID); override;

    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end;

  TResourceFactory = class
  private
    FList: TList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterClass(AClass: TResourceClass; const AResType: TResID; const Desc: TDescription);
    function GetAssociation(const AResID: TResID): PAssociation;
    function GetAssociatedClass(const AResID: TResID): TResourceClass;
    function GetDescription(const AResID: TResID): TDescription;
  end;

  TUnknowResource = class(TResource)
  end;

  TBitmapResource = class(TResource)
  private
    FBitmap: TBitmap;
  public
    constructor Create(AResList: TResourceList; const AResID: TResID);
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    property Bitmap: TBitmap read FBitmap;
  end;

  TDataResource = class(TResource)
  public
  end;

  T501Res = class(TResource)
  public
    FirstName, LastName: String;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end;

  T502Res = class(T501Res)
  public
    Address: String;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end;

function ReadStreamStr(Stream: TStream): String;
procedure WriteStreamStr(Stream: TStream; const Str: String);

function IsEqualResID(const ResID1, ResID2: TResID): Boolean;
function NameResID(const Str: string): TResID;
function ValueResID(id: TResValue): TResID;
function ResIDToString(const AResID: TResID): string;

const
  NullResID : TResID = (Kind: riName; Name: '');
  BitmapResID: TResID = (Kind: riValue; Value: 2);

var
  AvailTypes: TList;
  ResourceFactory: TResourceFactory;

implementation

{ *** utility functions *** }

function ReadStreamStr(Stream: TStream): String;
var
  Len: Integer;
begin
  Stream.Read(Len, SizeOf(Len));
  SetLength(Result, Len);
  Stream.Read(Result[1], Len);
end;

procedure WriteStreamStr(Stream: TStream; const Str: String);
var
  Len: Integer;
begin
  Len:=Length(Str);
  Stream.Write(Len, SizeOf(Len));
  Stream.Write(Str[1], Len);
end;

function IsEqualResID(const ResID1, ResID2: TResID): Boolean;
begin
  Result:=ResID1.Kind = ResID2.Kind;
  if Result then
    if ResID1.Kind = riValue then
      Result:=ResID1.Value = ResID2.Value
    else
      Result:=ResID1.Name = ResID1.Name;
end;

function NameResID(const Str: string): TResID;
begin
  Result.Kind := riName;
  Result.Name := Str;
end;

function ValueResID(id: TResValue): TResID;
begin
  Result.Kind := riValue;
  Result.Value := id;
end;

{function SizeOfResIDBuffer(const ResID: TResID): Integer;
begin
  if ResID.Kind = riValue then
    Result:=3
  else
    Result:=Length(ResID.Name) + 1;
end;

function ResIDToBuffer(const ResID: TResID; Buffer: PChar; var Size: Integer): Boolean;
var
  Needed: Integer;
begin
  Needed:=SizeOfResIDBuffer(ResID);
  Result:=Size>=Needed;
  Size:=Needed;
  if Result then
    if ResID.Kind = riValue then
      begin
        Byte((@Buffer[0])^):=$FF;
        Word((@Buffer[1])^):=ResID.Value;
      end
    else
      StrUpper(StrPLCopy(Buffer, ResID.Name, 63));
end;

function BufferToResID(Buffer: PChar; var ResID: TResID): Integer;
begin
  if Byte((@Buffer[0])^) = $FF then
    begin
      ResID.Kind:=riValue;
      ResID.Value:=Word((@Buffer[1])^);
    end
  else
    begin
      ResID.Kind:=riName;
      ResID.Name:=Buffer;
      ResID.Name[0]:=Chr(StrLen(Buffer));
    end;
  Result:=SizeOfResIDBuffer(ResID);
end;
}
{function ReadStreamResName(Stream: TStream): TResourceName;
var
  Size: Integer;
  Buf: PChar;
begin
  GetMem(Buf, 64);
  FillChar(Buf^, 64, #0);
  Size:=Stream.Size - ( Stream.Position + 1);
  if Size>64 then Size:=64;
  Stream.Read(Buf[0], Size);

  Result:=Buf;
  Result[0]:=Chr(StrLen(Buf));
  FreeMem(Buf);
  Stream.Seek(Length(Result)+1-Size, soFromCurrent);
end;}

{function ReadStreamResID(Stream: TStream): TResID;
var
  Bt: Byte;
begin
  Stream.Read(Bt, SizeOf(Bt));
  if Bt = $FF then
    begin
      Result.Kind:=riValue;
      Stream.Read(Result.Value, SizeOf(Result.Value));
    end
  else
    begin
      Result.Kind:=riName;
      Stream.Seek(-1, soFromCurrent);
      Result.Name:=ReadStreamResName(Stream);
    end;
end;}

{procedure WriteStreamResID(Stream: TStream; const ResID: TResID);
var
  Bt: Byte;
begin
  if ResID.Kind = riValue then
    begin
      Bt:=$FF;
      Stream.Write(Bt, SizeOf(Bt));
      Stream.Write(ResID.Value, SizeOf(ResID.Value));
    end
  else
    begin
      Bt:=$00;
      Stream.Write(ResID.Name[1], Length(ResID.Name));
      Stream.Write(Bt, SizeOf(Bt));
    end;
end;}

function ResIDToString(const AResID: TResID): string;
begin
  if AResID.Kind  = riValue then
    Result:=IntToStr(AResID.Value)
  else
    Result:=AResID.Name;
end;

procedure WriteZero(Stream: TStream; Len: Integer);
var
  p: Pointer;
begin
  if Len > 0 then begin
    GetMem(p, Len);
    FillChar(p^, Len, #0);
    Stream.Write(p^, Len);
    FreeMem(p);
  end;
end;

{ *** TResourceFactory class *** }

constructor TResourceFactory.Create;
begin
  inherited;
  FList:=TList.Create;
  RegisterClass(TBitmapResource, BitmapResID, 'Bitmap');
  RegisterClass(T501Res, ValueResID(501), '501');
  RegisterClass(T502Res, NameResID('Address'), 'Address');
end;

destructor TResourceFactory.Destroy;
var
  i: Integer;
begin
  For i:=0 to FList.Count - 1 do Dispose(FList.Items[i]);
  FList.Free;
  inherited;
end;

procedure TResourceFactory.RegisterClass(AClass: TResourceClass; const AResType: TResID; const Desc: TDescription);
var
  a: PAssociation;
begin
  if GetAssociatedClass(AResType) = nil then begin
    New(a);
    a^.ResID:=AResType;
    a^.ResClass:=AClass;
    a^.Description:=Desc;
    FList.Add(a);
  end;
end;

function TResourceFactory.GetAssociation(const AResID: TResID): PAssociation;
var
  i: Integer;
begin
  Result:=nil;
  For i:=0 to FList.Count - 1 do
    if IsEqualResID(PAssociation(FList.Items[i])^.ResID, AResID) then begin
      Result:=FList.Items[i];
      Break;
    end;
end;

function TResourceFactory.GetAssociatedClass(const AResID: TResID): TResourceClass;
var
  A: PAssociation;
begin
  A:=GetAssociation(AResID);
  if A<>nil then Result:=A^.ResClass else Result:=nil;
end;

function TResourceFactory.GetDescription(const AResID: TResID): TDescription;
var
  A: PAssociation;
begin
  A:=GetAssociation(AResID);
  if A<>nil then Result:=A^.Description else Result:='';
end;

{ *** TResourceList class *** }

{ TResourceList.Destroy }

destructor TResourceList.Destroy;
begin
  CleanUp;
  inherited Destroy;
end;

{ TResourceList.ResItems property }

function TResourceList.GetResItems(Index: Integer): TResource;
begin
  Result:=TResource(inherited Items[Index]);
end;

procedure TResourceList.SetResItems(Index: Integer; Value: TResource);
begin
  inherited Items[Index]:=Value;
end;

{ TResourceList.CleanUp ensures that all classes are freed }

procedure TResourceList.CleanUp;
var
  i: Integer;
begin
  For i:=0 to Count - 1 do ResItems[i].Free;
  Clear;
end;

{ The following two methods create a new TFileStream object
  based on FileName and pass it to their coresponding stream method.
  For example LoadFromFile calls LoadFromStream. }

procedure TResourceList.LoadFromFile(const FileName: String);
var
  Stream: TFileStream;
begin
  Stream:=TFileStream.Create(FileName, fmOpenRead);
  LoadFromStream(Stream);
  Stream.Free;
end;

procedure TResourceList.SaveToFile(const FileName: String);
var
  Stream: TFileStream;
begin
  Stream:=TFileStream.Create(FileName, fmCreate);
  SaveToStream(Stream);
  Stream.Free;
end;

procedure TResourceList.EnumResTypes(EProc: TEnumResTypesProc);
var
  IsDuplicate: Boolean;
  i, b: Integer;
begin
  IsDuplicate:=False;
  For i:=0 to Count - 1 do begin
    For b:=0 to i - 1 do begin
      IsDuplicate:=IsEqualResID(ResItems[b].ResType, ResItems[i].ResType);
      if IsDuplicate then Break;
    end;
    if not IsDuplicate then EProc(Self, ResItems[i].ResType, ResourceFactory.GetDescription(ResItems[i].ResType));
  end;
end;

procedure TResourceList.EnumResItemsOfType(EProc: TEnumResItemProc; const AType: TResID);
var
  i: Integer;
begin
  if IsEqualResID(AType, NullResID) then
    For i:=0 to Count - 1 do EProc(ResItems[i])
  else
    For i:=0 to Count - 1 do
      if IsEqualResID(AType, ResItems[i].ResType) then EProc(ResItems[i]);
end;



procedure Panic(const Msg: string);
begin
  raise Exception.Create(Msg);
end;

function EOS(Stream: TStream): Boolean;
begin
  Result:=Stream.Position + 1 >= Stream.Size;
end;

function ReadPAnsiChar(Stream: TStream): PAnsiChar;
var
  CharCount: Integer;
  ch: AnsiChar;
  Buf: PAnsiChar;
begin
  CharCount:=0;
  repeat
    if not EOS(Stream) then begin
      Inc(CharCount);
      Stream.Read(ch, SizeOf(ch));
    end;
  until EOS(Stream) or (ch = #0);
  if CharCount <> 0 then begin
    Stream.Seek(-CharCount*SizeOf(ch), soFromCurrent);
    GetMem(Buf, CharCount);
    Stream.Read(Buf^, CharCount);
    Result:=Buf;
  end
  else Result:=nil;
end;

function TResourceList16.ReadStreamResID(Stream: TStream): TResID;
var
  ValueFlag: Byte;
  Buf: PAnsiChar;
begin
  Stream.Read(ValueFlag, SizeOf(ValueFlag));
  if ValueFlag = $FF then {value resid}
    begin
      Result.Kind:=riValue;
      Stream.Read(Result.Value, SizeOf(Result.Value));
    end
  else
    begin
      Result.Kind:=riName;
      Stream.Seek(-SizeOf(ValueFlag), soFromCurrent);
      Buf:=ReadPAnsiChar(Stream);
      if Buf<>nil then
        begin
          Result.Name:=StrPas(Buf);
          FreeMem(Buf);
        end
      else
        Result.Name:='';
    end;
end;

procedure TResourceList16.WriteStreamResID(Stream: TStream; const AResID: TResID);
var
  ValueFlag: Byte;
  Buf: PChar;
begin
  if AResID.Kind = riValue then
    begin
      ValueFlag:=$FF;
      Stream.Write(ValueFlag, SizeOf(ValueFlag));
      Stream.Write(AResID.Value, SizeOf(AResID.Value));
    end
  else
    begin
      GetMem(Buf, Length(AResID.Name)+1);
      StrPCopy(Buf, AResID.Name);
      Stream.Write(Buf[0], Length(AResID.Name)+1);
      FreeMem(Buf);
    end;
end;

procedure TResourceList16.LoadFromStream(Stream: TStream);
var
  ResType, ResID: TResID;
  Flag: Word;
  Size: LongInt;
  NewClass: TResource;
begin
  CleanUp;
  while not EOS(Stream) do begin
    ResType:=ReadStreamResID(Stream);
    ResID:=ReadStreamResID(Stream);
    Stream.Read(Flag, SizeOf(Flag));
    //if Flag<>$1030 then ERROR!!!
    Stream.Read(Size, SizeOf(Size));
    NewClass:=ResourceFactory.GetAssociatedClass(ResType).Create(Self, ResType, ResID);
    NewClass.Size:=Size;
    NewClass.LoadFromStream(Stream);
  end;
end;

procedure TResourceList16.SaveToStream(Stream: TStream);
var
  i: Integer;
  ResFlag: Word;
  Origin, ImageSize: Longint;
begin
  For i:=0 to Count - 1 do begin
    WriteStreamResID(Stream, ResItems[i].ResType);
    WriteStreamResID(Stream, ResItems[i].ResID);
    ResFlag:=$1030;
    Stream.Write(ResFlag, SizeOf(ResFlag));
    WriteZero(Stream, SizeOf(LongInt));
    Origin := Stream.Position;
    ResItems[i].SaveToStream(Stream);
    ImageSize := Stream.Position - Origin;
    Stream.Position := Origin - 4;
    Stream.Write(ImageSize, SizeOf(Longint));
    Stream.Position := Origin + ImageSize;
  end;
end;




function ReadPWideChar(Stream: TStream): string;
var
  ch: WideChar;
  Buf: WideString;
begin
  Buf := '';
  ch := 'A';
  while (not EOS(Stream)) and (ch <> #0) do begin
    Stream.Read(ch, SizeOf(ch));
    if ch <> #0 then Buf := Buf + widestring(ch);
  end;
  Result := Buf;
end;

type
  TRes32Header = array [0..7] of LongInt;
const
  Res32Header: TRes32Header = (0, 32, $00FFFF, $00FFFF, 0, 0, 0, 0);

function TResourceList32.ReadStreamResID(Stream: TStream): TResID;
var
  ValueFlag: Word;
begin
  Stream.Read(ValueFlag, SizeOf(ValueFlag));
  if ValueFlag = $FFFF then {value resid}
    begin
      Result.Kind:=riValue;
      Stream.Read(Result.Value, SizeOf(Result.Value));
    end
  else
    begin
      Result.Kind:=riName;
      Stream.Seek(-SizeOf(ValueFlag), soFromCurrent);
      Result.Name := ReadPWideChar(Stream);
    end;
end;

procedure TResourceList32.WriteStreamResID(Stream: TStream; const AResID: TResID);
var
  ValueFlag: Word;
  Buf: PWideChar;
begin
  if AResID.Kind = riValue then
    begin
      ValueFlag:= $FFFF;
      Stream.Write(ValueFlag, SizeOf(ValueFlag));
      Stream.Write(AResID.Value, SizeOf(AResID.Value));
    end
  else
    begin
      GetMem(Buf, (Length(AResID.Name) + 1) * 2);
      StringToWideChar(AResID.Name, Buf, Length(AResID.Name) + 1);
      Stream.Write(Buf^, (Length(AResID.Name) + 1) * 2);
      FreeMem(Buf);
    end;
end;

procedure TResourceList32.LoadFromStream(Stream: TStream);
var
  AHeader: TRes32Header;
  DataSize, DataOffset, k: LongInt;
  ResType, ResName: TResID;
  NewRes: TResource;
begin
  Stream.Read(AHeader, SizeOf(AHeader));
  if (AHeader[0] = Res32Header[0]) and
     (AHeader[1] = Res32Header[1]) and
     (AHeader[2] = Res32Header[2]) and
     (AHeader[3] = Res32Header[3]) and
     (AHeader[4] = Res32Header[4]) and
     (AHeader[5] = Res32Header[5]) and
     (AHeader[6] = Res32Header[6]) and
     (AHeader[7] = Res32Header[7]) then
    begin
      while Stream.Position < Stream.Size do begin
      k:=Stream.Position;
      Stream.Read(DataSize, SizeOf(DataSize));
      Stream.Read(DataOffset, SizeOf(DataOffset));
      ResType:=ReadStreamResID(Stream);
      ResName:=ReadStreamResID(Stream);
      NewRes := TResource.Create(Self, ResType, ResName);
      NewRes.Size := DataSize;
      Stream.Seek(k - Stream.Position + DataOffset, soFromCurrent);
      NewRes.LoadFromStream(Stream);
      k := Stream.Position mod 4;
      if k <> 0 then k := 4 - k;
      Stream.Seek(k, soFromCurrent);
      end;

    end
  else
    Panic('Not a 32 bit res file');
end;

procedure TResourceList32.SaveToStream(Stream: TStream);
begin
end;

{ *** TResource abstract class *** }

constructor TResource.Create(AResList: TResourceList; const AResType, AResID: TResID);
begin
  inherited Create;
  FResList:=AResList;
  FResType := AResType;
  if FResList.IndexOf(Self)=-1 then FResList.Add(Self);
  FResID:=AResID;
end;

procedure TResource.LoadFromStream(Stream: TStream);
var
  Buf: Pointer;
begin
  GetMem(Buf, Size);
  Stream.Read(Buf^, Size);
  FreeMem(Buf);
end;

procedure TResource.SaveToStream(Stream: TStream);
begin
end;

{ *** TBitmapResource class *** }

constructor TBitmapResource.Create(AResList: TResourceList; const AResID: TResID);
begin
  inherited Create(AResList, BitmapResID, AResID);
  FBitmap:=TBitmap.Create;
end;

destructor TBitmapResource.Destroy;
begin
  FBitmap.Free;
  inherited;
end;

procedure TBitmapResource.LoadFromStream(Stream: TStream);
var
  MemStr: TMemoryStream;
  BH: TBitmapFileHeader;
begin
  FillChar(BH, sizeof(BH), #0);
  BH.bfType := $4D42;
  BH.bfSize := Size + SizeOf(BH);

  MemStr:=TMemoryStream.Create;
  MemStr.Write(BH, SizeOf(BH));
  MemStr.CopyFrom(Stream, Size);
  MemStr.Seek(0, 0);
  FBitmap.LoadFromStream(MemStr);
  MemStr.Free;
end;

procedure TBitmapResource.SaveToStream(Stream: TStream);
var
  MemStr: TMemoryStream;
begin
  MemStr:=TMemoryStream.Create;
  FBitmap.SaveToStream(MemStr);
  MemStr.Seek(SizeOf(TBitmapFileHeader), 0);
  Stream.CopyFrom(MemStr, MemStr.Size - SizeOf(TBitmapFileHeader));
  MemStr.Free;
end;

{ *** TDataResource abstract class *** }

{class function TDataResource.ResType: TResID;
begin
  Result.Kind:=riValue;
  Result.Value:=10;
end;}

{ *** T501Res demo class *** }

procedure T501Res.LoadFromStream(Stream: TStream);
begin
  FirstName:=ReadStreamStr(Stream);
  LastName:=ReadStreamStr(Stream);
end;

procedure T501Res.SaveToStream(Stream: TStream);
begin
  WriteStreamStr(Stream, FirstName);
  WriteStreamStr(Stream, LastName);
end;

{ *** T502Res demo class *** }

procedure T502Res.LoadFromStream(Stream: TStream);
begin
  inherited;
  Address:=ReadStreamStr(Stream);
end;

procedure T502Res.SaveToStream(Stream: TStream);
begin
  inherited;
  WriteStreamStr(Stream, Address);
end;

initialization
  ResourceFactory:=TResourceFactory.Create;

finalization
  ResourceFactory.Free;
end.

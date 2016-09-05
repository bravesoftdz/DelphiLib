unit NGSafe;

interface

uses SysUtils;

const
  MAX_PASSWORD = 6;
  Header: array [1..MAX_PASSWORD] of Char = ('N','G','S','A','F','E');
  MaxBuf   = 16384;

  ERROR_SUCCESS = 1;
  ERROR_FILE_NOT_ENCODED   = -1;
  ERROR_PASSWORD_INVALID   = -2;
  ERROR_GENERAL_FAILURE    = -3;
  ERROR_CANT_OPEN_SOURCE   = -4;
  ERROR_CANT_OPEN_DEST     = -5;
  ERROR_CANT_READ_SOURCE   = -6;
  ERROR_CANT_WRITE_DEST    = -7;
  ERROR_CANT_CLOSE_SOURCE  = -8;
  ERROR_CANT_CLOSE_DEST    = -9;
  ERROR_CANT_DELETE_SOURCE = -10;
  ERROR_CANT_RENAME_DEST   = -11;

type
  TPassword = string[MAX_PASSWORD];

function EncodeFile(Source, Dest: string; const Password: TPassword; DeleteSource: Boolean): LongInt;
function DecodeFile(Source, Dest: string; const Password: TPassword; DeleteSource: Boolean): LongInt;

implementation

uses Windows;

procedure GenerateSeeds(const Password: TPassword; var Seed1, Seed2: Integer);
var
  i, j: Integer;
begin
  Seed1:=0;
  Seed2:=0;
  j:=Length(Password);
  for i:=1 to length(password) do
    begin
      seed1:=seed1 + (Ord(Password[i]) * i);
      seed2:=seed2 + (Ord(Password[i]) * j);
      j:=j-1;
    end;
end;

function WipeDeleteFile(var F: file; Num: Double): Boolean;
var
  Buffer: array [1..MaxBuf] of Byte;
begin
  Result:=True;
  FillChar(Buffer, MaxBuf, #0);
  try
    Rewrite(F, 1);
    while Num>0 do begin
      if Num > MaxBuf then
        BlockWrite(F, Buffer, MaxBuf)
      else
        BlockWrite(F, Buffer, Trunc(Num));
      Num:=Num-MaxBuf;
    end;
    CloseFile(F);
    Erase(F);
  except
    Result:=False;
  end;
end;

function EncodeFile(Source, Dest: string; const Password: TPassword; DeleteSource: Boolean): LongInt;
var
  Seed1, Seed2: Integer;
  SourceF, TempF: File;
  i1, i2: Byte;
  rr, i: Integer;
  Buffer: array[1..MaxBuf] of Byte;
  BytesRead: Double;
  Temp, TempPath: array[0..MAX_PATH] of Char;
begin
  Result:=ERROR_GENERAL_FAILURE;
  try
    GenerateSeeds(Password, Seed1, Seed2);
    GetTempPath(MAX_PATH, TempPath);
    GetTempFileName(TempPath, 'NGS', 0, Temp);
    AssignFile(SourceF, Source);
    AssignFile(TempF, Temp);
    Result:= ERROR_CANT_OPEN_SOURCE;
    Reset(SourceF, 1);
    Result:= ERROR_CANT_OPEN_DEST;
    Rewrite(TempF, 1);
    Result:= ERROR_CANT_WRITE_DEST;
    BlockWrite(TempF, Header, MAX_PASSWORD);
    BlockWrite(TempF, Seed1, SizeOf(Seed1));
    BlockWrite(TempF, Seed2, SizeOf(Seed2));

    i1:=Seed1;
    i2:=Seed2;
    BytesRead:=0;
    Result:= ERROR_CANT_READ_SOURCE;
    BlockRead(SourceF, Buffer, MaxBuf, rr);
    BytesRead:=BytesRead+rr;
    while rr>0 do begin
      for i:=1 to rr do begin
        i1:=i1-i;
        i2:=i2+i;
        if Odd(i) then Dec(Buffer[i],i1) else Inc(Buffer[i], i2);
      end;
      Result:= ERROR_CANT_WRITE_DEST;
      BlockWrite(TempF, Buffer, rr);
      Result:= ERROR_CANT_READ_SOURCE;
      BlockRead(SourceF, Buffer, MaxBuf, rr);
      BytesRead:=BytesRead+rr;
    end;
    Result:= ERROR_CANT_CLOSE_SOURCE;
    CloseFile(SourceF);
    Result:= ERROR_CANT_CLOSE_DEST;
    CloseFile(TempF);

    Result:= ERROR_CANT_DELETE_SOURCE;
    if DeleteSource or (CompareText(Source, Dest)=0) then WipeDeleteFile(SourceF, BytesRead);

    Result:= ERROR_CANT_RENAME_DEST;
    Rename(TempF, Dest);
    Result:= ERROR_SUCCESS;
  except
    if Result = ERROR_CANT_RENAME_DEST then
      Erase(TempF);
  end;
end;

function DecodeFile(Source, Dest: string; const Password: TPassword; DeleteSource: Boolean): LongInt;
var
  Seed1, Seed2, Seed1x, Seed2x: Integer;
  SourceF, TempF: file;
  i1, i2: Byte;
  rr, i: Integer;
  Buffer: array[1..MaxBuf] of Byte;
  Temp, TempPath: array[0..MAX_PATH] of Char;
  BytesRead: Double;
  CheckHeader: array [1..6] of Char;
begin
  Result:=ERROR_GENERAL_FAILURE;
  GenerateSeeds(Password, Seed1x, Seed2x);
  try
    AssignFile(SourceF, Source);
    Reset(SourceF, 1);
    BlockRead(SourceF, CheckHeader, MAX_PASSWORD);
    if CheckHeader<>Header then begin
      Result:=ERROR_FILE_NOT_ENCODED;
      CloseFile(SourceF);
      Exit;
    end;
    BlockRead(SourceF, Seed1, SizeOf(Seed1));
    BlockRead(SourceF, Seed2, SizeOf(Seed2));
    if (Seed1<>Seed1x) or (Seed2<>Seed2x) then begin
      Result:=ERROR_PASSWORD_INVALID;
      CloseFile(SourceF);
      Exit;
    end;
  except
    Result:=ERROR_FILE_NOT_ENCODED;
    try
      CloseFile(SourceF);
    except
    end;
    Exit;
  end;
  try
    GetTempPath(MAX_PATH, TempPath);
    GetTempFileName(TempPath, 'NGS', 0, Temp);
    AssignFile(TempF, Temp);
    Rewrite(TempF, 1);

    i1:=Seed1;
    i2:=Seed2;
    BytesRead:=0;
    BlockRead(SourceF, Buffer, MaxBuf, rr);
    BytesRead:=BytesRead + rr;
    while rr>0 do begin
      for i:=1 to rr do begin
        Dec(i1, i);
        Inc(i2, i);
        if Odd(i) then Inc(Buffer[i], i1) else Dec(Buffer[i], i2);
      end;
      Result:= ERROR_CANT_WRITE_DEST;
      BlockWrite(TempF, Buffer, rr);
      Result:= ERROR_CANT_READ_SOURCE;
      BlockRead(SourceF, Buffer, MaxBuf, rr);
      BytesRead:=BytesRead+rr;
    end;

    Result:= ERROR_CANT_CLOSE_SOURCE;
    CloseFile(SourceF);
    Result:= ERROR_CANT_CLOSE_DEST;
    CloseFile(TempF);

    Result:= ERROR_CANT_DELETE_SOURCE;
    if DeleteSource or (CompareText(Source, Dest) = 0) then
       WipeDeleteFile(SourceF, BytesRead);
    Result:= ERROR_CANT_RENAME_DEST;
    Rename(TempF, Dest);
    Result:= ERROR_SUCCESS;
  except
    if Result = ERROR_CANT_RENAME_DEST then
      Erase(TempF);
  end;
end;

end.


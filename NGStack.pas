unit NGStack;

interface

type
  PSingleListNode = ^TSingleListNode;
  TSingleListNode = record
    Data: Pointer;
    Next: PSingleListNode;
  end;

  TOnDeleteItemEvent = procedure (Sender: TObject; Item: Pointer) of object;

  TSingleList = class
  private
    FFirst, FLast: PSingleListNode;
    FOnDeleteItem: TOnDeleteItemEvent;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(NewValue: Pointer);
    procedure Reset;
    property First: PSingleListNode read FFirst;
    property Last: PSingleListNode read FLast;
    property OnDeleteItem: TOnDeleteItemEvent read FOnDeleteItem write FOnDeleteItem;
  end;

  TSimpleStack = class
  private
    FTop: Integer;
    FSize: Integer;
    FBuf: PChar;
  public
    constructor Create(Size: Integer);
    destructor Destroy; override;
    function AsString: string;
    function Empty: Boolean;
    function Full: Boolean;
    function Push(ch: Char): Boolean;
    property Size: Integer read FSize;
    property Top: Integer read FTop;
  end;

const
  DefCapacity = 20;

type
  TStack = class
  private
    FChunkList: TSingleList;
    FCapacity: Cardinal;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Push(ch: Char);
    function AsString: string;
    property Capacity: Cardinal read FCapacity write FCapacity default DefCapacity;
  end;

implementation

constructor TSingleList.Create;
begin
  inherited Create;
  FFirst := nil;
end;

destructor TSingleList.Destroy;
begin
  Reset;
  inherited Destroy;
end;

procedure TSingleList.Add(NewValue: Pointer);
var
  PrevNode: PSingleListNode;
begin
  if FFirst = nil then
    begin
      New(FLast);
      FLast^.Data := NewValue;
      FFirst := FLast;
      FLast^.Next := nil;
    end
  else
    begin
      PrevNode := FLast;
      New(FLast);
      FLast^.Data := NewValue;
      PrevNode^.Next := FLast;
      FLast^.Next := nil;
    end;
end;

procedure TSingleList.Reset;
var
  q: PSingleListNode;
begin
  while FFirst<>nil do begin
    q:= FFirst^.Next;
    if Assigned(FOnDeleteItem) then FOnDeleteItem(Self, FFirst^.Data);
    Dispose(FFirst);
    FFirst:=q;
  end;
end;

constructor TSimpleStack.Create(Size: Integer);
begin
  inherited Create;
  FSize := Size;
  GetMem(FBuf, FSize);
  FTop := 0;
end;

destructor TSimpleStack.Destroy;
begin
  FreeMem(FBuf);
  inherited;
end;

function TSimpleStack.AsString: string;
begin
  SetLength(Result
end;

function TSimpleStack.Empty: Boolean;
begin
  Result := FTop = 0;
end;

function TSimpleStack.Full: Boolean;
begin
  Result := FTop = FSize;
end;

function TSimpleStack.Push(ch: Char): Boolean;
begin
  FBuf[FTop] := ch;
end;

constructor TStack.Create;
begin
  inherited;
  FChunkList := TSingleList.Create;
  FCapacity := DefCapacity;
end;

destructor TStack.Destroy;
begin
  FChunkList.Free;
  inherited;
end;

procedure TStack.Push(ch: Char);
var
  chunk: TSimpleStack;
begin
  if (FChunkList.Last = nil) or TSimpleStack(FChunkList.Last.Data).Full then begin
    chunk := TSimpleStack.Create(FCapacity);
    FChunkList.Add(chunk);
  end
  else
    chunk := TSimpleStack(FChunkList.Last.Data);
  chunk.Push(ch);
end;

function TStack.AsString: string;
begin
end;

end.

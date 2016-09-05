Unit NGObjects;

interface

type
  {ObjectList}

  ForEachObjectProc = procedure(Item: TObject; Extra:Integer);
  ForEachObjectThatFun = function(Item: TObject; Extra:Integer): Boolean;

  PObjectNode = ^TObjectNode;
  TObjectNode = Record
    Value: TObject;
    Next: PObjectNode;
  End;

  TObjectList = class
  private
    FCount: Integer;
    First: PObjectNode;
  public
    Constructor Create;
    Destructor Destroy; override;
    Procedure Add(NewItem: TObject);
    function Remove(Index: Integer): TObject;
    Procedure Delete(Index: Integer);
    Procedure DeleteAll;
    Function Get(Index: Integer): TObject;
    Function IndexOf(Item: TObject): Integer;
    Procedure Put(Index: Integer; NewValue: TObject);
    Function FirstThat(Condition: ForEachObjectThatFun; Extra: Integer): TObject;
    Procedure ForEach(Action: ForEachObjectProc; Extra: Integer);
    Procedure ForEachThat(Action: ForEachObjectProc; Condition: ForEachObjectThatFun; Extra: Integer);
  published
    property Count: Integer read FCount;
    property Items[Index: Integer]:TObject read Get write Put; default;
  end;

  {Indexed Object List}

  TIndexedObjectList = class(TObjectList)
  private
    function GetSelected: TObject;
  public
    ItemIndex: Integer;
    constructor Create;
  published
    property Selected: TObject read GetSelected;
  end;

  {PointerList}

  ForEachPointerProc = procedure(Item: Pointer; Extra:Integer);
  ForEachPointerThatFun = function(Item: Pointer; Extra:Integer): Boolean;

  PPointerNode = ^PointerNode;
  PointerNode = Record
    Value: Pointer;
    Next: PPointerNode;
  End;

  PPointerList = ^TPointerList;
  TPointerList = class
    First: PPointerNode;
    Count: Integer;
    Constructor Create;
    Destructor Destroy; override;
    Procedure Add(NewItem: Pointer);
    Procedure Delete(Index: Integer);
    Procedure DeleteAll;
    Function Get(Index: Integer): Pointer;
    Function IndexOf(Item: Pointer): Integer;
    Procedure Put(Index: Integer; NewValue: Pointer);
    Function FirstThat(Condition: ForEachPointerThatFun; Extra: Integer): Pointer;
    Procedure ForEach(Action: ForEachPointerProc; Extra: Integer);
    Procedure ForEachThat(Action: ForEachPointerProc; Condition: ForEachPointerThatFun; Extra: Integer);
  end;

implementation


{******* ObjectList ***********}

Constructor TObjectList.Create;
begin
  inherited Create;
  First:=nil;
  FCount:=0;
end;

Destructor TObjectList.Destroy;
begin
  DeleteAll;
  inherited;
end;

Procedure TObjectList.Add(NewItem: TObject);
var
  TempNode, NewNode: PObjectNode;
begin
  New(NewNode);
  NewNode^.Value:=NewItem;
  NewNode^.Next:=nil;
  FCount:=FCount+1;
  If First=nil Then
    First:=NewNode
  else
    begin
      TempNode:=First;
      While TempNode^.Next<>nil Do
        TempNode:=TempNode^.Next;
      TempNode^.Next:=NewNode;
    end;
end;

function TObjectList.Remove(Index: Integer): TObject;
var
  TempNode, PrevNode, NextNode: PObjectNode;
  b: Integer;
begin
  Result:=nil;
  If Index>=Count Then Exit;
  If Index=0 Then
    begin
      TempNode:=First;
      First:=First^.Next;
      Result:=TempNode^.Value;
      Dispose(TempNode);
    end
  else
    begin
      PrevNode:=First;
      For b:=0 to Index-2 Do
        PrevNode:=PrevNode^.Next;
      TempNode:=PrevNode^.Next;
      NextNode:=TempNode^.Next;
      Result:=TempNode^.Value;
      Dispose(TempNode);
      PrevNode^.Next:=NextNode;
    end;
  FCount:=FCount-1;
end;

Procedure TObjectList.Delete(Index: Integer);
var
  i: TObject;
begin
  i:=Remove(Index);
  if i<>nil then i.Free;
end;

Procedure TObjectList.DeleteAll;
var
  b:Integer;
begin
  For b:=1 to Count Do Delete(0);
end;

Function TObjectList.Get(Index: Integer): TObject;
var
  TempNode: PObjectNode;
  b: Integer;
begin
  If (Index>=Count) Or (Index<0) Then  {"Index" is zero-based while "Count" is not}
    Get:=nil
  else
    begin
      TempNode:=First;
      For b:=0 To Index-1 Do
        TempNode:=TempNode^.Next;
      Get:=TempNode^.Value;
    end;
end;

Function TObjectList.IndexOf(Item: TObject): Integer;
var
  p: PObjectNode;
  i: Integer;
begin
  p:=First;
  i:=0;
  While (p<>nil) And (p^.Value<>Item) Do
    begin
      i:=i+1;
      p:=p^.Next;
    end;
  If i<Count Then IndexOf:=i else IndexOf:=-1;
end;

Procedure TObjectList.Put(Index: Integer; NewValue: TObject);
var
  TempNode: PObjectNode;
  b: Integer;
begin
  If (Index>=Count) Or (Index<0) Then Exit; {"Index" is zero-based while "Count" is not}
  TempNode:=First;
  For b:=0 To Index-1 Do
    TempNode:=TempNode^.Next;
  TempNode^.Value:=NewValue;
end;

Function TObjectList.FirstThat(Condition: ForEachObjectThatFun; Extra: Integer):TObject;
var
  p: PObjectNode;
begin
  p:=First;
  While (p<>nil) And (Not Condition(p^.Value, Extra)) Do p:=p^.Next;
  If p=nil Then
    FirstThat:=nil
  else
    FirstThat:=p^.Value;
end;

Procedure TObjectList.ForEach(Action: ForEachObjectProc; Extra: Integer);
var
  p: PObjectNode;
begin
  p:=First;
  While p<>nil Do
    begin
      Action(p^.Value, Extra);
      p:=p^.Next;
    end;
end;

Procedure TObjectList.ForEachThat(Action: ForEachObjectProc; Condition: ForEachObjectThatFun; Extra: Integer);
var
  p: PObjectNode;
begin
  p:=First;
  While p<>nil Do
    begin
      If Condition(p^.Value, Extra) Then Action(p^.Value, Extra);
      p:=p^.Next;
    end;
end;

{******* Indexed Object List ***********}

constructor TIndexedObjectList.Create;
begin
  inherited;
  ItemIndex:=-1;
end;

function TIndexedObjectList.GetSelected: TObject;
begin
  Result:=Items[ItemIndex];
end;

{******* PointerList ***********}

Constructor TPointerList.Create;
begin
  inherited Create;
  First:=nil;
  Count:=0;
end;

Destructor TPointerList.Destroy;
begin
  DeleteAll;
end;

Procedure TPointerList.Add(NewItem: Pointer);
var
  TempNode, NewNode: PPointerNode;
begin
  New(NewNode);
  NewNode^.Value:=NewItem;
  NewNode^.Next:=nil;
  Count:=Count+1;
  If First=nil Then
    First:=NewNode
  else
    begin
      TempNode:=First;
      While TempNode^.Next<>nil Do
        TempNode:=TempNode^.Next;
      TempNode^.Next:=NewNode;
    end;
end;

Procedure TPointerList.Delete(Index: Integer);
var
  TempNode, PrevNode, NextNode: PPointerNode;
  b: Integer;
begin
  If Index>=Count Then Exit;
  If Index=0 Then
    begin
      TempNode:=First;
      First:=First^.Next;
      Dispose(TempNode);
    end
  else
    begin
      PrevNode:=First;
      For b:=0 to Index-2 Do
        PrevNode:=PrevNode^.Next;
      TempNode:=PrevNode^.Next;
      NextNode:=TempNode^.Next;
      Dispose(TempNode);
      PrevNode^.Next:=NextNode;
    end;
  Count:=Count-1;
end;

Procedure TPointerList.DeleteAll;
var
  b:Integer;
begin
  For b:=1 to Count Do Delete(0);
end;

Function TPointerList.Get(Index: Integer): Pointer;
var
  TempNode: PPointerNode;
  b: Integer;
begin
  If Index>=Count Then  {"Index" is zero-based while "Count" is not}
    Get:=nil
  else
    begin
      TempNode:=First;
      For b:=0 To Index-1 Do
        TempNode:=TempNode^.Next;
      Get:=TempNode^.Value;
    end;
end;

Function TPointerList.IndexOf(Item: Pointer): Integer;
var
  p: PPointerNode;
  i: Integer;
begin
  p:=First;
  i:=0;
  While (p<>nil) And (p^.Value<>Item) Do
    begin
      i:=i+1;
      p:=p^.Next;
    end;
  If i<Count Then IndexOf:=i else IndexOf:=-1;
end;

Procedure TPointerList.Put(Index: Integer; NewValue: Pointer);
var
  TempNode: PPointerNode;
  b: Integer;
begin
  If Index>=Count Then Exit; {"Index" is zero-based while "Count" is not}
  TempNode:=First;
  For b:=0 To Index-1 Do
    TempNode:=TempNode^.Next;
  TempNode^.Value:=NewValue;
end;

Function TPointerList.FirstThat(Condition: ForEachPointerThatFun; Extra: Integer):Pointer;
var
  p: PPointerNode;
begin
  p:=First;
  While (p<>nil) And (Not Condition(p^.Value, Extra)) Do p:=p^.Next;
  If p=nil Then
    FirstThat:=nil
  else
    FirstThat:=p^.Value;
end;

Procedure TPointerList.ForEach(Action: ForEachPointerProc; Extra: Integer);
var
  p: PPointerNode;
begin
  p:=First;
  While p<>nil Do
    begin
      Action(p^.Value, Extra);
      p:=p^.Next;
    end;
end;

Procedure TPointerList.ForEachThat(Action: ForEachPointerProc; Condition: ForEachPointerThatFun; Extra: Integer);
var
  p: PPointerNode;
begin
  p:=First;
  While p<>nil Do
    begin
      If Condition(p^.Value, Extra) Then Action(p^.Value, Extra);
      p:=p^.Next;
    end;
end;


end.

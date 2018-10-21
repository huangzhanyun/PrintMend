unit PMTypedef;

interface

uses  Classes, Windows;

const
  PM_FORMFREE         = $0C; //页结束
  PM_CMDFLAG          = $1B; //指令标识
  PM_GRSIZE           = $03;  //单个图形指令的字节数;
  PM_CMD_PRINTWAY     = $55; //设置双向打印
  PM_CMD_GRAPHICS     = $2A; //图象模式
  PM_CMD_ABSOLUTEPOS  = $24; //绝对位置定位(横向位置控制)
  PM_CMD_HSCROLL      = $4A; //垂直进纸(纵向位置控制)

type
  TLongWordDynArray = array of LongWord;

  PGraphicsRecord = ^TGraphicsRecord;
  TGraphicsRecord = packed record
    case Integer of
      0: (hb, mb, lb: Byte);
      1: (hc, mc, lc: Char);
      2: (Bytes: array[0..2] of Byte);
      3: (Chars: array[0..2] of Char);
  end;

  TMendData = packed record
    case Integer of
      1:(Data: LongWord);
      2:(Offset: ShortInt; GsRec: TGraphicsRecord);
  end;

  TLongWordList = class(TList)
  protected
    function Get(Index: Integer): LongWord;
    procedure Put(Index: Integer; Item: LongWord);
  public
    function Add(Item: LongWord): Integer;
    function First: LongWord;
    function IndexOf(Item: LongWord): Integer;
    procedure Insert(Index: Integer; Item: LongWord);
    function Last: LongWord;
    function Remove(Item: LongWord): Integer;
    property Items[Index: Integer]: LongWord read Get write Put; default;
  end;

  TMendDataList = class(TList)
  private
    function Get(Index: Integer): TMendData;
    procedure Put(Index: Integer; Item: TMendData);
  protected
  public
    function Add(Item: TMendData): Integer;
    function First:TMendData;
    function Last: TMendData;
    function IndexOf(Item: TMendData): Integer;
    procedure Insert(Index: Integer; Item: TMendData);
    function Remove(Item: TMendData): Integer;
    property Items[Index: Integer]: TMendData read Get write Put; default;
  end;



//////////////////// 命令 /////////////////////////

  PCmdGraphicsRecord = ^TCmdGraphcisRecord;    //图形记录命令
  TCmdGraphcisRecord = record
    Cmd: array [0..2] of Byte;
    Count: Word;
  end;

  PCmdForward = ^TCmdForward;  //打印纸前进命令
  TCmdForward = record
    Cmd: array [0..1] of Byte;
    Value: Byte;
  end;

  PCmdBack = ^TCmdBack;   //打印纸后退命令
  TCmdBack = record
    Cmd: array [0..1] of Byte;
    Value: Byte;
  end;



//////////////////// Array Pointer Type ////////////////////

  PGraphicsArray = ^TGraphicsArray;
  TGraphicsArray = array [0..MaxInt div SizeOf(TGraphicsRecord)-1] of TGraphicsRecord;
  

  PIntArray = ^TIntArray;
  TIntArray = array [0..MaxInt div SizeOf(Integer)-1] of Integer;
  PIntegerArray = PIntArray;

  PUIntArray = ^TUIntArray;
  TUIntArray = array [0..MaxInt div SizeOf(Cardinal)-1] of LongWord;

  PByteArray = ^TByteArray;
  TByteArray = array [0..MaxInt div SizeOf(Byte)-1] of Byte;

  PWordArray = ^TWordArray;
  TWordArray = array [0..MaxInt div SizeOf(Word)-1] of Word;
  
  TPMPointer = record
    case Integer of
      0: (p:      Pointer);
      1: (pc:     PChar);
      2: (pb:     PByte);
      3: (psi:    PSmallInt);
      4: (pw:     PWord);
      5: (pi:     PInteger);
      6: (pui:    PLongWord);
      7: (pba:    PByteArray);
      8: (pwa:    PWordArray);
      9: (pia:    PIntegerArray);
      10: (puia:  PUIntArray);
      11: (pgsa:  PGraphicsArray);
      12: (n:     Cardinal);
  end;

///////////////////////////////////////////////////////////////

function MakeGraphicsRec(I: LongWord): TGraphicsRecord; overload;

function MakeDWORD(G: TGraphicsRecord): DWORD; overload;

function MakeDWORD(P: PGraphicsRecord): DWORD; overload;

procedure GraphicsRecInterChange(pData: PGraphicsRecord; RecordCount: Cardinal);

function NextPosition(P: Pointer): Cardinal;

function GetGraphicsBitOr(PRecord: PGraphicsRecord; Count: Integer): LongWord;

implementation

{ TIntegerList }

function TLongWordList.Add(Item: LongWord): Integer;
begin
  Result := inherited Add(Pointer(Item));
end;

function TLongWordList.First: LongWord;
begin
  result := LongWord(inherited First);
end;

function TLongWordList.Get(Index: Integer): LongWord;
begin
  Result := LongWord(inherited Get(Index));
end;

function TLongWordList.IndexOf(Item: LongWord): Integer;
begin
  Result := inherited IndexOf(Pointer(Item));
end;

procedure TLongWordList.Insert(Index:Integer; Item: LongWord);
begin
  inherited Insert(Index, Pointer(Item))
end;

function TLongWordList.Last: LongWord;
begin
  Result := LongWord(inherited Last);
end;

procedure TLongWordList.Put(Index:Integer; Item: LongWord);
begin
  inherited Put(Index, Pointer(Item));
end;

function TLongWordList.Remove(Item: LongWord): Integer;
begin
  Result := inherited Remove(Pointer(Item));
end;



function NextPosition(P: Pointer): Cardinal;
var
  Opcode: Char;
  PC: PChar absolute P;
  RecNum: Cardinal;
begin
  Result := 0;

  if PC = nil then Exit;

  Opcode := PC^;

  if Opcode <> Chr($1B) then
  begin
    Result := 1;
    Exit;
  end;

  Opcode := PC[1];

  case Ord(Opcode) of
    $24: //横向绝对位置
      Result := 4;

    $2A: // 图形模式
      begin
        RecNum := PWord(PC + 3)^;
        Result := RecNum * 3 + 5;
      end;

    $19, //设定自动走纸器
    $43, //设定页长
    $4A, //打印纸前进
    $52, //选择国际字符组
    $55, //设置打印方向
    $6A, //打印纸后退
    $72, //设定上下标
    $74, //选择字符表
    $78: //设定打印方式
      Result := 3;

    $32, //设定1/6英寸行距
    $36, //设定2号西文字符组
    $3C, //当前行单向打印
    $40: //初始化打印机
      Result := 2;

  else Result := 1;
  end;
end;

function MakeDWORD(P: PGraphicsRecord): DWORD;
asm
	PUSH	ESI
  MOV   ESI, EAX
  XOR		EAX, EAX
  MOV		AX, [ESI+1]
  SHL		EAX, 8
  MOV		AL, [ESI]
  POP		ESI
end;

procedure GraphicsRecInterChange(pData: PGraphicsRecord; RecordCount: Cardinal);
asm
(*
		EAX ---------> pData
    EDX ---------> RecordCount;
*)
  TEST	EAX, EAX
  JZ		@@Exit
  TEST	EDX, EDX
  JZ		@@Exit;

	PUSH 	EBX
	MOV		EBX, EAX
@@InterChange:
	MOV		AL, [EBX]
  MOV		AH, [EBX+2]
  MOV		[EBX], AH
  MOV		[EBX+2], AL
  ADD		EBX, 3;
  DEC		EDX
  JNZ		@@InterChange;
  POP		EBX
@@Exit:

end;

function MakeGraphicsRec(I: LongWord): TGraphicsRecord;
asm
{
	EDX --------> Result;
  EAX --------> i
}
	PUSH	ESI
	MOV		ESI, EDX
  XCHG	AH, AL
  MOV   [ESI+1], AX
  SHR		EAX, 16
  MOV 	[ESI], AL
  POP		ESI
end;

function MakeDWORD(G: TGraphicsRecord): DWORD;
asm
	PUSH	ESI
	LEA		ESI, G
  XOR		EAX, EAX
  MOV		AX, [ESI+1]
  SHL		EAX, 8
  MOV		AL, [ESI]
  POP		ESI
end;

function GetGraphicsBitOr(PRecord: PGraphicsRecord;
  Count: Integer): LongWord;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Count do
  begin
    Result := Result or MakeDWORD(PRecord);
    Inc(PRecord);
  end;
end;


{ TMendDataList }

function TMendDataList.Add(Item: TMendData): Integer;
begin
  Result := inherited Add(Pointer(Item.Data));
end;

function TMendDataList.First: TMendData;
begin
  Result.Data := LongWord(inherited First);
end;

function TMendDataList.Get(Index: Integer): TMendData;
begin
  Result.Data := LongWord(inherited Get(Index));
end;

function TMendDataList.IndexOf(Item: TMendData): Integer;
begin
  Result := inherited IndexOf(Pointer(Item.Data));
end;

procedure TMendDataList.Insert(Index: Integer; Item: TMendData);
begin
  inherited Insert(Index, Pointer(Item.Data));
end;

function TMendDataList.Last: TMendData;
begin
  Result.Data := LongWord(inherited Last);
end;

procedure TMendDataList.Put(Index: Integer; Item: TMendData);
begin
  inherited Put(Index, Pointer(Item.Data));
end;

function TMendDataList.Remove(Item: TMendData): Integer;
begin
  Result := inherited Remove(Pointer(Item.Data));
end;

end.

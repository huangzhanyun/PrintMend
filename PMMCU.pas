(********************************************************)
(*                                                      *)
(*    Print Mender                                      *)
(*                                                      *)
(*               Mend Code Unit                         *)
(*                                                      *)
(*                                                      *)
(********************************************************)

unit PMMCU;

interface
uses
  SysUtils, Classes, MemBuf, VarPointer, PMTypedef, Mender, Windows;

type

  TPrnMend = class (TObject)
  private
    FOffset: Integer;
    FOwner: TMender;
    FPinState: LongWord;
    FEnter: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

  protected
    FCodeBuf: TMemoryBuffer; //存放打印数据(含打印指令和图形指令)
    FCmdBuf: TMemoryBuffer;  //存放非图形指令
    FGraphicsBuf: TMemoryBuffer; //存放图形指令
    FMendBuf: TMemoryBuffer;
    procedure SplitCode; virtual;   //代码分类
    procedure MendCode;
    procedure MergeBuffer;
    procedure GetPinStateArray(PinState: LongWord;  var PinStateArray: TLongWordDynArray);overload;
    procedure GetPinStateArray(PinState: LongWord;  PinStateList: TLongWordList);overload;
    function GetHighBitPos(I: LongWord): Integer;
    procedure GetMendData(PinState: LongWord; GraphicsState: LongWord; var BestPinState: LongWord; MendDataList: TMendDataList); virtual;
    procedure InternalMend(PinState: LongWord; GraphicsState: LongWord; MendDataList: TMendDataList); virtual;

  end;


implementation


{ TMCU }

constructor TPrnMend.Create;
begin
  FOffset := 0;
  FCodeBuf := TMemoryBuffer.Create;
  FCmdBuf := TMemoryBuffer.Create;
  FGraphicsBuf := TMemoryBuffer.Create;
  FMendBuf := TMemoryBuffer.Create;
end;

destructor TPrnMend.Destroy;
begin
  if FCodeBuf <> nil then
    FCodeBuf.Free;

  if FCmdBuf <> nil then
    FCmdBuf.Free;

  if FGraphicsBuf <> nil then
    FGraphicsBuf.Free;

  if FMendBuf <> nil then
    FMendBuf.Free;

  inherited;
end;


function TPrnMend.GetHighBitPos(I: LongWord): Integer;
begin
  Result := -1;
  while I <> 0 do
  begin
    I := I shr 1;
    Inc(Result);
  end;
end;

procedure TPrnMend.GetPinStateArray(PinState: LongWord;
  var PinStateArray: TLongWordDynArray);
var
  Count: Integer;
  Index: Integer;
begin
  SetLength(PinStateArray, 24);
  Index := 0;
  Count := 0;
  PinState := PinState and $FFFFFF;
  
  while PinState <> 0 do
  begin
    while (PinState and (1 shl 23)) = 0 do
    begin
      PinState := PinState shl 1 and $FFFFFF;
      Inc(Count);
    end;

    PinStateArray[Index] := PinState shr Count;
    PinState := PinState shl 1 and $FFFFFF;
    Inc(Count);
    Inc(Index);
  end;

  SetLength(PinStateArray, Index);
end;

procedure TPrnMend.GetMendData(PinState, GraphicsState: LongWord;
   var BestPinState: LongWord; MendDataList: TMendDataList);
var
  PinStateArray: TLongWordList;
  TempList: TMendDataList;
  I: Integer;
  tmp_Offset: Integer;
  dat_Offset: Integer;
  J: Integer;
begin
  if not Assigned(MendDataList) then
  begin
    raise EListError.Create('MendDataList Invaild Pointer');
  end;

  MendDataList.Clear;
  PinStateArray := TLongWordList.Create;
  TempList := TMendDataList.Create;
  GetPinStateArray(PinState, PinStateArray);
  BestPinState := PinState;

  for I := 0 to PinStateArray.Count - 1 do
  begin
    TempList.Clear;
    InternalMend(PinStateArray.Items[I], GraphicsState, TempList);

    if I = 0 then
    begin
      MendDataList.Assign(TempList);
      Continue;
    end;

    if TempList.Count < MendDataList.Count - 1 then
    begin
      BestPinState := PinStateArray[I];
      MendDataList.Assign(TempList);
      Continue;
    end;

    if TempList.Count = MendDataList.Count - 1 then
    begin
      tmp_Offset := 0;
      dat_Offset := 0;

      for J := 0 to TempList.Count - 1 do
      begin
        Inc(tmp_Offset, TempList.Items[J].Offset);
      end;

      for J := 0 to MendDataList.Count - 1 do
      begin
        Inc(dat_Offset, MendDataList.Items[J].Offset);
      end;

      if tmp_Offset < dat_Offset then
      begin
        BestPinState := PinStateArray.Items[I];
        MendDataList.Assign(TempList) 
      end;
    end;

  end;
  PinStateArray.Free;
  TempList.Free;
end;

procedure TPrnMend.GetPinStateArray(PinState: LongWord;
  PinStateList: TLongWordList);
var I: Integer;
begin
  if not Assigned(PinStateList) then
    raise EListError.Create('PinStateList Invaild Pointer');

  I := 0;
  PinStateList.Clear;
  PinState := PinState and $FFFFFF;

  while PinState  <> 0 do
  begin
    if (PinState and (1 shl 23)) <> 0 then
      PinStateList.Add(PinState shr I);

    PinState := PinState shl 1 and $FFFFFF;
    Inc(I);
  end;
end;

procedure TPrnMend.MendCode;
var
  gsState: LongWord;
  TotalOffset: Integer;
  BestPin: LongWord;
  I: Integer;
  MendDataList: TMendDataList;
  PassDataList: TLongWordList;
  Pass: DWORD;
  Residual: DWORD;
  G_IP: PGraphicsRecord;
  G_EP: PGraphicsRecord;
  BitDif: Integer;
  J: Integer;
  Rec: TGraphicsRecord;
begin
  if FGraphicsBuf.Size = 0 then
  begin
    MergeBuffer;
    Exit;
  end;

  gsState := GetGraphicsBitOr(FGraphicsBuf.Memory, FGraphicsBuf.Size div 3);

  if gsState = 0 then
  begin
    MergeBuffer;
    Exit;
  end;

  try
    FEnter := False;
    MendDataList := TMendDataList.Create;
    PassDataList := TLongWordList.Create;
    TotalOffset := 0;
    G_EP := FGraphicsBuf.Memory;
    Inc(G_EP, FGraphicsBuf.Size div PM_GRSIZE);
    GetMendData(FPinState, gsState, BestPin, MendDataList);

    for I := 0 to MendDataList.Count - 1 do
    begin
      PassDataList.Clear;
      G_IP := PGraphicsRecord(FGraphicsBuf.Memory);

      while LongInt(G_IP) < LongInt(G_EP) do
      begin
        Pass := MakeDWord(MendDataList.Items[I].gsRec);
        Residual := MakeDWord(G_IP);
        Pass := Pass and Residual;
        Residual := Pass xor Residual;
        G_IP^ := MakeGraphicsRec(Residual);
        Inc(G_IP);
        PassDataList.Add(Pass);
      end;

      BitDif := GetHighBitPos(BestPin) - GetHighBitPos(MakeDWord(MendDataList.Items[I].GsRec));

      if BitDif < 0 then
      begin
        for J := 0 to PassDataList.Count - 1 do
        begin
          Rec := MakeGraphicsRec(PassDataList.Items[J] shr Abs(BitDif));
          FMendBuf.Write(Rec, SizeOf(Rec));
        end;
      end
      else begin
        for J := 0 to PassDataList.Count - 1 do
        begin
          Rec := MakeGraphicsRec(PassDataList.Items[J] shl BitDif);
          FMendBuf.Write(Rec, SizeOf(Rec));
        end;
      end;

      FOffset := MendDataList.Items[I].Offset;
      Inc(TotalOffset, FOffset);
      MergeBuffer;
      FMendBuf.Clear;
      FEnter := True;

    end;

    FOffset := TotalOffset;
    
  finally
    MendDataList.Free;
    PassDataList.Free;
  end;

end;

procedure TPrnMend.MergeBuffer;
begin
  FCodeBuf.Clear;

  if FGraphicsBuf.Size = 0 then
  begin
    FCodeBuf.Write(FCmdBuf.Memory^, FCmdBuf.Size);
    Exit;
  end;

end;

procedure TPrnMend.SplitCode;
{功能:纠正补打后的针位偏移、代码分类和强制打印方向}
var
  BP: PChar;  //基址指针
  OBP: PChar; //输出数据的基址指针
  _IP: TPointer; //索引指针
  BufSize: Cardinal; //打印数据的字节数
  GrBytes: Cardinal; //图形指令的字节数
  SV: Integer;
  VSCmd: array [0..2] of Byte; //垂直进纸指令
begin
  BP := FCodeBuf.Memory;
  BufSize := FCodeBuf.Size;
  OBP := BP;
  _IP := TPointer.Create;
  _IP.Ptr := BP;

  while _IP.Ptr < BP + BufSize do
  begin

    if _IP.ReadByte() <> PM_CMDFLAG then
    begin
      _IP.SkipBytes(NextPosition(_IP.Ptr));
      Continue;
    end;


    case _IP.ReadByte(1) of
      PM_CMD_GRAPHICS: // 代码分类
      begin
        GrBytes := _IP.ReadWord(3) * PM_GRSIZE;   //获得图形指令的字节数
        _IP.SkipBytes(5);  //跳到图形指令标识的后面,准备输出非图形指令
        FCmdBuf.Write(OBP, _IP.Ptr - OBP);
        FGraphicsBuf.Write(_IP.Ptr, GrBytes);
        _IP.SkipBytes(GrBytes);
        OBP := _IP.Ptr;
        Continue;
      end;

      PM_CMD_PRINTWAY: //设置单双向打印
      begin
        if FOwner.PrintWay = pwBidirectional then
          _IP.WriteByte(2, 2)
        else
          _IP.WriteByte(1, 2);
      end;

      PM_CMD_HSCROLL: //纠正针位偏移
      begin
        SV := Integer(_IP.ReadByte(2)) + FOffset;
        if SV > 255 then  //超过单字节长度，分两次进纸
        begin
          _IP.WriteByte($FF, 2);
          _IP.SkipBytes(NextPosition(_IP.Ptr));
          FCmdBuf.Write(OBP, _IP.Ptr - OBP);
          VSCmd[0] := $1B;
          VSCmd[1] := $4A;
          VSCmd[2] := SV - 255;
          FCmdBuf.Write(VSCmd, SizeOf(VSCmd));
          OBP := _IP.Ptr;          
        end

        else if SV < 0 then  //后退
        begin
          _IP.WriteByte($6A, 1);
          _IP.WriteByte(Byte(Abs(SV)), 2);
        end

        else
          _IP.WriteByte(Byte(SV), 2);
      end;

    end;

    _IP.SkipBytes(NextPosition(_IP.Ptr));
  end; //End While

  _IP.Free;

  FCodeBuf.Clear;
end;

procedure TPrnMend.InternalMend(PinState, GraphicsState: LongWord;
  MendDataList: TMendDataList);
var
  MendData: TMendData;
  BitDif: SmallInt;
  Pass: LongWord;
begin

  while GraphicsState <> 0 do
  begin
    BitDif := GetHighBitPos(PinState) - GetHighBitPos(GraphicsState);

    if BitDif > 0 then
      PinState := PinState shr BitDif
    else
      PinState := PinState shl Abs(BitDif);

    Pass := PinState and GraphicsState;
    GraphicsState := GraphicsState xor Pass;
    MendData.Offset := BitDif;
    MendData.GsRec := MakeGraphicsRec(Pass);
    MendDataList.Add(MendData);
  end;

end;

end.













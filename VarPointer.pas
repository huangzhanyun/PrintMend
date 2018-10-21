unit VarPointer;

interface

uses
  SysUtils;
type
  TPointer = class(TObject)
  private
    FPtr: PChar;
    procedure SetPointer(const Value: PChar);
  public
    procedure ReadData(var Buf; Bytes: Integer; OffsetBytes: Integer=0);
    function ReadByte(OffsetBytes: Integer=0): Byte;
    function ReadWord(OffsetBytes: Integer=0): Word;
    function ReadInteger(OffsetBytes: Integer=0): Integer;
    procedure WriteData(var Data; Bytes: Integer; OffsetBytes: Integer=0);
    procedure WriteInteger(Data: Integer; OffsetBytes: Integer=0);
    procedure WriteByte(Data: Byte; OffsetBytes: Integer=0);
    procedure WriteWord(Data: Word; OffsetBytes: Integer=0);
    procedure SkipBytes(Bytes: Integer);
    property Ptr: PChar read FPtr  write SetPointer default nil;
  end;

implementation

{ TPointer }

function TPointer.ReadByte(OffsetBytes: Integer): Byte;
begin
  ReadData(Result, SizeOf(Result), OffsetBytes);
end;

procedure TPointer.ReadData(var Buf; Bytes, OffsetBytes: Integer);
begin
  Move((FPtr + OffsetBytes)^, Buf, Bytes);
end;

function TPointer.ReadInteger(OffsetBytes: Integer): Integer;
begin
  ReadData(Result, SizeOf(Result), OffsetBytes);
end;

function TPointer.ReadWord(OffsetBytes: Integer): Word;
begin
  ReadData(Result, SizeOf(Result), OffsetBytes);
end;

procedure TPointer.SetPointer(const Value: PChar);
begin
  FPtr := Value;
end;

procedure TPointer.SkipBytes(Bytes: Integer);
begin
  FPtr := FPtr + Bytes;
end;

procedure TPointer.WriteByte(Data: Byte; OffsetBytes: Integer);
begin
  WriteData(Data, SizeOf(Data), OffsetBytes);
end;

procedure TPointer.WriteData(var Data; Bytes, OffsetBytes: Integer);
begin
  Move(Data, (FPtr + OffsetBytes)^, Bytes);
end;

procedure TPointer.WriteInteger(Data, OffsetBytes: Integer);
begin
  WriteData(Data, SizeOf(Data), OffsetBytes);
end;

procedure TPointer.WriteWord(Data: Word; OffsetBytes: Integer);
begin
  WriteData(Data, SizeOf(Data), OffsetBytes);
end;

end.
 
unit PrnCmd;

interface


uses SysUtils, Windows, MemBuf, PmTypedef;

{$J+ $WARNINGS OFF}

type

  TPrnCmd = class(TObject)
  public
    procedure InitPrinter; virtual; abstract;
    procedure CommandEx(lpCmd: Pointer;
      cbCmdSize: Cardinal); virtual; //命令扩展
    procedure CarriageReturn; virtual; //回车
    procedure NewLine; virtual; //换行
    procedure Backspace; virtual;
    procedure Str(S: PChar); virtual; //字符串
    procedure HTab; virtual; //水平跳格
    procedure VTab; virtual; //垂直跳格
    procedure FormFeed; virtual; //换页
  protected
    procedure Write(lpData: Pointer;
      cbSize: Cardinal); virtual; abstract;
  end;

  TLQPrnCmd = class(TPrnCmd)
  public
    procedure NewLineEx(RowSpace: Byte=24); virtual; //换行
    procedure InitPrinter; override;
    procedure LeftIndent(Pos: Word); virtual;
    procedure Bidirectional(bBid: Boolean); virtual;
  end;

  TLQMemPrn = class(TLQPrnCmd)
  private
    function GetSize: Longint;
    function GetPointer: Pointer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure GraphicsMode(lpRec: PGraphicsRecord;
      RecCounts: Word); virtual;
    property Memory: Pointer read GetPointer;
    property Size: Longint read GetSize;

  protected
    FMem: TMemoryBuffer;
    procedure Write(lpData: Pointer; cbSize: Cardinal); override;
  end;


implementation

{ TPrnCmd }

procedure TPrnCmd.Backspace;
const Cmd: Byte = $08;
begin
  Write(@Cmd, SizeOf(Cmd));
end;

procedure TPrnCmd.CarriageReturn;
const CmdCR: Byte = $0D;
begin
  Write(@CmdCR, SizeOf(CmdCR));
end;

procedure TPrnCmd.CommandEx(lpCmd: Pointer; cbCmdSize: Cardinal);
begin
  Write(lpCmd, cbCmdSize);
end;

procedure TPrnCmd.FormFeed;
const Cmd: Byte = $0C;
begin
  Write(@Cmd, SizeOf(Cmd));
end;

procedure TPrnCmd.HTab;
const Cmd: Byte = $09;
begin
  Write(@Cmd, SizeOf(Cmd));
end;


procedure TPrnCmd.NewLine;
const Cmd: Byte = $A;
begin
  Write(@Cmd, SizeOf(Cmd));
end;


procedure TPrnCmd.Str(S: PChar);
begin
  Write(S, StrLen(S));
end;

procedure TPrnCmd.VTab;
const Cmd: Byte = $0B;
begin
  Write(@Cmd, SizeOf(Cmd));
end;


{ TLQPrnCmd }

procedure TLQPrnCmd.Bidirectional(bBid: Boolean);
const Cmd: array[0..2] of Byte = ($1B, $55, $01);
begin
  if bBid then
    Cmd[2] := $02;

  Write(@Cmd, SizeOf(Cmd));
end;


procedure TLQPrnCmd.InitPrinter;
const Cmd: array[0..1] of Byte = ($1B, $40);
begin
  Write(@Cmd, SizeOf(Cmd));
end;

procedure TLQPrnCmd.LeftIndent(Pos: Word);
const Cmd: array[0..3] of Byte = ($1B, $24, $00, $00);
var P: PWord;
begin
  P := PWord(@Cmd[2]);
  P^ := Pos;
  Write(@Cmd, SizeOf(Cmd));
end;

procedure TLQPrnCmd.NewLineEx(RowSpace: Byte = 24);
const Cmd: array[0..2] of Byte = ($1B, $4A, $00);
begin
  Cmd[2] := RowSpace;
  Write(@Cmd, SizeOf(Cmd));
end;

{ TLQMemPrn }

constructor TLQMemPrn.Create;
begin
  FMem := TMemoryBuffer.Create;
end;

destructor TLQMemPrn.Destroy;
begin
  if FMem <> nil then begin
    FMem.Free;
    FMem := nil;
  end;

  inherited Destroy;
end;

function TLQMemPrn.GetPointer: Pointer;
begin
  if FMem <> nil then
    Result := FMem.Memory
  else
    Result := nil;
end;

function TLQMemPrn.GetSize: Longint;
begin
  if FMem <> nil then
    Result := FMem.Size
  else
    Result := 0;
end;

procedure TLQMemPrn.GraphicsMode(lpRec: PGraphicsRecord;
  RecCounts: Word);
const Cmd: array[0..4] of Byte = ($1B, $2A, $27, $00, $00);
var P: PWord;
begin
  P := @(Cmd[3]);
  P^ := RecCounts;
  Write(@Cmd, SizeOf(Cmd));
  Write(lpRec, RecCounts * 3);
end;

procedure TLQMemPrn.Write(lpData: Pointer; cbSize: Cardinal);
begin
  if FMem <> nil then
    FMem.Write(lpData^, cbSize);
end;

end.


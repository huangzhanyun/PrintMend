(********************************************************)
(*                                                      *)
(*    Print Mender                                      *)
(*                                                      *)
(*               Read Code Unit                         *)
(*                                                      *)
(*                                                      *)
(********************************************************)

unit PMRCU;


interface
uses
  MemMap, SysUtils, MemBuf, varPointer, PMTypedef;

type
  EReadFile = class (Exception);

  TPrnRead = class (TObject)
  private
    FMemMap: TMemMapFile;
    FSize: Cardinal;
    FPtr: TPointer;
  public
    constructor Create(FileName: String);
    destructor Destroy; override;
    function ReadData(Buf: TMemoryBuffer): Boolean;
    property Size: Cardinal read FSize;
  end;
implementation

{ TRCU }

constructor TPrnRead.Create(FileName: String);
begin
  try
    FMemMap := TMemMapFile.Create(FileName, fmOpenRead, 0, False);
  except
    on E:EMMFError do
      raise EReadFile.Create(E.Message);
  end;

  FSize := FMemMap.Size;
  FPtr.Ptr := PChar(FMemMap.Data);
end;

destructor TPrnRead.Destroy;
begin
  if FMemMap <> nil then
    FMemMap.Free;

  if FPtr <> nil then
    FPtr.Free;

  inherited;

end;

function TPrnRead.ReadData(Buf: TMemoryBuffer): Boolean;
var 
  bEndOfRow: Boolean;        //行结束
  bHasGraphics: Boolean;     //已有图形数据
  Opcode: Byte;
  BP: PChar;              
  bFileHead: Boolean;       //文件头

begin
  Result := False;
  bEndOfRow := False;
  bHasGraphics := False;
  bFileHead := False;
                    
  if (Buf = nil) or (FSize=0) then
    Exit;

  Buf.Position := 0;
  BP := FPtr.Ptr;

  while  FPtr.Ptr < PChar(FMemMap.Data) + FMemMap.Size do
  begin
    with FPtr do
    begin
      Opcode := ReadByte;

      if Opcode = $0C then
      begin
        SkipBytes(NextPosition(Ptr));
        Break;
      end;

      if Opcode <> $1B then
      begin
        SkipBytes(NextPosition(Ptr));
        Continue;
      end;

      Opcode := ReadByte(1);
      case Opcode of
        $40:  //初始化指令
        begin
          bFileHead := True;
          SkipBytes(NextPosition(Ptr));
        end;

        $4A: //纸前进指令
        begin
          if bFileHead then
            Break;

          if bEndOfRow then
            Break;

          SkipBytes(NextPosition(Ptr));
          bEndOfRow := True;
        end;

        $2A: //图形模式指令
        begin
          SkipBytes(NextPosition(Ptr));
          bHasGraphics := True;
        end;

        else
          SkipBytes(NextPosition(Ptr));
      end;   // End Case
    end;     // End With
  end;       // End While

  Buf.Write(BP^, FPtr.Ptr - BP);
end;

end.

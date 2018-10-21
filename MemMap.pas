unit MemMap;

interface
uses
  Windows, SysUtils, Classes;
{
const
  fmCreate = $FFFF;
  fmOpenRead = $0000;
  fmOpenWrite = $0001;
  fmOpenReadWrite = $0002;
  fmShareCompat = $0000;
  fmShareExclusive = $0010;
  fmShareDenyWrite = $0020;
  fmShareDenyRead = $0030;
  fmShareDenyNone = $0040;
}
type
  EMMFError = class(Exception);
  TMemMapFile = class(TObject)
  private
    FFileName: string;
    FSize: LongInt;
    FFileSize: LongInt;
    FFileMode: Integer;
    FFileHandle: Integer;
    FMapHandle: Integer;
    FData: PByte;
    FMapNow: Boolean;

    procedure AllocFileHandle;
    procedure AllocFileMapping;
    procedure AllocFileView;
    function GetSize: LongInt;

  public
    constructor Create(FileName: string; FileMode: Integer;
      Size: Integer; MapNow: Boolean); virtual;
    destructor Destroy; override;
    procedure FreeMapping;
    property Data: PByte read FData;
    property Size: LongInt read GetSize;
    property FileName: string read FFileName;
    property MapHandle: Integer read FMapHandle;
  end;

                            
implementation

{ TMemMapFile }

procedure TMemMapFile.AllocFileHandle;
begin
  if FFileMode = fmCreate then
    FFileHandle := FileCreate(FFileName)
  else
    FFileHandle := FileOpen(FFileName, FFileMode);

  if FFileHandle < 0 then
    raise EMMFError.Create('Failed to open or create file');
end;

procedure TMemMapFile.AllocFileMapping;
var ProAttr: DWORD;
begin
  if FFileMode = fmOpenRead then
    ProAttr := PAGE_READONLY
  else
    ProAttr := PAGE_READWRITE;

  FMapHandle := CreateFileMapping(FFileHandle, nil, ProAttr,
    0, FSize, nil);

  if FMapHandle = 0 then
    raise EMMFError.Create('Failed to create file mapping');

end;

procedure TMemMapFile.AllocFileView;
var Access: LongInt;
begin
  if FFileMode = fmOpenRead then
    Access := FILE_MAP_READ
  else
    Access := FILE_MAP_ALL_ACCESS;
  FData := MapViewOfFile(FMapHandle, Access, 0, 0, FSize);

  if FData = nil then
  begin
    raise EMMFError.Create('Failed to map view of file');
  end;

end;

constructor TMemMapFile.Create(FileName: string; FileMode, Size: Integer;
  MapNow: Boolean);
begin
  FMapNow := MapNow;
  FFileName := FileName;
  FFileMode := FileMode;

  AllocFileHandle;

  FFileSize := GetFileSize(FFileHandle, nil);
  FSize := Size;

  try
    AllocFileMapping;
  except
    on EMMFError do
    begin
      CloseHandle(FFileHandle);
      FFileHandle := 0;
      raise;
    end;
  end;

  if FMapNow then
    AllocFileView;
end;

destructor TMemMapFile.Destroy;
begin
  FreeMapping;

  if FMapHandle <> 0 then
    CloseHandle(FMapHandle);

  if FFileHandle <> 0 then
    CloseHandle(FFileHandle);

  FSize := 0;
  FFileSize := 0;
  inherited;
end;

procedure TMemMapFile.FreeMapping;
begin
  if FData <> nil then
  begin
    UnmapViewOfFile(FData);
    FData := nil;
  end;
end;

function TMemMapFile.GetSize: LongInt;
begin
  if FSize <> 0 then
    Result := FSize
  else
    Result := FFileSize;
end;

end.

 
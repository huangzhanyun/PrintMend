unit Buffer;

interface

uses
  SysUtils;



type TSeek = (_BEGIN, _END, _CURRENT);

type
  TBuffer = class (TObject)
  private

  protected
    m_Buffer: PChar;
    m_BufferSize: Cardinal;
    m_Position: Cardinal;
    m_FileSize: Cardinal;
    m_GrowBytes: Cardinal;
    procedure GrowFile(nNewLen: Cardinal);virtual;
    function Alloc(nBytes: Cardinal): PChar;virtual;
    procedure Realloc(lpMem: PChar; nBytes: Cardinal);virtual;
    procedure MemFree(lpMem: Pointer);  virtual;
    procedure Memcpy(lpMemTarget, lpMemSource: Pointer; nBytes: Cardinal); virtual;


  public
    constructor Create(nGrowBytes: Cardinal=1024);
    destructor Destroy; override;
    procedure Close;virtual;
    function GetFileSize: Cardinal;
    function GetBufferPtr: PChar;
    function GetPosition: Cardinal;
    function Read(lpBuffer: Pointer; nCount: Cardinal): Cardinal;virtual;
    function Seek(lOffset: Longint; nFrom: TSeek): Longint;
    procedure SetLength(nNewLen: Cardinal);virtual;
    procedure Write(lpBuffer: Pointer; nCount: Cardinal);virtual;

end;
implementation

{ TMemFile }


function TBuffer.Alloc(nBytes: Cardinal): PChar;
begin
  Result := AllocMem(nBytes);
end;

procedure TBuffer.Close;
begin
  m_GrowBytes := 0;
  m_Position := 0;
  m_BufferSize := 0;
  m_FileSize := 0;

  if m_Buffer <> nil then
    MemFree(m_Buffer);

  m_Buffer := nil;
end;

constructor TBuffer.Create(nGrowBytes: Cardinal=1024);
begin
  m_Buffer := nil;
  m_BufferSize := 0;
  m_Position := 0;
  m_FileSize := 0;
  m_GrowBytes := nGrowBytes;
end;

procedure TBuffer.MemFree(lpMem: Pointer);
begin
  FreeMem(lpMem);
end;

function TBuffer.GetBufferPtr: PChar;
begin
  Result := m_Buffer;
end;

function TBuffer.GetFileSize: Cardinal;
begin
  Result := m_FileSize;
end;

function TBuffer.GetPosition: Cardinal;
begin
  Result := m_Position;
end;

procedure TBuffer.GrowFile(nNewLen: Cardinal);
var
  nNewBufferSize: Cardinal;

begin
  if nNewLen > m_BufferSize then
  begin
    nNewBufferSize := m_BufferSize;

    if m_GrowBytes = 0 then
      raise Exception.Create('增长值为0');

    while nNewBufferSize < nNewLen do
      Inc(nNewBufferSize, m_GrowBytes);

    if m_Buffer = nil then
      m_Buffer := Alloc(nNewBufferSize)
    else
      Realloc(m_Buffer, nNewBufferSize);

    if m_Buffer=nil then
      raise Exception.Create('Could not Allocate Memory.');

    m_BufferSize := nNewBufferSize;
  end;

end;


procedure TBuffer.Memcpy(lpMemTarget, lpMemSource: Pointer;
  nBytes: Cardinal);
begin
	Move( lpMemSource^, lpMemTarget^, nBytes );
end;

function TBuffer.Read(lpBuffer: Pointer; nCount: Cardinal): Cardinal;
begin
  Result := 0;
  if nCount = 0 then Exit;

  if m_Position > m_FileSize then Exit;

  if (m_Position + nCount) > m_FileSize then
    Result := m_FileSize - m_Position
  else
    Result := nCount;

  Memcpy(PChar(lpBuffer), m_Buffer + m_Position, nCount);
  Inc(m_Position, Result);
end;

procedure TBuffer.Realloc(lpMem: PChar; nBytes: Cardinal);
begin
  ReallocMem(lpMem, nBytes);
end;

function TBuffer.Seek(lOffset: LongInt; nFrom: TSeek): Longint;
var
  lNewPos: LongInt;
begin
  lNewPos := m_Position;
{
  if nFrom=_BEGIN then
    lNewPos := lOffset
  else if nFrom = _CURRENT then
    Inc(lNewPos, lOffset)
  else if nFrom = _END then
    lNewPos := m_FileSize + lOffset
  else begin
    Result := -1;
    Exit;
  end;
}
  case nFrom of
    _BEGIN:   lNewPos := lOffset;
    _CURRENT: Inc(lNewPos, lOffset);
    _END:     lNewPos := m_FileSize + lOffset;
    else begin
      Result := -1;
      Exit;
    end;
  end;

  if lNewPos < 0 then
    raise Exception.Create('Bad Seek.');

  m_Position := lNewPos;
  Result := m_Position;
end;

procedure TBuffer.SetLength(nNewLen: Cardinal);
begin
  if nNewLen > m_BufferSize then
    GrowFile(nNewLen);

  if nNewLen < m_Position then
    m_Position := nNewLen;

  m_FileSize := nNewLen;
end;

procedure TBuffer.Write(lpBuffer: Pointer; nCount: Cardinal);
begin
  if nCount = 0 then Exit;

  if (m_Position + nCount) > m_BufferSize then
    GrowFile(m_Position + nCount);

  Memcpy((m_Buffer+m_Position), PChar(lpBuffer), nCount);
  Inc(m_Position, nCount);

  if m_Position > m_FileSize then
    m_FileSize := m_Position;
end;

destructor TBuffer.Destroy;
begin
  Close;
  Inherited;
end;

end.

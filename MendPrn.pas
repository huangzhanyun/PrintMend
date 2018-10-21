unit MendPrn;

interface

uses SysUtils, Windows, (*Buffer,*) MemMap, Classes;

type

  ////////////////////////////////////////////////
  EFileOpen = class(Exception);


  ///////////////////////////////////////////////
  TPMCFG = packed record
    PinStatus: DWORD;
  end;

  TBuffer = class(TMemoryStream);


  TPM = class;
  TMPU = class;
  TOPU = class;
  TROM = class;



  ///////////////////////////////////////////////////////////
  TPM = class
  public
    constructor Create(FileName: string; Config: TPMCFG);
    destructor Destroy; override;
  private
    FConfig: TPMCFG;
    FMpu: TMPU;
    FOpu: TOPU;
    FRom: TROM;
  private
    function GetConfig: TPMCFG;
    procedure FreeMembers;

  public
    property Config: TPMCFG read GetConfig;
  end;

  /////////////////////////////////////////////////////
  TMPU = class
  public
    constructor Create(var PM: TPM);
    destructor Destroy; override;
  private
    FPm: TPM;
  end;
  /////////////////////////////////////////////////////
  TOPU = class
  public
    constructor Create(var PM: TPM);
    destructor Destroy; override;
  private
    FPm: TPM;
  end;
  /////////////////////////////////////////////////////
  TROM = class(TObject)
  public
    constructor Create(FileName: string);
    destructor Destroy; override;
    function GetData(var Buf: TBuffer): LongInt;
  private
    FFileName: string;
    FMap: TMemMapFile;
    FPosition: Cardinal;
    function GetFileName: string;
  public
    property FileName: string read GetFileName;

  end;




implementation

{ TPM }

constructor TPM.Create(FileName: string; Config: TPMCFG);
begin

  try
    FMpu := TMPU.Create(Self);
    FOpu := TOPU.Create(Self);
    FRom := TROM.Create(FileName);
  except
    on E: EFileOpen do
      raise;
  end;
  FConfig := Config;

end;

destructor TPM.Destroy;
begin
  FreeMembers;
  inherited;
end;

procedure TPM.FreeMembers;
begin
  if FMpu <> nil then begin
    FMpu.Free;
    FMpu := nil;
  end;

  if FOpu <> nil then begin
    FOpu.Free;
    FOpu := nil;
  end;

  if FRom <> nil then begin
    FRom.Free;
    FRom := nil;
  end;
end;

function TPM.GetConfig: TPMCFG;
begin
  Result := FConfig;
end;

{ TMPU }

constructor TMPU.Create(var PM: TPM);
begin
  FPm := PM;
end;

destructor TMPU.Destroy;
begin

  inherited;
end;

{ TOPU }

constructor TOPU.Create(var PM: TPM);
begin
  FPm := PM;
end;

destructor TOPU.Destroy;
begin

  inherited;
end;

{ TROM }

constructor TROM.Create(FileName: string);
begin
  try
    FMap := TMemMapFile.Create(FileName, fmOpenRead, 0, True);
  except
    raise EFileOpen.Create(FileName);
  end;

end;

destructor TROM.Destroy;
begin
  if FMap <> nil then
    FMap.Free;
  inherited;
end;



function TROM.GetData(var Buf: TBuffer): LongInt;
begin
  if not Assigned(Buf) then
    Buf := TBuffer.Create;




end;

function TROM.GetFileName: string;
begin
  Result := FFileName;
end;

end.

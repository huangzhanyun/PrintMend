unit PrtCtrl;

interface
uses
  Windows,
  Winspool,
  SysUtils,
  PMConst;

type
  EPrtOpenErr = class(Exception);
  TPrinterCtrl = class(TObject)
  private
    FHandle: THandle;
    FName: string;

  public
    constructor Create;
    destructor Destroy; override;
    procedure Open(PrtName: string);
    function Close: Boolean;
    function StartDocPrinter(Level: Cardinal; pDocInfo: Pointer): DWORD; overload;
    function StartDocPrinter(DocName, OutputFile, DataType: string): DWORD; overload;
    function EndDocPrinter: BOOL;
    function Write(pBuf: Pointer; BufSize: DWORD): DWORD;

  published
    property Handle: THandle read FHandle;
    property Name: string read FName;

  end;


implementation



{ TPrinterCtrl }

function TPrinterCtrl.Close: Boolean;
begin
  Result := False;

  if FHandle <> 0 then
  begin
    Result := ClosePrinter(FHandle);
    FHandle := 0;
    FName := '';
  end;
end;

constructor TPrinterCtrl.Create;
begin

end;

destructor TPrinterCtrl.Destroy;
begin
  Close;
  inherited;
end;

function TPrinterCtrl.EndDocPrinter: BOOL;
begin
  Result := Winspool.EndDocPrinter(FHandle);
end;

procedure TPrinterCtrl.Open(PrtName: string);
var
  Res: BOOL;
begin
  Res := OpenPrinter(PChar(PrtName), FHandle, nil);

  if Res then
    FName := PrtName
  else
    raise EPrtOpenErr.CreateFmt(ESTR_PrinterOpenError +
      ESTR_ErrorValue, [PrtName, GetLastError]);

end;

function TPrinterCtrl.StartDocPrinter(Level: Cardinal;
  pDocInfo: Pointer): DWORD;
begin
  Result := Winspool.StartDocPrinter(FHandle, Level, pDocInfo);
end;

function TPrinterCtrl.StartDocPrinter(DocName, OutputFile,
  DataType: string): DWORD;
var
  Doc: TDocInfo1;
begin
  with Doc do
  begin
    pDocName := PChar(DocName);
    pOutputFile := PChar(OutputFile);
    pDatatype := PChar(DataType);
  end;

  Result := StartDocPrinter(1, @Doc);
end;

function TPrinterCtrl.Write(pBuf: Pointer; BufSize: DWORD): DWORD;
var
  Written: DWORD;
begin
  WritePrinter(FHandle, pBuf, BufSize, Written);
  Result := Written;
end;

end.


unit Mender;

interface

type

  TPrintWay = (pwUnilateral, pwBidirectional);

  TMender = class
  private
    FPinState: Cardinal;
    FPrinterName: String;
    FFileName: String;
    FPrintWay: TPrintWay;
    function GetFileName: String;
    function GetPinState: Cardinal;
    function GetPrinterName: String;
    function GetPrinterWay: TPrintWay;
  protected
  public
    constructor Create;
    destructor Destroy; override;
  published
    property FileName: String read GetFileName;
    property PrinterName: String read GetPrinterName;
    property PrintWay: TPrintWay read GetPrinterWay default pwUnilateral;
    property PinState: Cardinal read GetPinState default $FFFFFF;
  end;

implementation

{ TMender }
constructor TMender.Create;
begin

end;

destructor TMender.Destroy;
begin
  inherited;
end;

function TMender.GetFileName: String;
begin
  Result := FFileName;
end;

function TMender.GetPinState: Cardinal;
begin
  Result := FPinState;
end;

function TMender.GetPrinterName: String;
begin
  Result := FPrinterName;
end;

function TMender.GetPrinterWay: TPrintWay;
begin
  Result := FPrintWay;
end;

end.

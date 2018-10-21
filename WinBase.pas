unit WinBase;

interface

uses Windows, Messages;

type
  TAppIdeEvent = procedure of object;

  TWinApp = class(TObject)
  public
    constructor Create;
    function MainWndProc(hWnd: HWND; uMsg: UINT; wParam: wPARAM;
      lParam: LPARAM): HRESULT; stdcall;
  private
    FInstance: THandle;
    FPlugin: THandle;
    FWnd: HWND;
    FMenu: HMENU;
    FOnIde: TAppIdeEvent;

    procedure SetWnd(Wnd: HWND);
    function GetExeName: string;
    procedure SetPlugin(const Value: THandle);
    procedure SetMenu(const Value: HMENU);
    procedure SetOnIde(const Value: TAppIdeEvent);
    procedure AppIdeEvent;


  public
    property HPlugin: THandle read FPlugin write SetPlugin;
    property MainWnd: HWND read FWnd write SetWnd;
    property ExeName: string read GetExeName;
    property MainMenu: HMENU read FMenu write SetMenu;
    property HInstance: THandle read FInstance;
    property OnIde: TAppIdeEvent read FOnIde write SetOnIde;


  end;

  TWnd = class(TObject)
  private
    FMenu: HMenu;
    procedure SetMenu(const Value: HMenu);
  public
    constructor Create(hParent: HWND);
    destructor Destroy; override;
    procedure DefaultHandler(var Message); override;
    function MainWndProc(hWnd: HWND; uMsg: UINT; wParam: wPARAM;
      lParam: LPARAM): HRESULT; stdcall;
  public
    Handle: HWND;
  protected
    procedure WndProc(var Message: TMessage); virtual;
  public
    property MainMenu: HMenu read FMenu write SetMenu;

  end;
  TWndFrame = class(TWnd)
  private

  protected

  public
    constructor Create(lpClassName: PChar; lpWndName: PChar; dwStyle: DWORD;
      x, y, Width, Height: integer; hParentWnd: HWND; hMenu: HMENU);

  published

  end;

  TDialog = class(TWnd)
  public
    procedure DefaultHandler(var Message); override;
    function DoModal(hWndParent: HWND): Integer; virtual;
  end;


  PWndProc = ^TWndProc;
  TWndProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM;
    lParam: LPARAM): HRESULT; stdcall;

function g_WndProc(hWnd: HWND; uMsg: Cardinal; wParam: WPARAM;
  lParam: LPARAM): HRESULT; stdcall;
function g_DlgProc(hDlg: HWND; uMsg: Cardinal; wParam: WPARAM;
  lParam: LPARAM): BOOL; stdcall;

function Application: TWinApp;
implementation

{ TWinApp }

constructor TWinApp.Create;
begin
  FInstance := GetModuleHandle(nil);
  FOnIde := AppIdeEvent;
end;






procedure TWinApp.SetWnd(Wnd: HWND);
begin
  FWnd := Wnd;
end;


function TWinApp.GetExeName: string;
begin
  Result := ParamStr(0);
end;



procedure TWinApp.SetPlugin(const Value: THandle);
begin
  FPlugin := Value;
end;


procedure TWinApp.SetMenu(const Value: HMENU);
begin
  FMenu := Value;
end;

{ Global Function }

function g_DlgProc(hDlg: HWND; uMsg: Cardinal; wParam: WPARAM;
  lParam: LPARAM): BOOL;
var
  Message: TMessage;
  Dlg: TWnd;
begin
  Message.Msg := uMsg;
  Message.LParam := lParam;
  Message.WParam := wParam;
  Message.Result := 0;
  if uMsg = WM_INITDIALOG then
  begin
    Dlg := TWnd(GetWindowLong(hDlg, GWL_USERDATA));
    if Dlg = nil then
    begin
      SetWindowLong(hDlg, GWL_USERDATA, Integer(lParam));
      Dlg := TWnd(lParam);
    end;
    Dlg.Handle := hDlg;
  end;

  Dlg := TWnd(GetWindowLong(hDlg, GWL_USERDATA));

  if Dlg <> nil then
  begin
    Dlg.Dispatch(Message);
    Result := BOOL(Message.Result);
    if Message.Msg = WM_CLOSE then
      Dlg.Free;

    Exit;
  end;

  Result := False;
end;

function g_WndProc(hWnd: HWND; uMsg: Cardinal; wParam: WPARAM;
  lParam: LPARAM): HRESULT;
var
  lpcs: PCreateStruct;
  Wnd: TWnd;
  Message: TMessage;
begin
  Message.Msg := uMsg;
  Message.WParam := wParam;
  Message.LParam := lParam;
  Message.Result := 0;

  if uMsg = WM_CREATE then
  begin
    lpcs := PCreateStruct(lParam);
    Wnd := TWnd(GetWindowLong(hWnd, GWL_USERDATA));
    if Wnd = nil then
    begin
      SetWindowLong(hWnd, GWL_USERDATA, Integer(lpcs.lpCreateParams));
      Wnd := TWnd(lpcs.lpCreateParams);
      Wnd.Handle := hWnd;
    end;
  end;

  Wnd := TWnd(GetWindowLong(hWnd, GWL_USERDATA));

  if Wnd <> nil then
  begin
    Wnd.Dispatch(Message);
    if Message.Msg = WM_DESTROY then
    begin
      SetWindowLong(Wnd.Handle, GWL_USERDATA, 0);
      Wnd.Free;
    end;
    Result := Message.Result;
    Exit;
  end;
  Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
end;


function TWinApp.MainWndProc(hWnd: HWND; uMsg: UINT; wParam: wPARAM;
  lParam: LPARAM): HRESULT;
var
  lpcs: PCreateStruct;
  Wnd: TWnd;
  Message: TMessage;
begin
  Message.Msg := uMsg;
  Message.WParam := wParam;
  Message.LParam := lParam;
  Message.Result := 0;

  if uMsg = WM_CREATE then
  begin
    lpcs := PCreateStruct(lParam);
    Wnd := TWnd(GetWindowLong(hWnd, GWL_USERDATA));
    if Wnd = nil then
    begin
      SetWindowLong(hWnd, GWL_USERDATA, Integer(lpcs.lpCreateParams));
      Wnd := TWnd(lpcs.lpCreateParams);
      Wnd.Handle := hWnd;
    end;
  end;

  Wnd := TWnd(GetWindowLong(hWnd, GWL_USERDATA));

  if Wnd <> nil then
  begin
    Wnd.Dispatch(Message);
    if Message.Msg = WM_DESTROY then
    begin
      SetWindowLong(Wnd.Handle, GWL_USERDATA, 0);
      Wnd.Free;
    end;
    Result := Message.Result;
    Exit;
  end;
  Result := DefWindowProc(hWnd, uMsg, wParam, lParam);

end;

procedure TWinApp.SetOnIde(const Value: TAppIdeEvent);
begin
  FOnIde := Value;
end;

procedure TWinApp.AppIdeEvent;
begin

end;

{ TWnd }





constructor TWnd.Create(hParent: HWND);
begin

end;

procedure TWnd.DefaultHandler(var Message);
begin
  with TMessage(Message) do
    Result := DefWindowProc(Handle, Msg, WParam, LParam);
end;

destructor TWnd.Destroy;
begin

end;

var WinApp: TWinApp;

function Application: TWinApp;
begin
  if WinApp = nil then
  begin
    WinApp := TWinApp.Create;
  end;

  Result := WinApp;
end;

function TWnd.MainWndProc(hWnd: HWND; uMsg: UINT; wParam: wPARAM;
  lParam: LPARAM): HRESULT;
begin
  Result := 0;
end;

procedure TWnd.SetMenu(const Value: HMenu);
begin
  FMenu := Value;
  if Handle <> 0 then
    Windows.SetMenu(Handle, FMenu);
end;

procedure TWnd.WndProc(var Message: TMessage);
begin

end;

{ TDialog }




procedure TDialog.DefaultHandler(var Message);
begin

end;




function TDialog.DoModal(hWndParent: HWND): Integer;
begin

end;

{ TWndFrame }

constructor TWndFrame.Create(lpClassName, lpWndName: PChar; dwStyle: DWORD;
  x, y, Width, Height: integer; hParentWnd: HWND; hMenu: HMENU);
var WndCls: TWndClassEx;
begin
  if IsWindow(hParentWnd) then
  begin
    CreateWindowEx(WS_EX_OVERLAPPEDWINDOW, lpClassName, lpWndName, dwStyle, x, y, Width, Height, hParentWnd,
      hMenu, Application.HInstance, Self);
    Exit;
  end;

end;

initialization
  WinApp := nil;
finalization
  if WinApp <> nil then
    WinApp.Free;
end.

 
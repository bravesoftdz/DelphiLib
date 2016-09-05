unit DigiLedAPI;

interface

uses Windows, Messages;

const
  DIGILED_CLASSNAME = 'NGDIGILED';

  // DigiLed Messages
  DLM_GET_LED          = WM_USER + 1;
  DLM_SET_LED          = WM_USER + 2;
  DLM_GET_MASK	       = WM_USER + 3;
  DLM_SET_MASK	       = WM_USER + 4;
  DLM_GET_TYPE	       = WM_USER + 5;
  DLM_SET_TYPE	       = WM_USER + 6;
  DLM_GET_VALUE	       = WM_USER + 7;
  DLM_SET_VALUE	       = WM_USER + 8;
  DLM_GET_BKCOLOR      = WM_USER + 9;
  DLM_SET_BKCOLOR      = WM_USER + 10;
  DLM_GET_LED_COLOR    = WM_USER + 11;
  DLM_SET_LED_COLOR    = WM_USER + 12;
  DLM_GET_BORDER_COLOR = WM_USER + 13;
  DLM_SET_BORDER_COLOR = WM_USER + 14;


  // DigiLed Notification Codes
  DLN_CLICK  = 50;
  DLN_RCLICK = 51;

  // DigiLed Types
  DLT_SEVEN_LEDS = 1;
  DLT_EIGHT_LEDS = 2;

  // helper functions
  function CreateDigiLed(hWndParent: HWND; nID, x, y, nWidth, nHeight: Integer; hInstance: THandle): HWND; stdcall;
  function InitDigiLed(hInst: THandle): BOOL; stdcall;
  function DigiLed_IsLedOn(hWnd: HWND; index: Integer): BOOL; stdcall;
  procedure DigiLed_SetLed(hWnd: HWND; index: Integer; status: BOOL); stdcall;
  function DigiLed_GetMask(hWnd: HWND): Integer; stdcall;
  procedure DigiLed_SetMask(hWnd: HWND; newMask: Integer); stdcall;
  function DigiLed_GetType(hWnd: HWND): Integer; stdcall;
  procedure DigiLed_SetType(hWnd: HWND; newType: Integer); stdcall;
  function DigiLed_GetValue(hWnd: HWND): char; stdcall;
  procedure DigiLed_SetValue(hWnd: HWND; ch: char); stdcall;

implementation

const
  DigiDLL = 'DigiDLL.DLL';

  function CreateDigiLed(hWndParent: HWND; nID, x, y, nWidth, nHeight: Integer; hInstance: THandle): HWND; external DigiDLL name 'CreateDigiLed';
  function InitDigiLed(hInst: THandle): BOOL; external DigiDLL name 'InitDigiLed';
  function DigiLed_IsLedOn(hWnd: HWND; index: Integer): BOOL; external DigiDLL name 'DigiLed_IsLedOn';
  procedure DigiLed_SetLed(hWnd: HWND; index: Integer; status: BOOL); external DigiDLL name 'DigiLed_SetLed';
  function DigiLed_GetMask(hWnd: HWND): Integer; external DigiDLL name 'DigiLed_GetMask';
  procedure DigiLed_SetMask(hWnd: HWND; newMask: Integer); external DigiDLL name 'DigiLed_SetMask';
  function DigiLed_GetType(hWnd: HWND): Integer; external DigiDLL name 'DigiLed_GetType';
  procedure DigiLed_SetType(hWnd: HWND; newType: Integer); external DigiDLL name 'DigiLed_SetType';
  function DigiLed_GetValue(hWnd: HWND): char; external DigiDLL name 'DigiLed_GetValue';
  procedure DigiLed_SetValue(hWnd: HWND; ch: char); external DigiDLL name 'DigiLed_SetValue';

end.

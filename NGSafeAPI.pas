unit NGSafeAPI;

interface

uses Windows;

const
  ERROR_SUCCESS = 1;
  ERROR_FILE_NOT_ENCODED = -1;
  ERROR_PASSWORD_INVALID = -2;
  ERROR_FAILURE          = -3;

  MAX_PASSWORD = 6;

type
  TPassword = String[MAX_PASSWORD];

function GetNGSafeVersion: LongInt;
function EncodeFile(Source, Dest: PChar; const Password: TPassword; DeleteSource: BOOL): LongInt;
function DecodeFile(Source, Dest: PChar; const Password: TPassword; DeleteSource: BOOL): LongInt;

implementation

const
  NGSafeDLL = 'NGSafe.Dll';

function GetNGSafeVersion: LongInt; external NGSafeDLL index 1;
function EncodeFile(Source, Dest: PChar; const Password: TPassword; DeleteSource: BOOL): LongInt; external NGSafeDLL index 2;
function DecodeFile(Source, Dest: PChar; const Password: TPassword; DeleteSource: BOOL): LongInt; external NGSafeDLL index 3;

end.

// === File: TestBibleResourceManager.lpr ===
program TestBibleResourceManager;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, StrUtils,
  BibleResourceManager;

const
{$IFDEF mswindows}
  BTTLibraryDir = 'AppData\Local\BTT-Writer\library';
{$ENDIF}
{$IFDEF unix}
  {$IFDEF darwin}
  BTTLibraryDir = 'Library/Application Support/BTT-Writer/library';
  {$ELSE}
  BTTLibraryDir = '.config/BTT-Writer/library';
  {$ENDIF}
{$ENDIF}

  DefaultLang1 = 'en';
  DefaultLang2 = 'arb';
  DefaultBook = '2ch';
  DefaultResType = 'ulb';

function GetParamValue(const Flag: string; const Default: string): string;
var
  i: Integer;
begin
  for i := 1 to ParamCount - 1 do
  begin
    if ParamStr(i) = Flag then
    begin
      Result := ParamStr(i + 1);
      Exit;
    end;
  end;
  Result := Default;
end;

var
  SourceDir: string;
  Container: TLanguageContainer;
  Report: TStringList;
  Lang1, Lang2, Book: string;
begin
  SourceDir := ExpandFileName(IncludeTrailingPathDelimiter(GetUserDir) + BTTLibraryDir);
  Lang1 := GetParamValue('-1', DefaultLang1);
  Lang2 := GetParamValue('-2', DefaultLang2);
  Book  := GetParamValue('-book', DefaultBook);

  WriteLn('Comparing book: ', Book);
  WriteLn('From language: ', Lang1);
  WriteLn('To language:   ', Lang2);

  Container := TLanguageContainer.Create;
  try
    if not Container.LoadFromDirectory(SourceDir) then
    begin
      WriteLn('Failed to load resource directory at ', SourceDir);
      Halt(1);
    end;

    Report := Container.CompareBooks(Lang1, Book, DefaultResType, DefaultResType);
    try
      WriteLn;
      WriteLn('--- Comparison Report ---');
      WriteLn;
      WriteLn(Report.Text);
    finally
      Report.Free;
    end;
  finally
    Container.Free;
  end;
end.

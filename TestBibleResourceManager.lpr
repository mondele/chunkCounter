program TestBibleResourceManager;

{$mode objfpc}{$H+}

uses
  SysUtils,
  StrUtils,
  Classes,
  BibleResourceManager,
  Globals;

const
  {$IFDEF mswindows}
  BTTLibraryDir = 'AppData\Local\BTT-Writer\library\resource_containers';
  {$ENDIF}
  {$IFDEF unix}
  {$IFDEF darwin}
  BTTLibraryDir = 'Library/Application Support/BTT-Writer/library/resource_containers';
  {$ELSE}
  BTTLibraryDir = '.config/BTT-Writer/library/resource_containers';
  {$ENDIF}
  {$ENDIF}

var
  Container: TLanguageContainer;
  Output: TStringList;
  Putout: string;
  SourceDir, Lang1, Lang2, BookCode, ResType1, ResType2: string;
  I: integer;

begin
  // Defaults
  Lang1 := 'arb';
  Lang2 := 'arb';
  BookCode := 'gen';
  ResType1 := 'nav';
  ResType2 := 'avd';
  Putout := '';

  // Parse command-line arguments
  for I := 1 to ParamCount do
  begin
    if ParamStr(I) = '-1' then
      Lang1 := ParamStr(I + 1)
    else if ParamStr(I) = '-2' then
      Lang2 := ParamStr(I + 1)
    else if ParamStr(I) = '-r1' then
      ResType1 := ParamStr(I + 1)
    else if ParamStr(I) = '-r2' then
      ResType2 := ParamStr(I + 1)
    else if ParamStr(I) = '-book' then
      BookCode := ParamStr(I + 1)
    else if ParamStr(I) = '-v' then
      Verbose := True
    else if ParamStr(I) = '-h' then
    begin
      WriteLn('TestBibleResourceManager: Compare Bible resources between two languages and/or resource types.');
      WriteLn('Options:');
      WriteLn('  -1 lang1        Language code for the first resource (default: en)');
      WriteLn('  -r1 resType1    Resource type for the first resource (default: ulb)');
      WriteLn('  -2 lang2        Language code for the second resource (default: arb)');
      WriteLn('  -r2 resType2    Resource type for the second resource (default: ulb)');
      WriteLn('  -book bookCode  Book code to compare (default: 2ch)');
      WriteLn('  -v              Enable verbose output');
      WriteLn('  -h              Show this help message');
      Halt(0);
    end;
  end;

  SourceDir := ExpandFileName(IncludeTrailingPathDelimiter(GetUserDir) + BTTLibraryDir);
  Container := TLanguageContainer.Create;

  try
    begin
    if not Container.LoadFromDirectory(SourceDir) then
    begin
      WriteLn('Failed to load resources from: ', SourceDir);
      Halt(1);
    end;

    Output := Container.CompareBooks(Lang1, ResType1, Lang2, ResType2, BookCode);
    for Putout in Output do
      WriteLn(Putout);
      end;
    WriteLn(Output.Text);
    FreeAndNil(Output);
  finally
    FreeAndNil(Container);
  end;
end.

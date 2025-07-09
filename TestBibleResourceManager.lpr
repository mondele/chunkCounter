program TestBibleResourceManager;

{$mode objfpc}{$H+}

uses
  SysUtils,
  StrUtils,
  Classes,
  BibleResourceManager;

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
  SourceDir, Lang1, Lang2, BookCode, ResType1, ResType2: string;
  Verbose: boolean;
  I: integer;

begin
  // Defaults
  Lang1 := 'en';
  Lang2 := 'arb';
  BookCode := '2ch';
  ResType1 := 'ulb';
  ResType2 := 'ulb';
  Verbose := False;

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
      Verbose := True;
  end;

  SourceDir := ExpandFileName(IncludeTrailingPathDelimiter(GetUserDir) + BTTLibraryDir);
  Container := TLanguageContainer.Create;
  try
    if not Container.LoadFromDirectory(SourceDir) then
    begin
      WriteLn('Failed to load resources from: ', SourceDir);
      Halt(1);
    end;

    Output := Container.CompareBooks(Lang1, ResType1, Lang2, ResType2, BookCode);
    try
      WriteLn('Comparing ', Lang1, ' ', ResType1, ' and ', Lang2, ' ',
        ResType2, ' for book ', BookCode);
      WriteLn(Output.Text);
    finally
      if Assigned(Output) then
      begin
        WriteLn(Output.Text);
        Output.Free;
      end;
    end;

  finally
    Container.Free;
  end;
end.

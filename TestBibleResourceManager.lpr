program TestBibleResourceManager;

{$mode objfpc}{$H+}

uses
  SysUtils,
  BibleResourceManager, Classes;

const
  {$IFDEF mswindows}
  BTTLibraryDir = 'AppData\Local\BTT-Writer\library\resource_containers\';
  {$ENDIF}
  {$IFDEF unix}
  {$IFDEF darwin}
  BTTLibraryDir = 'Library/Application Support/BTT-Writer/library/resource_containers/';
  {$ELSE}
  BTTLibraryDir = '.config/BTT-Writer/library/resource_containers/';
  {$ENDIF}
  {$ENDIF}
  defaultLangCode = 'arb';

var
  Container: TLanguageContainer;
  Output: string;
  sourceDir: string;
  LangCode: string;
  I: Integer; // for loop index

begin
  sourceDir := ExpandFileName(IncludeTrailingPathDelimiter(GetUserDir) + BTTLibraryDir);
  Container := TLanguageContainer.Create;
  if ParamCount > 0 then
    LangCode := ParamStr(1)
  else
    LangCode := defaultLangCode;
  try
    Container.LoadFromDirectory(sourceDir);
    // testing block
    WriteLn('Using source directory: ', sourceDir);
    WriteLn('Languages found: ', Container.LanguageCount);
    for I := 0 to Container.LanguageCount - 1 do
      WriteLn('Loaded language: ', Container.GetLanguageCode(I));

    Output := Container.GetStructure(LangCode);
    if Output = '' then
      WriteLn('No structure found for language code: ', LangCode)
    else
      WriteLn(Output);

    // end of testing block
    Output := Container.GetStructure(LangCode); // or another known language
    WriteLn('Looking for Resources in ' + sourceDir + '.');
    WriteLn(Output);
  finally
    Container.Free;
  end;
end.

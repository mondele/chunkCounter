program TestProjectVsResource;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Classes,
  BibleBook,
  Globals;

const
  {$IFDEF mswindows}
  BTTLibraryDir = 'AppData\Local\BTT-Writer\library\resource_containers';
  BTTTargetDir = 'AppData\Local\BTT-Writer\targetTranslations';
  {$ENDIF}
  {$IFDEF unix}
  {$IFDEF darwin}
  BTTLibraryDir = 'Library/Application Support/BTT-Writer/library/resource_containers';
  BTTTargetDir = 'Library/Application Support/BTT-Writer/targetTranslations';
  {$ELSE}
  BTTLibraryDir = '.config/BTT-Writer/library/resource_containers';
  BTTTargetDir = '.config/BTT-Writer/targetTranslations';
  {$ENDIF}
  {$ENDIF}

var
  SourceBook, TargetBook: TBook;
  Output: TStringList;
  Putout: string;
  TargetBaseDir, LibraryBaseDir: string;
  Project, Lang, ResType, BookCode: string;
  Parts: TStringArray;
  I: Integer;

begin
  Project := '';
  Lang := 'en';
  ResType := 'ulb';
  BookCode := '';

  for I := 1 to ParamCount do
  begin
    if ParamStr(I) = '-project' then
      Project := ParamStr(I + 1)
    else if ParamStr(I) = '-lang' then
      Lang := ParamStr(I + 1)
    else if ParamStr(I) = '-res' then
      ResType := ParamStr(I + 1)
    else if ParamStr(I) = '-book' then
      BookCode := ParamStr(I + 1)
    else if ParamStr(I) = '-v' then
      Verbose := True
    else if ParamStr(I) = '-h' then
    begin
      WriteLn('TestProjectVsResource: Compare a target translation project''s chunks against a source resource.');
      WriteLn('Options:');
      WriteLn('  -project dirName  Target translation project directory name under targetTranslations');
      WriteLn('                    (e.g. udm_1ch_text_reg). Book code defaults to its second segment.');
      WriteLn('  -lang lang        Source resource language code (default: en)');
      WriteLn('  -res resType      Source resource type (default: ulb)');
      WriteLn('  -book bookCode    Book code override (default: derived from -project)');
      WriteLn('  -v                Enable verbose output');
      WriteLn('  -h                Show this help message');
      Halt(0);
    end;
  end;

  if Project = '' then
  begin
    WriteLn('Missing required -project <dirName>. Use -h for help.');
    Halt(1);
  end;

  if BookCode = '' then
  begin
    Parts := Project.Split('_');
    if Length(Parts) >= 2 then
      BookCode := Parts[1];
    if BookCode = '' then
    begin
      WriteLn('Could not derive book code from project name "', Project, '". Pass -book explicitly.');
      Halt(1);
    end;
  end;

  TargetBaseDir := ExpandFileName(IncludeTrailingPathDelimiter(GetUserDir) + BTTTargetDir);
  LibraryBaseDir := ExpandFileName(IncludeTrailingPathDelimiter(GetUserDir) + BTTLibraryDir);

  SourceBook := TBook.Create(BookCode, ResType);
  TargetBook := TBook.Create(BookCode, Project);
  try
    SourceBook.LoadFromDisk(IncludeTrailingPathDelimiter(LibraryBaseDir) +
      Lang + '_' + BookCode + '_' + ResType + PathDelim + 'content');

    TargetBook.LoadFromTargetTranslation(IncludeTrailingPathDelimiter(TargetBaseDir) + Project);

    if SourceBook.Chapters.Count = 0 then
    begin
      WriteLn('Source resource not found: lang=', Lang, ', book=', BookCode, ', type=', ResType);
      Halt(1);
    end;
    if TargetBook.Chapters.Count = 0 then
    begin
      WriteLn('Target translation project not found or empty: ', Project);
      Halt(1);
    end;

    Output := SourceBook.CompareWith(TargetBook);
    for Putout in Output do
      WriteLn(Putout);
    FreeAndNil(Output);
  finally
    FreeAndNil(SourceBook);
    FreeAndNil(TargetBook);
  end;
end.

program GenerateSourceReport;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Classes,
  fgl,
  fpjson,
  jsonparser,
  BibleBook,
  BibleChapter,
  BibleChunk,
  SourceReport,
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

const
  // Canonical USFM book order, Genesis..Malachi then Matthew..Revelation.
  // Numbering skips 40 (reserved in the USFM scheme, unused between OT/NT).
  CanonicalBookCodes: array[1..66] of string = (
    'gen', 'exo', 'lev', 'num', 'deu', 'jos', 'jdg', 'rut', '1sa', '2sa',
    '1ki', '2ki', '1ch', '2ch', 'ezr', 'neh', 'est', 'job', 'psa', 'pro',
    'ecc', 'sng', 'isa', 'jer', 'lam', 'ezk', 'dan', 'hos', 'jol', 'amo',
    'oba', 'jon', 'mic', 'nam', 'hab', 'zep', 'hag', 'zec', 'mal',
    'mat', 'mrk', 'luk', 'jhn', 'act', 'rom', '1co', '2co', 'gal', 'eph',
    'php', 'col', '1th', '2th', '1ti', '2ti', 'tit', 'phm', 'heb', 'jas',
    '1pe', '2pe', '1jn', '2jn', '3jn', 'jud', 'rev'
  );

type
  TBaselineCache = specialize TFPGMapObject<string, TBook>;

  TLangResCounter = class
    Lang, Res: string;
    Total, Match: Integer;
  end;

  TBookCounter = class
    BookCode: string;
    EnChapters, EnChunksTotal, EnChunksExclTitle: Integer;
    Total, Match: Integer;
  end;

var
  LibraryBaseDir, OutDir, BaseLang, BaseRes: string;
  I: Integer;
  Baseline: TBaselineCache;
  SummaryFile, DetailFile: TextFile;
  DetailRows: TStringList;
  LangResStats: TStringList;
  BookStats: TStringList;
  DirsSeen, RowsWritten, IdenticalCount, DifferCount: Integer;

function ReadPackageType(const PkgPath: string; out ResType: string): Boolean;
var
  Content: TStringList;
  JSON, TypeNode: TJSONData;
begin
  Result := False;
  ResType := '';
  if not FileExists(PkgPath) then Exit;

  Content := TStringList.Create;
  JSON := nil;
  try
    try
      Content.LoadFromFile(PkgPath);
      JSON := GetJSON(Content.Text);
      TypeNode := JSON.FindPath('resource.type');
      if Assigned(TypeNode) then
      begin
        ResType := TypeNode.AsString;
        Result := True;
      end;
    except
      Result := False;
    end;
  finally
    if Assigned(JSON) then JSON.Free;
    FreeAndNil(Content);
  end;
end;

function CanonicalBookOrder(const BookCode: string): string;
var
  i, Order: Integer;
begin
  Result := '';
  for i := Low(CanonicalBookCodes) to High(CanonicalBookCodes) do
    if CanonicalBookCodes[i] = BookCode then
    begin
      if i <= 39 then
        Order := i
      else
        Order := i + 1;
      Result := Format('%.2d', [Order]);
      Exit;
    end;
end;

function GetOrCreateCounter(const Lang, Res: string): TLangResCounter;
var
  Key: string;
  Idx: Integer;
begin
  Key := Lang + '_' + Res;
  Idx := LangResStats.IndexOf(Key);
  if Idx = -1 then
  begin
    Result := TLangResCounter.Create;
    Result.Lang := Lang;
    Result.Res := Res;
    Result.Total := 0;
    Result.Match := 0;
    LangResStats.AddObject(Key, Result);
  end
  else
    Result := TLangResCounter(LangResStats.Objects[Idx]);
end;

function CompareLangResStats(List: TStringList; Index1, Index2: Integer): Integer;
var
  A, B: TLangResCounter;
begin
  A := TLangResCounter(List.Objects[Index1]);
  B := TLangResCounter(List.Objects[Index2]);
  if A.Match <> B.Match then
    Result := B.Match - A.Match
  else
    Result := (A.Total - A.Match) - (B.Total - B.Match);
end;

function GetOrCreateBookCounter(const BookCode: string): TBookCounter;
var
  Idx: Integer;
begin
  Idx := BookStats.IndexOf(BookCode);
  if Idx = -1 then
  begin
    Result := TBookCounter.Create;
    Result.BookCode := BookCode;
    Result.EnChapters := 0;
    Result.EnChunksTotal := 0;
    Result.EnChunksExclTitle := 0;
    Result.Total := 0;
    Result.Match := 0;
    BookStats.AddObject(BookCode, Result);
  end
  else
    Result := TBookCounter(BookStats.Objects[Idx]);
end;

function GetOrLoadBaseline(const BookCode: string): TBook;
var
  BC: TBookCounter;
  ci, cj: Integer;
  Chap: TChapter;
begin
  if not Baseline.TryGetData(BookCode, Result) then
  begin
    Result := TBook.Create(BookCode, BaseRes);
    Result.LoadFromDisk(IncludeTrailingPathDelimiter(LibraryBaseDir) +
      BaseLang + '_' + BookCode + '_' + BaseRes + PathDelim + 'content');
    Baseline.Add(BookCode, Result);

    BC := GetOrCreateBookCounter(BookCode);
    BC.EnChapters := Result.Chapters.Count;
    for ci := 0 to Result.Chapters.Count - 1 do
    begin
      Chap := Result.Chapters[ci];
      Inc(BC.EnChunksTotal, Chap.Chunks.Count);
      for cj := 0 to Chap.Chunks.Count - 1 do
        if Chap.Chunks[cj].Name <> 'title' then
          Inc(BC.EnChunksExclTitle);
    end;
  end;
end;

procedure ProcessResourceDir(const DirName: string);
var
  Parts: TStringArray;
  Lang, BookCode, ResType, PkgResType: string;
  EnBook, OtherBook: TBook;
  Stats: TBookDiffStats;
  Counter: TLangResCounter;
  BookCounter: TBookCounter;
  k: Integer;
begin
  Parts := DirName.Split('_');
  if Length(Parts) <> 3 then Exit;
  Lang := Parts[0];
  BookCode := Parts[1];
  ResType := Parts[2];

  if not ReadPackageType(IncludeTrailingPathDelimiter(LibraryBaseDir) +
    DirName + PathDelim + 'package.json', PkgResType) then Exit;
  if PkgResType <> 'book' then Exit;
  if (Lang = BaseLang) and (ResType = BaseRes) then Exit;

  EnBook := GetOrLoadBaseline(BookCode);
  if (EnBook = nil) or (EnBook.Chapters.Count = 0) then
  begin
    if Verbose then WriteLn('  no baseline for book ', BookCode, ', skipping ', DirName);
    Exit;
  end;

  Inc(DirsSeen);
  if Verbose then WriteLn('Comparing ', DirName, ' vs ', BaseLang, '_', BookCode, '_', BaseRes);

  OtherBook := TBook.Create(BookCode, ResType);
  try
    OtherBook.LoadFromDisk(IncludeTrailingPathDelimiter(LibraryBaseDir) +
      DirName + PathDelim + 'content');
    if OtherBook.Chapters.Count = 0 then
    begin
      if Verbose then WriteLn('  empty/unreadable: ', DirName);
      Exit;
    end;

    DetailRows.Clear;
    Stats := ComputeDiff(EnBook, OtherBook, Lang, BookCode, ResType, DetailRows);

    WriteLn(SummaryFile, Format('%s,%s,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s',
      [Lang, BookCode, CanonicalBookOrder(BookCode), ResType, Stats.ChaptersSource, Stats.ChaptersOther,
       Stats.ChaptersMissingInOther, Stats.ChaptersExtraInOther,
       Stats.ChunksSource, Stats.ChunksOther, Stats.ChunksMissingInOther,
       Stats.ChunksExtraInOther, Stats.ChunksOnDiskMismatch,
       BoolToStr(Stats.IsIdentical, 'Y', 'N')]));
    Inc(RowsWritten);

    Counter := GetOrCreateCounter(Lang, ResType);
    Inc(Counter.Total);
    if Stats.IsIdentical then
    begin
      Inc(Counter.Match);
      Inc(IdenticalCount);
    end
    else
      Inc(DifferCount);

    BookCounter := GetOrCreateBookCounter(BookCode);
    Inc(BookCounter.Total);
    if Stats.IsIdentical then
      Inc(BookCounter.Match);

    for k := 0 to DetailRows.Count - 1 do
      WriteLn(DetailFile, DetailRows[k]);
  finally
    FreeAndNil(OtherBook);
  end;
end;

procedure WriteMarkdownSummary;
var
  MdFile: TextFile;
  i: Integer;
  C: TLangResCounter;
  B: TBookCounter;
  Pct: Double;
  FullMatches: TStringList;
begin
  LangResStats.CustomSort(@CompareLangResStats);

  AssignFile(MdFile, IncludeTrailingPathDelimiter(OutDir) + 'summary.md');
  Rewrite(MdFile);
  try
    WriteLn(MdFile, '# Source chunk comparison vs ', BaseLang, '_', BaseRes);
    WriteLn(MdFile, '');
    WriteLn(MdFile, 'Generated ', DateTimeToStr(Now), '.');
    WriteLn(MdFile, '');
    WriteLn(MdFile, 'Compared ', DirsSeen, ' resources: ', IdenticalCount,
      ' identical, ', DifferCount, ' differing.');
    WriteLn(MdFile, '');
    WriteLn(MdFile, '| Language | Source | Books Matched | Books Compared | Match % |');
    WriteLn(MdFile, '|---|---|---|---|---|');

    FullMatches := TStringList.Create;
    try
      for i := 0 to LangResStats.Count - 1 do
      begin
        C := TLangResCounter(LangResStats.Objects[i]);
        if C.Total > 0 then
          Pct := 100.0 * C.Match / C.Total
        else
          Pct := 0;
        WriteLn(MdFile, Format('| %s | %s | %d | %d | %.1f%% |',
          [C.Lang, C.Res, C.Match, C.Total, Pct]));

        if C.Match = C.Total then
        begin
          if C.Total < 10 then
            FullMatches.Add(Format('%s_%s (%d/%d, limited coverage)',
              [C.Lang, C.Res, C.Match, C.Total]))
          else
            FullMatches.Add(Format('%s_%s (%d/%d)', [C.Lang, C.Res, C.Match, C.Total]));
        end;
      end;

      WriteLn(MdFile, '');
      if FullMatches.Count = 0 then
        WriteLn(MdFile, 'No source reaches a 100% match with ', BaseLang, '_', BaseRes, '.')
      else
      begin
        WriteLn(MdFile, 'Sources matching 100%:');
        WriteLn(MdFile, '');
        for i := 0 to FullMatches.Count - 1 do
          WriteLn(MdFile, '- ', FullMatches[i]);
      end;
    finally
      FreeAndNil(FullMatches);
    end;

    WriteLn(MdFile, '');
    WriteLn(MdFile, '## Per-book totals');
    WriteLn(MdFile, '');
    WriteLn(MdFile, 'The `', BaseLang, '_', BaseRes,
      '` columns are the baseline''s own numbers for that book (compare');
    WriteLn(MdFile, 'against PORT directly); the rest is the rollup of every other source');
    WriteLn(MdFile, 'checked against that baseline.');
    WriteLn(MdFile, '');
    WriteLn(MdFile, Format('| Book | %s Chapters | %s Chunks (total) | %s Chunks (excl. title) | Sources Compared | Sources Matching | Match %% |',
      [BaseLang + '_' + BaseRes, BaseLang + '_' + BaseRes, BaseLang + '_' + BaseRes]));
    WriteLn(MdFile, '|---|---|---|---|---|---|---|');
    for i := 0 to BookStats.Count - 1 do
    begin
      B := TBookCounter(BookStats.Objects[i]);
      if B.Total > 0 then
        Pct := 100.0 * B.Match / B.Total
      else
        Pct := 0;
      WriteLn(MdFile, Format('| %s | %d | %d | %d | %d | %d | %.1f%% |',
        [B.BookCode, B.EnChapters, B.EnChunksTotal, B.EnChunksExclTitle,
         B.Total, B.Match, Pct]));
    end;
  finally
    CloseFile(MdFile);
  end;
end;

var
  SR: TSearchRec;

begin
  BaseLang := 'en';
  BaseRes := 'ulb';
  OutDir := 'reports';
  DirsSeen := 0;
  RowsWritten := 0;
  IdenticalCount := 0;
  DifferCount := 0;

  I := 1;
  while I <= ParamCount do
  begin
    if ParamStr(I) = '-baseLang' then
    begin
      BaseLang := ParamStr(I + 1);
      Inc(I);
    end
    else if ParamStr(I) = '-baseRes' then
    begin
      BaseRes := ParamStr(I + 1);
      Inc(I);
    end
    else if ParamStr(I) = '-out' then
    begin
      OutDir := ParamStr(I + 1);
      Inc(I);
    end
    else if ParamStr(I) = '-v' then
      Verbose := True
    else if ParamStr(I) = '-h' then
    begin
      WriteLn('GenerateSourceReport: batch-diff every book-type resource container against a baseline.');
      WriteLn('Options:');
      WriteLn('  -baseLang lang   Baseline language code (default: en)');
      WriteLn('  -baseRes  res    Baseline resource type (default: ulb)');
      WriteLn('  -out      dir    Output directory for summary.csv/detail.csv/summary.md (default: ./reports)');
      WriteLn('  -v               Verbose output');
      WriteLn('  -h               Show this help message');
      Halt(0);
    end;
    Inc(I);
  end;

  LibraryBaseDir := ExpandFileName(IncludeTrailingPathDelimiter(GetUserDir) + BTTLibraryDir);
  if not DirectoryExists(LibraryBaseDir) then
  begin
    WriteLn('Library not found: ', LibraryBaseDir);
    Halt(1);
  end;
  if not DirectoryExists(OutDir) then
    ForceDirectories(OutDir);

  Baseline := TBaselineCache.Create;
  DetailRows := TStringList.Create;
  LangResStats := TStringList.Create;
  BookStats := TStringList.Create;
  BookStats.Sorted := True;

  AssignFile(SummaryFile, IncludeTrailingPathDelimiter(OutDir) + 'summary.csv');
  Rewrite(SummaryFile);
  WriteLn(SummaryFile, 'lang,book,book_order,res,chapters_source,chapters_other,chapters_missing_in_other,chapters_extra_in_other,chunks_source,chunks_other,chunks_missing_in_other,chunks_extra_in_other,chunks_ondisk_mismatch,is_identical');

  AssignFile(DetailFile, IncludeTrailingPathDelimiter(OutDir) + 'detail.csv');
  Rewrite(DetailFile);
  WriteLn(DetailFile, 'lang,book,res,chapter,chunk,issue');

  try
    if FindFirst(IncludeTrailingPathDelimiter(LibraryBaseDir) + '*', faDirectory, SR) = 0 then
    begin
      try
        repeat
          if (SR.Attr and faDirectory <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then
            ProcessResourceDir(SR.Name);
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
    end;
  finally
    CloseFile(SummaryFile);
    CloseFile(DetailFile);
    FreeAndNil(DetailRows);
    FreeAndNil(Baseline);
  end;

  WriteMarkdownSummary;

  for I := 0 to LangResStats.Count - 1 do
    LangResStats.Objects[I].Free;
  FreeAndNil(LangResStats);

  for I := 0 to BookStats.Count - 1 do
    BookStats.Objects[I].Free;
  FreeAndNil(BookStats);

  WriteLn('Compared ', DirsSeen, ' resource(s), wrote ', RowsWritten,
    ' summary row(s) and summary.md to ', OutDir);
end.

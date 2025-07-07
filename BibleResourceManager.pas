unit BibleResourceManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Generics.Collections;

type
  TChunk = class
    Name: string;
    ExistsOnDisk: boolean;
    constructor Create(const AName: string; AExistsOnDisk: boolean);
  end;

  TChapter = class
    Name: string;
    Chunks: specialize TObjectList<TChunk>;
    constructor Create(const AName: string);
    destructor Destroy; override;
  end;

  TBook = class
    Code: string;
    ResourceType: string;
    Chapters: specialize TObjectList<TChapter>;
    constructor Create(const ACode, AResourceType: string);
    destructor Destroy; override;
    procedure LoadFromTOC(const DirPath: string);
    procedure VerifyDiskChunks(const DirPath: string);
    function ToString: string; override;
  end;

  TBibleInLanguage = class
    LanguageCode: string;
    Books: specialize TObjectList<TBook>;
    constructor Create(const ALanguageCode: string);
    destructor Destroy; override;
    function FindOrAddBook(const BookCode, ResType: string): TBook;
    function ToString: string; override;
  end;

  TLanguageContainer = class
  private
    FLanguages: specialize TObjectList<TBibleInLanguage>;
    function GetLanguageCount: integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromDirectory(const RootDir: string);
    function GetStructure(const LangCode: string): string;
    function GetLanguage(const LangCode: string): TBibleInLanguage;
    function GetLanguageCode(const Index: Integer): string;
    property LanguageCount: integer read GetLanguageCount;
  end;

implementation

uses
  StrUtils;

function ParseResourceDirName(const DirName: string;
  out LangCode, BookCode, ResType: string): boolean;
var
  Parts: TStringArray;
begin
  Parts := SplitString(DirName, '_');
  Result := Length(Parts) = 3;
  if Result then
  begin
    LangCode := Parts[0];
    BookCode := Parts[1];
    ResType := Parts[2];
  end;
end;

{ TChunk }

constructor TChunk.Create(const AName: string; AExistsOnDisk: boolean);
begin
  Name := AName;
  ExistsOnDisk := AExistsOnDisk;
end;

{ TChapter }

constructor TChapter.Create(const AName: string);
begin
  Name := AName;
  Chunks := specialize TObjectList<TChunk>.Create(True);
end;

destructor TChapter.Destroy;
begin
  Chunks.Free;
  inherited Destroy;
end;

{ TBook }

constructor TBook.Create(const ACode, AResourceType: string);
begin
  Code := ACode;
  ResourceType := AResourceType;
  Chapters := specialize TObjectList<TChapter>.Create(True);
end;

destructor TBook.Destroy;
begin
  Chapters.Free;
  inherited Destroy;
end;

procedure TBook.LoadFromTOC(const DirPath: string);
var
  TOCPath, Line: string;
  F: TextFile;
  Chapter, CurrentChapter: TChapter;
begin
  TOCPath := IncludeTrailingPathDelimiter(DirPath) + 'toc.yml';
  if not FileExists(TOCPath) then Exit;

  AssignFile(F, TOCPath);
  Reset(F);
  CurrentChapter := nil;
  while not EOF(F) do
  begin
    ReadLn(F, Line);
    Line := Trim(Line);
    if Line.StartsWith('chapter:') then
    begin
      Chapter := TChapter.Create(Trim(Copy(Line, 9, Length(Line))));
      Chapters.Add(Chapter);
      CurrentChapter := Chapter;
    end
    else if Line.StartsWith('-') and Assigned(CurrentChapter) then
    begin
      CurrentChapter.Chunks.Add(
        TChunk.Create(Trim(StringReplace(Line, '-', '', [])), False));
    end;
  end;
  CloseFile(F);
end;

procedure TBook.VerifyDiskChunks(const DirPath: string);
var
  Chapter: TChapter;
  Chunk: TChunk;
  FilePath: string;
begin
  for Chapter in Chapters do
    for Chunk in Chapter.Chunks do
    begin
      FilePath := Format('%s/%s/%s.usx', [DirPath, Chapter.Name, Chunk.Name]);
      Chunk.ExistsOnDisk := FileExists(FilePath);
    end;
end;

function TBook.ToString: string;
var
  Chapter: TChapter;
  Chunk: TChunk;
  ResultLines: TStringList;
begin
  ResultLines := TStringList.Create;
  try
    ResultLines.Add(Format('  Book: %s (%s)', [Code, ResourceType]));
    for Chapter in Chapters do
    begin
      ResultLines.Add('    Chapter: ' + Chapter.Name);
      for Chunk in Chapter.Chunks do
      begin
        if Chunk.ExistsOnDisk then
          ResultLines.Add('      ✓ ' + Chunk.Name)
        else
          ResultLines.Add('      ✗ ' + Chunk.Name);
      end;
    end;
    Result := ResultLines.Text;
  finally
    ResultLines.Free;
  end;
end;

{ TBibleInLanguage }

constructor TBibleInLanguage.Create(const ALanguageCode: string);
begin
  LanguageCode := ALanguageCode;
  Books := specialize TObjectList<TBook>.Create(True);
end;

destructor TBibleInLanguage.Destroy;
begin
  Books.Free;
  inherited Destroy;
end;

function TBibleInLanguage.FindOrAddBook(const BookCode, ResType: string): TBook;
var
  Book: TBook;
begin
  for Book in Books do
    if (Book.Code = BookCode) and (Book.ResourceType = ResType) then
      Exit(Book);
  Result := TBook.Create(BookCode, ResType);
  Books.Add(Result);
end;

function TBibleInLanguage.ToString: string;
var
  Book: TBook;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('Language: ' + LanguageCode);
    for Book in Books do
      Lines.Add(Book.ToString);
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

{ TLanguageContainer }

constructor TLanguageContainer.Create;
begin
  FLanguages := specialize TObjectList<TBibleInLanguage>.Create(True);
end;

destructor TLanguageContainer.Destroy;
begin
  FLanguages.Free;
  inherited Destroy;
end;

function TLanguageContainer.GetLanguage(const LangCode: string): TBibleInLanguage;
var
  Bible: TBibleInLanguage;
begin
  for Bible in FLanguages do
    if Bible.LanguageCode = LangCode then
      Exit(Bible);
  Result := TBibleInLanguage.Create(LangCode);
  FLanguages.Add(Result);
end;

function TLanguageContainer.GetLanguageCode(const Index: integer): string;
begin
  Result := TBibleInLanguage(FLanguages[Index]).LanguageCode;
end;

function TLanguageContainer.GetStructure(const LangCode: string): string;
var
  Bible: TBibleInLanguage;
begin
  for Bible in FLanguages do
    if Bible.LanguageCode = LangCode then
      Exit(Bible.ToString);
  Result := 'Language not found: ' + LangCode;
end;

function TLanguageContainer.GetLanguageCount: integer;
begin
  Result := FLanguages.Count;
end;

procedure TLanguageContainer.LoadFromDirectory(const RootDir: string);
var
  SR: TSearchRec;
  Path, LangCode, BookCode, ResType: string;
  Bible: TBibleInLanguage;
  Book: TBook;
begin
  if not DirectoryExists(RootDir) then
  begin
    WriteLn('Root directory does not exist: ', RootDir);
    Exit;
  end;

  if FindFirst(IncludeTrailingPathDelimiter(RootDir) + '*', faDirectory, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory <> 0) and (SR.Name[1] <> '.') then
      begin
        WriteLn('Inspecting directory: ', SR.Name);
        Path := IncludeTrailingPathDelimiter(RootDir) + SR.Name;
        LangCode := '';
        BookCode := '';
        ResType := '';

        if ParseResourceDirName(SR.Name, LangCode, BookCode, ResType) then
        begin
          WriteLn('Parsed OK: ', LangCode, ' - ', BookCode, ' - ', ResType);
          Bible := GetLanguage(LangCode);
          Book := Bible.FindOrAddBook(BookCode, ResType);
          Book.LoadFromTOC(Path);
          Book.VerifyDiskChunks(Path);
        end
        else
          WriteLn('Skipped directory (unrecognized name format): ', SR.Name);
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;
{
function ParseResourceDirName(const DirName: string; out LangCode, BookCode, ResType: string): Boolean;
var
  Parts: TStringArray;
begin
  Parts := SplitString(DirName, '_');
  Result := Length(Parts) = 3;
  if Result then
  begin
    LangCode := Parts[0];
    BookCode := Parts[1];
    ResType := Parts[2];
  end;
end; }

end.

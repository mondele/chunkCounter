// === File: BibleResourceManager.pas ===
unit BibleResourceManager;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Generics.Collections,
  BibleBook, BibleChapter, BibleChunk;

type
  TLanguageContainer = class
  private
    FLanguages: specialize TObjectList<TObjectList<TBook>>; // List of lists of books by language
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromDirectory(const BaseDir: string): Boolean;
    function FindBook(const LangCode, BookCode, ResType: string): TBook;
    function CompareBooks(const LangCode, BookCode, ResTypeA, ResTypeB: string): TStringList;
  end;

function ParseResourceDirName(const DirName: string;
  out LangCode, BookCode, ResType: string): Boolean;

implementation

uses
  FileUtil, LazFileUtils, StrUtils;

function ParseResourceDirName(const DirName: string;
  out LangCode, BookCode, ResType: string): Boolean;
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

constructor TLanguageContainer.Create;
begin
  FLanguages := specialize TObjectList<TObjectList<TBook>>.Create(True);
end;

destructor TLanguageContainer.Destroy;
var
  i: Integer;
begin
  for i := 0 to FLanguages.Count - 1 do
    FLanguages[i].Free;
  FLanguages.Free;
  inherited Destroy;
end;

function TLanguageContainer.LoadFromDirectory(const BaseDir: string): Boolean;
var
  DirList: TStringList;
  DirName, LangCode, BookCode, ResType: string;
  i: Integer;
  Book: TBook;
  Chapter: TChapter;
  Chunk: TChunk;
begin
  Result := False;
  if not DirectoryExists(BaseDir) then Exit;
  DirList := FindAllDirectories(BaseDir, False);
  try
    for i := 0 to DirList.Count - 1 do
    begin
      DirName := ExtractFileName(DirList[i]);
      if not ParseResourceDirName(DirName, LangCode, BookCode, ResType) then
        Continue;
      Book := TBook.Create(BookCode, ResType);
      // Simulate loading TOC and disk structure:
      Chapter := TChapter.Create('01');
      Chapter.Chunks.Add(TChunk.Create('01', True));
      Chapter.Chunks.Add(TChunk.Create('03', True));
      Book.Chapters.Add(Chapter);
      Chapter := TChapter.Create('02');
      Chapter.Chunks.Add(TChunk.Create('01', True));
      Chapter.Chunks.Add(TChunk.Create('04', True));
      Book.Chapters.Add(Chapter);

      // For this example, just keep books in their own list for language
      FLanguages.Add(specialize TObjectList<TBook>.Create(True));
      FLanguages[FLanguages.Count - 1].Add(Book);
    end;
    Result := True;
  finally
    DirList.Free;
  end;
end;

function TLanguageContainer.FindBook(const LangCode, BookCode, ResType: string): TBook;
var
  i, j: Integer;
  BookList: TObjectList<TBook>;
  Book: TBook;
begin
  for i := 0 to FLanguages.Count - 1 do
  begin
    BookList := FLanguages[i];
    for j := 0 to BookList.Count - 1 do
    begin
      Book := BookList[j];
      if (Book.Code = BookCode) and (Book.ResourceType = ResType) then
        Exit(Book);
    end;
  end;
  Result := nil;
end;

function TLanguageContainer.CompareBooks(const LangCode, BookCode, ResTypeA, ResTypeB: string): TStringList;
var
  BookA, BookB: TBook;
begin
  BookA := FindBook(LangCode, BookCode, ResTypeA);
  BookB := FindBook(LangCode, BookCode, ResTypeB);
  if (BookA = nil) or (BookB = nil) then
  begin
    Result := TStringList.Create;
    Result.Add('One or both books not found.');
    Exit;
  end;
  Result := BookA.CompareWith(BookB);
end;

end.

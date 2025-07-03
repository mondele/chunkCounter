unit BibleResourceManager;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Generics.Collections;

type
  TChunk = class
    Name: string;
    ExistsInTOC: Boolean;
    ExistsOnDisk: Boolean;
    constructor Create(AName: string);
  end;

  TChapter = class
    Name: string;
    Chunks: specialize TObjectList<TChunk>;
    constructor Create(AName: string);
    destructor Destroy; override;
    function FindOrAddChunk(const ChunkName: string): TChunk;
  end;

  TBook = class
    Name: string;
    ResourceType: string;
    Chapters: specialize TObjectList<TChapter>;
    constructor Create(ABookName, AResourceType: string);
    destructor Destroy; override;
    function FindOrAddChapter(const ChapterName: string): TChapter;
  end;

  TBibleInLanguage = class
    LanguageCode: string;
    Books: specialize TObjectList<TBook>;
    constructor Create(ALanguageCode: string);
    destructor Destroy; override;
    function FindOrAddBook(const BookName, ResourceType: string): TBook;
  end;

  TLanguageContainer = class
    Languages: specialize TObjectList<TBibleInLanguage>;
    constructor Create;
    destructor Destroy; override;
    function GetLanguage(const LanguageCode: string): TBibleInLanguage;
  end;

implementation

{ TChunk }

constructor TChunk.Create(AName: string);
begin
  Name := AName;
  ExistsInTOC := False;
  ExistsOnDisk := False;
end;

{ TChapter }

constructor TChapter.Create(AName: string);
begin
  Name := AName;
  Chunks := specialize TObjectList<TChunk>.Create(True);
end;

destructor TChapter.Destroy;
begin
  Chunks.Free;
  inherited Destroy;
end;

function TChapter.FindOrAddChunk(const ChunkName: string): TChunk;
var
  Chunk: TChunk;
begin
  for Chunk in Chunks do
    if Chunk.Name = ChunkName then
      Exit(Chunk);

  Result := TChunk.Create(ChunkName);
  Chunks.Add(Result);
end;

{ TBook }

constructor TBook.Create(ABookName, AResourceType: string);
begin
  Name := ABookName;
  ResourceType := AResourceType;
  Chapters := specialize TObjectList<TChapter>.Create(True);
end;

destructor TBook.Destroy;
begin
  Chapters.Free;
  inherited Destroy;
end;

function TBook.FindOrAddChapter(const ChapterName: string): TChapter;
var
  Chapter: TChapter;
begin
  for Chapter in Chapters do
    if Chapter.Name = ChapterName then
      Exit(Chapter);

  Result := TChapter.Create(ChapterName);
  Chapters.Add(Result);
end;

{ TBibleInLanguage }

constructor TBibleInLanguage.Create(ALanguageCode: string);
begin
  LanguageCode := ALanguageCode;
  Books := specialize TObjectList<TBook>.Create(True);
end;

destructor TBibleInLanguage.Destroy;
begin
  Books.Free;
  inherited Destroy;
end;

function TBibleInLanguage.FindOrAddBook(const BookName, ResourceType: string): TBook;
var
  Book: TBook;
begin
  for Book in Books do
    if (Book.Name = BookName) and (Book.ResourceType = ResourceType) then
      Exit(Book);

  Result := TBook.Create(BookName, ResourceType);
  Books.Add(Result);
end;

{ TLanguageContainer }

constructor TLanguageContainer.Create;
begin
  Languages := specialize TObjectList<TBibleInLanguage>.Create(True);
end;

destructor TLanguageContainer.Destroy;
begin
  Languages.Free;
  inherited Destroy;
end;

function TLanguageContainer.GetLanguage(const LanguageCode: string): TBibleInLanguage;
var
  LangObj: TBibleInLanguage;
begin
  for LangObj in Languages do
    if LangObj.LanguageCode = LanguageCode then
      Exit(LangObj);

  Result := TBibleInLanguage.Create(LanguageCode);
  Languages.Add(Result);
end;

end.


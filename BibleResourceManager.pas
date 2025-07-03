unit BibleResourceManager;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpYaml, FileUtil;

type
  TChunk = class
    Id: string;
    ExistsInYAML: Boolean;
    ExistsOnDisk: Boolean;
    constructor Create(const AId: string; InYAML: Boolean);
  end;

  TChapter = class
    Id: string;
    Chunks: TStringList; // Key = chunk ID, value = TChunk
    constructor Create(const AId: string);
    destructor Destroy; override;
    procedure AddChunk(AChunk: TChunk);
    function GetChunk(const ChunkId: string): TChunk;
  end;

  TBook = class
    Name: string;
    ResourceType: string;
    Chapters: TStringList; // Key = chapter ID, value = TChapter
    constructor Create(const AName, AResourceType: string);
    destructor Destroy; override;
    procedure AddChapter(AChapter: TChapter);
    function GetChapter(const ChapterId: string): TChapter;
  end;

  TBibleInLanguage = class
    LanguageCode: string;
    Books: TStringList; // Key = book+resourcetype, value = TBook
    constructor Create(const ALanguageCode: string);
    destructor Destroy; override;
    procedure AddBook(ABook: TBook);
    function GetBook(const BookName, ResourceType: string): TBook;
  end;

  TLanguageContainer = class
    Languages: TStringList; // Key = language code, value = TBibleInLanguage
    constructor Create;
    destructor Destroy; override;
    function GetLanguage(const LangCode: string): TBibleInLanguage;
    procedure LoadFromRoot(const RootDir: string);
  end;

implementation

{ TChunk }

constructor TChunk.Create(const AId: string; InYAML: Boolean);
begin
  Id := AId;
  ExistsInYAML := InYAML;
  ExistsOnDisk := False;
end;

{ TChapter }

constructor TChapter.Create(const AId: string);
begin
  Id := AId;
  Chunks := TStringList.Create;
  Chunks.OwnsObjects := True;
end;

destructor TChapter.Destroy;
begin
  Chunks.Free;
  inherited Destroy;
end;

procedure TChapter.AddChunk(AChunk: TChunk);
begin
  if Chunks.IndexOf(AChunk.Id) = -1 then
    Chunks.AddObject(AChunk.Id, AChunk);
end;

function TChapter.GetChunk(const ChunkId: string): TChunk;
var
  idx: Integer;
begin
  idx := Chunks.IndexOf(ChunkId);
  if idx <> -1 then
    Result := TChunk(Chunks.Objects[idx])
  else
    Result := nil;
end;

{ TBook }

constructor TBook.Create(const AName, AResourceType: string);
begin
  Name := AName;
  ResourceType := AResourceType;
  Chapters := TStringList.Create;
  Chapters.OwnsObjects := True;
end;

destructor TBook.Destroy;
begin
  Chapters.Free;
  inherited Destroy;
end;

procedure TBook.AddChapter(AChapter: TChapter);
begin
  if Chapters.IndexOf(AChapter.Id) = -1 then
    Chapters.AddObject(AChapter.Id, AChapter);
end;

function TBook.GetChapter(const ChapterId: string): TChapter;
var
  idx: Integer;
begin
  idx := Chapters.IndexOf(ChapterId);
  if idx <> -1 then
    Result := TChapter(Chapters.Objects[idx])
  else
    Result := nil;
end;

{ TBibleInLanguage }

constructor TBibleInLanguage.Create(const ALanguageCode: string);
begin
  LanguageCode := ALanguageCode;
  Books := TStringList.Create;
  Books.OwnsObjects := True;
end;

destructor TBibleInLanguage.Destroy;
begin
  Books.Free;
  inherited Destroy;
end;

procedure TBibleInLanguage.AddBook(ABook: TBook);
var
  key: string;
begin
  key := ABook.Name + '_' + ABook.ResourceType;
  if Books.IndexOf(key) = -1 then
    Books.AddObject(key, ABook);
end;

function TBibleInLanguage.GetBook(const BookName, ResourceType: string): TBook;
var
  key: string;
  idx: Integer;
begin
  key := BookName + '_' + ResourceType;
  idx := Books.IndexOf(key);
  if idx <> -1 then
    Result := TBook(Books.Objects[idx])
  else
    Result := nil;
end;

{ TLanguageContainer }

constructor TLanguageContainer.Create;
begin
  Languages := TStringList.Create;
  Languages.OwnsObjects := True;
end;

destructor TLanguageContainer.Destroy;
begin
  Languages.Free;
  inherited Destroy;
end;

function TLanguageContainer.GetLanguage(const LangCode: string): TBibleInLanguage;
var
  idx: Integer;
begin
  idx := Languages.IndexOf(LangCode);
  if idx <> -1 then
    Result := TBibleInLanguage(Languages.Objects[idx])
  else
    Result := nil;
end;

procedure TLanguageContainer.LoadFromRoot(const RootDir: string);
var
  sr: TSearchRec;
  DirName, Lang, Book, ResType: string;
  LangObj: TBibleInLanguage;
  BookObj: TBook;
  TocPath, ContentPath, ChapterDir, ChunkFile, ChapterId, ChunkId: string;
  TocYaml: TYAMLDocument;
  TocRoot, Node, ChunkNode: TFPYamlNode;
  I, J: Integer;
  Chapter: TChapter;
  Chunk: TChunk;
  ChapterDirs, Files: TStringList;
begin
  if FindFirst(RootDir + DirectorySeparator + '*', faDirectory, sr) = 0 then
  repeat
    DirName := sr.Name;
    if (DirName <> '.') and (DirName <> '..') and (sr.Attr and faDirectory <> 0) then
    begin
      // Expect: lang_book_resource
      if Length(DirName) >= 7 then
      begin
        Lang := Copy(DirName, 1, 3);
        Book := Copy(DirName, 5, 3);
        ResType := Copy(DirName, 9, Length(DirName));

        LangObj := GetLanguage(Lang);
        if LangObj = nil then
        begin
          LangObj := TBibleInLanguage.Create(Lang);
          Languages.AddObject(Lang, LangObj);
        end;

        BookObj := TBook.Create(Book, ResType);
        LangObj.AddBook(BookObj);

        TocPath := RootDir + DirectorySeparator + DirName + DirectorySeparator + 'toc.yml';
        if FileExists(TocPath) then
        begin
          TocYaml := TYAMLDocument.Create;
          try
            TocYaml.LoadFromFile(TocPath);
            TocRoot := TocYaml.Root;
            for I := 0 to TocRoot.Count - 1 do
            begin
              Node := TocRoot[I];
              ChapterId := Node.Mapping['chapter'].Value;
              Chapter := BookObj.GetChapter(ChapterId);
              if Chapter = nil then
              begin
                Chapter := TChapter.Create(ChapterId);
                BookObj.AddChapter(Chapter);
              end;
              for J := 0 to Node.Mapping['chunks'].Count - 1 do
              begin
                ChunkNode := Node.Mapping['chunks'].Sequence[J];
                Chunk := Chapter.GetChunk(ChunkNode.Value);
                if Chunk = nil then
                begin
                  Chunk := TChunk.Create(ChunkNode.Value, True);
                  Chapter.AddChunk(Chunk);
                end
                else
                  Chunk.ExistsInYAML := True;
              end;
            end;
          finally
            TocYaml.Free;
          end;
        end;

        // Disk structure: content/[chapter]/[chunk].usx
        ContentPath := RootDir + DirectorySeparator + DirName + DirectorySeparator + 'content';
        ChapterDirs := FindAllDirectories(ContentPath, False);
        for ChapterDir in ChapterDirs do
        begin
          ChapterId := ExtractFileName(ChapterDir);
          Chapter := BookObj.GetChapter(ChapterId);
          if Chapter = nil then
          begin
            Chapter := TChapter.Create(ChapterId);
            BookObj.AddChapter(Chapter);
          end;

          Files := FindAllFiles(ChapterDir, '*.usx', False);
          try
            for ChunkFile in Files do
            begin
              ChunkId := ChangeFileExt(ExtractFileName(ChunkFile), '');
              Chunk := Chapter.GetChunk(ChunkId);
              if Chunk = nil then
              begin
                Chunk := TChunk.Create(ChunkId, False);
                Chapter.AddChunk(Chunk);
              end;
              Chunk.ExistsOnDisk := True;
            end;
          finally
            Files.Free;
          end;
        end;
      end;
    end;
  until FindNext(sr) <> 0;
  FindClose(sr);
end;

end.

unit BibleResourceManager;

{$mode objfpc}{$H+}

interface
uses
  Classes, SysUtils, FileUtil, fgl, BibleBook, BibleChapter, BibleChunk, Globals;

type
  TBookKey = record
    BookCode: string;
    ResourceType: string;
  end;

  TLanguageContainer = class
  private
    FBooks: specialize TFPGMapObject<string, specialize TFPGMapObject<string, TBook>>;
    function ParseResourceDirName(const DirName: string;
      out LangCode, BookCode, ResType: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromDirectory(const BasePath: string): Boolean;
    function GetBook(const LangCode, BookCode, ResType: string): TBook;
    function CompareBooks(const Lang1, Res1, Lang2, Res2, Book: string): TStringList;
  end;

implementation

constructor TLanguageContainer.Create;
begin
  inherited Create;
  FBooks := specialize TFPGMapObject<string, specialize TFPGMapObject<string, TBook>>.Create;
end;

destructor TLanguageContainer.Destroy;
begin
  FreeAndNil(FBooks);
  inherited Destroy;
end;

function TLanguageContainer.ParseResourceDirName(const DirName: string;
  out LangCode, BookCode, ResType: string): Boolean;
var
  Parts: TStringArray;
begin
  Parts := DirName.Split('_');
  Result := Length(Parts) = 3;
  if Result then
  begin
    LangCode := Parts[0];
    BookCode := Parts[1];
    ResType := Parts[High(Parts)]; // High returns the last index
  end;
end;

function TLanguageContainer.LoadFromDirectory(const BasePath: string): Boolean;
var
  SR: TSearchRec;
  FullPath, LangCode, BookCode, ResType: string;
  Book: TBook;
  LangMap: specialize TFPGMapObject<string, TBook>;
  AnyBooksLoaded: Boolean;
begin
  Result := False;
  AnyBooksLoaded := False;

  if FindFirst(IncludeTrailingPathDelimiter(BasePath) + '*', faDirectory, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        if ParseResourceDirName(SR.Name, LangCode, BookCode, ResType) then
        begin
          FullPath := IncludeTrailingPathDelimiter(BasePath) + SR.Name + DirectorySeparator + 'content';
          Book := TBook.Create(BookCode, ResType);
          Book.LoadFromDisk(FullPath);

          if not FBooks.TryGetData(LangCode, LangMap) then
          begin
            LangMap := specialize TFPGMapObject<string, TBook>.Create;
            FBooks.Add(LangCode, LangMap);
          end;

          LangMap.Add(BookCode + '_' + ResType, Book);
          AnyBooksLoaded := True;
            if Verbose then WriteLn(Format('Loaded book: lang=%s, book=%s, type=%s', [LangCode, BookCode, ResType]));
        end;
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  Result := AnyBooksLoaded;
end;

function TLanguageContainer.GetBook(const LangCode, BookCode, ResType: string): TBook;
var
  LangMap: specialize TFPGMapObject<string, TBook>;
  Key: string;
begin
  Result := nil;
  if FBooks.TryGetData(LangCode, LangMap) then
  begin
    Key := BookCode + '_' + ResType;
    LangMap.TryGetData(Key, Result);
  end;
end;

function TLanguageContainer.CompareBooks(const Lang1, Res1, Lang2, Res2, Book: string): TStringList;
var
  BookA, BookB: TBook;
begin
  BookA := GetBook(Lang1, Book, Res1);
  BookB := GetBook(Lang2, Book, Res2);

  Result := TStringList.Create;

  if (BookA = nil) or (BookB = nil) then
    Result.Add('One or both books not found.')
  else
    Result.AddStrings(BookA.CompareWith(BookB));
end;


end.

unit BibleBook;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, BibleChapter, BibleChunk, Generics.Collections;

type
  TChapterList = specialize TObjectList<TChapter>;

  TBook = class
  private
    FCode: string;
    FResourceType: string;
    FChapters: TChapterList;
  public
    constructor Create(const ACode, AResType: string);
    destructor Destroy; override;

    function GetCode: string;
    function GetResourceType: string;
    function GetChapter(const ID: string): TChapter;
    procedure AddChapter(AChapter: TChapter);

    function CompareWith(Other: TBook): TStringList;
    procedure LoadFromDisk(const ContentDir: string);

    property Code: string read GetCode;
    property ResourceType: string read GetResourceType;
    property Chapters: TChapterList read FChapters;
  end;

implementation

{ TBook }

constructor TBook.Create(const ACode, AResType: string);
begin
  inherited Create;
  FCode := ACode;
  FResourceType := AResType;
  FChapters := specialize TObjectList<TChapter>.Create(True);
end;

destructor TBook.Destroy;
begin
  FreeAndNil(FChapters);
  inherited Destroy;
end;

function TBook.GetCode: string;
begin
  Result := FCode;
end;

function TBook.GetResourceType: string;
begin
  Result := FResourceType;
end;

function TBook.GetChapter(const ID: string): TChapter;
var
  I: Integer;
begin
  for I := 0 to FChapters.Count - 1 do
    if FChapters[I].ID = ID then
      Exit(FChapters[I]);
  Result := nil;
end;

procedure TBook.AddChapter(AChapter: TChapter);
begin
  FChapters.Add(AChapter);
end;

function TBook.CompareWith(Other: TBook): TStringList;
var
  I: Integer;
  ChapterA, ChapterB: TChapter;
  DiffLines: TStringList;

begin
  Result := TStringList.Create;
  if Other = nil then
  begin
    Result.Add('Other book is missing.');
    Exit;
  end;

  for I := 0 to FChapters.Count - 1 do
  begin
    ChapterA := FChapters[I];
    ChapterB := Other.GetChapter(ChapterA.ID);

    if ChapterB = nil then
      Result.Add('Chapter missing in other: ' + ChapterA.ID)
    else
    begin
      DiffLines := ChapterA.CompareChunks(ChapterB);
      if DiffLines.Count > 0 then
      begin
        Result.Add('Differences in chapter ' + ChapterA.ID + ':');
        Result.AddStrings(DiffLines);
      end;
//      Result.Sort;
      FreeAndNil(DiffLines);
    end;
  end;
end;

procedure TBook.LoadFromDisk(const ContentDir: string);
var
  TocPath: string;
  TocLines: TStringList;
  Line, ChapterID, ChunkID: string;
  CurrentChapter: TChapter;
  Chunk: TChunk;
  I: Integer;

  function IsChapterLine(const S: string): Boolean;
  begin
    Result := Trim(S).StartsWith('chapter:');
  end;

  function ExtractChapterID(const S: string): string;
  begin
    Result := Trim(Copy(S, Pos(':', S) + 1, MaxInt)).Trim([' ', '''', '"']);
  end;

  function IsChunkListStart(const S: string): Boolean;
  begin
    Result := Trim(S) = 'chunks:';
  end;

  function IsChunkLine(const S: string): Boolean;
  begin
    Result := Trim(S).StartsWith('-');
  end;

  function ExtractChunkID(const S: string): string;
  begin
    Result := Trim(Copy(S, Pos('-', S) + 1, MaxInt)).Trim([' ', '''', '"']);
  end;

begin
  WriteLn('Loading book ', FCode, ' of type ', FResourceType, ' from ', ContentDir);
  TocPath := IncludeTrailingPathDelimiter(ContentDir) + 'toc.yml';
  if not FileExists(TocPath) then
    begin
    WriteLn('Can’t find file ',TocPath);
    Exit;
    end;

  TocLines := TStringList.Create;
  WriteLn('Just created TocLines object.');
  try
    TocLines.LoadFromFile(TocPath);
    CurrentChapter := nil;

    for I := 0 to TocLines.Count - 1 do
    begin
      Line := TocLines[I];
      if IsChapterLine(Line) then
      begin
        ChapterID := ExtractChapterID(Line);
        WriteLn('Adding chapter ', ChapterID);
        CurrentChapter := TChapter.Create(ChapterID);
        AddChapter(CurrentChapter);
      end
      else if IsChunkListStart(Line) then
      begin
        WriteLn('Starting chunk list');
        Continue;
      end
      else if Assigned(CurrentChapter) and IsChunkLine(Line) then
      begin
        ChunkID := ExtractChunkID(Line);
        if ChunkID <> '' then
        begin
          WriteLn('   Adding Chunk ', ChunkID);
          Chunk := TChunk.Create(ChunkID, FileExists(IncludeTrailingPathDelimiter(ContentDir) + ChapterID + PathDelim + ChunkID + '.usx'));
          CurrentChapter.AddChunk(Chunk);
        end;
      end;
    end;
  finally
    FreeAndNil(TocLines);
  end;
end;

end.

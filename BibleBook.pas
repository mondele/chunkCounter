unit BibleBook;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, BibleChapter, BibleChunk, Generics.Collections, Globals;

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
  isDifferent: Boolean;

begin
  isDifferent := False;
  Result := TStringList.Create;
  if Other = nil then
  begin
    Result.Add('Other book is missing.');
    isDifferent := True;
    Exit;
  end;

  for I := 0 to FChapters.Count - 1 do
  begin
    ChapterA := FChapters[I];
    ChapterB := Other.GetChapter(ChapterA.ID);

    if ChapterB = nil then
    begin
      isDifferent := True;
      Result.Add('Chapter missing in other: ' + ChapterA.ID)
    end
    else
    begin
      DiffLines := ChapterA.CompareChunks(ChapterB);
      if DiffLines.Count > 0 then
      begin
        isDifferent := True;
        Result.Add('Differences in chapter ' + ChapterA.ID + ':');
        Result.AddStrings(DiffLines);
      end;
      FreeAndNil(DiffLines);
    end;
  end;
  if not isDifferent then
    Result.Add('No differences found between books ' + FCode + ' (' + FResourceType + ') and ' + Other.FCode + ' (' + Other.FResourceType + ').');
end;

procedure TBook.LoadFromDisk(const ContentDir: string);
var
  TocPath: string;
  TocLines: TStringList;
  Line, ChapterID, ChunkID, ChunkExt : string;
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
  if Verbose then WriteLn('Loading book ', FCode, ' of type ', FResourceType, ' from ', ContentDir);
  TocPath := IncludeTrailingPathDelimiter(ContentDir) + 'toc.yml';
  if not FileExists(TocPath) then
    begin
    WriteLn('Can’t find file ',TocPath);
    Exit;
    end;

  TocLines := TStringList.Create;
  if Verbose then WriteLn('Just created TocLines object.');
  try
    TocLines.LoadFromFile(TocPath);
    CurrentChapter := nil;

    for I := 0 to TocLines.Count - 1 do
    begin
      Line := TocLines[I];
      if IsChapterLine(Line) then
      begin
        ChapterID := ExtractChapterID(Line);
        if Verbose then WriteLn('Adding chapter ', ChapterID);
        CurrentChapter := TChapter.Create(ChapterID);
        AddChapter(CurrentChapter);
      end
      else if IsChunkListStart(Line) then
      begin
        if Verbose then WriteLn('Starting chunk list');
        Continue;
      end
      else if Assigned(CurrentChapter) and IsChunkLine(Line) then
      begin
        ChunkID := ExtractChunkID(Line);
        if ChunkID <> '' then
        begin
          if Verbose then WriteLn('   Adding Chunk ', ChunkID);
          if (Pos('content', ContentDir) > 0) then
            ChunkExt := '.usx'
          else
            ChunkExt := '.txt';

          Chunk := TChunk.Create(ChunkID, FileExists(IncludeTrailingPathDelimiter(ContentDir) + ChapterID + PathDelim + ChunkID + ChunkExt));
          CurrentChapter.AddChunk(Chunk);
        end;
      end;
    end;
  finally
    FreeAndNil(TocLines);
  end;
end;

end.

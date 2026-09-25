unit SourceReport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BibleBook, BibleChapter, BibleChunk;

type
  TBookDiffStats = record
    ChaptersSource: Integer;
    ChaptersOther: Integer;
    ChaptersMissingInOther: Integer;
    ChaptersExtraInOther: Integer;
    ChunksSource: Integer;
    ChunksOther: Integer;
    ChunksMissingInOther: Integer;
    ChunksExtraInOther: Integer;
    ChunksOnDiskMismatch: Integer;
    IsIdentical: Boolean;
  end;

function ComputeDiff(EnBook, OtherBook: TBook; const OtherLang, OtherBookCode,
  OtherRes: string; DetailRows: TStringList): TBookDiffStats;

implementation

procedure CompareChapterChunks(ChapA, ChapB: TChapter; const OtherLang,
  OtherBookCode, OtherRes: string; var Stats: TBookDiffStats; DetailRows: TStringList);
var
  i, j: Integer;
  ChunkA, ChunkB: TChunk;
  Found: Boolean;
  SeenNames: TStringList;
begin
  SeenNames := TStringList.Create;
  try
    for i := 0 to ChapA.Chunks.Count - 1 do
    begin
      ChunkA := ChapA.Chunks[i];
      Found := False;
      for j := 0 to ChapB.Chunks.Count - 1 do
      begin
        ChunkB := ChapB.Chunks[j];
        if ChunkA.Name = ChunkB.Name then
        begin
          SeenNames.Add(ChunkA.Name);
          Found := True;
          if ChunkA.ExistsOnDisk <> ChunkB.ExistsOnDisk then
          begin
            Inc(Stats.ChunksOnDiskMismatch);
            Stats.IsIdentical := False;
            DetailRows.Add(Format('%s,%s,%s,%s,%s,chunk_ondisk_mismatch',
              [OtherLang, OtherBookCode, OtherRes, ChapA.ID, ChunkA.Name]));
          end;
          Break;
        end;
      end;
      if not Found then
      begin
        Inc(Stats.ChunksMissingInOther);
        Stats.IsIdentical := False;
        DetailRows.Add(Format('%s,%s,%s,%s,%s,chunk_missing_in_other',
          [OtherLang, OtherBookCode, OtherRes, ChapA.ID, ChunkA.Name]));
      end;
    end;

    for j := 0 to ChapB.Chunks.Count - 1 do
    begin
      ChunkB := ChapB.Chunks[j];
      if SeenNames.IndexOf(ChunkB.Name) = -1 then
      begin
        Inc(Stats.ChunksExtraInOther);
        Stats.IsIdentical := False;
        DetailRows.Add(Format('%s,%s,%s,%s,%s,chunk_extra_in_other',
          [OtherLang, OtherBookCode, OtherRes, ChapA.ID, ChunkB.Name]));
      end;
    end;
  finally
    FreeAndNil(SeenNames);
  end;
end;

function ComputeDiff(EnBook, OtherBook: TBook; const OtherLang, OtherBookCode,
  OtherRes: string; DetailRows: TStringList): TBookDiffStats;
var
  i, j, k: Integer;
  ChapA, ChapB: TChapter;
  SeenChapters: TStringList;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.IsIdentical := True;
  Result.ChaptersSource := EnBook.Chapters.Count;
  Result.ChaptersOther := OtherBook.Chapters.Count;

  SeenChapters := TStringList.Create;
  try
    for i := 0 to EnBook.Chapters.Count - 1 do
    begin
      ChapA := EnBook.Chapters[i];
      ChapB := OtherBook.GetChapter(ChapA.ID);
      Inc(Result.ChunksSource, ChapA.Chunks.Count);

      if ChapB = nil then
      begin
        Inc(Result.ChaptersMissingInOther);
        Inc(Result.ChunksMissingInOther, ChapA.Chunks.Count);
        Result.IsIdentical := False;
        DetailRows.Add(Format('%s,%s,%s,%s,,chapter_missing_in_other',
          [OtherLang, OtherBookCode, OtherRes, ChapA.ID]));
        for k := 0 to ChapA.Chunks.Count - 1 do
          DetailRows.Add(Format('%s,%s,%s,%s,%s,chunk_missing_in_other',
            [OtherLang, OtherBookCode, OtherRes, ChapA.ID, ChapA.Chunks[k].Name]));
      end
      else
      begin
        SeenChapters.Add(ChapA.ID);
        CompareChapterChunks(ChapA, ChapB, OtherLang, OtherBookCode, OtherRes,
          Result, DetailRows);
      end;
    end;

    for j := 0 to OtherBook.Chapters.Count - 1 do
    begin
      ChapB := OtherBook.Chapters[j];
      Inc(Result.ChunksOther, ChapB.Chunks.Count);
      if SeenChapters.IndexOf(ChapB.ID) = -1 then
      begin
        Inc(Result.ChaptersExtraInOther);
        Inc(Result.ChunksExtraInOther, ChapB.Chunks.Count);
        Result.IsIdentical := False;
        DetailRows.Add(Format('%s,%s,%s,%s,,chapter_extra_in_other',
          [OtherLang, OtherBookCode, OtherRes, ChapB.ID]));
        for k := 0 to ChapB.Chunks.Count - 1 do
          DetailRows.Add(Format('%s,%s,%s,%s,%s,chunk_extra_in_other',
            [OtherLang, OtherBookCode, OtherRes, ChapB.ID, ChapB.Chunks[k].Name]));
      end;
    end;
  finally
    FreeAndNil(SeenChapters);
  end;
end;

end.

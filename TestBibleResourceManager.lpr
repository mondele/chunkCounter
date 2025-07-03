program TestBibleResourceManager;

{$mode objfpc}{$H+}

uses
  SysUtils, Generics.Collections, BibleResourceManager;

var
  LanguageContainer: TLanguageContainer;
  Lang: TBibleInLanguage;
  Book: TBook;
  Chapter: TChapter;
  Chunk: TChunk;
begin
  LanguageContainer := TLanguageContainer.Create;
  try
    // Simulate directory name parsing: arb_2ch_avd
    Lang := LanguageContainer.GetLanguage('arb');
    Book := Lang.FindOrAddBook('2ch', 'avd');
    Chapter := Book.FindOrAddChapter('01');
    Chunk := Chapter.FindOrAddChunk('01');
    Chunk.ExistsInTOC := True;
    Chunk.ExistsOnDisk := True;

    Chapter := Book.FindOrAddChapter('01');
    Chunk := Chapter.FindOrAddChunk('02');
    Chunk.ExistsInTOC := True;
    Chunk.ExistsOnDisk := False;

    Chapter := Book.FindOrAddChapter('02');
    Chunk := Chapter.FindOrAddChunk('01');
    Chunk.ExistsInTOC := False;
    Chunk.ExistsOnDisk := True;

    // Output the data structure
    for Lang in LanguageContainer.Languages do
    begin
      WriteLn('Language: ', Lang.LanguageCode);
      for Book in Lang.Books do
      begin
        WriteLn('  Book: ', Book.Name, ' (', Book.ResourceType, ')');
        for Chapter in Book.Chapters do
        begin
          WriteLn('    Chapter: ', Chapter.Name);
          for Chunk in Chapter.Chunks do
            WriteLn('      Chunk: ', Chunk.Name,
                    ' [TOC=', BoolToStr(Chunk.ExistsInTOC, True),
                    ', Disk=', BoolToStr(Chunk.ExistsOnDisk, True), ']');
        end;
      end;
    end;
  finally
    LanguageContainer.Free;
  end;
end.


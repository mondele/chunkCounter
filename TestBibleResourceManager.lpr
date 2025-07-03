program TestBibleResourceManager;

{$mode objfpc}{$H+}

uses
  SysUtils, BibleResourceManager;

const
{$IFDEF mswindows}
  sourceDir = 'C:\Path\To\library'; // adjust this path for Windows
{$ENDIF}
{$IFDEF unix}
  {$IFDEF darwin}
  sourceDir = '/Users/yourname/Library/Application Support/BTT-Writer/library';
  {$ELSE}
  sourceDir = '/home/yourname/.config/BTT-Writer/library';
  {$ENDIF}
{$ENDIF}

var
  Container: TLanguageContainer;
  Lang: TBibleInLanguage;
  Book: TBook;
  Chapter: TChapter;
  Chunk: TChunk;
  i, j, k: Integer;
begin
  Container := TLanguageContainer.Create;
  try
    WriteLn('Loading data from: ', sourceDir);
    Container.LoadFromRoot(sourceDir);

    // Show structure for one language (e.g. Arabic)
    Lang := Container.GetLanguage('arb');
    if Assigned(Lang) then
    begin
      WriteLn('Language: ', Lang.LanguageCode);
      for i := 0 to Lang.Books.Count - 1 do
      begin
        Book := TBook(Lang.Books.Objects[i]);
        WriteLn('  Book: ', Book.Name, ' [', Book.ResourceType, ']');
        for j := 0 to Book.Chapters.Count - 1 do
        begin
          Chapter := TChapter(Book.Chapters.Objects[j]);
          WriteLn('    Chapter: ', Chapter.Id);
          for k := 0 to Chapter.Chunks.Count - 1 do
          begin
            Chunk := TChunk(Chapter.Chunks.Objects[k]);
            WriteLn('      Chunk: ', Chunk.Id,
              ' (YAML: ', BoolToStr(Chunk.ExistsInYAML, True),
              ', Disk: ', BoolToStr(Chunk.ExistsOnDisk, True), ')');
          end;
        end;
      end;
    end
    else
      WriteLn('Language not found.');
  finally
    Container.Free;
  end;
end.

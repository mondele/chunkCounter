program TestBibleBook;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  BibleBook, BibleChapter, BibleChunk;

var
  BookA, BookB: TBook;
  Differences: TStringList;
  I: Integer;
  DirA, DirB: string;
begin
  try
    // Adjust these to point to two valid book content directories
    DirA := '/home/jdwood/.config/BTT-Writer/library/resource_containers/arb_gen_avd/content'; // e.g., contains toc.yml and USX files
    DirB := '/home/jdwood/.config/BTT-Writer/library/resource_containers/arb_exo_nav/content';

    // Create and load BookA
    BookA := TBook.Create('gen', 'avd');
    BookA.LoadFromDisk(DirA);

    // Create and load BookB
    BookB := TBook.Create('gen', 'nav');
    BookB.LoadFromDisk(DirB);

    // Compare books
    Differences := BookA.CompareWith(BookB);
    try
      if Differences.Count = 0 then
        WriteLn('Books are equivalent.')
      else
      begin
        WriteLn('Differences found:');
        for I := 0 to Differences.Count - 1 do
          WriteLn(Differences[I]);
      end;
    finally
      Differences.Free;
    end;

  finally
    BookA.Free;
    BookB.Free;
  end;
end.

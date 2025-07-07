// === File: BibleBook.pas ===
unit BibleBook;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Generics.Collections, BibleChapter;

type
  TBook = class
  public
    Code: string;
    ResourceType: string;
    Chapters: specialize TObjectList<TChapter>;
    constructor Create(const ACode, AResourceType: string);
    destructor Destroy; override;
    function CompareWith(Other: TBook): TStringList;
  end;

implementation

constructor TBook.Create(const ACode, AResourceType: string);
begin
  Code := ACode;
  ResourceType := AResourceType;
  Chapters := specialize TObjectList<TChapter>.Create(True);
end;

destructor TBook.Destroy;
begin
  Chapters.Free;
  inherited Destroy;
end;

function TBook.CompareWith(Other: TBook): TStringList;
var
  i, j: Integer;
  ChapA, ChapB: TChapter;
  Found: Boolean;
  Seen: TStringList;
  Report: TStringList;
begin
  Report := TStringList.Create;
  Report.Add(Format('Comparing book %s (%s) with %s (%s)',
    [Code, ResourceType, Other.Code, Other.ResourceType]));
  Seen := TStringList.Create;
  try
    for i := 0 to Chapters.Count - 1 do
    begin
      ChapA := Chapters[i];
      Found := False;
      for j := 0 to Other.Chapters.Count - 1 do
      begin
        ChapB := Other.Chapters[j];
        if ChapA.Name = ChapB.Name then
        begin
          Report.AddStrings(ChapA.CompareChunks(ChapB));
          Seen.Add(ChapB.Name);
          Found := True;
          Break;
        end;
      end;
      if not Found then
        Report.Add('  Chapter ' + ChapA.Name + ': missing in target');
    end;
    // Check for extra chapters in Other
    for j := 0 to Other.Chapters.Count - 1 do
    begin
      if Seen.IndexOf(Other.Chapters[j].Name) = -1 then
        Report.Add('  Chapter ' + Other.Chapters[j].Name + ': extra in target');
    end;
    Result := Report;
  finally
    Seen.Free;
  end;
end;

end.

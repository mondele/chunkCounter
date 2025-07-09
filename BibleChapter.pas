// === File: BibleChapter.pas ===
unit BibleChapter;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Generics.Collections, BibleChunk;

type
  TChapter = class
  private
    FID: string;
  public
    Name: string;
    Chunks: specialize TObjectList<TChunk>;
    constructor Create(const AName: string);
    destructor Destroy; override;
    function CompareChunks(Other: TChapter): TStringList;
    property ID: string read FID;
    procedure AddChunk(AChunk: TChunk);
  end;

implementation

constructor TChapter.Create(const AName: string);
begin
  Name := AName;
  Chunks := specialize TObjectList<TChunk>.Create(True);
end;

destructor TChapter.Destroy;
begin
  Chunks.Free;
  inherited Destroy;
end;

procedure TChapter.AddChunk(AChunk: TChunk);
begin
  Chunks.Add(AChunk);
end;

function TChapter.CompareChunks(Other: TChapter): TStringList;
var
  i, j: Integer;
  ChunkA, ChunkB: TChunk;
  FoundMatch: Boolean;
  Seen: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('  Chapter ' + Name + ':');

  if Other = nil then
  begin
    Result.Add('    ✗ Target chapter missing');
    Exit;
  end;

  Seen := TStringList.Create;
  try
    for i := 0 to Chunks.Count - 1 do
    begin
      ChunkA := Chunks[i];
      FoundMatch := False;
      for j := 0 to Other.Chunks.Count - 1 do
      begin
        ChunkB := Other.Chunks[j];
        if (ChunkA <> nil) and (ChunkB <> nil) and ChunkA.IsEquivalentTo(ChunkB) then
        begin
          FoundMatch := True;
          Seen.Add(ChunkB.Name);
          Break;
        end;
      end;
      if FoundMatch then
        Result.Add('    ✓ ' + ChunkA.Name)
      else
        Result.Add('    ✗ ' + ChunkA.Name + ' (missing in target)');
    end;

    // Now look for extras in Other that weren't seen
    for j := 0 to Other.Chunks.Count - 1 do
    begin
      ChunkB := Other.Chunks[j];
      if (ChunkB <> nil) and (Seen.IndexOf(ChunkB.Name) = -1) then
        Result.Add('    ✗ ' + ChunkB.Name + ' (extra in target)');
    end;
  finally
    Seen.Free;
  end;
end;

end.
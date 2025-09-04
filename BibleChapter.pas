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
  Chunks := specialize TObjectList<TChunk>.Create;
end;

destructor TChapter.Destroy;
begin
  FreeAndNil(Chunks);
  inherited Destroy;
end;

procedure TChapter.AddChunk(AChunk: TChunk);
begin
  Chunks.Add(AChunk);
end;

function TChapter.CompareChunks(Other: TChapter): TStringList;
var
  ChunkA, ChunkB: TChunk;
  chunkIndex: Integer;
  FoundMatch: Boolean;
  Seen: TStringList;
  ISaw: string;
begin
  Result := TStringList.Create;
  Result.Add('  Chapter ' + ID + ':');

  if Other = nil then
  begin
    Result.Add('    ✗ Target chapter missing');
    Exit;
  end;

  // Compare chunks by index

  Seen := TStringList.Create;
  try
    for Pair in Chunks do
    begin
      ChunkA := Pair.Value;
      if Other.Chunks.TryGetValue(Pair.Key, ChunkB) then
      begin
        FoundMatch := True;
        Seen.Add(Pair.Key);

        if ChunkA.ExistsOnDisk = ChunkB.ExistsOnDisk then
          Result.Add('    ✓ ' + ChunkA.Name)
        else
          Result.Add('    ! ' + ChunkA.Name + ' (OnDisk mismatch: ' +
            BoolToStr(ChunkA.ExistsOnDisk, True) + ' vs ' +
            BoolToStr(ChunkB.ExistsOnDisk, True) + ')');
      end
      else
        Result.Add('    ✗ ' + ChunkA.Name + ' (missing in target)');
    end;

    for Pair in Other.Chunks do
      if Seen.IndexOf(Pair.Key) = -1 then
        Result.Add('    ✗ ' + Pair.Value.Name + ' (extra in target)');
    finally
      FreeAndNil(Seen);
  end;
  end;
end.
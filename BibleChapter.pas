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
    Chunks: specialize TDictionary<string, TChunk>;
    constructor Create(const AName: string);
    destructor Destroy; override;
    function CompareChunks(Other: TChapter): TStringList;
    property ID: string read FID;
    procedure AddChunk(AChunkID: string; AChunk: TChunk);
  end;

implementation

constructor TChapter.Create(const AName: string);
begin
  Name := AName;
  Chunks := specialize TDictionary<string, TChunk>.Create;
end;

destructor TChapter.Destroy;
begin
  FreeAndNil(Chunks);
  inherited Destroy;
end;

procedure TChapter.AddChunk(AChunkID: string; AChunk: TChunk);
begin
  Chunks.Add(AChunkID, AChunk);
end;

function TChapter.CompareChunks(Other: TChapter): TStringList;
var
  i, j: Integer;
  ChunkA, ChunkB: TChunk;
  Pair: specialize TPair<string, TChunk>;
  FoundMatch: Boolean;
  Seen: TStringList;
  ISaw: string;
begin
  Result := TStringList.Create;
  Result.Add('  Chapter ' + Name + ':');

  if Other = nil then
  begin
    Result.Add('    ✗ Target chapter missing');
    Exit;
  end;

  Seen := TStringList.Create;
  for Pair in Chunks do
  begin
    ChunkA := Pair.Value;
    //ChunkB := Other.Chunks;
    WriteLn('Key: ', Pair.Key);
    WriteLn('Chunk Name: ', ChunkA.Name);
    if Other.Chunks.ContainsKey(Pair.Key) then
      WriteLn('The other chapter also contains this key.');
      begin
        Other.Chunks.TryGetValue(Pair.Key, ChunkB);
        FoundMatch := True;
        Seen.Add(Pair.Key);

        if ChunkA.ExistsOnDisk = ChunkB.ExistsOnDisk then
          Result.Add('    ✓ ' + ChunkA.Name)
        else
          Result.Add('    ! ' + ChunkA.Name + ' (OnDisk mismatch: ' +
            BoolToStr(ChunkA.ExistsOnDisk, True) + ' vs ' +
            BoolToStr(ChunkB.ExistsOnDisk, True) + ')');

        Break;
      if not FoundMatch then
        Result.Add('    ✗ ' + ChunkA.Name + ' (missing in target)');
  end;

{    for i := 0 to Chunks.Count - 1 do
    begin
      ChunkA := Chunks[i];
      FoundMatch := False;
      for j := 0 to Other.Chunks.Count - 1 do
      begin
        ChunkB := Other.Chunks[j];
        WriteLn('ChunkA is ', ChunkA.Name,'. ChunkB is ', ChunkB.Name);
        if (ChunkA <> nil) and (ChunkB <> nil) and SameText(ChunkA.Name, ChunkB.Name) then
        end;
      end;

    end;}

    // Now look for extras in Other that weren't seen
    for Pair in Other.Chunks do
    try
      if Seen.IndexOf(Pair.Key) = -1 then
        Result.Add('    ✗ ' + Pair.Key + ' (extra in target)');

    {for j := 0 to Other.Chunks.Count - 1 do
    begin
      ChunkB := Other.Chunks[j];
      if Seen.IndexOf(ChunkB.Name) = -1 then
        Result.Add('    ✗ ' + ChunkB.Name + ' (extra in target)');
    end;}
end;
  finally
    FreeAndNil(Seen);
  end;

end.
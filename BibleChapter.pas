// === File: BibleChapter.pas ===

Unit BibleChapter;

{$mode objfpc}{$H+}

Interface

Uses 
SysUtils, Classes, Generics.Collections, BibleChunk;

Type 
  TChapter = Class
    Private 
      FID: string;
    Public 
      Chunks: specialize TObjectList<TChunk>;
      constructor Create(Const AName: String);
      destructor Destroy;
      override;
      Function CompareChunks(Other: TChapter): TStringList;
      property ID: string read FID;
      Procedure AddChunk(AChunk: TChunk);
  End;

Implementation

constructor TChapter.Create(Const AName: String);
Begin
  FID := AName;
  Chunks := specialize TObjectList<TChunk>.Create;
End;

destructor TChapter.Destroy;
Begin
  FreeAndNil(Chunks);
  inherited Destroy;
End;

Procedure TChapter.AddChunk(AChunk: TChunk);
Begin
  Chunks.Add(AChunk);
End;

Function TChapter.CompareChunks(Other: TChapter): TStringList;

Var 
  i, j: Integer;
  ChunkA, ChunkB: TChunk;
  Found: Boolean;
  SeenNames: TStringList;
  HasDifferences: Boolean;
Begin
  Result := TStringList.Create;
  HasDifferences := False;

  If Other = Nil Then
    Begin
      Result.Add('  Chapter ' + ID + ':');
      Result.Add('    ✗ Target chapter missing');
      Exit;
    End;

  SeenNames := TStringList.Create;
  Try
    // Check for matching and missing chunks
    For i := 0 To Chunks.Count - 1 Do
      Begin
        ChunkA := Chunks[i];
        Found := False;
        For j := 0 To Other.Chunks.Count - 1 Do
          Begin
            ChunkB := Other.Chunks[j];
            If ChunkA.Name = ChunkB.Name Then
              Begin
                SeenNames.Add(ChunkA.Name);
                Found := True;
                If ChunkA.ExistsOnDisk <> ChunkB.ExistsOnDisk Then
                  Begin
                    Result.Add('    ! ' + ChunkA.Name + ' (OnDisk mismatch: ' +
                      BoolToStr(ChunkA.ExistsOnDisk, True) + ' vs ' +
                      BoolToStr(ChunkB.ExistsOnDisk, True) + ')');
                    HasDifferences := True;
                  End;
                Break;
              End;
          End;
        If Not Found Then
          Begin
            Result.Add('    ✗ ' + ChunkA.Name + ' (missing in target)');
            HasDifferences := True;
          End;
      End;

    // Check for extra chunks in Other
    For j := 0 To Other.Chunks.Count - 1 Do
      Begin
        ChunkB := Other.Chunks[j];
        If SeenNames.IndexOf(ChunkB.Name) = -1 Then
          Begin
            Result.Add('    ✗ ' + ChunkB.Name + ' (extra in target)');
            HasDifferences := True;
          End;
      End;
  Finally
    FreeAndNil(SeenNames);
  End;

  // Only add chapter header if there are differences
  If HasDifferences Then
    Result.Insert(0, '  Chapter ' + ID + ':')
  Else
    Result.Clear;
End;
End.

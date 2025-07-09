// Folder Structure Suggestion:
//
// src/
//   BibleChunk.pas
//   BibleChapter.pas
//   BibleBook.pas
//   BibleResourceManager.pas
//   TestBibleResourceManager.lpr

// === File: BibleChunk.pas ===
unit BibleChunk;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TChunk = class
  private
    FID: string;
  public
    Name: string;
    ExistsOnDisk: Boolean;
    constructor Create(const AName: string; AExistsOnDisk: Boolean);
    function IsEquivalentTo(Other: TChunk): Boolean;
    property ID: string read FID;
  end;

implementation

constructor TChunk.Create(const AName: string; AExistsOnDisk: Boolean);
begin
  Name := AName;
  ExistsOnDisk := AExistsOnDisk;
end;

function TChunk.IsEquivalentTo(Other: TChunk): Boolean;
begin
  Result := Name = Other.Name;
end;

end.

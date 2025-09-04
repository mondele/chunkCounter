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

{ ===INTERFACE=== }

interface

uses
  SysUtils;

type
  TChunk = class
  private
    FName: string;
    FExistsOnDisk: Boolean;
    procedure SetExistsOnDisk(const AExistsOnDisk: boolean);
    procedure SetName(const AName: string);
    procedure AddChunk(const AName: string);
  public
    constructor Create(const AName: string; AExistsOnDisk: Boolean);
    function IsEquivalentTo(Other: TChunk): Boolean;
    property Name: string read FName write SetName;
    property ExistsOnDisk: boolean read FExistsOnDisk write SetExistsOnDisk;
  end;

{ ===IMPLEMENTATION=== }

implementation

procedure TChunk.SetExistsOnDisk( const AExistsOnDisk: boolean);
begin
  if FExistsOnDisk <> AExistsOnDisk then
    FExistsOnDisk := AExistsOnDisk;
end;

procedure TChunk.SetName( const AName: string);
begin
  if FName <> AName then
    FName := AName;
end;

constructor TChunk.Create(const AName: string; AExistsOnDisk: Boolean);
begin
  SetName(AName);
  SetExistsOnDisk(AExistsOnDisk);
end;

function TChunk.IsEquivalentTo(Other: TChunk): Boolean;
begin
  Result := (Name = Other.Name) and (ExistsOnDisk = Other.ExistsOnDisk);
end;

end.

unit ResourceProcessor;

interface

uses
  Classes, sysUtils;

type
  TResource = class
    language: string;
    book: string;
    chunks: TStringList;
    procedure ProcessResourceContainers;
  end;


implementation

procedure TResource.ProcessResourceContainers;
var
  LibraryPath, ResourceContainers, SubDir: string;
  SearchRec: TSearchRec;
  
  // Helper function to check if a directory name matches the pattern
  function IsMatch(const Name: string): boolean;
  var
    Pos1, Pos2: integer;
    Parts: array[0..2] of string;
  begin
    Result := False;
    Pos1 := Pos('_', Name);
    if Pos1 = 0 then
      Exit;
    
    Pos2 := Pos('_', Name, Pos1 + 1);
    if Pos2 = 0 then
      Exit;
    
    Parts[0] := Copy(Name, 1, Pos1 - 1);
    Parts[1] := Copy(Name, Pos1 + 1, Pos2 - Pos1 - 1);
    Parts[2] := Copy(Name, Pos2 + 1, Length(Name) - Pos2);
    
    Result := (Parts[2] = 'ulb');
  end;

begin
  // Get the user's home directory using GetUserDir
  LibraryPath := GetUserDir + '/.config/BTT-Writer/library';
  if LibraryPath = '' then
    // Fallback to using the HOME environment variable
    LibraryPath := GetEnvironmentVariable('HOME') + '/.config/BTT-Writer/library';
  
  ResourceContainers := LibraryPath + '/resource_containers';
  
  // Check if the resource containers directory exists
  if not DirectoryExists(ResourceContainers) then
    raise Exception.Create('Resource containers directory does not exist.');
  
  // Set current directory to resource_containers
  if not DirectoryExists(ResourceContainers) then
    raise Exception.Create('Could not change to resource_containers directory.')
  else
    ChDir(ResourceContainers);
  
  // Search for all subdirectories
  if FindFirst('*', faDirectory, SearchRec) = 0 then
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          // Check if the directory name matches the pattern
          if IsMatch(SearchRec.Name) then
          begin
            // Process the directory
            SubDir := ResourceContainers + '/' + SearchRec.Name;
            WriteLn('Processing directory: ', SubDir);
            // Add your processing logic here
          end;
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  
  // Reset to original directory
  if not DirectoryExists(LibraryPath) then
    raise Exception.Create('Could not return to original directory.')
  else
    ChDir(LibraryPath);
end;

end.

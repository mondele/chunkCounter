unit ResourceContainerUnit;

interface

uses
  SysUtils, Classes, Generics.Collections;

type
  TContentFile = record
    FileName: string;
    FilePath: string;
    // Add more fields as needed for each content file
  end;

  TContentFolder = class
  private
    FName: string;
    FFiles: TObjectList<TContentFile>;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;

    procedure AddFile(const AFile: TContentFile);

    property Name: string read FName;
    property Files: TObjectList<TContentFile> read FFiles;
  end;

  TResourceContainer = class
  private
    FLanguageCode: string;
    FContentFolders: TObjectList<TContentFolder>;
  public
    constructor Create(const ALanguageCode: string);
    destructor Destroy; override;

    procedure AddContentFolder(const AContentFolder: TContentFolder);
    function GetContentFolderByName(const AName: string): TContentFolder;

    property LanguageCode: string read FLanguageCode;
    property ContentFolders: TObjectList<TContentFolder> read FContentFolders;
  end;

  TResourceContainerManager = class
  private
    FResourceContainers: TObjectList<TResourceContainer>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ScanResourceContainers(const ABasePath: string);
    function GetResourceContainersByLanguage(const ALanguageCode: string): TObjectList<TResourceContainer>;

    property ResourceContainers: TObjectList<TResourceContainer> read FResourceContainers;
  end;

implementation

{ TContentFolder }

constructor TContentFolder.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FFiles := TObjectList<TContentFile>.Create;
end;

destructor TContentFolder.Destroy;
begin
  FreeAndNil(FFiles);
  inherited;
end;

procedure TContentFolder.AddFile(const AFile: TContentFile);
begin
  FFiles.Add(AFile);
end;

{ TResourceContainer }

constructor TResourceContainer.Create(const ALanguageCode: string);
begin
  inherited Create;
  FLanguageCode := ALanguageCode;
  FContentFolders := TObjectList<TContentFolder>.Create;
end;

destructor TResourceContainer.Destroy;
begin
  FreeAndNil(FContentFolders);
  inherited;
end;

procedure TResourceContainer.AddContentFolder(const AContentFolder: TContentFolder);
begin
  FContentFolders.Add(AContentFolder);
end;

function TResourceContainer.GetContentFolderByName(const AName: string): TContentFolder;
var
  i: Integer;
begin
  for i := 0 to FContentFolders.Count - 1 do
  begin
    if FContentFolders[i].Name = AName then
      Exit(FContentFolders[i]);
  end;
  Result := nil;
end;

{ TResourceContainerManager }

constructor TResourceContainerManager.Create;
begin
  inherited Create;
  FResourceContainers := TObjectList<TResourceContainer>.Create;
end;

destructor TResourceContainerManager.Destroy;
begin
  FreeAndNil(FResourceContainers);
  inherited;
end;

procedure TResourceContainerManager.ScanResourceContainers(const ABasePath: string);
var
  searchRec: TSearchRec;
  path: string;
  container: TResourceContainer;
  contentFolder: TContentFolder;
  contentFile: TContentFile;
begin
  if FindFirst(ABasePath + '\*.*', faDirectory, searchRec) = 0 then
  begin
    repeat
      if (searchRec.Attr and faDirectory = faDirectory) and (searchRec.Name <> '.') and (searchRec.Name <> '..') then
      begin
        path := IncludeTrailingPathDelimiter(ABasePath + searchRec.Name + '\content');
        container := TResourceContainer.Create(Copy(searchRec.Name, 1, Pos('_', searchRec.Name) - 1));
        FResourceContainers.Add(container);

        if DirectoryExists(path) then
        begin
          if FindFirst(path + '\*.*', faAnyFile, searchRec) = 0 then
          begin
            repeat
              if (searchRec.Attr and faDirectory = 0) then
              begin
                contentFile.FileName := searchRec.Name;
                contentFile.FilePath := path + '\' + searchRec.Name;
                contentFolder := TContentFolder.Create(ExtractFileName(path));
                contentFolder.AddFile(contentFile);
                container.AddContentFolder(contentFolder);
              end;
            until FindNext(searchRec) <> 0;
            FindClose(searchRec);
          end;
        end;
      end;
    until FindNext(searchRec) <> 0;
    FindClose(searchRec);
  end;
end;

function TResourceContainerManager.GetResourceContainersByLanguage(const ALanguageCode: string): TObjectList<TResourceContainer>;
var
  i: Integer;
begin
  Result := TObjectList<TResourceContainer>.Create;
  for i := 0 to FResourceContainers.Count - 1 do
  begin
    if FResourceContainers[i].LanguageCode = ALanguageCode then
      Result.Add(FResourceContainers[i]);
  end;
end;

end.
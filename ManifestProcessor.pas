unit ManifestProcessor;

uses fpjson, jsonparser;

function GetSourceInfo(const ManifestPath: string; out LangID, ResID: string): Boolean;
var
  JSON: TJSONData;
  SourceArr: TJSONArray;
  SourceObj: TJSONObject;
begin
  Result := False;
  JSON := nil;
  try
    JSON := GetJSON(ReadFileToString(ManifestPath));
    if JSON.FindPath('source_translations') is TJSONArray then
    begin
      SourceArr := TJSONArray(JSON.FindPath('source_translations'));
      if SourceArr.Count > 0 then
      begin
        SourceObj := TJSONObject(SourceArr.Items[0]);
        LangID := SourceObj.Get('language_id', '');
        ResID := SourceObj.Get('resource_id', '');
        Result := (LangID <> '') and (ResID <> '');
      end;
    end;
  finally
    if Assigned(JSON) then JSON.Free;
  end;
end;
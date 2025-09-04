unit CliMenu;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes;

type
  TMenuAction = procedure;

  TMenuItem = record
    Text: string;
    Action: TMenuAction;
    SubMenu: TMenu;
  end;

  TMenu = class
  private
    FTitle: string;
    FItems: TList;
    FParentMenu: TMenu;
  public
    constructor Create(ATitle: string; AParentMenu: TMenu = nil);
    destructor Destroy; override;
    procedure AddItem(AText: string; AAction: TMenuAction; ASubMenu: TMenu = nil);
    procedure Run;
    property Title: string read FTitle write FTitle;
    property ParentMenu: TMenu read FParentMenu write FParentMenu;
  end;

implementation

uses
  SysUtils, Classes; // Re-include uses clauses in the implementation section

{ TMenu }

constructor TMenu.Create(ATitle: string; AParentMenu: TMenu);
begin
  inherited Create;
  FTitle := ATitle;
  FItems := TList.Create;
  FParentMenu := AParentMenu;
end;

destructor TMenu.Destroy;
var
  Item: TMenuItem;
begin
  for Item in FItems do
  begin
    if Assigned(Item.SubMenu) then
      Item.SubMenu.Free;
  end;
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TMenu.AddItem(AText: string; AAction: TMenuAction; ASubMenu: TMenu);
var
  NewItem: TMenuItem;
begin
  NewItem.Text := AText;
  NewItem.Action := AAction;
  NewItem.SubMenu := ASubMenu;
  FItems.Add(NewItem);
end;

procedure TMenu.Run;
var
  Choice: Integer;
  Item: TMenuItem;
  Input: string;
begin
  repeat
    Writeln('');
    Writeln('--- ' + FTitle + ' ---');
    for i := 0 to FItems.Count - 1 do
    begin
      Item := FItems[i];
      Writeln(Format('%d) %s', [i + 1, Item.Text]));
    end;

    Writeln('0) Exit/Return to Previous Menu');
    Write('Enter your choice: ');
    Readln(Input);

    Val(Input, Choice, nil);

    if (Choice >= 1) and (Choice <= FItems.Count) then
    begin
      Item := FItems[Choice - 1];
      if Assigned(Item.SubMenu) then
      begin
        Item.SubMenu.Run;
      end else
      begin
        if Assigned(Item.Action) then
          Item.Action;
      end;
    end else if Choice = 0 then
    begin
      if Assigned(FParentMenu) then
      begin
         FParentMenu.Run;
      end else
      begin
          Writeln('Exiting application.');
          Exit;
      end;
    end else
    begin
      Writeln('Invalid choice. Please try again.');
    end;
  until False;
end;

end.
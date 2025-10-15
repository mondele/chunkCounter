program chunkCounter;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  sourceCounter,
  targetCounter,
  resourceProcessor,
  chunkCounterHome,
  mainform, unit1 { you can add units after this };

  {$R *.res}

const
  {$IFDEF mswindows}
  sourceDir = '';
  {$ENDIF}
  {$IFDEF unix}
  {$IFDEF darwin}
  sourceDir = '~/Library/Application Support/BTT-Writer/library';
  {$ELSE}
  sourceDir = '~/.config/BTT-Writer/library';
  {$ENDIF}
  {$ENDIF}

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  // Application.CreateForm(TForm1, Form1);
  ProcessResourceContainers();
  Application.CreateForm(TmainWindow, mainWindow);
  Application.Run;
end.

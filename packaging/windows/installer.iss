[Setup]
AppName=GramVidya AI
AppVersion=0.1.0
DefaultDirName={autopf}\GramVidya
DefaultGroupName=GramVidya AI
OutputDir=..\..\build
OutputBaseFilename=GramVidya-Setup
Compression=lzma2
[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs
[Icons]
Name: "{group}\GramVidya AI"; Filename: "{app}\gramvidya.exe"
Name: "{commondesktop}\GramVidya AI"; Filename: "{app}\gramvidya.exe"

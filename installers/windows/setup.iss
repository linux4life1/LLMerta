; Inno Setup script for LLMerta — single stable channel.
; Ported from Front Porch AI's setup.iss minus its Beta/Nightly machinery
; (fresh AppId, one install dir, no folder-heal history to carry).
; CI passes: /DMyAppVersion /DMyAppBuildDir /DMyAppLicenseFile /DMyAppIconFile

#define MyAppName "LLMerta"
#define MyAppPublisher "linux4life1"
#define MyAppURL "https://github.com/linux4life1/LLMerta"
#define MyAppExeName "llmerta.exe"

[Setup]
AppId={{7C31A6DA-9E1B-4F0D-8B95-46D2A11F30C7}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
; Per-user install: no elevation needed; machine-wide stays available via
; the dialog (FPA precedent).
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
LicenseFile={#MyAppLicenseFile}
OutputBaseFilename=LLMerta_Setup
OutputDir=.
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile={#MyAppIconFile}
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes
RestartApplications=yes
AppMutex=LLMerta_7C31A6DA
MinVersion=10.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#MyAppBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; VC++ 2015-2022 redistributable, downloaded by CI before ISCC runs.
Source: "{#MyAppBuildDir}\..\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[INI]
; Self-update gate: the in-app updater only runs when this marker exists
; (i.e. an installed build, never a loose folder).
Filename: "{app}\.installed"; Section: "install"; Key: "method"; String: "innosetup"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; \
  StatusMsg: "Installing Visual C++ Runtime (required)..."; \
  Check: VCRedistNeedsInstall; Flags: waituntilterminated
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Canonical VC++ 2015-2022 x64 detection (Microsoft-documented key).
function VCRedistNeedsInstall: Boolean;
var
  Installed: Cardinal;
begin
  Result := not RegQueryDWordValue(
    HKLM,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64',
    'Installed',
    Installed
  ) or (Installed <> 1);
end;

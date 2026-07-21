#ifndef AppVersion
  #error AppVersion must be supplied by scripts/build-installer.ps1
#endif
#ifndef ReleaseDirectory
  #error ReleaseDirectory must be supplied by scripts/build-installer.ps1
#endif
#ifndef PayloadPath
  #error PayloadPath must be supplied by scripts/build-installer.ps1
#endif
#ifndef OutputDirectory
  #error OutputDirectory must be supplied by scripts/build-installer.ps1
#endif
#ifndef OutputBaseFilename
  #error OutputBaseFilename must be supplied by scripts/build-installer.ps1
#endif
#ifndef SteamAppId
  #error SteamAppId must be supplied by scripts/build-installer.ps1
#endif
#ifndef SteamBuildId
  #error SteamBuildId must be supplied by scripts/build-installer.ps1
#endif
#ifndef DepotId
  #error DepotId must be supplied by scripts/build-installer.ps1
#endif
#ifndef DepotManifestId
  #error DepotManifestId must be supplied by scripts/build-installer.ps1
#endif
#ifndef GameExeSize
  #error GameExeSize must be supplied by scripts/build-installer.ps1
#endif
#ifndef GameExeSha256
  #error GameExeSha256 must be supplied by scripts/build-installer.ps1
#endif
#ifndef PayloadSize
  #error PayloadSize must be supplied by scripts/build-installer.ps1
#endif
#ifndef PayloadSha256
  #error PayloadSha256 must be supplied by scripts/build-installer.ps1
#endif
#ifndef InstallerReadmePath
  #error InstallerReadmePath must be supplied by scripts/build-installer.ps1
#endif
#ifndef InstallerReadmeSha256
  #error InstallerReadmeSha256 must be supplied by scripts/build-installer.ps1
#endif
#ifndef TranslationLicensePath
  #error TranslationLicensePath must be supplied by scripts/build-installer.ps1
#endif
#ifndef TranslationLicenseSha256
  #error TranslationLicenseSha256 must be supplied by scripts/build-installer.ps1
#endif
#ifdef InstallerTestMode
  #ifndef TestAppDirectory
    #error TestAppDirectory must be supplied with InstallerTestMode
  #endif
#endif

#if LowerCase(GetSHA256OfFile(PayloadPath)) != LowerCase(PayloadSha256)
  #error PayloadPath SHA-256 does not match PayloadSha256
#endif
#if FileSize(PayloadPath) != Int(PayloadSize)
  #error PayloadPath size does not match PayloadSize
#endif
#if LowerCase(GetSHA256OfFile(InstallerReadmePath)) != LowerCase(InstallerReadmeSha256)
  #error InstallerReadmePath SHA-256 does not match InstallerReadmeSha256
#endif
#if LowerCase(GetSHA256OfFile(TranslationLicensePath)) != LowerCase(TranslationLicenseSha256)
  #error TranslationLicensePath SHA-256 does not match TranslationLicenseSha256
#endif

[Setup]
#ifdef InstallerTestMode
AppId={{2761DB31-0DBB-45DA-AD2B-E7D76950A3E7}
AppName=Русификатор Anvil Empires (installer test)
DefaultDirName={#TestAppDirectory}
UninstallFilesDir={#TestAppDirectory}\uninstall
CreateUninstallRegKey=no
SetupMutex=Global\AnvilEmpiresRussianLocalizationInstallerTest-Setup-2761DB31
#else
AppId={{C81E30F8-0FCF-4A0D-8741-A2AD20C3C28F}
AppName=Русификатор Anvil Empires
DefaultDirName={localappdata}\Programs\Anvil Empires Russian Localization
UninstallFilesDir={localappdata}\Programs\Anvil Empires Russian Localization\uninstall
SetupMutex=Global\AnvilEmpiresRussianLocalization-Setup-C81E30F8
#endif
AppVersion={#AppVersion}
AppVerName=Русификатор Anvil Empires {#AppVersion}
AppPublisher=nullith
AppPublisherURL=https://github.com/nullith2/anvil-empires-russian
AppSupportURL=https://github.com/nullith2/anvil-empires-russian/issues
AppUpdatesURL=https://github.com/nullith2/anvil-empires-russian/releases
AppComments=Неофициальный русский перевод Anvil Empires
AppReadmeFile={app}\README_INSTALLER_RU.txt
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableWelcomePage=no
AllowNoIcons=yes
Uninstallable=yes
UninstallDisplayName=Русификатор Anvil Empires {#AppVersion}
UninstallDisplayIcon={uninstallexe}
PrivilegesRequired=lowest
CloseApplications=no
RestartApplications=no
SetupLogging=yes
UninstallLogging=yes
WizardStyle=modern dynamic
WizardResizable=no
SetupArchitecture=x64
ArchitecturesAllowed=x64compatible
Compression=lzma2/ultra64
SolidCompression=yes
OutputDir={#OutputDirectory}
OutputBaseFilename={#OutputBaseFilename}
VersionInfoVersion={#AppVersion}.0
VersionInfoDescription=Установщик русификатора Anvil Empires
VersionInfoCompany=nullith
VersionInfoCopyright=Copyright (C) 2026 nullith
VersionInfoProductName=Русификатор Anvil Empires
VersionInfoProductVersion={#AppVersion}
SignedUninstaller=no

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
Source: "{#PayloadPath}"; DestName: "Anvil-Russian-Full_P.pak"; Hash: "{#PayloadSha256}"; Flags: dontcopy noencryption notimestamp
Source: "{#InstallerReadmePath}"; DestDir: "{app}"; Hash: "{#InstallerReadmeSha256}"; Flags: ignoreversion notimestamp
Source: "{#TranslationLicensePath}"; DestDir: "{app}\INFO"; Hash: "{#TranslationLicenseSha256}"; Flags: ignoreversion notimestamp
Source: "{#ReleaseDirectory}\README_RU.txt"; DestDir: "{app}"; Flags: ignoreversion notimestamp
Source: "{#ReleaseDirectory}\RELEASE_NOTES_RU.txt"; DestDir: "{app}"; Flags: ignoreversion notimestamp
Source: "{#ReleaseDirectory}\INFO\release-manifest.json"; DestDir: "{app}\INFO"; Flags: ignoreversion notimestamp
Source: "{#ReleaseDirectory}\INFO\SHA256SUMS.txt"; DestDir: "{app}\INFO"; Flags: ignoreversion notimestamp
Source: "{#ReleaseDirectory}\INFO\THIRD-PARTY-NOTICES.txt"; DestDir: "{app}\INFO"; Flags: ignoreversion notimestamp
Source: "{#ReleaseDirectory}\INFO\LICENSES\Apache-2.0.txt"; DestDir: "{app}\INFO\LICENSES"; Flags: ignoreversion notimestamp

[UninstallDelete]
Type: files; Name: "{app}\install-state.ini"
Type: files; Name: "{app}\install-state.ini.new"
Type: files; Name: "{app}\install-state.ini.rollback"

[Code]
const
  ExpectedSteamAppId = '{#SteamAppId}';
  ExpectedSteamBuildId = '{#SteamBuildId}';
  ExpectedDepotId = '{#DepotId}';
  ExpectedDepotManifestId = '{#DepotManifestId}';
  ExpectedGameExeSize = {#GameExeSize};
  ExpectedGameExeSha256 = '{#GameExeSha256}';
  ExpectedPayloadSize = {#PayloadSize};
  ExpectedPayloadSha256 = '{#PayloadSha256}';
  TargetPakName = 'Anvil-Russian-Full_P.pak';
  TargetPakPrefix = 'Anvil-Russian';
  AppManifestName = 'appmanifest_{#SteamAppId}.acf';
  GameExecutableRelativePath = 'Anvil\Binaries\Win64\Anvil-Win64-Shipping.exe';
  PakDirectoryRelativePath = 'Anvil\Content\Paks';
  StateFileName = 'install-state.ini';
  StateSection = 'Installation';
  ErrorAlreadyExists = 183;
#ifdef InstallerTestMode
  InstallerMutexName = 'Global\AnvilEmpiresRussianLocalizationInstallerTest-Transaction-2761DB31';
#else
  InstallerMutexName = 'Global\AnvilEmpiresRussianLocalization-Transaction-C81E30F8';
#endif

type
  TSteamManifestInfo = record
    AppId: String;
    Name: String;
    InstallDir: String;
    BuildId: String;
    TargetBuildId: String;
    Language: String;
    DepotManifestId: String;
  end;

var
  ProjectInfoPage: TWizardPage;
  ProjectInfoText: TNewStaticText;
  ProjectLinks: TNewLinkLabel;
  GameDirectoryPage: TInputDirWizardPage;
  SelectedGameRoot: String;
  SelectedManifestPath: String;
  SelectedPakDirectory: String;
  SelectedTargetPakPath: String;
  SelectedSteamBuildId: String;
  SelectedDepotManifestId: String;
  SelectedGameExeSize: Int64;
  SelectedGameExeSha256: String;
  SelectedCompatibilityWarning: String;
  IncompatibleInstallationAccepted: Boolean;
  InstallPayloadRequired: Boolean;
  PayloadMutationStarted: Boolean;
  PayloadInstalledThisRun: Boolean;
  HadPreviousTarget: Boolean;
  RollbackPakPath: String;
  StagingPakPath: String;
  PreviousPayloadHash: String;
  StateMutationStarted: Boolean;
  StateInstalledThisRun: Boolean;
  HadPreviousState: Boolean;
  PreviousStateHash: String;
  InstallationCommitted: Boolean;
  UninstallGameRoot: String;
  UninstallPakPath: String;
  UninstallPayloadHash: String;
  UninstallStateIsSafe: Boolean;
  GameProcessCheckSucceeded: Boolean;
  InstallerMutexHandle: THandle;

function CreateMutex(
  MutexAttributes: Integer;
  InitialOwner: Boolean;
  Name: String
): THandle;
external 'CreateMutexW@kernel32.dll stdcall';

function CloseHandle(Handle: THandle): Boolean;
external 'CloseHandle@kernel32.dll stdcall';

function AcquireInstallerMutex(var ErrorText: String): Boolean;
var
  LastError: LongInt;
begin
  Result := False;
  InstallerMutexHandle := CreateMutex(0, False, InstallerMutexName);
  LastError := DLLGetLastError;
  if InstallerMutexHandle = 0 then begin
    ErrorText := 'Не удалось заблокировать параллельный запуск Setup/Uninstall: ' +
      SysErrorMessage(LastError);
    exit;
  end;
  if LastError = ErrorAlreadyExists then begin
    CloseHandle(InstallerMutexHandle);
    InstallerMutexHandle := 0;
    ErrorText := 'Другой экземпляр Setup или Uninstall уже работает. ' +
      'Дождитесь его завершения и повторите.';
    exit;
  end;
  Result := True;
end;

procedure ReleaseInstallerMutex;
begin
  if InstallerMutexHandle <> 0 then begin
    CloseHandle(InstallerMutexHandle);
    InstallerMutexHandle := 0;
  end;
end;

function ReadQuotedToken(const Line: String; var Index: Integer; var Value: String): Boolean;
var
  Current: Char;
begin
  Result := False;
  Value := '';
  while (Index <= Length(Line)) and (Line[Index] <= ' ') do
    Index := Index + 1;
  if (Index > Length(Line)) or (Line[Index] <> '"') then
    exit;
  Index := Index + 1;
  while Index <= Length(Line) do begin
    Current := Line[Index];
    if Current = '"' then begin
      Index := Index + 1;
      Result := True;
      exit;
    end;
    if (Current = '\') and (Index < Length(Line)) and
       ((Line[Index + 1] = '\') or (Line[Index + 1] = '"')) then begin
      Value := Value + Line[Index + 1];
      Index := Index + 2;
    end else begin
      Value := Value + Current;
      Index := Index + 1;
    end;
  end;
end;

function ExtractQuotedPair(const Line: String; var Key, Value: String): Boolean;
var
  Index: Integer;
begin
  Index := 1;
  Result := ReadQuotedToken(Line, Index, Key) and ReadQuotedToken(Line, Index, Value);
end;

function ExtractQuotedKey(const Line: String; var Key: String): Boolean;
var
  Index: Integer;
  Ignored: String;
begin
  Index := 1;
  Result := ReadQuotedToken(Line, Index, Key) and not ReadQuotedToken(Line, Index, Ignored);
end;

function IsDecimalString(const Value: String): Boolean;
var
  Index: Integer;
begin
  Result := Value <> '';
  for Index := 1 to Length(Value) do
    if (Value[Index] < '0') or (Value[Index] > '9') then begin
      Result := False;
      exit;
    end;
end;

function NormalizeDirectory(const Value: String): String;
var
  Path: String;
begin
  Path := Trim(Value);
  StringChangeEx(Path, '/', '\', True);
  if Path <> '' then
    Path := RemoveBackslashUnlessRoot(ExpandFileName(Path));
  Result := Path;
end;

procedure AddUniqueSteamRoot(Roots: TStringList; const Candidate: String);
var
  Root: String;
begin
  Root := NormalizeDirectory(Candidate);
  if (Root <> '') and DirExists(AddBackslash(Root) + 'steamapps') and
     (Roots.IndexOf(Root) < 0) then
    Roots.Add(Root);
end;

procedure AddRegistrySteamRoots(Roots: TStringList);
var
  Value: String;
begin
  if RegQueryStringValue(HKCU, 'Software\Valve\Steam', 'SteamPath', Value) then
    AddUniqueSteamRoot(Roots, Value);
  if RegQueryStringValue(HKLM32, 'Software\Valve\Steam', 'InstallPath', Value) then
    AddUniqueSteamRoot(Roots, Value);
  if IsWin64 and RegQueryStringValue(HKLM64, 'Software\Valve\Steam', 'InstallPath', Value) then
    AddUniqueSteamRoot(Roots, Value);
end;

procedure AddLibraryFolders(Roots: TStringList; const SteamRoot: String);
var
  Lines: TArrayOfString;
  Index: Integer;
  Key: String;
  Value: String;
  LibraryFile: String;
begin
  LibraryFile := AddBackslash(SteamRoot) + 'steamapps\libraryfolders.vdf';
  if not LoadStringsFromFile(LibraryFile, Lines) then begin
    Log('Steam library list was not readable: ' + LibraryFile);
    exit;
  end;
  for Index := 0 to GetArrayLength(Lines) - 1 do
    if ExtractQuotedPair(Lines[Index], Key, Value) then
      if (CompareText(Key, 'path') = 0) or IsDecimalString(Key) then
        AddUniqueSteamRoot(Roots, Value);
end;

procedure FindSteamLibraries(Roots: TStringList);
var
  Index: Integer;
begin
  Roots.Clear;
  Roots.CaseSensitive := False;
#ifdef InstallerTestMode
  { Test-only injection keeps synthetic discovery independent of the real game. }
  AddUniqueSteamRoot(Roots, ExpandConstant('{param:TESTSTEAMROOT|}'));
#endif
  AddRegistrySteamRoots(Roots);
  Index := 0;
  while Index < Roots.Count do begin
    AddLibraryFolders(Roots, Roots[Index]);
    Index := Index + 1;
  end;
end;

procedure ClearManifestInfo(var Info: TSteamManifestInfo);
begin
  Info.AppId := '';
  Info.Name := '';
  Info.InstallDir := '';
  Info.BuildId := '';
  Info.TargetBuildId := '';
  Info.Language := '';
  Info.DepotManifestId := '';
end;

function ReadAppManifest(const ManifestPath: String; var Info: TSteamManifestInfo): Boolean;
var
  Lines: TArrayOfString;
  Index: Integer;
  SearchIndex: Integer;
  Key: String;
  Value: String;
  SingleKey: String;
begin
  Result := False;
  ClearManifestInfo(Info);
  if not LoadStringsFromFile(ManifestPath, Lines) then
    exit;

  for Index := 0 to GetArrayLength(Lines) - 1 do begin
    if ExtractQuotedPair(Lines[Index], Key, Value) then begin
      if CompareText(Key, 'appid') = 0 then
        Info.AppId := Value
      else if CompareText(Key, 'name') = 0 then
        Info.Name := Value
      else if CompareText(Key, 'installdir') = 0 then
        Info.InstallDir := Value
      else if CompareText(Key, 'buildid') = 0 then
        Info.BuildId := Value
      else if CompareText(Key, 'TargetBuildID') = 0 then
        Info.TargetBuildId := Value
      else if CompareText(Key, 'language') = 0 then
        Info.Language := Value;
    end;

    if ExtractQuotedKey(Lines[Index], SingleKey) and
       (CompareText(SingleKey, ExpectedDepotId) = 0) then begin
      SearchIndex := Index + 1;
      while (SearchIndex < GetArrayLength(Lines)) and
            (SearchIndex <= Index + 16) do begin
        if ExtractQuotedPair(Lines[SearchIndex], Key, Value) and
           (CompareText(Key, 'manifest') = 0) then begin
          Info.DepotManifestId := Value;
          break;
        end;
        SearchIndex := SearchIndex + 1;
      end;
    end;
  end;

  Result := (Info.AppId <> '') and (Info.InstallDir <> '') and (Info.BuildId <> '');
end;

function ManifestMatchesRequiredBuild(const Info: TSteamManifestInfo): Boolean;
begin
  Result :=
    (CompareText(Info.AppId, ExpectedSteamAppId) = 0) and
    (CompareText(Info.BuildId, ExpectedSteamBuildId) = 0) and
    ((Info.TargetBuildId = '') or
     (CompareText(Info.TargetBuildId, ExpectedSteamBuildId) = 0)) and
    (CompareText(Info.DepotManifestId, ExpectedDepotManifestId) = 0) and
    ((Info.Language = '') or (CompareText(Info.Language, 'english') = 0));
end;

function FindGameInstallation(var GameRoot: String): Boolean;
var
  Roots: TStringList;
  Index: Integer;
  ManifestPath: String;
  Candidate: String;
  FirstCandidate: String;
  Info: TSteamManifestInfo;
begin
  Result := False;
  GameRoot := '';
  FirstCandidate := '';
  Roots := TStringList.Create;
  try
    FindSteamLibraries(Roots);
    for Index := 0 to Roots.Count - 1 do begin
      ManifestPath := AddBackslash(Roots[Index]) + 'steamapps\' + AppManifestName;
      if ReadAppManifest(ManifestPath, Info) and
         (CompareText(Info.AppId, ExpectedSteamAppId) = 0) then begin
        Candidate := AddBackslash(Roots[Index]) + 'steamapps\common\' + Info.InstallDir;
        Candidate := NormalizeDirectory(Candidate);
        if DirExists(Candidate) then begin
          if FirstCandidate = '' then
            FirstCandidate := Candidate;
          if ManifestMatchesRequiredBuild(Info) then begin
            GameRoot := Candidate;
            Result := True;
            exit;
          end;
        end;
      end;
    end;
    if FirstCandidate <> '' then begin
      GameRoot := FirstCandidate;
      Result := True;
    end;
  finally
    Roots.Free;
  end;
end;

procedure AppendCompatibilityWarning(
  var CompatibilityWarning: String;
  const WarningLine: String
);
begin
  if CompatibilityWarning <> '' then
    CompatibilityWarning := CompatibilityWarning + #13#10;
  CompatibilityWarning := CompatibilityWarning + '- ' + WarningLine;
end;

function ValidateGameInstallation(
  const Candidate: String;
  const VerifyExecutableHash: Boolean;
  var ErrorText: String;
  var CompatibilityWarning: String
): Boolean;
var
  Root: String;
  CommonDirectory: String;
  SteamAppsDirectory: String;
  ManifestPath: String;
  ExecutablePath: String;
  PakDirectory: String;
  Info: TSteamManifestInfo;
  ExecutableSize: Int64;
  ActualHash: String;
begin
  Result := False;
  ErrorText := '';
  CompatibilityWarning := '';
  Root := NormalizeDirectory(Candidate);
  if (Root = '') or not DirExists(Root) then begin
    ErrorText := 'Указанная папка игры не существует.';
    exit;
  end;

  CommonDirectory := ExtractFileDir(Root);
  if CompareText(ExtractFileName(CommonDirectory), 'common') <> 0 then begin
    ErrorText := 'Выберите корневую папку игры внутри steamapps\common.';
    exit;
  end;
  SteamAppsDirectory := ExtractFileDir(CommonDirectory);
  if CompareText(ExtractFileName(SteamAppsDirectory), 'steamapps') <> 0 then begin
    ErrorText := 'Не удалось подтвердить расположение Steam-библиотеки.';
    exit;
  end;

  ManifestPath := AddBackslash(SteamAppsDirectory) + AppManifestName;
  if not ReadAppManifest(ManifestPath, Info) then begin
    ErrorText := 'Не удалось прочитать Steam manifest: ' + ManifestPath;
    exit;
  end;
  if CompareText(Info.AppId, ExpectedSteamAppId) <> 0 then begin
    ErrorText := 'Steam App ID не совпадает. Ожидается ' + ExpectedSteamAppId + '.';
    exit;
  end;
  if CompareText(Info.InstallDir, ExtractFileName(Root)) <> 0 then begin
    ErrorText := 'Выбранная папка не совпадает с installdir из Steam manifest.';
    exit;
  end;
  if (Info.TargetBuildId <> '') and
     (CompareText(Info.TargetBuildId, Info.BuildId) <> 0) then begin
    ErrorText := 'Steam обновляет игру с build ' + Info.BuildId +
      ' до build ' + Info.TargetBuildId + '. Дождитесь окончания обновления.';
    exit;
  end;
  if (Info.Language <> '') and (CompareText(Info.Language, 'english') <> 0) then begin
    ErrorText := 'Для работы русификатора выберите язык English в свойствах игры Steam.';
    exit;
  end;

  PakDirectory := AddBackslash(Root) + PakDirectoryRelativePath;
  if not DirExists(PakDirectory) then begin
    ErrorText := 'Не найдена папка PAK игры: ' + PakDirectory;
    exit;
  end;
  ExecutablePath := AddBackslash(Root) + GameExecutableRelativePath;
  if not FileExists(ExecutablePath) then begin
    ErrorText := 'Не найден исполняемый файл игры: ' + ExecutablePath;
    exit;
  end;
  if not FileSize64(ExecutablePath, ExecutableSize) then begin
    ErrorText := 'Не удалось прочитать размер исполняемого файла игры.';
    exit;
  end;

  if CompareText(Info.BuildId, ExpectedSteamBuildId) <> 0 then
    AppendCompatibilityWarning(
      CompatibilityWarning,
      'ожидается Steam build ' + ExpectedSteamBuildId +
        ', обнаружен build ' + Info.BuildId + '.');
  if CompareText(Info.DepotManifestId, ExpectedDepotManifestId) <> 0 then
    AppendCompatibilityWarning(
      CompatibilityWarning,
      'ожидается depot manifest ' + ExpectedDepotManifestId +
        ', обнаружен ' + Info.DepotManifestId + '.');
  if ExecutableSize <> ExpectedGameExeSize then
    AppendCompatibilityWarning(
      CompatibilityWarning,
      'размер Anvil-Win64-Shipping.exe: ожидается ' +
        IntToStr(ExpectedGameExeSize) + ', обнаружено ' +
        IntToStr(ExecutableSize) + ' байт.');

  if VerifyExecutableHash then begin
    try
      ActualHash := Lowercase(GetSHA256OfFile(ExecutablePath));
    except
      ErrorText := 'Не удалось вычислить SHA-256 исполняемого файла игры: ' +
        GetExceptionMessage;
      exit;
    end;
    if CompareText(ActualHash, ExpectedGameExeSha256) <> 0 then
      AppendCompatibilityWarning(
        CompatibilityWarning,
        'SHA-256 Anvil-Win64-Shipping.exe не совпадает с проверенной сборкой.');
  end;

  SelectedGameRoot := Root;
  SelectedManifestPath := ManifestPath;
  SelectedPakDirectory := PakDirectory;
  SelectedTargetPakPath := AddBackslash(PakDirectory) + TargetPakName;
  SelectedSteamBuildId := Info.BuildId;
  SelectedDepotManifestId := Info.DepotManifestId;
  SelectedGameExeSize := ExecutableSize;
  if VerifyExecutableHash then
    SelectedGameExeSha256 := ActualHash;
  Result := True;
end;

function ConfirmIncompatibleInstallation(
  const CompatibilityWarning: String;
  var ErrorText: String
): Boolean;
var
  WarningText: String;
begin
  Result := False;
  ErrorText := '';
  if CompatibilityWarning = '' then begin
    IncompatibleInstallationAccepted := False;
    Result := True;
    exit;
  end;

#ifdef InstallerTestMode
  if CompareText(ExpandConstant('{param:ALLOWINCOMPATIBLE|}'), '1') = 0 then begin
    IncompatibleInstallationAccepted := True;
    Log('Synthetic incompatible-build override accepted in installer test mode.');
    Result := True;
    exit;
  end;
#endif

  if WizardSilent then begin
    ErrorText := 'Обнаруженная сборка не совпадает с проверенной. ' +
      'Для такой установки требуется явное подтверждение в обычном режиме Setup.';
    exit;
  end;

  WarningText :=
    'СОВМЕСТИМОСТЬ НЕ ПОДТВЕРЖДЕНА' + #13#10#13#10 +
    'Русификатор проверен только для Steam build ' +
      ExpectedSteamBuildId + ' и depot manifest ' +
      ExpectedDepotManifestId + '.' + #13#10#13#10 +
    'Обнаружены следующие отличия:' + #13#10 +
      CompatibilityWarning + #13#10#13#10 +
    'На этой версии перевод может работать неправильно или помешать запуску игры.' +
      '' + #13#10#13#10 +
    'Продолжить установку на свой страх и риск?';

  if SuppressibleMsgBox(
       WarningText,
       mbConfirmation,
       MB_YESNO or MB_DEFBUTTON2,
       IDNO) = IDYES then begin
    IncompatibleInstallationAccepted := True;
    Result := True;
  end else
    ErrorText := 'Установка на неподтверждённую сборку отменена.';
end;

function IsGameProcessRunning: Boolean;
var
  Locator: Variant;
  Services: Variant;
  Processes: Variant;
begin
  Result := False;
  GameProcessCheckSucceeded := False;
  try
    Locator := CreateOleObject('WbemScripting.SWbemLocator');
    Services := Locator.ConnectServer('.', 'root\CIMV2');
    Processes := Services.ExecQuery(
      'SELECT Name FROM Win32_Process WHERE Name="Anvil.exe" OR ' +
      'Name="Anvil-Win64-Shipping.exe"');
    Result := Processes.Count > 0;
    GameProcessCheckSucceeded := True;
  except
    Log('WMI process check failed; installer will stop safely.');
  end;
end;

function ConfirmGameIsClosed(var ErrorText: String): Boolean;
var
  Running: Boolean;
begin
  Running := IsGameProcessRunning;
  if not GameProcessCheckSucceeded then begin
    ErrorText := 'Не удалось проверить, запущена ли Anvil Empires. ' +
      'Перезапустите Windows или восстановите службу WMI и повторите.';
    Result := False;
  end else if Running then begin
    ErrorText := 'Anvil Empires сейчас запущена. Сохраните игру, полностью ' +
      'закройте клиент и повторите.';
    Result := False;
  end else
    Result := True;
end;

function IsActiveRussianPakName(const FileName: String): Boolean;
begin
  Result :=
    (Length(FileName) >= Length(TargetPakPrefix)) and
    (CompareText(Copy(FileName, 1, Length(TargetPakPrefix)), TargetPakPrefix) = 0) and
    (CompareText(ExtractFileExt(FileName), '.pak') = 0);
end;

function CollectActivePakConflicts(const PakDirectory: String): String;
var
  FindRecord: TFindRec;
  Candidate: String;
begin
  Result := '';
  if FindFirst(AddBackslash(PakDirectory) + TargetPakPrefix + '*', FindRecord) then begin
    try
      repeat
        if (FindRecord.Attributes and FILE_ATTRIBUTE_DIRECTORY = 0) and
           IsActiveRussianPakName(FindRecord.Name) and
           (CompareText(FindRecord.Name, TargetPakName) <> 0) then begin
          Candidate := FindRecord.Name;
          if Result <> '' then
            Result := Result + #13#10;
          Result := Result + Candidate;
        end;
      until not FindNext(FindRecord);
    finally
      FindClose(FindRecord);
    end;
  end;
end;

function StateFilePath: String;
begin
  Result := ExpandConstant('{app}\') + StateFileName;
end;

function ReadOwnedInstallState(var GameRoot, PakPath, PakHash, BuildId: String): Boolean;
var
  StatePath: String;
  StateSchema: String;
  StateSteamAppId: String;
  StateVersion: String;
begin
  StatePath := StateFilePath;
  StateSchema := GetIniString(StateSection, 'Schema', '', StatePath);
  StateSteamAppId := GetIniString(StateSection, 'SteamAppId', '', StatePath);
  StateVersion := GetIniString(StateSection, 'Version', '', StatePath);
  GameRoot := GetIniString(StateSection, 'GameRoot', '', StatePath);
  PakPath := GetIniString(StateSection, 'PakPath', '', StatePath);
  PakHash := Lowercase(GetIniString(StateSection, 'PakSha256', '', StatePath));
  BuildId := GetIniString(StateSection, 'SteamBuildId', '', StatePath);
  Result :=
    (CompareText(StateSchema, 'anvil-russian-installer-state/1') = 0) and
    (CompareText(StateSteamAppId, ExpectedSteamAppId) = 0) and
    (StateVersion <> '') and
    (GameRoot <> '') and
    (PakPath <> '') and
    (Length(PakHash) = 64);
end;

function IsKnownPreviousInstallerPayloadHash(const PakHash: String): Boolean;
begin
  { Shipped predecessor hashes are explicit so an upgrade never takes
    ownership of an unrelated or user-modified PAK. Synthetic test builds
    allow their first payload to exercise the upgrade/rollback path. }
#ifdef InstallerTestMode
  Result := Length(PakHash) = 64;
#else
  Result := CompareText(
    PakHash,
    'd09f98eee9178051ecf26e9224cc84d1872f52d323b1cabf9d187def1dc4e5ed'
  ) = 0;
#endif
end;

function CreateDisabledBackupPath(const TargetPath: String): String;
begin
  Result := TargetPath + '.installer-rollback.disabled';
end;

function CanWritePakDirectory(var ErrorText: String): Boolean;
var
  ProbePath: String;
begin
  ProbePath := GenerateUniqueName(SelectedPakDirectory, '.installer-write-test');
  Result := SaveStringToFile(ProbePath, 'write-test', False);
  if Result then begin
    if not DeleteFile(ProbePath) then begin
      ErrorText := 'Не удалось удалить проверочный файл: ' + ProbePath;
      Result := False;
    end;
  end else
    ErrorText := 'Нет доступа на запись в папку PAK. Закройте установщик и ' +
      'дайте текущей учётной записи доступ к библиотеке Steam либо перенесите ' +
      'игру в доступную библиотеку. Если это ваша административная учётная ' +
      'запись, можно повторить запуск от имени администратора.';
end;

function RecoverInterruptedRollback(var ErrorText: String): Boolean;
var
  StateGameRoot: String;
  StatePakPath: String;
  StatePakHash: String;
  StateBuildId: String;
begin
  Result := True;
  RollbackPakPath := CreateDisabledBackupPath(SelectedTargetPakPath);
  StagingPakPath := SelectedTargetPakPath + '.installer-staging';
  if FileExists(StagingPakPath) then begin
    ErrorText := 'Найден незавершённый staging-файл установщика: ' + StagingPakPath +
      '. Удалите его вручную после проверки.';
    Result := False;
    exit;
  end;
  if not FileExists(RollbackPakPath) then
    exit;

  if (not FileExists(SelectedTargetPakPath)) and
     ReadOwnedInstallState(StateGameRoot, StatePakPath, StatePakHash, StateBuildId) and
     (CompareText(NormalizeDirectory(StateGameRoot), SelectedGameRoot) = 0) and
     (CompareText(NormalizeDirectory(StatePakPath), SelectedTargetPakPath) = 0) and
     ((CompareText(StatePakHash, ExpectedPayloadSha256) = 0) or
       IsKnownPreviousInstallerPayloadHash(StatePakHash)) and
     (CompareText(Lowercase(GetSHA256OfFile(RollbackPakPath)), StatePakHash) = 0) then begin
    if RenameFile(RollbackPakPath, SelectedTargetPakPath) then begin
      Log('Recovered an installer-owned PAK from interrupted rollback.');
      exit;
    end;
  end;

  ErrorText := 'Найдена сохранённая копия незавершённой установки: ' +
    RollbackPakPath + '. Установщик не будет изменять её автоматически.';
  Result := False;
end;

function DetermineInstallPlan(var ErrorText: String): Boolean;
var
  Conflicts: String;
  CurrentHash: String;
  StateGameRoot: String;
  StatePakPath: String;
  StatePakHash: String;
  StateBuildId: String;
begin
  Result := False;
  InstallPayloadRequired := True;
  PreviousPayloadHash := '';
  HadPreviousTarget := FileExists(SelectedTargetPakPath);

  if not RecoverInterruptedRollback(ErrorText) then
    exit;
  HadPreviousTarget := FileExists(SelectedTargetPakPath);

  Conflicts := CollectActivePakConflicts(SelectedPakDirectory);
  if Conflicts <> '' then begin
    ErrorText := 'Найдены другие активные русификаторы:' + #13#10 + Conflicts +
      '' + #13#10#13#10 + 'Переименуйте или вынесите их из папки Paks. Файлы .disabled не затрагиваются.';
    exit;
  end;

  if HadPreviousTarget then begin
    CurrentHash := Lowercase(GetSHA256OfFile(SelectedTargetPakPath));
    if CompareText(CurrentHash, ExpectedPayloadSha256) = 0 then begin
      InstallPayloadRequired := False;
      Result := True;
      exit;
    end;

    if ReadOwnedInstallState(StateGameRoot, StatePakPath, StatePakHash, StateBuildId) and
       (CompareText(NormalizeDirectory(StateGameRoot), SelectedGameRoot) = 0) and
       (CompareText(NormalizeDirectory(StatePakPath), SelectedTargetPakPath) = 0) and
       (CompareText(StatePakHash, CurrentHash) = 0) and
       IsKnownPreviousInstallerPayloadHash(CurrentHash) then begin
      PreviousPayloadHash := CurrentHash;
      InstallPayloadRequired := True;
    end else begin
      ErrorText := 'Файл ' + TargetPakName + ' уже существует, но не принадлежит ' +
        'этому установщику. Его SHA-256: ' + CurrentHash + '.' + #13#10 +
        'Установщик сохранил файл без изменений. Уберите его вручную и повторите установку.';
      exit;
    end;
  end;

  if not CanWritePakDirectory(ErrorText) then
    exit;
  Result := True;
end;

procedure RollbackGameChanges;
begin
  if not PayloadMutationStarted then
    exit;

  if FileExists(StagingPakPath) then begin
    if not DeleteFile(StagingPakPath) then
      Log('Could not delete installer staging PAK: ' + StagingPakPath);
  end;

  if PayloadInstalledThisRun then begin
    if not FileExists(SelectedTargetPakPath) then
      PayloadInstalledThisRun := False
    else if DeleteFile(SelectedTargetPakPath) then
      PayloadInstalledThisRun := False
    else
      Log('Could not delete newly installed PAK during rollback: ' + SelectedTargetPakPath);
  end;

  if HadPreviousTarget then begin
    if FileExists(RollbackPakPath) and not FileExists(SelectedTargetPakPath) then begin
      if RenameFile(RollbackPakPath, SelectedTargetPakPath) then
        HadPreviousTarget := False
      else
        Log('Could not restore previous installer-owned PAK: ' + RollbackPakPath);
    end else if (not FileExists(RollbackPakPath)) and
                FileExists(SelectedTargetPakPath) and
                (PreviousPayloadHash <> '') and
                (CompareText(
                  Lowercase(GetSHA256OfFile(SelectedTargetPakPath)),
                  PreviousPayloadHash) = 0) then
      HadPreviousTarget := False;
  end;

  if (not FileExists(StagingPakPath)) and
     (not PayloadInstalledThisRun) and
     (not HadPreviousTarget) then
    PayloadMutationStarted := False;
end;

procedure InstallPayloadAtomically;
var
  ExtractedPath: String;
  ExtractedSize: Int64;
  ErrorText: String;
  CompatibilityWarning: String;
  Conflicts: String;
  CurrentHash: String;
begin
  if not InstallPayloadRequired then
    exit;

  PayloadMutationStarted := True;
  PayloadInstalledThisRun := False;
  RollbackPakPath := CreateDisabledBackupPath(SelectedTargetPakPath);
  StagingPakPath := SelectedTargetPakPath + '.installer-staging';
  ExtractTemporaryFile(TargetPakName);
  ExtractedPath := ExpandConstant('{tmp}\') + TargetPakName;

  if not FileSize64(ExtractedPath, ExtractedSize) or
     (ExtractedSize <> ExpectedPayloadSize) or
     (CompareText(Lowercase(GetSHA256OfFile(ExtractedPath)), ExpectedPayloadSha256) <> 0) then
    RaiseException('Встроенный PAK не прошёл контроль целостности.');

  if FileExists(StagingPakPath) or FileExists(RollbackPakPath) then
    RaiseException('Найдены служебные файлы предыдущей незавершённой установки.');

  if not ConfirmGameIsClosed(ErrorText) then
    RaiseException(ErrorText);
  Conflicts := CollectActivePakConflicts(SelectedPakDirectory);
  if Conflicts <> '' then
    RaiseException('Перед копированием появился другой активный русификатор: ' + Conflicts);
  if HadPreviousTarget then begin
    if not FileExists(SelectedTargetPakPath) then
      RaiseException('Прежний installer-owned PAK исчез перед заменой.');
    CurrentHash := Lowercase(GetSHA256OfFile(SelectedTargetPakPath));
    if CompareText(CurrentHash, PreviousPayloadHash) <> 0 then
      RaiseException('Прежний installer-owned PAK изменился перед заменой и оставлен без изменений.');
  end else if FileExists(SelectedTargetPakPath) then
    RaiseException('Целевой PAK появился после проверки и оставлен без изменений.');

  if not FileCopy(ExtractedPath, StagingPakPath, True) then
    RaiseException('Не удалось создать staging-копию PAK: ' + StagingPakPath);
  if CompareText(Lowercase(GetSHA256OfFile(StagingPakPath)), ExpectedPayloadSha256) <> 0 then begin
    DeleteFile(StagingPakPath);
    RaiseException('Staging-копия PAK не прошла проверку SHA-256.');
  end;

  if HadPreviousTarget then begin
    if not RenameFile(SelectedTargetPakPath, RollbackPakPath) then begin
      DeleteFile(StagingPakPath);
      RaiseException('Не удалось временно сохранить прежний PAK.');
    end;
  end;

  if not RenameFile(StagingPakPath, SelectedTargetPakPath) then begin
    RollbackGameChanges;
    RaiseException('Не удалось атомарно активировать новый PAK.');
  end;
  PayloadInstalledThisRun := True;

  if CompareText(Lowercase(GetSHA256OfFile(SelectedTargetPakPath)), ExpectedPayloadSha256) <> 0 then begin
    RollbackGameChanges;
    RaiseException('Установленный PAK не прошёл итоговую проверку SHA-256.');
  end;

  if not ValidateGameInstallation(
       SelectedGameRoot,
       False,
       ErrorText,
       CompatibilityWarning) then begin
    RollbackGameChanges;
    RaiseException('Steam-сборка изменилась во время установки: ' + ErrorText);
  end;
  if (CompatibilityWarning <> '') and
     not IncompatibleInstallationAccepted then begin
    RollbackGameChanges;
    RaiseException(
      'Совместимость изменилась во время установки: ' + CompatibilityWarning);
  end;
end;

procedure RollbackInstallState;
var
  StatePath: String;
  NewPath: String;
  BackupPath: String;
begin
  if not StateMutationStarted then
    exit;

  StatePath := StateFilePath;
  NewPath := StatePath + '.new';
  BackupPath := StatePath + '.rollback';

  if FileExists(NewPath) and not DeleteFile(NewPath) then
    Log('Could not delete staged installer state: ' + NewPath);

  if StateInstalledThisRun then begin
    if not FileExists(StatePath) then
      StateInstalledThisRun := False
    else if DeleteFile(StatePath) then
      StateInstalledThisRun := False
    else
      Log('Could not delete newly installed state during rollback: ' + StatePath);
  end;

  if HadPreviousState then begin
    if FileExists(BackupPath) and not FileExists(StatePath) then begin
      if RenameFile(BackupPath, StatePath) then
        HadPreviousState := False
      else
        Log('Could not restore previous installer state: ' + BackupPath);
    end else if (not FileExists(BackupPath)) and
                FileExists(StatePath) and
                (PreviousStateHash <> '') and
                (CompareText(
                  Lowercase(GetSHA256OfFile(StatePath)),
                  PreviousStateHash) = 0) then
      HadPreviousState := False;
  end;

  if (not FileExists(NewPath)) and
     (not StateInstalledThisRun) and
     (not HadPreviousState) then
    StateMutationStarted := False;
end;

procedure RollbackInstallationTransaction;
begin
  RollbackInstallState;
  RollbackGameChanges;
end;

function WriteInstallStateAtomically: Boolean;
var
  StatePath: String;
  NewPath: String;
  BackupPath: String;
  CompatibilityStatus: String;
begin
  Result := False;
  StatePath := StateFilePath;
  NewPath := StatePath + '.new';
  BackupPath := StatePath + '.rollback';

  if not ForceDirectories(ExtractFileDir(StatePath)) then
    exit;
  if FileExists(NewPath) or FileExists(BackupPath) then begin
    Log('Refusing to overwrite an unfinished installer state transaction.');
    exit;
  end;

  StateMutationStarted := True;
  StateInstalledThisRun := False;
  HadPreviousState := FileExists(StatePath);
  PreviousStateHash := '';
  if HadPreviousState then
    PreviousStateHash := Lowercase(GetSHA256OfFile(StatePath));

  if SelectedCompatibilityWarning = '' then
    CompatibilityStatus := 'verified'
  else
    CompatibilityStatus := 'incompatible-user-confirmed';

  if not SetIniString(StateSection, 'Schema', 'anvil-russian-installer-state/1', NewPath) or
     not SetIniString(StateSection, 'Version', '{#AppVersion}', NewPath) or
     not SetIniString(StateSection, 'SteamAppId', ExpectedSteamAppId, NewPath) or
     not SetIniString(StateSection, 'SteamBuildId', ExpectedSteamBuildId, NewPath) or
     not SetIniString(StateSection, 'InstalledSteamBuildId', SelectedSteamBuildId, NewPath) or
     not SetIniString(StateSection, 'InstalledDepotManifestId', SelectedDepotManifestId, NewPath) or
     not SetIniString(StateSection, 'InstalledGameExeSize', IntToStr(SelectedGameExeSize), NewPath) or
     not SetIniString(StateSection, 'InstalledGameExeSha256', SelectedGameExeSha256, NewPath) or
     not SetIniString(StateSection, 'CompatibilityStatus', CompatibilityStatus, NewPath) or
     not SetIniString(StateSection, 'GameRoot', SelectedGameRoot, NewPath) or
     not SetIniString(StateSection, 'PakPath', SelectedTargetPakPath, NewPath) or
     not SetIniString(StateSection, 'PakSha256', ExpectedPayloadSha256, NewPath) then begin
    DeleteFile(NewPath);
    exit;
  end;

  if HadPreviousState and not RenameFile(StatePath, BackupPath) then begin
    DeleteFile(NewPath);
    exit;
  end;
  if not RenameFile(NewPath, StatePath) then begin
    if HadPreviousState then
      RenameFile(BackupPath, StatePath);
    exit;
  end;
  StateInstalledThisRun := True;
  Result := True;
end;

procedure StageInstallationTransaction;
var
  ErrorText: String;
  CompatibilityWarning: String;
begin
  if not FileExists(SelectedTargetPakPath) then
    RaiseException('Итоговый PAK отсутствует перед фиксацией состояния установки.');
  if CompareText(Lowercase(GetSHA256OfFile(SelectedTargetPakPath)), ExpectedPayloadSha256) <> 0 then begin
    RaiseException('Итоговый PAK изменился до завершения установки.');
  end;
  if not ValidateGameInstallation(
       SelectedGameRoot,
       True,
       ErrorText,
       CompatibilityWarning) then begin
    RaiseException('Проверка Steam-сборки после установки не пройдена: ' + ErrorText);
  end;
  SelectedCompatibilityWarning := CompatibilityWarning;
  if (CompatibilityWarning <> '') and
     not IncompatibleInstallationAccepted then begin
    RaiseException(
      'Совместимость изменилась во время установки: ' + CompatibilityWarning);
  end;
  if not WriteInstallStateAtomically then begin
    RaiseException('Не удалось сохранить состояние установщика.');
  end;
end;

procedure FinalizeInstallationCommit;
var
  StatePath: String;
  StateBackupPath: String;
begin
  InstallationCommitted := True;
  PayloadMutationStarted := False;
  StateMutationStarted := False;
  PayloadInstalledThisRun := False;
  StateInstalledThisRun := False;
  HadPreviousTarget := False;
  HadPreviousState := False;
  if FileExists(RollbackPakPath) and not DeleteFile(RollbackPakPath) then
    Log('Installer-owned rollback PAK was left disabled: ' + RollbackPakPath);
  StatePath := StateFilePath;
  StateBackupPath := StatePath + '.rollback';
  if FileExists(StateBackupPath) and not DeleteFile(StateBackupPath) then
    Log('Previous installer state backup was left in place: ' + StateBackupPath);
  if FileExists(StatePath + '.new') and not DeleteFile(StatePath + '.new') then
    Log('Staged installer state was left in place: ' + StatePath + '.new');
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ErrorText: String;
  CompatibilityWarning: String;
begin
  Result := '';
  NeedsRestart := False;
  if not ConfirmGameIsClosed(ErrorText) then begin
    Result := ErrorText;
    exit;
  end;
  if not ValidateGameInstallation(
       GameDirectoryPage.Values[0],
       True,
       ErrorText,
       CompatibilityWarning) then begin
    Result := ErrorText;
    exit;
  end;
  SelectedCompatibilityWarning := CompatibilityWarning;
  if not DetermineInstallPlan(ErrorText) then begin
    Result := ErrorText;
    exit;
  end;
  if not ConfirmIncompatibleInstallation(CompatibilityWarning, ErrorText) then
    Result := ErrorText;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then begin
    try
      InstallPayloadAtomically;
      StageInstallationTransaction;
#ifdef InstallerTestFailBeforeCommit
      RaiseException('Synthetic failure before installer commit.');
#endif
    except
      RollbackInstallationTransaction;
      RaiseException(GetExceptionMessage);
    end;
  end else if CurStep = ssPostInstall then
    FinalizeInstallationCommit;
end;

procedure DeinitializeSetup;
begin
  if not InstallationCommitted then
    RollbackInstallationTransaction;
  ReleaseInstallerMutex;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  ErrorText: String;
  CompatibilityWarning: String;
begin
  Result := True;
  if CurPageID = GameDirectoryPage.ID then begin
    WizardForm.NextButton.Enabled := False;
    try
      IncompatibleInstallationAccepted := False;
      Result := ValidateGameInstallation(
        GameDirectoryPage.Values[0],
        True,
        ErrorText,
        CompatibilityWarning);
      if not Result then
        MsgBox(ErrorText, mbError, MB_OK)
      else begin
        SelectedCompatibilityWarning := CompatibilityWarning;
        GameDirectoryPage.Values[0] := SelectedGameRoot;
      end;
    finally
      WizardForm.NextButton.Enabled := True;
    end;
  end;
end;

procedure ProjectLinkOnLinkClick(
  Sender: TObject;
  const Link: String;
  LinkType: TSysLinkType
);
var
  ErrorCode: Integer;
begin
  if (LinkType <> sltURL) or
     ((CompareText(
        Link,
        'https://github.com/nullith2/anvil-empires-russian') <> 0) and
      (CompareText(
        Link,
        'https://github.com/nullith2/anvil-empires-russian/issues') <> 0) and
      (CompareText(
        Link,
        'https://github.com/nullith2/anvil-empires-russian/releases') <> 0)) then
    exit;
  try
    if not ShellExecAsOriginalUser(
         'open',
         Link,
         '',
         '',
         SW_SHOWNORMAL,
         ewNoWait,
         ErrorCode) then
      SuppressibleMsgBox(
        'Не удалось открыть ссылку:' + #13#10 + Link + #13#10#13#10 +
          SysErrorMessage(ErrorCode),
        mbError,
        MB_OK,
        IDOK);
  except
    SuppressibleMsgBox(
      'Не удалось открыть ссылку:' + #13#10 + Link + #13#10#13#10 +
        GetExceptionMessage,
      mbError,
      MB_OK,
      IDOK);
  end;
end;

function UpdateReadyMemo(
  Space: String;
  NewLine: String;
  MemoUserInfoInfo: String;
  MemoDirInfo: String;
  MemoTypeInfo: String;
  MemoComponentsInfo: String;
  MemoGroupInfo: String;
  MemoTasksInfo: String
): String;
var
  CompatibilityMemo: String;
begin
  if SelectedCompatibilityWarning = '' then
    CompatibilityMemo :=
      'Совместимость подтверждена: Steam build ' + SelectedSteamBuildId +
      ', depot manifest ' + SelectedDepotManifestId + '.'
  else
    CompatibilityMemo :=
      'СОВМЕСТИМОСТЬ НЕ ПОДТВЕРЖДЕНА' + NewLine +
      SelectedCompatibilityWarning + NewLine +
      'Перед установкой потребуется явное подтверждение риска.';

  Result :=
    'Папка игры:' + NewLine + Space + SelectedGameRoot + NewLine + NewLine +
    'Совместимость:' + NewLine + Space + CompatibilityMemo + NewLine + NewLine +
    'Файл:' + NewLine + Space + SelectedTargetPakPath + NewLine + NewLine +
    'Автор:' + NewLine + Space + 'nullith' + NewLine + NewLine +
    'Репозиторий:' + NewLine + Space +
      'https://github.com/nullith2/anvil-empires-russian' + NewLine + NewLine +
    'Установщик изменяет только собственный PAK русификатора. ' +
    'Штатный Anvil-Windows.pak и файлы .disabled не затрагиваются.';
end;

procedure InitializeWizard;
var
  DetectedRoot: String;
  SavedRoot: String;
  SavedPakPath: String;
  SavedPakHash: String;
  SavedBuildId: String;
  RequestedRoot: String;
begin
  InstallationCommitted := False;
  IncompatibleInstallationAccepted := False;
  SelectedCompatibilityWarning := '';
  SelectedGameExeSha256 := '';
  PayloadMutationStarted := False;
  PayloadInstalledThisRun := False;
  StateMutationStarted := False;
  StateInstalledThisRun := False;
  HadPreviousState := False;
  PreviousStateHash := '';

  ProjectInfoPage := CreateCustomPage(
    wpWelcome,
    'О проекте',
    'Автор и официальные ссылки русификатора');

  ProjectInfoText := TNewStaticText.Create(ProjectInfoPage);
  ProjectInfoText.AutoSize := False;
  ProjectInfoText.WordWrap := True;
  ProjectInfoText.Width := ProjectInfoPage.SurfaceWidth;
  ProjectInfoText.Caption :=
    'Неофициальный русский перевод Anvil Empires.' + #13#10#13#10 +
    'Автор русификатора: nullith' + #13#10#13#10 +
    'Ниже находятся официальный репозиторий проекта, сообщения об ошибках ' +
      'и страница выпусков. Скачивайте обновления только из этого репозитория.';
  ProjectInfoText.Parent := ProjectInfoPage.Surface;
  ProjectInfoText.AdjustHeight;

  ProjectLinks := TNewLinkLabel.Create(ProjectInfoPage);
  ProjectLinks.AutoSize := False;
  ProjectLinks.Left := 0;
  ProjectLinks.Top := ProjectInfoText.Top + ProjectInfoText.Height + ScaleY(20);
  ProjectLinks.Width := ProjectInfoPage.SurfaceWidth;
  ProjectLinks.Caption :=
    '<a href="https://github.com/nullith2/anvil-empires-russian">' +
      'Репозиторий проекта</a>' + #13#10#13#10 +
    '<a href="https://github.com/nullith2/anvil-empires-russian/issues">' +
      'Сообщить об ошибке (GitHub Issues)</a>' + #13#10#13#10 +
    '<a href="https://github.com/nullith2/anvil-empires-russian/releases">' +
      'Скачать новые версии (GitHub Releases)</a>';
  ProjectLinks.UseVisualStyle := HighContrastActive;
  ProjectLinks.OnLinkClick := @ProjectLinkOnLinkClick;
  ProjectLinks.Parent := ProjectInfoPage.Surface;
  ProjectLinks.AdjustHeight;

  GameDirectoryPage := CreateInputDirPage(
    ProjectInfoPage.ID,
    'Папка Anvil Empires',
    'Укажите корневую папку установленной игры.',
    'Установщик ищет игру во всех библиотеках Steam и проверяет её сборку. ' +
      'При необходимости выберите папку вручную.',
    False,
    '');
  GameDirectoryPage.Add('');

  RequestedRoot := ExpandConstant('{param:GAMEPATH|}');
  if RequestedRoot <> '' then
    GameDirectoryPage.Values[0] := NormalizeDirectory(RequestedRoot)
  else if FindGameInstallation(DetectedRoot) then
    GameDirectoryPage.Values[0] := DetectedRoot
  else if ReadOwnedInstallState(SavedRoot, SavedPakPath, SavedPakHash, SavedBuildId) then
    GameDirectoryPage.Values[0] := NormalizeDirectory(SavedRoot)
  else
    GameDirectoryPage.Values[0] := '';
end;

function InitializeSetup: Boolean;
var
  ErrorText: String;
begin
  Result := AcquireInstallerMutex(ErrorText);
  if not Result then
    SuppressibleMsgBox(ErrorText, mbError, MB_OK, IDOK);
end;

function IsSafeStoredPakPath(const GameRoot, PakPath: String): Boolean;
var
  ExpectedPath: String;
begin
  ExpectedPath := NormalizeDirectory(
    AddBackslash(NormalizeDirectory(GameRoot)) + PakDirectoryRelativePath + '\' + TargetPakName);
  Result := (GameRoot <> '') and (PakPath <> '') and
    (CompareText(NormalizeDirectory(PakPath), ExpectedPath) = 0);
end;

function TryRediscoverUninstallPak: Boolean;
var
  DetectedRoot: String;
  CandidatePath: String;
begin
  Result := False;
#ifndef InstallerTestMode
  if FindGameInstallation(DetectedRoot) then begin
    CandidatePath := NormalizeDirectory(
      AddBackslash(DetectedRoot) + PakDirectoryRelativePath + '\' + TargetPakName);
    if FileExists(CandidatePath) then begin
      UninstallGameRoot := NormalizeDirectory(DetectedRoot);
      UninstallPakPath := CandidatePath;
      UninstallStateIsSafe := IsSafeStoredPakPath(UninstallGameRoot, UninstallPakPath);
      Result := UninstallStateIsSafe;
      if Result then
        Log('Rediscovered installer-owned PAK after the Steam game path changed: ' + CandidatePath);
    end;
  end;
#endif
end;

function InitializeUninstall: Boolean;
var
  StatePath: String;
  ActualHash: String;
  ErrorText: String;
  StateSchema: String;
  StateSteamAppId: String;
  StateSteamBuildId: String;
  StateVersion: String;
begin
  if not AcquireInstallerMutex(ErrorText) then begin
    SuppressibleMsgBox('Русификатор не удалён: ' + ErrorText, mbError, MB_OK, IDOK);
    Result := False;
    exit;
  end;

  StatePath := ExpandConstant('{app}\') + StateFileName;
  StateSchema := GetIniString(StateSection, 'Schema', '', StatePath);
  StateSteamAppId := GetIniString(StateSection, 'SteamAppId', '', StatePath);
  StateSteamBuildId := GetIniString(StateSection, 'SteamBuildId', '', StatePath);
  StateVersion := GetIniString(StateSection, 'Version', '', StatePath);
  UninstallGameRoot := GetIniString(StateSection, 'GameRoot', '', StatePath);
  UninstallPakPath := GetIniString(StateSection, 'PakPath', '', StatePath);
  UninstallPayloadHash := Lowercase(GetIniString(StateSection, 'PakSha256', '', StatePath));
  UninstallStateIsSafe :=
    (CompareText(StateSchema, 'anvil-russian-installer-state/1') = 0) and
    (CompareText(StateSteamAppId, ExpectedSteamAppId) = 0) and
    (CompareText(StateSteamBuildId, ExpectedSteamBuildId) = 0) and
    (CompareText(StateVersion, '{#AppVersion}') = 0) and
    (CompareText(UninstallPayloadHash, ExpectedPayloadSha256) = 0) and
    IsSafeStoredPakPath(UninstallGameRoot, UninstallPakPath);

  if not UninstallStateIsSafe then begin
    SuppressibleMsgBox(
      'Русификатор не удалён: состояние установки не прошло проверку. ' +
        'Переустановите эту же версию Setup либо удалите PAK вручную, затем повторите удаление.',
      mbError, MB_OK, IDOK);
    Result := False;
    exit;
  end;

  if not FileExists(UninstallPakPath) then
    TryRediscoverUninstallPak;
  if FileExists(UninstallPakPath) then begin
    ActualHash := Lowercase(GetSHA256OfFile(UninstallPakPath));
    if CompareText(ActualHash, UninstallPayloadHash) <> 0 then begin
      SuppressibleMsgBox(
        'Русификатор не удалён: установленный PAK был изменён после установки.' +
          '' + #13#10 + UninstallPakPath + #13#10 + 'SHA-256: ' + ActualHash +
          '' + #13#10#13#10 + 'Удалите этот файл вручную или восстановите исходный PAK, затем повторите удаление.',
        mbError, MB_OK, IDOK);
      Result := False;
      exit;
    end;
    if not ConfirmGameIsClosed(ErrorText) then begin
      SuppressibleMsgBox('Русификатор не удалён: ' + ErrorText, mbError, MB_OK, IDOK);
      Result := False;
      exit;
    end;
  end;
  Result := True;
end;

procedure RemoveOwnedPayloadOnUninstall;
var
  ActualHash: String;
  ErrorText: String;
begin
  if not UninstallStateIsSafe then
    RaiseException('Русификатор не удалён: небезопасное состояние установки.');
  if not FileExists(UninstallPakPath) then
    exit;

  if not ConfirmGameIsClosed(ErrorText) then
    RaiseException('Русификатор не удалён: ' + ErrorText);
  ActualHash := Lowercase(GetSHA256OfFile(UninstallPakPath));
  if CompareText(ActualHash, UninstallPayloadHash) <> 0 then
    RaiseException('Русификатор не удалён: PAK изменился после предварительной проверки.');
  if not DeleteFile(UninstallPakPath) then
    RaiseException('Не удалось удалить PAK русификатора: ' + UninstallPakPath);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    RemoveOwnedPayloadOnUninstall;
end;

procedure DeinitializeUninstall;
begin
  ReleaseInstallerMutex;
end;

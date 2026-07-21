[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $ReleaseDirectory,

    [Parameter(Mandatory = $true)]
    [string] $ReleasePolicy,

    [string] $Iscc,

    [string] $ToolchainPolicy,

    [string] $InstallerScript,

    [string] $InstallerReadme,

    [string] $OutputRoot,

    [switch] $ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ToolchainPolicy)) {
    $ToolchainPolicy = Join-Path $projectRoot 'packaging\installer\inno-toolchain-v7.0.2.json'
}
if ([string]::IsNullOrWhiteSpace($InstallerScript)) {
    $InstallerScript = Join-Path $projectRoot 'packaging\installer\Anvil-Empires-Russian.iss'
}
if ([string]::IsNullOrWhiteSpace($InstallerReadme)) {
    $InstallerReadme = Join-Path $projectRoot 'packaging\installer\README_INSTALLER_RU.txt'
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $projectRoot 'dist'
}

$allowedReleaseFiles = @(
    'Anvil-Russian-Full_P.pak',
    'README_RU.txt',
    'RELEASE_NOTES_RU.txt',
    'INFO/LICENSE_RU.txt',
    'INFO/LICENSES/Apache-2.0.txt',
    'INFO/release-manifest.json',
    'INFO/SHA256SUMS.txt',
    'INFO/THIRD-PARTY-NOTICES.txt'
)
$checksumMembers = @($allowedReleaseFiles | Where-Object { $_ -ne 'INFO/SHA256SUMS.txt' })

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string] $Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-DirectoryTreeIdentity {
    param([Parameter(Mandatory = $true)][string] $Root)

    $rootPath = (Resolve-Path -LiteralPath $Root).Path.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    $records = [System.Collections.Generic.List[string]]::new()
    foreach ($file in Get-ChildItem -LiteralPath $rootPath -File -Recurse -Force) {
        $relativePath = Get-RelativeSlashPath -Root $rootPath -Path $file.FullName
        $size = $file.Length.ToString([System.Globalization.CultureInfo]::InvariantCulture)
        $records.Add(
            $relativePath + [char]0 + $size + [char]0 + (Get-Sha256 -Path $file.FullName)
        )
    }
    $records.Sort([System.StringComparer]::Ordinal)

    $fingerprintText = [string]::Join("`n", $records) + "`n"
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha256.ComputeHash($utf8NoBom.GetBytes($fingerprintText))
    } finally {
        $sha256.Dispose()
    }

    return [pscustomobject]@{
        file_count = $records.Count
        sha256 = -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
    }
}

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)] $Actual,
        [Parameter(Mandatory = $true)] $Expected,
        [Parameter(Mandatory = $true)][string] $Label
    )

    if ($Actual -ne $Expected) {
        throw "$Label mismatch: expected '$Expected', got '$Actual'"
    }
}

function Assert-DecimalId {
    param(
        [Parameter(Mandatory = $true)][string] $Value,
        [Parameter(Mandatory = $true)][string] $Label
    )

    if ($Value -notmatch '^[0-9]+$') {
        throw "$Label must contain decimal digits only: '$Value'"
    }
}

function Get-PolicySha256 {
    param(
        [Parameter(Mandatory = $true)] $Value,
        [Parameter(Mandatory = $true)][string] $Label
    )

    $text = [string]$Value
    if ($text -notmatch '^sha256:([0-9a-f]{64})$') {
        throw "$Label must use lowercase sha256:<hex> form: '$text'"
    }
    return $Matches[1]
}

function Get-RelativeSlashPath {
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][string] $Path
    )

    $rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $filePath = [System.IO.Path]::GetFullPath($Path)
    $prefix = $rootPath + [System.IO.Path]::DirectorySeparatorChar
    if (-not $filePath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the expected root: '$filePath'"
    }
    return $filePath.Substring($prefix.Length).Replace('\', '/')
}

function Assert-ExactStringSet {
    param(
        [Parameter(Mandatory = $true)][string[]] $Actual,
        [Parameter(Mandatory = $true)][string[]] $Expected,
        [Parameter(Mandatory = $true)][string] $Label
    )

    $actualSorted = @($Actual | Sort-Object -Unique)
    $expectedSorted = @($Expected | Sort-Object -Unique)
    $difference = @(Compare-Object -ReferenceObject $expectedSorted -DifferenceObject $actualSorted)
    if ($difference.Count -ne 0) {
        $details = ($difference | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" }) -join '; '
        throw "$Label mismatch: $details"
    }
}

$releaseDirectoryPath = (Resolve-Path -LiteralPath $ReleaseDirectory).Path
if (-not (Test-Path -LiteralPath $releaseDirectoryPath -PathType Container)) {
    throw "Release directory does not exist: $releaseDirectoryPath"
}
$releasePolicyPath = (Resolve-Path -LiteralPath $ReleasePolicy).Path
$toolchainPolicyPath = (Resolve-Path -LiteralPath $ToolchainPolicy).Path
$installerScriptPath = (Resolve-Path -LiteralPath $InstallerScript).Path
$installerReadmePath = (Resolve-Path -LiteralPath $InstallerReadme).Path
$installerReadmeHash = Get-Sha256 -Path $installerReadmePath
$translationLicensePath = Join-Path $releaseDirectoryPath 'INFO\LICENSE_RU.txt'
$translationLicenseHash = Get-Sha256 -Path $translationLicensePath

$actualReleaseFiles = @(
    Get-ChildItem -LiteralPath $releaseDirectoryPath -File -Recurse -Force |
        ForEach-Object { Get-RelativeSlashPath -Root $releaseDirectoryPath -Path $_.FullName }
)
Assert-ExactStringSet `
    -Actual $actualReleaseFiles `
    -Expected $allowedReleaseFiles `
    -Label 'public release allowlist'

$manifestPath = Join-Path $releaseDirectoryPath 'INFO\release-manifest.json'
$checksumsPath = Join-Path $releaseDirectoryPath 'INFO\SHA256SUMS.txt'
$payloadPath = Join-Path $releaseDirectoryPath 'Anvil-Russian-Full_P.pak'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$policy = Get-Content -LiteralPath $releasePolicyPath -Raw | ConvertFrom-Json
$toolchain = Get-Content -LiteralPath $toolchainPolicyPath -Raw | ConvertFrom-Json

Assert-Equal -Actual $manifest.schema -Expected 'anvil-russian-release/1' -Label 'release manifest schema'
Assert-Equal -Actual $policy.schema -Expected 'anvil-russian-release-policy/1' -Label 'release policy schema'
Assert-Equal -Actual $toolchain.schema -Expected 'anvil-russian-inno-toolchain/1' -Label 'toolchain policy schema'
Assert-Equal `
    -Actual ([string]$manifest.legal.translation_terms) `
    -Expected 'INFO/LICENSE_RU.txt' `
    -Label 'translation terms file'
Assert-Equal `
    -Actual ([string]$manifest.legal.third_party_notices) `
    -Expected 'INFO/THIRD-PARTY-NOTICES.txt' `
    -Label 'third-party notices file'
Assert-ExactStringSet `
    -Actual @($manifest.legal.third_party_licenses) `
    -Expected @('INFO/LICENSES/Apache-2.0.txt') `
    -Label 'third-party license files'
if ([int]$toolchain.compiler_tree_file_count -le 0) {
    throw 'Toolchain policy compiler_tree_file_count must be positive.'
}
if ($toolchain.compiler_tree_sha256 -notmatch '^[0-9a-f]{64}$') {
    throw 'Toolchain policy compiler_tree_sha256 must be lowercase SHA-256.'
}

$releasePolicyHash = Get-Sha256 -Path $releasePolicyPath
Assert-Equal `
    -Actual ([string]$manifest.verification.release_policy_sha256) `
    -Expected $releasePolicyHash `
    -Label 'release policy SHA-256'

$version = [string]$policy.release_version
if ($version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
    throw "Release version must use x.y.z form: '$version'"
}
Assert-Equal -Actual ([string]$manifest.release.version) -Expected $version -Label 'release version'

$steamPolicy = $policy.release_identity.steam
$pakPolicy = $policy.release_identity.pak
$executablePolicy = $policy.release_identity.native_executable
$depot = @($manifest.compatibility.depot_manifests)
Assert-Equal -Actual $depot.Count -Expected 1 -Label 'release depot count'

$steamAppId = [string]$steamPolicy.app_id
$steamBuildId = [string]$steamPolicy.build_id
$depotId = [string]$steamPolicy.depot_id
$depotManifestId = [string]$steamPolicy.depot_manifest_id
Assert-DecimalId -Value $steamAppId -Label 'Steam App ID'
Assert-DecimalId -Value $steamBuildId -Label 'Steam build ID'
Assert-DecimalId -Value $depotId -Label 'Steam depot ID'
Assert-DecimalId -Value $depotManifestId -Label 'Steam depot manifest ID'

Assert-Equal -Actual ([string]$manifest.compatibility.steam_app_id) -Expected $steamAppId -Label 'manifest Steam App ID'
Assert-Equal -Actual ([string]$manifest.compatibility.steam_build_id) -Expected $steamBuildId -Label 'manifest Steam build ID'
Assert-Equal -Actual ([string]$manifest.compatibility.game_language) -Expected 'english' -Label 'manifest game language'
Assert-Equal -Actual ([bool]$manifest.compatibility.strict_build_match) -Expected $true -Label 'strict build match'
Assert-Equal -Actual ([string]$depot[0].depot_id) -Expected $depotId -Label 'manifest depot ID'
Assert-Equal -Actual ([string]$depot[0].manifest_id) -Expected $depotManifestId -Label 'manifest depot manifest ID'

$payloadHash = Get-PolicySha256 -Value $pakPolicy.sha256 -Label 'policy PAK SHA-256'
$gameExeHash = Get-PolicySha256 -Value $executablePolicy.sha256 -Label 'policy executable SHA-256'
Assert-Equal -Actual ([string]$pakPolicy.file) -Expected 'Anvil-Russian-Full_P.pak' -Label 'policy PAK file'
Assert-Equal -Actual ([string]$manifest.payload.file) -Expected 'Anvil-Russian-Full_P.pak' -Label 'manifest PAK file'
Assert-Equal -Actual ([long]$manifest.payload.size) -Expected ([long]$pakPolicy.size) -Label 'manifest PAK size'
Assert-Equal -Actual ([string]$manifest.payload.sha256) -Expected $payloadHash -Label 'manifest PAK SHA-256'
Assert-Equal -Actual ([long]$manifest.compatibility.executable.size) -Expected ([long]$executablePolicy.size) -Label 'game executable size'
Assert-Equal -Actual ([string]$manifest.compatibility.executable.sha256) -Expected $gameExeHash -Label 'game executable SHA-256'

$payload = Get-Item -LiteralPath $payloadPath
Assert-Equal -Actual $payload.Length -Expected ([long]$pakPolicy.size) -Label 'PAK size'
Assert-Equal -Actual (Get-Sha256 -Path $payloadPath) -Expected $payloadHash -Label 'PAK SHA-256'

$checksumTable = @{}
foreach ($line in Get-Content -LiteralPath $checksumsPath) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }
    if ($line -notmatch '^([0-9a-f]{64})  ([^\\]+)$') {
        throw "Malformed SHA256SUMS.txt line: '$line'"
    }
    $relativePath = $Matches[2]
    if (
        [System.IO.Path]::IsPathRooted($relativePath) -or
        $relativePath.Split('/') -contains '..' -or
        $checksumTable.ContainsKey($relativePath)
    ) {
        throw "Unsafe or duplicate SHA256SUMS.txt member: '$relativePath'"
    }
    $checksumTable[$relativePath] = $Matches[1]
}
Assert-ExactStringSet `
    -Actual @($checksumTable.Keys) `
    -Expected $checksumMembers `
    -Label 'SHA256SUMS.txt members'
foreach ($relativePath in $checksumMembers) {
    $memberPath = Join-Path $releaseDirectoryPath $relativePath.Replace('/', '\')
    Assert-Equal `
        -Actual (Get-Sha256 -Path $memberPath) `
        -Expected $checksumTable[$relativePath] `
        -Label "SHA256SUMS.txt $relativePath"
}

$validation = [ordered]@{
    release_directory = $releaseDirectoryPath
    release_policy = $releasePolicyPath
    release_version = $version
    steam_app_id = $steamAppId
    steam_build_id = $steamBuildId
    payload_path = $payloadPath
    payload_size = [long]$payload.Length
    payload_sha256 = $payloadHash
    installer_script = $installerScriptPath
    installer_readme = $installerReadmePath
    installer_readme_sha256 = $installerReadmeHash
    translation_license = $translationLicensePath
    translation_license_sha256 = $translationLicenseHash
}
if ($ValidateOnly) {
    [pscustomobject]$validation
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Iscc)) {
    throw 'Iscc is required unless ValidateOnly is set.'
}
$isccPath = (Resolve-Path -LiteralPath $Iscc).Path
if ([System.IO.Path]::GetExtension($isccPath) -ine '.exe') {
    throw "ISCC must be an executable: $isccPath"
}
$compiler = Get-Item -LiteralPath $isccPath
Assert-Equal -Actual $compiler.Length -Expected ([long]$toolchain.compiler_size) -Label 'ISCC size'
Assert-Equal `
    -Actual (Get-Sha256 -Path $isccPath) `
    -Expected ([string]$toolchain.compiler_sha256) `
    -Label 'ISCC SHA-256'
$compilerSignature = Get-AuthenticodeSignature -LiteralPath $isccPath
if ($compilerSignature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
    throw "ISCC Authenticode signature is not valid: $($compilerSignature.Status)"
}
if (([string]$compilerSignature.SignerCertificate.Subject).IndexOf(
        [string]$toolchain.authenticode_subject_contains,
        [StringComparison]::OrdinalIgnoreCase
    ) -lt 0) {
    throw "Unexpected ISCC signer: '$($compilerSignature.SignerCertificate.Subject)'"
}
$toolchainRoot = Split-Path -Parent $isccPath
$treeIdentity = Get-DirectoryTreeIdentity -Root $toolchainRoot
Assert-Equal `
    -Actual $treeIdentity.file_count `
    -Expected ([int]$toolchain.compiler_tree_file_count) `
    -Label 'portable toolchain file count'
Assert-Equal `
    -Actual $treeIdentity.sha256 `
    -Expected ([string]$toolchain.compiler_tree_sha256) `
    -Label 'portable toolchain tree SHA-256'

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
$outputRootPath = (Resolve-Path -LiteralPath $OutputRoot).Path
$outputBaseName = "Anvil-Empires-Russian-v$version-Setup"
$setupName = "$outputBaseName.exe"
$checksumName = "$setupName.sha256"
$installerManifestName = "$outputBaseName.manifest.json"
$finalSetupPath = Join-Path $outputRootPath $setupName
$finalChecksumPath = Join-Path $outputRootPath $checksumName
$finalInstallerManifestPath = Join-Path $outputRootPath $installerManifestName
foreach ($target in @($finalSetupPath, $finalChecksumPath, $finalInstallerManifestPath)) {
    if (Test-Path -LiteralPath $target) {
        throw "Refusing to overwrite installer output: $target"
    }
}

$stagingDirectory = Join-Path $outputRootPath ('.installer-staging-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stagingDirectory | Out-Null
try {
    $compilerArguments = @(
        '/Qp',
        "/O$stagingDirectory",
        "/F$outputBaseName",
        "/DAppVersion=$version",
        "/DReleaseDirectory=$releaseDirectoryPath",
        "/DPayloadPath=$payloadPath",
        "/DOutputDirectory=$stagingDirectory",
        "/DOutputBaseFilename=$outputBaseName",
        "/DSteamAppId=$steamAppId",
        "/DSteamBuildId=$steamBuildId",
        "/DDepotId=$depotId",
        "/DDepotManifestId=$depotManifestId",
        "/DGameExeSize=$([long]$executablePolicy.size)",
        "/DGameExeSha256=$gameExeHash",
        "/DPayloadSize=$([long]$pakPolicy.size)",
        "/DPayloadSha256=$payloadHash",
        "/DInstallerReadmePath=$installerReadmePath",
        "/DInstallerReadmeSha256=$installerReadmeHash",
        "/DTranslationLicensePath=$translationLicensePath",
        "/DTranslationLicenseSha256=$translationLicenseHash",
        $installerScriptPath
    )
    $compilerOutput = & $isccPath @compilerArguments 2>&1
    $compilerExitCode = $LASTEXITCODE
    if ($compilerExitCode -ne 0) {
        $compilerText = (@($compilerOutput) | ForEach-Object { [string]$_ }) -join "`n"
        throw "ISCC failed with exit code $compilerExitCode`n$compilerText"
    }

    $stagedSetupPath = Join-Path $stagingDirectory $setupName
    if (-not (Test-Path -LiteralPath $stagedSetupPath -PathType Leaf)) {
        throw "ISCC did not produce expected installer: $stagedSetupPath"
    }
    $setup = Get-Item -LiteralPath $stagedSetupPath
    if ($setup.Length -le 0) {
        throw 'ISCC produced an empty installer.'
    }
    $setupSignature = Get-AuthenticodeSignature -LiteralPath $stagedSetupPath
    if ($setupSignature.Status -ne [System.Management.Automation.SignatureStatus]::NotSigned) {
        throw "Unsigned build unexpectedly has Authenticode status '$($setupSignature.Status)'."
    }
    $setupHash = Get-Sha256 -Path $stagedSetupPath

    $installerManifest = [ordered]@{
        schema = 'anvil-russian-installer/1'
        release = [ordered]@{
            version = $version
            steam_app_id = $steamAppId
            steam_build_id = $steamBuildId
            release_manifest_sha256 = Get-Sha256 -Path $manifestPath
            release_policy_sha256 = $releasePolicyHash
        }
        payload = [ordered]@{
            file = 'Anvil-Russian-Full_P.pak'
            size = [long]$payload.Length
            sha256 = $payloadHash
        }
        legal = [ordered]@{
            translation_terms_file = 'INFO/LICENSE_RU.txt'
            translation_terms_sha256 = $translationLicenseHash
        }
        installer = [ordered]@{
            file = $setupName
            size = [long]$setup.Length
            sha256 = $setupHash
            authenticode = 'unsigned'
            source_sha256 = Get-Sha256 -Path $installerScriptPath
            readme_sha256 = $installerReadmeHash
        }
        compiler = [ordered]@{
            name = [string]$toolchain.name
            version = [string]$toolchain.version
            architecture = [string]$toolchain.architecture
            executable_sha256 = Get-Sha256 -Path $isccPath
            tree_file_count = [int]$treeIdentity.file_count
            tree_sha256 = [string]$treeIdentity.sha256
            policy_sha256 = Get-Sha256 -Path $toolchainPolicyPath
        }
    }
    $stagedManifestPath = Join-Path $stagingDirectory $installerManifestName
    $manifestJson = $installerManifest | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText(
        $stagedManifestPath,
        $manifestJson.Replace("`r`n", "`n") + "`n",
        [System.Text.UTF8Encoding]::new($false)
    )
    $stagedChecksumPath = Join-Path $stagingDirectory $checksumName
    [System.IO.File]::WriteAllText(
        $stagedChecksumPath,
        "$setupHash  $setupName`n",
        [System.Text.UTF8Encoding]::new($false)
    )

    [System.IO.File]::Move($stagedManifestPath, $finalInstallerManifestPath)
    [System.IO.File]::Move($stagedChecksumPath, $finalChecksumPath)
    [System.IO.File]::Move($stagedSetupPath, $finalSetupPath)

    [pscustomobject]@{
        setup = $finalSetupPath
        size = [long]$setup.Length
        sha256 = $setupHash
        checksum = $finalChecksumPath
        manifest = $finalInstallerManifestPath
        signed = $false
    }
} finally {
    if (Test-Path -LiteralPath $stagingDirectory) {
        $resolvedStaging = [System.IO.Path]::GetFullPath($stagingDirectory)
        $resolvedParent = [System.IO.Path]::GetDirectoryName($resolvedStaging)
        if (-not $resolvedParent.Equals($outputRootPath, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean unexpected staging path: $resolvedStaging"
        }
        [System.IO.Directory]::Delete($resolvedStaging, $true)
    }
}

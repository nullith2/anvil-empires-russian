[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $ReleaseZip,

    [string] $BuildPolicy,

    [string] $OutputRoot,

    [string] $BootstrapScript,

    [string] $BuildScript
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string] $Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-RequiredProperty {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Label
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        throw "$Label does not contain required property '$Name'."
    }
    return $property.Value
}

function Get-PositiveInt64 {
    param(
        [Parameter(Mandatory = $true)] $Value,
        [Parameter(Mandatory = $true)][string] $Label
    )

    try {
        $number = [Convert]::ToInt64(
            $Value,
            [Globalization.CultureInfo]::InvariantCulture
        )
    } catch {
        throw "$Label must be an integer."
    }
    if ($number -le 0) {
        throw "$Label must be positive."
    }
    return $number
}

function Get-LowercaseSha256 {
    param(
        [Parameter(Mandatory = $true)] $Value,
        [Parameter(Mandatory = $true)][string] $Label
    )

    $text = [string]$Value
    if ($text -notmatch '^[0-9a-f]{64}$') {
        throw "$Label must be a lowercase SHA-256 value."
    }
    return $text
}

function Assert-SafeLeafName {
    param(
        [Parameter(Mandatory = $true)][string] $Value,
        [Parameter(Mandatory = $true)][string] $Label
    )

    if (
        [string]::IsNullOrWhiteSpace($Value) -or
        [IO.Path]::IsPathRooted($Value) -or
        ([IO.Path]::GetFileName($Value) -cne $Value) -or
        ($Value -eq '.') -or
        ($Value -eq '..') -or
        ($Value.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0)
    ) {
        throw "$Label must be a safe file name without a directory: '$Value'"
    }
}

function Assert-SafeMemberPath {
    param(
        [Parameter(Mandatory = $true)][string] $Value,
        [Parameter(Mandatory = $true)][string] $Label
    )

    if (
        [string]::IsNullOrWhiteSpace($Value) -or
        [IO.Path]::IsPathRooted($Value) -or
        $Value.StartsWith('/', [StringComparison]::Ordinal) -or
        $Value.EndsWith('/', [StringComparison]::Ordinal) -or
        ($Value.IndexOf('\') -ge 0) -or
        ($Value.IndexOf([char]0) -ge 0)
    ) {
        throw "$Label is not a safe relative slash path: '$Value'"
    }

    foreach ($segment in $Value.Split('/')) {
        if (
            [string]::IsNullOrWhiteSpace($segment) -or
            ($segment -eq '.') -or
            ($segment -eq '..') -or
            ($segment.IndexOf(':') -ge 0)
        ) {
            throw "$Label contains an unsafe path segment: '$Value'"
        }
    }
}

function Assert-ChildPath {
    param(
        [Parameter(Mandatory = $true)][string] $Parent,
        [Parameter(Mandatory = $true)][string] $Child,
        [Parameter(Mandatory = $true)][string] $Label
    )

    $parentPath = [IO.Path]::GetFullPath($Parent).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $childPath = [IO.Path]::GetFullPath($Child)
    $prefix = $parentPath + [IO.Path]::DirectorySeparatorChar
    if (-not $childPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label escapes its intended parent: '$childPath'"
    }
    return $childPath
}

function Resolve-RequiredFile {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Label
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label does not exist: $Path"
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Test-ExactStringSet {
    param(
        [Parameter(Mandatory = $true)][string[]] $Actual,
        [Parameter(Mandatory = $true)][string[]] $Expected
    )

    if ($Actual.Count -ne $Expected.Count) {
        return $false
    }
    [string[]]$actualSorted = @($Actual)
    [string[]]$expectedSorted = @($Expected)
    [Array]::Sort($actualSorted, [StringComparer]::Ordinal)
    [Array]::Sort($expectedSorted, [StringComparer]::Ordinal)
    for ($index = 0; $index -lt $actualSorted.Count; $index++) {
        if ($actualSorted[$index] -cne $expectedSorted[$index]) {
            return $false
        }
    }
    return $true
}

function Assert-ExactStringSet {
    param(
        [Parameter(Mandatory = $true)][string[]] $Actual,
        [Parameter(Mandatory = $true)][string[]] $Expected,
        [Parameter(Mandatory = $true)][string] $Label
    )

    if (-not (Test-ExactStringSet -Actual $Actual -Expected $Expected)) {
        [string[]]$actualSorted = @($Actual)
        [string[]]$expectedSorted = @($Expected)
        [Array]::Sort($actualSorted, [StringComparer]::Ordinal)
        [Array]::Sort($expectedSorted, [StringComparer]::Ordinal)
        throw "$Label mismatch.`nExpected: $($expectedSorted -join ', ')`nActual: $($actualSorted -join ', ')"
    }
}

function Test-ArchiveChecksums {
    param(
        [Parameter(Mandatory = $true)][string] $ReleaseDirectory,
        [Parameter(Mandatory = $true)][string[]] $Members,
        [Parameter(Mandatory = $true)][string] $ChecksumMember
    )

    $expectedMembers = @($Members | Where-Object { $_ -cne $ChecksumMember })
    $checksumPath = Join-Path $ReleaseDirectory $ChecksumMember.Replace('/', '\')
    $checksumTable = @{}
    foreach ($line in Get-Content -LiteralPath $checksumPath) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        if ($line -notmatch '^([0-9a-f]{64})  ([^\\]+)$') {
            throw "Malformed release ZIP checksum line: '$line'"
        }
        $member = $Matches[2]
        Assert-SafeMemberPath -Value $member -Label 'release ZIP checksum member'
        if ($checksumTable.ContainsKey($member)) {
            throw "Duplicate release ZIP checksum member: '$member'"
        }
        $checksumTable[$member] = $Matches[1]
    }

    Assert-ExactStringSet `
        -Actual @($checksumTable.Keys) `
        -Expected $expectedMembers `
        -Label 'release ZIP checksum members'

    foreach ($member in $expectedMembers) {
        $memberPath = Assert-ChildPath `
            -Parent $ReleaseDirectory `
            -Child (Join-Path $ReleaseDirectory $member.Replace('/', '\')) `
            -Label 'release ZIP checksum target'
        $actualHash = Get-Sha256 -Path $memberPath
        if ($actualHash -ne [string]$checksumTable[$member]) {
            throw "Release ZIP member SHA-256 mismatch: '$member'"
        }
    }
}

$containerDirectory = Split-Path -Parent $PSScriptRoot
$projectRootCandidate = Split-Path -Parent $containerDirectory
if (Test-Path -LiteralPath (Join-Path $projectRootCandidate 'scripts\build-installer.ps1')) {
    $projectRoot = $projectRootCandidate
} else {
    $projectRoot = $containerDirectory
}

if ([string]::IsNullOrWhiteSpace($BuildPolicy)) {
    $BuildPolicy = Join-Path $PSScriptRoot 'reproducible-build.json'
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $projectRoot 'out'
}
if ([string]::IsNullOrWhiteSpace($BootstrapScript)) {
    $siblingBootstrap = Join-Path $PSScriptRoot 'bootstrap-inno.ps1'
    if (Test-Path -LiteralPath $siblingBootstrap -PathType Leaf) {
        $BootstrapScript = $siblingBootstrap
    } else {
        $BootstrapScript = Join-Path $projectRoot 'scripts\bootstrap-inno.ps1'
    }
}
if ([string]::IsNullOrWhiteSpace($BuildScript)) {
    $siblingBuilder = Join-Path $PSScriptRoot 'build-installer.ps1'
    if (Test-Path -LiteralPath $siblingBuilder -PathType Leaf) {
        $BuildScript = $siblingBuilder
    } else {
        $BuildScript = Join-Path $projectRoot 'scripts\build-installer.ps1'
    }
}

$releaseZipPath = Resolve-RequiredFile -Path $ReleaseZip -Label 'release ZIP'
$buildPolicyPath = Resolve-RequiredFile -Path $BuildPolicy -Label 'reproducible build policy'
$bootstrapScriptPath = Resolve-RequiredFile -Path $BootstrapScript -Label 'Inno bootstrap script'
$buildScriptPath = Resolve-RequiredFile -Path $BuildScript -Label 'installer build script'
$installerScriptPath = Resolve-RequiredFile `
    -Path (Join-Path $PSScriptRoot 'Anvil-Empires-Russian.iss') `
    -Label 'Inno installer source'
$installerReadmePath = Resolve-RequiredFile `
    -Path (Join-Path $PSScriptRoot 'README_INSTALLER_RU.txt') `
    -Label 'installer README'
$toolchainPolicyPath = Resolve-RequiredFile `
    -Path (Join-Path $PSScriptRoot 'inno-toolchain-v7.0.2.json') `
    -Label 'Inno toolchain policy'

$policy = Get-Content -LiteralPath $buildPolicyPath -Raw | ConvertFrom-Json
$schema = [string](Get-RequiredProperty -Object $policy -Name 'schema' -Label 'build policy')
if ($schema -ne 'anvil-russian-reproducible-build/1') {
    throw "Unsupported reproducible build policy schema: '$schema'"
}

$version = [string](Get-RequiredProperty -Object $policy -Name 'version' -Label 'build policy')
if ($version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
    throw "Build policy version must use x.y.z form: '$version'"
}
$zipPolicy = Get-RequiredProperty -Object $policy -Name 'release_zip' -Label 'build policy'
$setupPolicy = Get-RequiredProperty -Object $policy -Name 'setup' -Label 'build policy'

$expectedZipFile = [string](Get-RequiredProperty -Object $zipPolicy -Name 'file' -Label 'release_zip')
Assert-SafeLeafName -Value $expectedZipFile -Label 'release_zip.file'
$expectedZipSize = Get-PositiveInt64 `
    -Value (Get-RequiredProperty -Object $zipPolicy -Name 'size' -Label 'release_zip') `
    -Label 'release_zip.size'
$expectedZipHash = Get-LowercaseSha256 `
    -Value (Get-RequiredProperty -Object $zipPolicy -Name 'sha256' -Label 'release_zip') `
    -Label 'release_zip.sha256'
$archiveRoot = [string](Get-RequiredProperty -Object $zipPolicy -Name 'root' -Label 'release_zip')
Assert-SafeLeafName -Value $archiveRoot -Label 'release_zip.root'

$membersValue = Get-RequiredProperty -Object $zipPolicy -Name 'members' -Label 'release_zip'
[string[]]$policyMembers = @($membersValue | ForEach-Object { [string]$_ })
if ($policyMembers.Count -ne 8) {
    throw "release_zip.members must contain exactly 8 files; got $($policyMembers.Count)."
}
$memberNames = @{}
foreach ($member in $policyMembers) {
    Assert-SafeMemberPath -Value $member -Label 'release_zip.members entry'
    if ($memberNames.ContainsKey($member)) {
        throw "release_zip.members contains a duplicate Windows path: '$member'"
    }
    $memberNames[$member] = $true
}

$expectedSetupFile = [string](Get-RequiredProperty -Object $setupPolicy -Name 'file' -Label 'setup')
Assert-SafeLeafName -Value $expectedSetupFile -Label 'setup.file'
$expectedSetupSize = Get-PositiveInt64 `
    -Value (Get-RequiredProperty -Object $setupPolicy -Name 'size' -Label 'setup') `
    -Label 'setup.size'
$expectedSetupHash = Get-LowercaseSha256 `
    -Value (Get-RequiredProperty -Object $setupPolicy -Name 'sha256' -Label 'setup') `
    -Label 'setup.sha256'

$derivedSetupFile = "Anvil-Empires-Russian-v$version-Setup.exe"
if ($expectedSetupFile -cne $derivedSetupFile) {
    throw "setup.file mismatch: version '$version' requires '$derivedSetupFile'."
}
if ([IO.Path]::GetFileName($releaseZipPath) -cne $expectedZipFile) {
    throw "Release ZIP file name mismatch: expected '$expectedZipFile'."
}
$releaseZipItem = Get-Item -LiteralPath $releaseZipPath
if ($releaseZipItem.Length -ne $expectedZipSize) {
    throw "Release ZIP size mismatch: expected $expectedZipSize, got $($releaseZipItem.Length)."
}
$actualZipHash = Get-Sha256 -Path $releaseZipPath
if ($actualZipHash -ne $expectedZipHash) {
    throw "Release ZIP SHA-256 mismatch: expected $expectedZipHash, got $actualZipHash."
}

[string[]]$infoLayoutMembers = @(
    'Anvil-Russian-Full_P.pak',
    'INFO/LICENSE_RU.txt',
    'INFO/LICENSES/Apache-2.0.txt',
    'INFO/SHA256SUMS.txt',
    'INFO/THIRD-PARTY-NOTICES.txt',
    'INFO/release-manifest.json',
    'README_RU.txt',
    'RELEASE_NOTES_RU.txt'
)
Assert-ExactStringSet `
    -Actual $policyMembers `
    -Expected $infoLayoutMembers `
    -Label 'release_zip.members layout'

$releasePolicyName = "release-policy-v$version.json"
$releasePolicyCandidate = Join-Path $PSScriptRoot $releasePolicyName
if (-not (Test-Path -LiteralPath $releasePolicyCandidate -PathType Leaf)) {
    $releasePolicyCandidate = Join-Path $projectRoot "packaging\public\$releasePolicyName"
}
$releasePolicyPath = Resolve-RequiredFile `
    -Path $releasePolicyCandidate `
    -Label "release policy for v$version"

$buildRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot '.build'))
if (-not (Test-Path -LiteralPath $buildRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $buildRoot | Out-Null
}
$buildRoot = (Resolve-Path -LiteralPath $buildRoot).Path
$buildRootItem = Get-Item -LiteralPath $buildRoot -Force
if (($buildRootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "Refusing to use a reparse-point build directory: $buildRoot"
}

$stagingName = 'release-staging-' + [Guid]::NewGuid().ToString('N')
$stagingRoot = Assert-ChildPath `
    -Parent $buildRoot `
    -Child (Join-Path $buildRoot $stagingName) `
    -Label 'release staging directory'
$archiveReleaseDirectory = Assert-ChildPath `
    -Parent $stagingRoot `
    -Child (Join-Path $stagingRoot $archiveRoot) `
    -Label 'archive release directory'
$outputRootPath = [IO.Path]::GetFullPath($OutputRoot)
$downloadRoot = Join-Path $buildRoot 'downloads'
$toolRoot = Join-Path $buildRoot 'tools'

New-Item -ItemType Directory -Path $stagingRoot | Out-Null
try {
    New-Item -ItemType Directory -Path $archiveReleaseDirectory | Out-Null

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($releaseZipPath)
    try {
        $rootPrefix = $archiveRoot + '/'
        $actualArchiveMembers = New-Object System.Collections.Generic.List[string]
        $seenEntries = @{}

        foreach ($entry in $archive.Entries) {
            if ([string]::IsNullOrEmpty($entry.Name)) {
                throw "Release ZIP contains an unexpected directory entry: '$($entry.FullName)'"
            }
            if ($seenEntries.ContainsKey($entry.FullName)) {
                throw "Release ZIP contains a duplicate Windows path: '$($entry.FullName)'"
            }
            $seenEntries[$entry.FullName] = $true
            if (-not $entry.FullName.StartsWith($rootPrefix, [StringComparison]::Ordinal)) {
                throw "Release ZIP member is outside the expected root '$archiveRoot': '$($entry.FullName)'"
            }

            $relativeMember = $entry.FullName.Substring($rootPrefix.Length)
            Assert-SafeMemberPath -Value $relativeMember -Label 'release ZIP member'
            $actualArchiveMembers.Add($relativeMember)

            $destinationPath = Assert-ChildPath `
                -Parent $archiveReleaseDirectory `
                -Child (Join-Path $archiveReleaseDirectory $relativeMember.Replace('/', '\')) `
                -Label 'release ZIP extraction target'
            $destinationParent = Split-Path -Parent $destinationPath
            if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
                New-Item -ItemType Directory -Path $destinationParent | Out-Null
            }

            $inputStream = $entry.Open()
            try {
                $outputStream = [IO.File]::Open(
                    $destinationPath,
                    [IO.FileMode]::CreateNew,
                    [IO.FileAccess]::Write,
                    [IO.FileShare]::None
                )
                try {
                    $inputStream.CopyTo($outputStream)
                } finally {
                    $outputStream.Dispose()
                }
            } finally {
                $inputStream.Dispose()
            }

            if ((Get-Item -LiteralPath $destinationPath).Length -ne $entry.Length) {
                throw "Extracted release ZIP member size mismatch: '$relativeMember'"
            }
        }

        Assert-ExactStringSet `
            -Actual $actualArchiveMembers.ToArray() `
            -Expected $policyMembers `
            -Label 'release ZIP member allowlist'
    } finally {
        $archive.Dispose()
    }

    Test-ArchiveChecksums `
        -ReleaseDirectory $archiveReleaseDirectory `
        -Members $policyMembers `
        -ChecksumMember 'INFO/SHA256SUMS.txt'

    $bootstrapOutput = @(
        & $bootstrapScriptPath `
            -ToolchainPolicy $toolchainPolicyPath `
            -DownloadRoot $downloadRoot `
            -ToolRoot $toolRoot
    )
    $isccCandidates = @(
        $bootstrapOutput |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    if ($isccCandidates.Count -eq 0) {
        throw 'Inno bootstrap did not return an ISCC.exe path.'
    }
    $isccPath = Resolve-RequiredFile `
        -Path $isccCandidates[$isccCandidates.Count - 1] `
        -Label 'bootstrapped ISCC.exe'

    $buildOutput = @(
        & $buildScriptPath `
            -ReleaseDirectory $archiveReleaseDirectory `
            -ReleasePolicy $releasePolicyPath `
            -Iscc $isccPath `
            -ToolchainPolicy $toolchainPolicyPath `
            -InstallerScript $installerScriptPath `
            -InstallerReadme $installerReadmePath `
            -OutputRoot $outputRootPath
    )

    $setupPath = Join-Path $outputRootPath $expectedSetupFile
    if (-not (Test-Path -LiteralPath $setupPath -PathType Leaf)) {
        throw "Installer build did not produce expected Setup: $setupPath"
    }
    $setupItem = Get-Item -LiteralPath $setupPath
    if ($setupItem.Length -ne $expectedSetupSize) {
        throw "Setup size mismatch: expected $expectedSetupSize, got $($setupItem.Length)."
    }
    $actualSetupHash = Get-Sha256 -Path $setupPath
    if ($actualSetupHash -ne $expectedSetupHash) {
        throw "Setup SHA-256 mismatch: expected $expectedSetupHash, got $actualSetupHash."
    }

    [pscustomobject]@{
        verified = $true
        version = $version
        release_zip = $releaseZipPath
        release_zip_sha256 = $actualZipHash
        setup = $setupPath
        setup_size = [long]$setupItem.Length
        setup_sha256 = $actualSetupHash
        compiler = $isccPath
    }
} finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        $resolvedStaging = (Resolve-Path -LiteralPath $stagingRoot).Path
        $resolvedParent = Split-Path -Parent $resolvedStaging
        $resolvedName = Split-Path -Leaf $resolvedStaging
        if (
            (-not $resolvedParent.Equals($buildRoot, [StringComparison]::OrdinalIgnoreCase)) -or
            (-not $resolvedName.StartsWith('release-staging-', [StringComparison]::Ordinal))
        ) {
            throw "Refusing to clean unexpected staging directory: $resolvedStaging"
        }
        [IO.Directory]::Delete($resolvedStaging, $true)
    }
}

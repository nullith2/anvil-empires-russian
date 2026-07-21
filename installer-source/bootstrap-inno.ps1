[CmdletBinding()]
param(
    [string] $ToolchainPolicy,
    [string] $DownloadRoot,
    [string] $ToolRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ToolchainPolicy)) {
    $ToolchainPolicy = Join-Path $projectRoot 'packaging\installer\inno-toolchain-v7.0.2.json'
}
if ([string]::IsNullOrWhiteSpace($DownloadRoot)) {
    $DownloadRoot = Join-Path $projectRoot 'work\downloads'
}
if ([string]::IsNullOrWhiteSpace($ToolRoot)) {
    $ToolRoot = Join-Path $projectRoot 'work\tools'
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string] $Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
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

function Assert-PortableToolchain {
    param(
        [Parameter(Mandatory = $true)][string] $PortableDirectory,
        [Parameter(Mandatory = $true)][string] $IsccPath,
        [Parameter(Mandatory = $true)] $Policy
    )

    if (-not (Test-Path -LiteralPath $IsccPath -PathType Leaf)) {
        throw "Portable toolchain does not contain ISCC.exe: $IsccPath"
    }

    $compiler = Get-Item -LiteralPath $IsccPath
    if ($compiler.Length -ne [long]$Policy.compiler_size) {
        throw "ISCC.exe size mismatch: expected $($Policy.compiler_size), got $($compiler.Length)"
    }
    $compilerHash = Get-Sha256 -Path $IsccPath
    if ($compilerHash -ne [string]$Policy.compiler_sha256) {
        throw "ISCC.exe SHA-256 mismatch: expected $($Policy.compiler_sha256), got $compilerHash"
    }

    $compilerSignature = Get-AuthenticodeSignature -LiteralPath $IsccPath
    if ($compilerSignature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
        throw "ISCC.exe Authenticode signature is not valid: $($compilerSignature.Status)"
    }
    if (([string]$compilerSignature.SignerCertificate.Subject).IndexOf(
            [string]$Policy.authenticode_subject_contains,
            [StringComparison]::OrdinalIgnoreCase
        ) -lt 0) {
        throw "Unexpected ISCC.exe signer: '$($compilerSignature.SignerCertificate.Subject)'"
    }

    $treeIdentity = Get-DirectoryTreeIdentity -Root $PortableDirectory
    if ($treeIdentity.file_count -ne [int]$Policy.compiler_tree_file_count) {
        throw "Portable toolchain file count mismatch: expected $($Policy.compiler_tree_file_count), got $($treeIdentity.file_count)"
    }
    if ($treeIdentity.sha256 -ne [string]$Policy.compiler_tree_sha256) {
        throw "Portable toolchain tree SHA-256 mismatch: expected $($Policy.compiler_tree_sha256), got $($treeIdentity.sha256)"
    }
}

function Assert-ChildPath {
    param(
        [Parameter(Mandatory = $true)][string] $Parent,
        [Parameter(Mandatory = $true)][string] $Child,
        [Parameter(Mandatory = $true)][string] $Label
    )

    $parentPath = [System.IO.Path]::GetFullPath($Parent).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    $childPath = [System.IO.Path]::GetFullPath($Child)
    $prefix = $parentPath + [System.IO.Path]::DirectorySeparatorChar
    if (-not $childPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label escapes its intended parent: '$childPath'"
    }
    return $childPath
}

$policyPath = (Resolve-Path -LiteralPath $ToolchainPolicy).Path
$policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
if ($policy.schema -ne 'anvil-russian-inno-toolchain/1') {
    throw "Unsupported Inno toolchain policy schema: '$($policy.schema)'"
}
if ($policy.version -notmatch '^7\.[0-9]+\.[0-9]+$') {
    throw "Unsupported Inno Setup version: '$($policy.version)'"
}
if ($policy.download_sha256 -notmatch '^[0-9a-f]{64}$') {
    throw 'Toolchain policy download_sha256 must be lowercase SHA-256.'
}
if ([long]$policy.download_size -le 0) {
    throw 'Toolchain policy download_size must be positive.'
}
if ([int]$policy.compiler_tree_file_count -le 0) {
    throw 'Toolchain policy compiler_tree_file_count must be positive.'
}
if ($policy.compiler_tree_sha256 -notmatch '^[0-9a-f]{64}$') {
    throw 'Toolchain policy compiler_tree_sha256 must be lowercase SHA-256.'
}

New-Item -ItemType Directory -Path $DownloadRoot -Force | Out-Null
New-Item -ItemType Directory -Path $ToolRoot -Force | Out-Null
$downloadRootPath = (Resolve-Path -LiteralPath $DownloadRoot).Path
$toolRootPath = (Resolve-Path -LiteralPath $ToolRoot).Path

$installerName = "innosetup-$($policy.version)-$($policy.architecture).exe"
$installerPath = Assert-ChildPath `
    -Parent $downloadRootPath `
    -Child (Join-Path $downloadRootPath $installerName) `
    -Label 'download path'
$portableDirectory = Assert-ChildPath `
    -Parent $toolRootPath `
    -Child (Join-Path $toolRootPath "inno-setup-$($policy.version)-$($policy.architecture)") `
    -Label 'portable tool path'
$isccPath = Join-Path $portableDirectory ([string]$policy.compiler_file)

if (Test-Path -LiteralPath $isccPath -PathType Leaf) {
    Assert-PortableToolchain `
        -PortableDirectory $portableDirectory `
        -IsccPath $isccPath `
        -Policy $policy
    Write-Output $isccPath
    exit 0
}

if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    Invoke-WebRequest `
        -Uri ([string]$policy.download_url) `
        -OutFile $installerPath `
        -UseBasicParsing
}

$download = Get-Item -LiteralPath $installerPath
if ($download.Length -ne [long]$policy.download_size) {
    throw "Inno Setup download size mismatch: expected $($policy.download_size), got $($download.Length)"
}
$downloadHash = Get-Sha256 -Path $installerPath
if ($downloadHash -ne [string]$policy.download_sha256) {
    throw "Inno Setup download SHA-256 mismatch: expected $($policy.download_sha256), got $downloadHash"
}

$signature = Get-AuthenticodeSignature -LiteralPath $installerPath
if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
    throw "Inno Setup Authenticode signature is not valid: $($signature.Status)"
}
$signerSubject = [string]$signature.SignerCertificate.Subject
if ($signerSubject.IndexOf(
        [string]$policy.authenticode_subject_contains,
        [StringComparison]::OrdinalIgnoreCase
    ) -lt 0) {
    throw "Unexpected Inno Setup signer: '$signerSubject'"
}

if (Test-Path -LiteralPath $portableDirectory) {
    $existingEntries = @(Get-ChildItem -LiteralPath $portableDirectory -Force)
    if ($existingEntries.Count -ne 0) {
        throw "Portable tool directory exists and is not empty: $portableDirectory"
    }
} else {
    New-Item -ItemType Directory -Path $portableDirectory | Out-Null
}

$portableArguments = @($policy.portable_arguments | ForEach-Object { [string]$_ })
$portableArguments += ('/DIR="' + $portableDirectory + '"')
$process = Start-Process `
    -FilePath $installerPath `
    -ArgumentList $portableArguments `
    -Wait `
    -PassThru `
    -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "Portable Inno Setup extraction failed with exit code $($process.ExitCode)."
}
if (-not (Test-Path -LiteralPath $isccPath -PathType Leaf)) {
    throw "Portable extraction did not produce ISCC.exe: $isccPath"
}

Assert-PortableToolchain `
    -PortableDirectory $portableDirectory `
    -IsccPath $isccPath `
    -Policy $policy

Write-Output $isccPath

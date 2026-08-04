[CmdletBinding()]
param(
    [string]$Serial = "",
    [string]$AdbPath = "",
    [string]$ModelPath = "",
    [switch]$PrepareOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol =
        [Net.SecurityProtocolType]::Tls12

$installerDirectory = $PSScriptRoot
$manifestPath = Join-Path $installerDirectory "release-manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Release manifest is missing: $manifestPath"
}
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$cacheRoot = Join-Path $env:LOCALAPPDATA "LocalFlow\InstallerCache"
New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Test-VerifiedFile(
    [string]$Path,
    [long]$ExpectedBytes,
    [string]$ExpectedSha256
) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }
    $file = Get-Item -LiteralPath $Path
    if ($file.Length -ne $ExpectedBytes) {
        return $false
    }
    return (Get-Sha256 $Path) -eq $ExpectedSha256.ToLowerInvariant()
}

function Get-VerifiedDownload(
    [string]$Url,
    [string]$Destination,
    [long]$ExpectedBytes,
    [string]$ExpectedSha256
) {
    if (Test-VerifiedFile $Destination $ExpectedBytes $ExpectedSha256) {
        Write-Host "Using verified cache: $Destination"
        return $Destination
    }
    if (Test-Path -LiteralPath $Destination) {
        Write-Host "Removing an invalid cached file: $Destination"
        Remove-Item -Force -LiteralPath $Destination
    }

    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $partial = "$Destination.part"
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($null -ne $curl) {
        Write-Host "Downloading from the pinned upstream URL..."
        & $curl.Source `
            --location `
            --fail `
            --retry 3 `
            --retry-delay 2 `
            --continue-at - `
            --output $partial `
            $Url
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Resume failed; retrying this file from the beginning."
            if (Test-Path -LiteralPath $partial) {
                Remove-Item -Force -LiteralPath $partial
            }
            & $curl.Source `
                --location `
                --fail `
                --retry 3 `
                --retry-delay 2 `
                --output $partial `
                $Url
            if ($LASTEXITCODE -ne 0) {
                throw "Download failed: $Url"
            }
        }
    } else {
        Write-Host "curl.exe is unavailable; using Windows BITS."
        Import-Module BitsTransfer -ErrorAction Stop
        Start-BitsTransfer -Source $Url -Destination $partial
    }

    if (-not (Test-VerifiedFile $partial $ExpectedBytes $ExpectedSha256)) {
        $actualBytes = if (Test-Path -LiteralPath $partial) {
            (Get-Item -LiteralPath $partial).Length
        } else {
            0
        }
        $actualHash = if (Test-Path -LiteralPath $partial) {
            Get-Sha256 $partial
        } else {
            "missing"
        }
        throw "Downloaded file verification failed " +
                "(bytes=$actualBytes, SHA-256=$actualHash)."
    }
    Move-Item -Force -LiteralPath $partial -Destination $Destination
    Write-Host "Verified SHA-256: $ExpectedSha256"
    return $Destination
}

function Remove-InstallerCacheDirectory([string]$Path) {
    $resolvedCache = [IO.Path]::GetFullPath($cacheRoot).TrimEnd('\') + '\'
    $resolvedTarget = [IO.Path]::GetFullPath($Path).TrimEnd('\') + '\'
    if (-not $resolvedTarget.StartsWith(
            $resolvedCache,
            [StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Refusing to remove a directory outside the installer cache: $Path"
    }
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -Recurse -Force -LiteralPath $Path
    }
}

Write-Step "Verifying the signed LocalFlow APK"
$apkPath = Join-Path $installerDirectory $manifest.apk.fileName
if (-not (Test-VerifiedFile `
        $apkPath `
        ([long]$manifest.apk.bytes) `
        $manifest.apk.sha256
)) {
    throw "The APK is missing or does not match release-manifest.json: $apkPath"
}
Write-Host "APK: $($manifest.apk.fileName)"
Write-Host "SHA-256: $($manifest.apk.sha256)"

if (-not $AdbPath) {
    $toolsRevision = $manifest.platformTools.revision
    $toolsArchive = Join-Path `
            $cacheRoot `
            $manifest.platformTools.archiveFileName
    $toolsArchive = Get-VerifiedDownload `
            $manifest.platformTools.url `
            $toolsArchive `
            ([long]$manifest.platformTools.bytes) `
            $manifest.platformTools.sha256
    $toolsRoot = Join-Path $cacheRoot "platform-tools-$toolsRevision"
    $AdbPath = Join-Path $toolsRoot "platform-tools\adb.exe"
    if (-not (Test-Path -LiteralPath $AdbPath -PathType Leaf)) {
        Write-Step "Extracting Google Android Platform Tools $toolsRevision"
        Remove-InstallerCacheDirectory $toolsRoot
        New-Item -ItemType Directory -Force -Path $toolsRoot | Out-Null
        Expand-Archive -LiteralPath $toolsArchive -DestinationPath $toolsRoot
    }
}
$AdbPath = [IO.Path]::GetFullPath($AdbPath)
if (-not (Test-Path -LiteralPath $AdbPath -PathType Leaf)) {
    throw "adb.exe was not found: $AdbPath"
}
Write-Host "ADB: $AdbPath"

function Resolve-ModelFile {
    if ($ModelPath) {
        $candidate = [IO.Path]::GetFullPath($ModelPath)
        if (-not (Test-VerifiedFile `
                $candidate `
                ([long]$manifest.model.bytes) `
                $manifest.model.sha256
        )) {
            throw "The supplied model does not match the tested model: $candidate"
        }
        Write-Host "Using verified model: $candidate"
        return $candidate
    }
    $cachedModel = Join-Path $cacheRoot $manifest.model.localFileName
    return Get-VerifiedDownload `
            $manifest.model.url `
            $cachedModel `
            ([long]$manifest.model.bytes) `
            $manifest.model.sha256
}

if ($PrepareOnly) {
    Write-Step "Preparing and verifying the translation model"
    $preparedModel = Resolve-ModelFile
    Write-Host "Model ready: $preparedModel"
    Write-Host "Preparation completed; no phone was changed."
    exit 0
}

Write-Step "Detecting one authorized Android phone"
$deviceOutput = & $AdbPath devices
if ($LASTEXITCODE -ne 0) {
    throw "ADB could not list Android devices."
}
$authorized = @()
$unauthorized = @()
foreach ($line in ($deviceOutput | Select-Object -Skip 1)) {
    $parts = @($line -split "\s+")
    if ($parts.Count -lt 2) {
        continue
    }
    if ($parts[1] -eq "device") {
        $authorized += $parts[0]
    } elseif ($parts[1] -eq "unauthorized") {
        $unauthorized += $parts[0]
    }
}
if (-not $Serial) {
    if ($unauthorized.Count -gt 0) {
        throw "Unlock the phone and accept its USB debugging authorization, then run the installer again."
    }
    if ($authorized.Count -ne 1) {
        throw "Expected exactly one authorized phone; found $($authorized.Count)."
    }
    $Serial = $authorized[0]
}
if ($authorized -notcontains $Serial) {
    throw "The selected phone is not connected and authorized: $Serial"
}
Write-Host "Phone: $Serial"

Write-Step "Installing LocalFlow $($manifest.release.version)"
$installOutput = & $AdbPath `
        -s $Serial `
        install `
        --user 0 `
        -r `
        --no-streaming `
        $apkPath 2>&1
$installCode = $LASTEXITCODE
$installOutput | ForEach-Object { Write-Host $_ }
if ($installCode -ne 0) {
    $joinedOutput = $installOutput -join "`n"
    if ($joinedOutput -match "UPDATE_INCOMPATIBLE") {
        throw "A differently signed LocalFlow build is already installed. " +
                "This installer will not uninstall it automatically because " +
                "uninstalling would remove its app data."
    }
    throw "APK installation failed."
}

$packageName = $manifest.release.packageName
& $AdbPath -s $Serial shell monkey -p $packageName 1 | Out-Null
Start-Sleep -Seconds 2

$remoteDirectory = "/sdcard/Android/data/$packageName/files/models"
$remoteModel = "$remoteDirectory/$($manifest.model.localFileName)"
$remotePartial = "$remoteModel.part"
$remoteMarker = "$remoteDirectory/$($manifest.model.readyMarkerFileName)"
& $AdbPath -s $Serial shell mkdir -p $remoteDirectory
if ($LASTEXITCODE -ne 0) {
    throw "Unable to create LocalFlow's USB model staging directory."
}

$marker = (& $AdbPath -s $Serial shell cat $remoteMarker 2>$null) -join ""
if ($marker.Trim().ToLowerInvariant() -eq $manifest.model.sha256) {
    Write-Step "The verified translation model is already installed"
    Write-Host "Skipping the 1.3 GB download and USB transfer."
} else {
    Write-Step "Preparing the verified translation model"
    $resolvedModel = Resolve-ModelFile

    Write-Step "Transferring the translation model to the phone"
    & $AdbPath -s $Serial push $resolvedModel $remotePartial
    if ($LASTEXITCODE -ne 0) {
        throw "ADB model transfer failed."
    }
    $remoteBytes = (
        & $AdbPath -s $Serial shell stat -c "%s" $remotePartial
    ).Trim()
    if ($LASTEXITCODE -ne 0 `
            -or $remoteBytes -ne ([string]$manifest.model.bytes)) {
        throw "Phone-side model size mismatch: $remoteBytes"
    }
    Write-Host "Checking the model SHA-256 on the phone..."
    $remoteHashLine = (
        & $AdbPath -s $Serial shell sha256sum $remotePartial
    ).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "The phone could not calculate the model SHA-256."
    }
    $remoteHash = ($remoteHashLine -split "\s+")[0].ToLowerInvariant()
    if ($remoteHash -ne $manifest.model.sha256) {
        throw "Phone-side model SHA-256 mismatch: $remoteHash"
    }
    & $AdbPath -s $Serial shell mv $remotePartial $remoteModel
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to activate the USB-staged model."
    }
}

Write-Step "Launching LocalFlow"
& $AdbPath -s $Serial shell am force-stop $packageName
& $AdbPath -s $Serial shell monkey -p $packageName 1 | Out-Null
Write-Host "Select two languages on the phone and enter translation."
Write-Host "On first use, LocalFlow verifies and imports the staged model."
Write-Host "The app removes the USB staging copy after a successful import."
Write-Host "After setup, translation runs without Internet access."

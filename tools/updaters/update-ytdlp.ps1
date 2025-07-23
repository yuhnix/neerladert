# yt-dlp Update Checker en Downloader
# Controleert op nieuwe releases en downloadt automatisch de nieuwste versie

param(
    [string]$DownloadPath = ".\",
    [switch]$Force,
    [switch]$Verbose
)

# Configuratie
$GitHubRepo = "yt-dlp/yt-dlp"
$ApiUrl = "https://api.github.com/repos/$GitHubRepo/releases/latest"
$CurrentVersionFile = Join-Path $DownloadPath "yt-dlp-version.txt"
$ExecutableName = "yt-dlp.exe"

# Functie om de huidige geïnstalleerde versie te krijgen
function Get-CurrentVersion {
    if (Test-Path $CurrentVersionFile) {
        return Get-Content $CurrentVersionFile -Raw
    }
    
    # Probeer versie te krijgen van bestaande executable
    $ytdlpPath = Join-Path $DownloadPath $ExecutableName
    if (Test-Path $ytdlpPath) {
        try {
            $versionOutput = & $ytdlpPath --version 2>$null
            if ($versionOutput) {
                return $versionOutput.Trim()
            }
        }
        catch {
            Write-Warning "Kon versie niet ophalen van bestaande yt-dlp executable"
        }
    }
    
    return $null
}

# Functie om de nieuwste release info te krijgen
function Get-LatestReleaseInfo {
    try {
        Write-Host "Controleren op nieuwste release..." -ForegroundColor Yellow
        
        # GitHub API aanroepen
        $response = Invoke-RestMethod -Uri $ApiUrl -Headers @{
            "User-Agent" = "PowerShell-yt-dlp-updater"
        }
        
        return $response
    }
    catch {
        Write-Error "Fout bij ophalen release informatie: $($_.Exception.Message)"
        return $null
    }
}

# Functie om yt-dlp te downloaden
function Download-YtDlp {
    param(
        [object]$ReleaseInfo
    )
    
    # Zoek naar Windows executable in assets
    $windowsAsset = $ReleaseInfo.assets | Where-Object { 
        $_.name -eq "yt-dlp.exe" 
    }
    
    if (-not $windowsAsset) {
        Write-Error "Windows executable niet gevonden in release assets"
        return $false
    }
    
    $downloadUrl = $windowsAsset.browser_download_url
    $outputPath = Join-Path $DownloadPath $ExecutableName
    $backupPath = Join-Path $DownloadPath "yt-dlp-backup.exe"
    
    try {
        # Backup maken van bestaande versie
        if (Test-Path $outputPath) {
            Write-Host "Backup maken van huidige versie..." -ForegroundColor Yellow
            Copy-Item $outputPath $backupPath -Force
        }
        
        Write-Host "Downloaden van $($ReleaseInfo.tag_name)..." -ForegroundColor Green
        Write-Host "URL: $downloadUrl"
        
        # Download met Invoke-WebRequest (eenvoudiger en meer compatibel)
        try {
            Write-Progress -Activity "Downloaden yt-dlp" -Status "Bezig met downloaden..." -PercentComplete 0
            Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -UseBasicParsing
            Write-Progress -Activity "Downloaden yt-dlp" -Completed
        } catch {
            Write-Progress -Activity "Downloaden yt-dlp" -Completed
            throw "Download mislukt: $($_.Exception.Message)"
        }
        
        # Verificeren dat download succesvol was
        if (Test-Path $outputPath) {
            $fileSize = (Get-Item $outputPath).Length
            if ($fileSize -gt 0) {
                Write-Host "Download succesvol! Bestandsgrootte: $([math]::Round($fileSize / 1MB, 2)) MB" -ForegroundColor Green
                
                # Versie opslaan
                $ReleaseInfo.tag_name | Out-File $CurrentVersionFile -Encoding UTF8
                
                # Backup verwijderen als alles goed ging
                if (Test-Path $backupPath) {
                    Remove-Item $backupPath -Force
                }
                
                return $true
            }
        }
        
        Write-Error "Download mislukt - bestand is leeg of beschadigd"
        
        # Restore backup bij falen
        if (Test-Path $backupPath) {
            Write-Host "Herstellen van backup..." -ForegroundColor Yellow
            Move-Item $backupPath $outputPath -Force
        }
        
        return $false
    }
    catch {
        Write-Error "Fout tijdens download: $($_.Exception.Message)"
        
        # Restore backup bij falen
        if (Test-Path $backupPath) {
            Write-Host "Herstellen van backup..." -ForegroundColor Yellow
            Move-Item $backupPath $outputPath -Force
        }
        
        return $false
    }
}

# Hoofdscript
Write-Host "=== yt-dlp Update Checker ===" -ForegroundColor Cyan
Write-Host "Download pad: $DownloadPath"

# Controleer of download directory bestaat
if (-not (Test-Path $DownloadPath)) {
    Write-Host "Aanmaken van download directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null
}

# Huidige versie ophalen
$currentVersion = Get-CurrentVersion
if ($currentVersion) {
    Write-Host "Huidige versie: $currentVersion" -ForegroundColor Green
} else {
    Write-Host "Geen huidige versie gevonden" -ForegroundColor Yellow
}

# Nieuwste release informatie ophalen
$latestRelease = Get-LatestReleaseInfo
if (-not $latestRelease) {
    Write-Error "Kan nieuwste release informatie niet ophalen"
    exit 1
}

$latestVersion = $latestRelease.tag_name
Write-Host "Nieuwste versie: $latestVersion" -ForegroundColor Green

# Vergelijken van versies
$needsUpdate = $Force -or ($currentVersion -ne $latestVersion)

if ($needsUpdate) {
    if ($Force) {
        Write-Host "Geforceerde update..." -ForegroundColor Yellow
    } else {
        Write-Host "Nieuwe versie beschikbaar!" -ForegroundColor Yellow
    }
    
    Write-Host "Release datum: $($latestRelease.published_at)"
    if ($Verbose -and $latestRelease.body) {
        Write-Host "`nRelease notes:" -ForegroundColor Cyan
        Write-Host $latestRelease.body
    }
    
    # Download uitvoeren
    $downloadSuccess = Download-YtDlp -ReleaseInfo $latestRelease
    
    if ($downloadSuccess) {
        Write-Host "`n✅ Update succesvol voltooid!" -ForegroundColor Green
        Write-Host "yt-dlp $latestVersion is geïnstalleerd in $DownloadPath"
        
        # Toon locatie van executable
        $finalPath = Join-Path $DownloadPath $ExecutableName
        Write-Host "Executable pad: $finalPath" -ForegroundColor Cyan
    } else {
        Write-Host "`n❌ Update mislukt" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n✅ Je hebt al de nieuwste versie ($currentVersion)" -ForegroundColor Green
}

Write-Host "`nKlaar!" -ForegroundColor Cyan
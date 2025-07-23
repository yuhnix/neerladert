# FFmpeg Update Checker en Downloader
# Controleert op nieuwe releases en downloadt automatisch de nieuwste versie

param(
    [string]$DownloadPath = ".\",
    [switch]$Force,
    [switch]$Verbose
)

# Configuratie
$FFmpegUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-full.7z"
$CurrentVersionFile = Join-Path $DownloadPath "ffmpeg-version.txt"
$RequiredExecutables = @("ffmpeg.exe", "ffplay.exe", "ffprobe.exe")

# Functie om de huidige geïnstalleerde versie te krijgen
function Get-CurrentVersion {
    if (Test-Path $CurrentVersionFile) {
        return Get-Content $CurrentVersionFile -Raw
    }
    
    # Probeer versie te krijgen van bestaande executable
    $ffmpegPath = Join-Path $DownloadPath "ffmpeg.exe"
    if (Test-Path $ffmpegPath) {
        try {
            $versionOutput = & $ffmpegPath -version 2>$null | Select-Object -First 1
            if ($versionOutput -and $versionOutput -match "ffmpeg version (\S+)") {
                return $matches[1]
            }
        }
        catch {
            Write-Warning "Kon versie niet ophalen van bestaande ffmpeg executable"
        }
    }
    
    return $null
}

# Functie om de remote file datum te krijgen (voor versie vergelijking)
function Get-RemoteFileDate {
    try {
        Write-Host "Controleren op nieuwste FFmpeg build..." -ForegroundColor Yellow
        
        # HEAD request om Last-Modified te krijgen
        $response = Invoke-WebRequest -Uri $FFmpegUrl -Method Head -UseBasicParsing
        $lastModified = $response.Headers['Last-Modified']
        
        if ($lastModified) {
            # Probeer verschillende datum formaten
            try {
                if ($lastModified -is [array]) {
                    $dateString = $lastModified[0]
                } else {
                    $dateString = $lastModified
                }
                
                # Probeer standaard parsing
                return [DateTime]::Parse($dateString)
            }
            catch {
                try {
                    # Probeer met UTC parsing voor HTTP date format
                    return [DateTime]::ParseExact($dateString, "ddd, dd MMM yyyy HH:mm:ss 'GMT'", [System.Globalization.CultureInfo]::InvariantCulture)
                }
                catch {
                    Write-Warning "Kon datum niet parsen: '$dateString'. Gebruik huidige datum."
                    return Get-Date
                }
            }
        }
        
        # Fallback: gebruik huidige datum
        Write-Warning "Geen Last-Modified header gevonden. Gebruik huidige datum."
        return Get-Date
    }
    catch {
        Write-Error "Fout bij controleren remote file info: $($_.Exception.Message)"
        return $null
    }
}

# Functie om FFmpeg te downloaden en te installeren
function Download-FFmpeg {
    param(
        [DateTime]$RemoteDate
    )
    
    $archivePath = Join-Path $env:TEMP "ffmpeg-latest.7z"
    $extractPath = Join-Path $env:TEMP "ffmpeg-extract"
    $backupPath = Join-Path $DownloadPath "ffmpeg-backup"
    
    try {
        # Backup maken van bestaande executables
        if (Test-Path (Join-Path $DownloadPath "ffmpeg.exe")) {
            Write-Host "Backup maken van huidige versie..." -ForegroundColor Yellow
            if (Test-Path $backupPath) {
                Remove-Item $backupPath -Recurse -Force
            }
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
            
            foreach ($exe in $RequiredExecutables) {
                $sourcePath = Join-Path $DownloadPath $exe
                if (Test-Path $sourcePath) {
                    Copy-Item $sourcePath (Join-Path $backupPath $exe) -Force
                }
            }
        }
        
        Write-Host "Downloaden van FFmpeg archief..." -ForegroundColor Green
        Write-Host "URL: $FFmpegUrl"
        
        # Download met Invoke-WebRequest (meer compatibel)
        try {
            Write-Progress -Activity "Downloaden FFmpeg" -Status "Bezig met downloaden..." -PercentComplete 0
            Invoke-WebRequest -Uri $FFmpegUrl -OutFile $archivePath -UseBasicParsing
            Write-Progress -Activity "Downloaden FFmpeg" -Completed
        } catch {
            Write-Progress -Activity "Downloaden FFmpeg" -Completed
            throw "Download mislukt: $($_.Exception.Message)"
        }
        
        # Verificeren dat download succesvol was
        if (-not (Test-Path $archivePath) -or (Get-Item $archivePath).Length -eq 0) {
            throw "Download mislukt - archief niet gevonden of leeg"
        }
        
        $fileSize = (Get-Item $archivePath).Length
        Write-Host "Download succesvol! Archief grootte: $([math]::Round($fileSize / 1MB, 2)) MB" -ForegroundColor Green
        
        # Zoek naar 7-Zip voor extractie
        $sevenZipPaths = @(
            "${env:ProgramFiles}\7-Zip\7z.exe",
            "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
            "7z.exe"
        )
        
        $sevenZipFound = $false
        $sevenZipPath = $null
        
        foreach ($path in $sevenZipPaths) {
            if (Test-Path $path -ErrorAction SilentlyContinue) {
                $sevenZipPath = $path
                $sevenZipFound = $true
                break
            }
        }
        
        if (-not $sevenZipFound) {
            # Probeer PowerShell Expand-Archive als fallback (werkt alleen voor ZIP, niet voor 7Z)
            throw "7-Zip niet gevonden. FFmpeg gebruikt .7z formaat dat PowerShell niet kan uitpakken."
        }
        
        Write-Host "Uitpakken van archief..." -ForegroundColor Yellow
        
        # Extract naar tijdelijke directory
        if (Test-Path $extractPath) { 
            Remove-Item $extractPath -Recurse -Force 
        }
        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        
        # Uitpakken met 7-Zip
        $extractArgs = "x `"$archivePath`" `"-o$extractPath`" -y"
        $process = Start-Process $sevenZipPath -ArgumentList $extractArgs -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            throw "Uitpakken mislukt (exit code: $($process.ExitCode))"
        }
        
        # Zoek naar de bin directory met executables
        $binDir = Get-ChildItem -Path $extractPath -Recurse -Directory -Name "bin" | Select-Object -First 1
        if (-not $binDir) {
            throw "Bin directory niet gevonden in uitgepakte archief"
        }
        
        $binPath = Join-Path $extractPath $binDir
        Write-Host "Executables gevonden in: $binPath" -ForegroundColor Green
        
        # Kopieer de vereiste executables
        $copiedCount = 0
        foreach ($exe in $RequiredExecutables) {
            $sourceExe = Join-Path $binPath $exe
            $destExe = Join-Path $DownloadPath $exe
            
            if (Test-Path $sourceExe) {
                Copy-Item $sourceExe $destExe -Force
                Write-Host "Gekopieerd: $exe" -ForegroundColor Green
                $copiedCount++
            } else {
                Write-Warning "Executable niet gevonden: $exe"
            }
        }
        
        if ($copiedCount -eq 0) {
            throw "Geen executables konden worden gekopieerd"
        }
        
        # Versie informatie opslaan
        $versionInfo = "Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        if ($RemoteDate) {
            $versionInfo += "`nBuild Date: $($RemoteDate.ToString('yyyy-MM-dd HH:mm:ss'))"
        }
        $versionInfo | Out-File $CurrentVersionFile -Encoding UTF8
        
        # Backup verwijderen als alles goed ging
        if (Test-Path $backupPath) {
            Remove-Item $backupPath -Recurse -Force
        }
        
        Write-Host "FFmpeg executables succesvol geüpdatet ($copiedCount/$($RequiredExecutables.Count))" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Error "Fout tijdens download/installatie: $($_.Exception.Message)"
        
        # Restore backup bij falen
        if (Test-Path $backupPath) {
            Write-Host "Herstellen van backup..." -ForegroundColor Yellow
            foreach ($exe in $RequiredExecutables) {
                $backupExe = Join-Path $backupPath $exe
                $destExe = Join-Path $DownloadPath $exe
                if (Test-Path $backupExe) {
                    Copy-Item $backupExe $destExe -Force
                }
            }
            Remove-Item $backupPath -Recurse -Force
        }
        
        return $false
    }
    finally {
        # Cleanup tijdelijke bestanden
        if (Test-Path $archivePath) { 
            Remove-Item $archivePath -Force -ErrorAction SilentlyContinue 
        }
        if (Test-Path $extractPath) { 
            Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue 
        }
    }
}

# Hoofdscript
Write-Host "=== FFmpeg Update Checker ===" -ForegroundColor Cyan
Write-Host "Download pad: $DownloadPath"

# Controleer of download directory bestaat
if (-not (Test-Path $DownloadPath)) {
    Write-Host "Aanmaken van download directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null
}

# Huidige versie ophalen
$currentVersion = Get-CurrentVersion
if ($currentVersion) {
    Write-Host "Huidige versie info: $currentVersion" -ForegroundColor Green
} else {
    Write-Host "Geen huidige versie informatie gevonden" -ForegroundColor Yellow
}

# Nieuwste build info ophalen
$remoteDate = Get-RemoteFileDate
if (-not $remoteDate) {
    Write-Error "Kan nieuwste build informatie niet ophalen"
    exit 1
}

Write-Host "Nieuwste build datum: $($remoteDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Green

# Bepalen of update nodig is
$needsUpdate = $Force
if (-not $Force) {
    if (-not $currentVersion) {
        $needsUpdate = $true
        Write-Host "Geen bestaande installatie gevonden - downloaden..." -ForegroundColor Yellow
    } else {
        # Vergelijk met lokale versie file datum
        if (Test-Path $CurrentVersionFile) {
            $localDate = (Get-Item $CurrentVersionFile).LastWriteTime
            if ($remoteDate -gt $localDate.AddDays(1)) { # Alleen updaten als remote > 1 dag nieuwer
                $needsUpdate = $true
                Write-Host "Nieuwere build beschikbaar (remote: $($remoteDate.ToString('yyyy-MM-dd')), local: $($localDate.ToString('yyyy-MM-dd')))" -ForegroundColor Yellow
            }
        } else {
            $needsUpdate = $true
        }
    }
}

if ($needsUpdate) {
    if ($Force) {
        Write-Host "Geforceerde update..." -ForegroundColor Yellow
    } else {
        Write-Host "Update nodig - nieuwere build beschikbaar!" -ForegroundColor Yellow
    }
    
    # Download uitvoeren
    $downloadSuccess = Download-FFmpeg -RemoteDate $remoteDate
    
    if ($downloadSuccess) {
        Write-Host "`n✅ Update succesvol voltooid!" -ForegroundColor Green
        Write-Host "FFmpeg executables zijn geïnstalleerd in $DownloadPath"
        
        # Toon versie van nieuwe installatie
        $ffmpegPath = Join-Path $DownloadPath "ffmpeg.exe"
        if (Test-Path $ffmpegPath) {
            try {
                $newVersion = & $ffmpegPath -version 2>$null | Select-Object -First 1
                Write-Host "Nieuwe versie: $newVersion" -ForegroundColor Cyan
            } catch {
                Write-Warning "Kon nieuwe versie niet ophalen"
            }
        }
    } else {
        Write-Host "`n❌ Update mislukt" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n✅ Je hebt al de nieuwste versie" -ForegroundColor Green
}

Write-Host "`nKlaar!" -ForegroundColor Cyan
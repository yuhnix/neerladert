# Pirate Cavia Installation Script
param(
    [string]$InstallPath = "",
    [switch]$CreateDesktopShortcut = $false
)

# Set execution policy for current process
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Restart as administrator if needed
if (-not (Test-Administrator)) {
    Write-Host "Dit script moet worden uitgevoerd met administrator rechten." -ForegroundColor Yellow
    Write-Host "Opnieuw opstarten met administrator rechten..." -ForegroundColor Yellow
    
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($InstallPath) { $arguments += " -InstallPath `"$InstallPath`"" }
    if ($CreateDesktopShortcut) { $arguments += " -CreateDesktopShortcut" }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs
    exit
}

Write-Host "Pirate Cavia Installatie Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Get installation directory
if (-not $InstallPath) {
    Write-Host ""
    Write-Host "Waar wilt u Pirate Cavia installeren?"
    Write-Host "1. Program Files (aanbevolen): C:\Program Files\PirateCavia"
    Write-Host "2. Gebruikers directory: $env:LOCALAPPDATA\PirateCavia"
    Write-Host "3. Aangepaste locatie"
    Write-Host ""
    
    do {
        $choice = Read-Host "Voer uw keuze in (1, 2, of 3)"
        switch ($choice) {
            "1" { 
                $InstallPath = "C:\Program Files\PirateCavia"
                break
            }
            "2" { 
                $InstallPath = "$env:LOCALAPPDATA\PirateCavia"
                break
            }
            "3" { 
                $InstallPath = Read-Host "Voer het gewenste installatiepad in"
                break
            }
            default {
                Write-Host "Ongeldige keuze. Kies 1, 2, of 3." -ForegroundColor Red
            }
        }
    } while ($choice -notin @("1", "2", "3"))
}

Write-Host "Installatie pad: $InstallPath" -ForegroundColor Green

# Create installation directory
try {
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Host "Installatie directory aangemaakt: $InstallPath" -ForegroundColor Green
    }
} catch {
    Write-Host "Fout bij aanmaken installatie directory: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get source directory (where this script is located)
$SourcePath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Kopiëren van bestanden van $SourcePath naar $InstallPath..." -ForegroundColor Yellow

# Items to exclude from copying (installer and temp files)
$ItemsToExclude = @(
    "install.ps1",
    ".git",
    ".gitignore",
    "*.tmp",
    "*.log"
)

# Get all items in source directory
$AllItems = Get-ChildItem -Path $SourcePath -Force | Where-Object {
    $item = $_
    $shouldExclude = $false
    
    foreach ($exclude in $ItemsToExclude) {
        if ($exclude.Contains("*")) {
            # Wildcard pattern
            if ($item.Name -like $exclude) {
                $shouldExclude = $true
                break
            }
        } else {
            # Exact match
            if ($item.Name -eq $exclude) {
                $shouldExclude = $true
                break
            }
        }
    }
    
    return -not $shouldExclude
}

# Copy all files and directories
foreach ($item in $AllItems) {
    $sourcePath = $item.FullName
    $destPath = Join-Path $InstallPath $item.Name
    
    try {
        if ($item.PSIsContainer) {
            # Directory
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
            Write-Host "Gekopieerd directory: $($item.Name)" -ForegroundColor Green
        } else {
            # File
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "Gekopieerd bestand: $($item.Name)" -ForegroundColor Green
        }
    } catch {
        Write-Host "Fout bij kopiëren van $($item.Name)`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create logs and Downloads directories
$LogsPath = Join-Path $InstallPath "logs"
$DownloadsPath = Join-Path $InstallPath "Downloads"

try {
    if (-not (Test-Path $LogsPath)) {
        New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
        Write-Host "Logs directory aangemaakt" -ForegroundColor Green
    }
    if (-not (Test-Path $DownloadsPath)) {
        New-Item -ItemType Directory -Path $DownloadsPath -Force | Out-Null
        Write-Host "Downloads directory aangemaakt" -ForegroundColor Green
    }
} catch {
    Write-Host "Fout bij aanmaken directories: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Basis installatie voltooid!" -ForegroundColor Green
Write-Host ""

# Download latest tools (yt-dlp and ffmpeg)
Write-Host "Downloaden van laatste versies van tools..." -ForegroundColor Yellow

# Download yt-dlp
try {
    Write-Host "Downloaden van yt-dlp..." -ForegroundColor Yellow
    $ytdlPath = Join-Path $InstallPath "tools"
    $ytdlExe = Join-Path $ytdlPath "yt-dlp.exe"
    
    # Download latest yt-dlp
    $ytdlUrl = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
    Invoke-WebRequest -Uri $ytdlUrl -OutFile $ytdlExe -UseBasicParsing
    Write-Host "yt-dlp succesvol gedownload" -ForegroundColor Green
} catch {
    Write-Host "Fout bij downloaden van yt-dlp: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "U kunt later handmatig de laatste versie downloaden van: https://github.com/yt-dlp/yt-dlp/releases" -ForegroundColor Yellow
}

# Download FFmpeg
try {
    Write-Host "Downloaden van FFmpeg..." -ForegroundColor Yellow
    $toolsPath = Join-Path $InstallPath "tools"
    $ffmpegZip = Join-Path $env:TEMP "ffmpeg-latest.7z"
    
    # Download latest FFmpeg
    $ffmpegUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-full.7z"
    Invoke-WebRequest -Uri $ffmpegUrl -OutFile $ffmpegZip -UseBasicParsing
    Write-Host "FFmpeg archive gedownload" -ForegroundColor Green
    
    # Try to extract using 7zip (if available)
    $sevenZipPaths = @(
        "${env:ProgramFiles}\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
        "7z.exe"
    )
    
    $sevenZipFound = $false
    foreach ($path in $sevenZipPaths) {
        if (Test-Path $path -ErrorAction SilentlyContinue) {
            try {
                # Extract to temp directory first
                $extractPath = Join-Path $env:TEMP "ffmpeg-extract"
                if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
                New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
                
                & $path x $ffmpegZip "-o$extractPath" -y
                
                # Find the bin directory with ffmpeg executables
                $ffmpegBin = Get-ChildItem -Path $extractPath -Recurse -Directory -Name "bin" | Select-Object -First 1
                if ($ffmpegBin) {
                    $ffmpegBinPath = Join-Path $extractPath $ffmpegBin
                    
                    # Copy the three executables we need
                    $executables = @("ffmpeg.exe", "ffplay.exe", "ffprobe.exe")
                    foreach ($exe in $executables) {
                        $sourceExe = Join-Path $ffmpegBinPath $exe
                        $destExe = Join-Path $toolsPath $exe
                        if (Test-Path $sourceExe) {
                            Copy-Item $sourceExe $destExe -Force
                            Write-Host "Gekopieerd: $exe" -ForegroundColor Green
                        }
                    }
                    $sevenZipFound = $true
                }
                
                # Cleanup temp extraction
                Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
                break
            } catch {
                Write-Host "Fout bij extracten met $path`: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    if (-not $sevenZipFound) {
        Write-Host "7-Zip niet gevonden. FFmpeg archief gedownload naar: $ffmpegZip" -ForegroundColor Yellow
        Write-Host "Pak handmatig uit en kopieer ffmpeg.exe, ffplay.exe, en ffprobe.exe naar: $toolsPath" -ForegroundColor Yellow
    }
    
    # Cleanup downloaded archive
    Remove-Item $ffmpegZip -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "Fout bij downloaden van FFmpeg: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "U kunt later handmatig FFmpeg downloaden van: https://www.gyan.dev/ffmpeg/builds/" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Tool downloads voltooid!" -ForegroundColor Green
Write-Host ""

# Ask about desktop shortcut if not specified
if (-not $PSBoundParameters.ContainsKey('CreateDesktopShortcut')) {
    $response = Read-Host "Wilt u een desktop snelkoppeling aanmaken? (j/n)"
    $CreateDesktopShortcut = $response -match "^[jJyY]"
}

# Create desktop shortcut
if ($CreateDesktopShortcut) {
    try {
        $DesktopPath = [Environment]::GetFolderPath("Desktop")
        $ShortcutPath = Join-Path $DesktopPath "Pirate Cavia.lnk"
        $TargetPath = Join-Path $InstallPath "run-gui.cmd"
        $IconPath = Join-Path $InstallPath "icons\go-caviaPirate.png"
        
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $TargetPath
        $Shortcut.WorkingDirectory = $InstallPath
        if (Test-Path $IconPath) {
            $Shortcut.IconLocation = $IconPath
        }
        $Shortcut.Save()
        
        Write-Host "Desktop snelkoppeling aangemaakt: $ShortcutPath" -ForegroundColor Green
    } catch {
        Write-Host "Fout bij aanmaken desktop snelkoppeling: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Check if installation path is in PATH
$currentPath = $env:PATH
$installPathInPath = $currentPath.Split(';') -contains $InstallPath

if (-not $installPathInPath) {
    Write-Host ""
    $response = Read-Host "Wilt u het installatiepad toevoegen aan de PATH omgevingsvariabele? (j/n)"
    if ($response -match "^[jJyY]") {
        try {
            # Add to system PATH
            $newPath = $currentPath + ";" + $InstallPath
            [Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::Machine)
            Write-Host "Installatiepad toegevoegd aan PATH" -ForegroundColor Green
            Write-Host "Herstart uw terminal om de wijzigingen te activeren" -ForegroundColor Yellow
        } catch {
            Write-Host "Fout bij toevoegen aan PATH: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Set permissions for normal users
try {
    Write-Host ""
    Write-Host "Instellen van bestandspermissies..." -ForegroundColor Yellow
    
    # Give Users group modify permissions
    $acl = Get-Acl $InstallPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl $InstallPath $acl
    
    Write-Host "Gebruikerspermissies ingesteld" -ForegroundColor Green
} catch {
    Write-Host "Fout bij instellen permissies: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Gebruikers hebben mogelijk geen schrijfrechten in de installatie directory" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Installatie succesvol voltooid!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pirate Cavia is geïnstalleerd in: $InstallPath" -ForegroundColor White
Write-Host ""
Write-Host "U kunt de applicatie starten door:" -ForegroundColor White
if ($installPathInPath) {
    Write-Host "- run-gui.cmd (vanuit elke directory)" -ForegroundColor Green
} else {
    Write-Host "- Dubbelklik op run-gui.cmd in $InstallPath" -ForegroundColor Green
}
if ($CreateDesktopShortcut) {
    Write-Host "- Dubbelklik op de desktop snelkoppeling" -ForegroundColor Green
}
Write-Host ""
Write-Host "Druk op een toets om af te sluiten..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
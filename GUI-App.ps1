Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Initialize log file and default save path
$global:logFile = ".\logs\pirate-cavia-$(Get-Date -Format 'yyyy-MM-dd-HHmm').log"
$global:logDir = ".\logs"
$global:savePath = "$(Get-Location)\Downloads"

# Create directories if they don't exist
if (!(Test-Path $global:logDir)) {
    New-Item -ItemType Directory -Path $global:logDir -Force
}
if (!(Test-Path $global:savePath)) {
    New-Item -ItemType Directory -Path $global:savePath -Force
}

# Function to log to both textbox and file
function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $message"
    
    # Write to textbox
    $logTextBox.AppendText("$message`r`n")
    $logTextBox.ScrollToCaret()
    
    # Write to file
    Add-Content -Path $global:logFile -Value $logEntry -Encoding UTF8
}

# Startup update check
function Show-StartupUpdateDialog {
    $updateForm = New-Object System.Windows.Forms.Form
    $updateForm.Text = "Update Check"
    $updateForm.Size = New-Object System.Drawing.Size(400, 200)
    $updateForm.StartPosition = "CenterScreen"
    $updateForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $updateForm.MaximizeBox = $false
    $updateForm.MinimizeBox = $false
    
    # Question label
    $questionLabel = New-Object System.Windows.Forms.Label
    $questionLabel.Location = New-Object System.Drawing.Point(20, 20)
    $questionLabel.Size = New-Object System.Drawing.Size(340, 40)
    $questionLabel.Text = "Wil je controleren of er updates voor yt-dlp en/of FFmpeg zijn?"
    $questionLabel.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
    $updateForm.Controls.Add($questionLabel)
    
    # yt-dlp checkbox
    $ytdlpCheckBox = New-Object System.Windows.Forms.CheckBox
    $ytdlpCheckBox.Location = New-Object System.Drawing.Point(60, 80)
    $ytdlpCheckBox.Size = New-Object System.Drawing.Size(120, 20)
    $ytdlpCheckBox.Text = "yt-dlp updaten"
    $ytdlpCheckBox.Checked = $true
    $updateForm.Controls.Add($ytdlpCheckBox)
    
    # FFmpeg checkbox
    $ffmpegCheckBox = New-Object System.Windows.Forms.CheckBox
    $ffmpegCheckBox.Location = New-Object System.Drawing.Point(200, 80)
    $ffmpegCheckBox.Size = New-Object System.Drawing.Size(120, 20)
    $ffmpegCheckBox.Text = "FFmpeg updaten"
    $ffmpegCheckBox.Checked = $true
    $updateForm.Controls.Add($ffmpegCheckBox)
    
    # OK button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(120, 120)
    $okButton.Size = New-Object System.Drawing.Size(75, 25)
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $updateForm.Controls.Add($okButton)
    
    # Cancel button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(210, 120)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 25)
    $cancelButton.Text = "Overslaan"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $updateForm.Controls.Add($cancelButton)
    
    $updateForm.AcceptButton = $okButton
    $updateForm.CancelButton = $cancelButton
    
    $result = $updateForm.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $updateResults = @{
            UpdateYtDlp = $ytdlpCheckBox.Checked
            UpdateFFmpeg = $ffmpegCheckBox.Checked
        }
    } else {
        $updateResults = @{
            UpdateYtDlp = $false
            UpdateFFmpeg = $false
        }
    }
    
    $updateForm.Dispose()
    return $updateResults
}

# Show startup update dialog
$startupUpdates = Show-StartupUpdateDialog

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Pirate Cavia, HAR HAR"
$form.Size = New-Object System.Drawing.Size(520, 880) # Adjusted height to show status bar properly
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false

# Create a menu bar
$menuBar = New-Object System.Windows.Forms.MenuStrip
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "Bestand"

$newItem = New-Object System.Windows.Forms.ToolStripMenuItem
$newItem.Text = "Nieuw"
$newItem.Add_Click({
    $urlTextBox.Text = ""
    $batchFileCheckBox.Checked = $false
    $batchFileTextBox.Text = ""
    $mp3CheckBox.Checked = $false
    $mp4CheckBox.Checked = $false
    $wavCheckBox.Checked = $false
    $playlistCheckBox.Checked = $false
    $cookieCheckBox.Checked = $false
    $browserDropdown.SelectedIndex = 0
    $browserDropdown.Enabled = $false
    $logTextBox.Text = ""
    $statusLabel.Text = "Gereed"
})

$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitItem.Text = "Afsluiten"
$exitItem.Add_Click({
    $form.Close()
})

[void]$fileMenu.DropDownItems.Add($newItem)
[void]$fileMenu.DropDownItems.Add($exitItem)

$helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenu.Text = "Help"

# Update yt-dlp menu item
$updateYtDlpItem = New-Object System.Windows.Forms.ToolStripMenuItem
$updateYtDlpItem.Text = "Update yt-dlp"
$updateYtDlpItem.Add_Click({
    try {
        $statusLabel.Text = "yt-dlp updaten..."
        $logTextBox.Text = ""
        Write-Log "=== yt-dlp Update Gestart ==="
        
        # Pad naar het update script en tools directory
        $updateScript = ".\tools\updaters\update-ytdlp.ps1"
        $ytdlPath = ".\tools"
        
        if (Test-Path $updateScript) {
            Write-Log "Update script gevonden, starten van update proces..."
            
            # Voer het update script uit in de achtergrond
            $job = Start-Job -ScriptBlock {
                param($script, $path)
                & powershell.exe -ExecutionPolicy Bypass -File $script -DownloadPath $path -Verbose
            } -ArgumentList $updateScript, $ytdlPath
            
            # Wacht op voltooiing en toon progress
            do {
                Start-Sleep -Milliseconds 500
                $form.Refresh()
                [System.Windows.Forms.Application]::DoEvents()
            } while ($job.State -eq 'Running')
            
            $result = Receive-Job $job
            Remove-Job $job
            
            # Toon resultaat
            if ($result) {
                Write-Log ($result | Out-String)
            }
            
            # Test of yt-dlp werkt
            $ytdlExe = Join-Path $ytdlPath "yt-dlp.exe"
            if (Test-Path $ytdlExe) {
                try {
                    $version = & $ytdlExe --version
                    Write-Log "yt-dlp update voltooid! Versie: $version"
                    $statusLabel.Text = "yt-dlp update voltooid"
                } catch {
                    Write-Log "Fout bij versie controle: $_"
                    $statusLabel.Text = "Update voltooid, versie controle mislukt"
                }
            } else {
                Write-Log "WAARSCHUWING: yt-dlp.exe niet gevonden na update!"
                $statusLabel.Text = "Update mislukt"
            }
        } else {
            Write-Log "Update script niet gevonden: $updateScript"
            $statusLabel.Text = "Update script niet gevonden"
        }
    } catch {
        Write-Log "Fout tijdens yt-dlp update: $_"
        $statusLabel.Text = "Update mislukt"
    }
})

# Update FFmpeg menu item  
$updateFFmpegItem = New-Object System.Windows.Forms.ToolStripMenuItem
$updateFFmpegItem.Text = "Update FFmpeg"
$updateFFmpegItem.Add_Click({
    try {
        $statusLabel.Text = "FFmpeg updaten..."
        $logTextBox.Text = ""
        Write-Log "=== FFmpeg Update Gestart ==="
        
        # Pad naar het update script en tools directory
        $updateScript = ".\tools\updaters\update-ffmpeg.ps1"
        $ffmpegPath = ".\tools"
        
        if (Test-Path $updateScript) {
            Write-Log "Update script gevonden, starten van update proces..."
            
            # Voer het update script uit in de achtergrond
            $job = Start-Job -ScriptBlock {
                param($script, $path)
                & powershell.exe -ExecutionPolicy Bypass -File $script -DownloadPath $path -Verbose
            } -ArgumentList $updateScript, $ffmpegPath
            
            # Wacht op voltooiing en toon progress
            do {
                Start-Sleep -Milliseconds 500
                $form.Refresh()
                [System.Windows.Forms.Application]::DoEvents()
            } while ($job.State -eq 'Running')
            
            $result = Receive-Job $job
            Remove-Job $job
            
            # Toon resultaat
            if ($result) {
                Write-Log ($result | Out-String)
            }
            
            # Test of FFmpeg werkt
            $ffmpegExe = Join-Path $ffmpegPath "ffmpeg.exe"
            if (Test-Path $ffmpegExe) {
                try {
                    $version = & $ffmpegExe -version 2>$null | Select-Object -First 1
                    Write-Log "FFmpeg update voltooid! $version"
                    $statusLabel.Text = "FFmpeg update voltooid"
                } catch {
                    Write-Log "Fout bij versie controle: $_"
                    $statusLabel.Text = "Update voltooid, versie controle mislukt"
                }
            } else {
                Write-Log "WAARSCHUWING: ffmpeg.exe niet gevonden na update!"
                $statusLabel.Text = "Update mislukt"
            }
        } else {
            Write-Log "Update script niet gevonden: $updateScript"
            $statusLabel.Text = "Update script niet gevonden"
        }
    } catch {
        Write-Log "Fout tijdens FFmpeg update: $_"
        $statusLabel.Text = "Update mislukt"
    }
})

$aboutItem = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutItem.Text = "Over Pirate Cavia"
$aboutItem.Add_Click({
    # Create About dialog form
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = "Over Pirate Cavia"
    $aboutForm.Size = New-Object System.Drawing.Size(400, 300)
    $aboutForm.StartPosition = "CenterParent"
    $aboutForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false
    
    # Main info label
    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Location = New-Object System.Drawing.Point(20, 20)
    $infoLabel.Size = New-Object System.Drawing.Size(340, 80)
    $infoLabel.Text = "Pirate Cavia - Media Downloader`n`nVersie: 1.0`nBuilt with PowerShell & Windows Forms`n`nHAR HAR!"
    $infoLabel.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
    $aboutForm.Controls.Add($infoLabel)
    
    # yt-dlp version button
    $ytdlpVersionButton = New-Object System.Windows.Forms.Button
    $ytdlpVersionButton.Location = New-Object System.Drawing.Point(50, 120)
    $ytdlpVersionButton.Size = New-Object System.Drawing.Size(120, 30)
    $ytdlpVersionButton.Text = "yt-dlp versie"
    $ytdlpVersionButton.Add_Click({
        try {
            $ytdlpPath = ".\tools\yt-dlp.exe"
            if (Test-Path $ytdlpPath) {
                $version = & $ytdlpPath --version 2>$null
                [System.Windows.Forms.MessageBox]::Show("yt-dlp versie: $version", "yt-dlp Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                [System.Windows.Forms.MessageBox]::Show("yt-dlp.exe niet gevonden in tools directory", "Fout", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Kon yt-dlp versie niet ophalen: $_", "Fout", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $aboutForm.Controls.Add($ytdlpVersionButton)
    
    # FFmpeg version button
    $ffmpegVersionButton = New-Object System.Windows.Forms.Button
    $ffmpegVersionButton.Location = New-Object System.Drawing.Point(190, 120)
    $ffmpegVersionButton.Size = New-Object System.Drawing.Size(120, 30)
    $ffmpegVersionButton.Text = "FFmpeg versie"
    $ffmpegVersionButton.Add_Click({
        try {
            $ffmpegPath = ".\tools\ffmpeg.exe"
            if (Test-Path $ffmpegPath) {
                $version = & $ffmpegPath -version 2>$null | Select-Object -First 1
                if ($version -match "ffmpeg version ([^\s]+)") {
                    $versionInfo = $matches[1]
                    [System.Windows.Forms.MessageBox]::Show("FFmpeg versie: $versionInfo", "FFmpeg Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                } else {
                    [System.Windows.Forms.MessageBox]::Show("FFmpeg versie info: $version", "FFmpeg Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show("ffmpeg.exe niet gevonden in tools directory", "Fout", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Kon FFmpeg versie niet ophalen: $_", "Fout", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $aboutForm.Controls.Add($ffmpegVersionButton)
    
    # Close button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Location = New-Object System.Drawing.Point(160, 180)
    $closeButton.Size = New-Object System.Drawing.Size(80, 30)
    $closeButton.Text = "Sluiten"
    $closeButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $aboutForm.Controls.Add($closeButton)
    $aboutForm.AcceptButton = $closeButton
    
    # Show dialog
    [void]$aboutForm.ShowDialog()
    $aboutForm.Dispose()
})

[void]$helpMenu.DropDownItems.Add($updateYtDlpItem)
[void]$helpMenu.DropDownItems.Add($updateFFmpegItem)
[void]$helpMenu.DropDownItems.Add("-") # Separator
[void]$helpMenu.DropDownItems.Add($aboutItem)

[void]$menuBar.Items.Add($fileMenu)
[void]$menuBar.Items.Add($helpMenu)
$form.MainMenuStrip = $menuBar
$form.Controls.Add($menuBar)

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20, 35)
$label.Size = New-Object System.Drawing.Size(460, 30)
$label.Text = "Pirate Cavia - Voer URL in"
$label.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($label)

# Create a URL textbox
$urlTextBox = New-Object System.Windows.Forms.TextBox
$urlTextBox.Location = New-Object System.Drawing.Point(20, 75)
$urlTextBox.Size = New-Object System.Drawing.Size(460, 30)
$urlTextBox.PlaceholderText = "Voer URL in..."
$form.Controls.Add($urlTextBox)

# Create general options group box (renamed from format)
$generalGroupBox = New-Object System.Windows.Forms.GroupBox
$generalGroupBox.Location = New-Object System.Drawing.Point(20, 115)
$generalGroupBox.Size = New-Object System.Drawing.Size(460, 220)
$generalGroupBox.Text = "Algemeen"
$form.Controls.Add($generalGroupBox)

# Create batch file checkbox inside general group
$batchFileCheckBox = New-Object System.Windows.Forms.CheckBox
$batchFileCheckBox.Location = New-Object System.Drawing.Point(20, 30)
$batchFileCheckBox.Size = New-Object System.Drawing.Size(180, 20)
$batchFileCheckBox.Text = "Gebruik bestand met URLs"
$generalGroupBox.Controls.Add($batchFileCheckBox)

# Create batch file path textbox inside general group
$batchFileTextBox = New-Object System.Windows.Forms.TextBox
$batchFileTextBox.Location = New-Object System.Drawing.Point(20, 55)
$batchFileTextBox.Size = New-Object System.Drawing.Size(300, 25)
$batchFileTextBox.PlaceholderText = "Selecteer bestand..."
$batchFileTextBox.Enabled = $false
$generalGroupBox.Controls.Add($batchFileTextBox)

# Create batch file browse button inside general group
$batchFileBrowseButton = New-Object System.Windows.Forms.Button
$batchFileBrowseButton.Location = New-Object System.Drawing.Point(330, 53)
$batchFileBrowseButton.Size = New-Object System.Drawing.Size(90, 27)
$batchFileBrowseButton.Text = "Bladeren"
$batchFileBrowseButton.Enabled = $false
$batchFileBrowseButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Text bestanden (*.txt)|*.txt|Alle bestanden (*.*)|*.*"
    $openFileDialog.Title = "Selecteer bestand met URLs"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $batchFileTextBox.Text = $openFileDialog.FileName
    }
})
$generalGroupBox.Controls.Add($batchFileBrowseButton)

# Add event handler for batch file checkbox
$batchFileCheckBox.Add_CheckedChanged({
    if ($batchFileCheckBox.Checked) {
        $batchFileTextBox.Enabled = $true
        $batchFileBrowseButton.Enabled = $true
        $urlTextBox.Enabled = $false
    } else {
        $batchFileTextBox.Enabled = $false
        $batchFileBrowseButton.Enabled = $false
        $batchFileTextBox.Text = ""
        $urlTextBox.Enabled = $true
    }
})

# Create MP3 checkbox
$mp3CheckBox = New-Object System.Windows.Forms.CheckBox
$mp3CheckBox.Location = New-Object System.Drawing.Point(20, 90)
$mp3CheckBox.Size = New-Object System.Drawing.Size(100, 20)
$mp3CheckBox.Text = "MP3"
$mp3CheckBox.Checked = $true
$generalGroupBox.Controls.Add($mp3CheckBox)

# Create MP4 checkbox
$mp4CheckBox = New-Object System.Windows.Forms.CheckBox
$mp4CheckBox.Location = New-Object System.Drawing.Point(130, 90)
$mp4CheckBox.Size = New-Object System.Drawing.Size(100, 20)
$mp4CheckBox.Text = "MP4"
$generalGroupBox.Controls.Add($mp4CheckBox)

# Create WAV checkbox
$wavCheckBox = New-Object System.Windows.Forms.CheckBox
$wavCheckBox.Location = New-Object System.Drawing.Point(240, 90)
$wavCheckBox.Size = New-Object System.Drawing.Size(100, 20)
$wavCheckBox.Text = "WAV"
$generalGroupBox.Controls.Add($wavCheckBox)

# Create playlist checkbox
$playlistCheckBox = New-Object System.Windows.Forms.CheckBox
$playlistCheckBox.Location = New-Object System.Drawing.Point(20, 120)
$playlistCheckBox.Size = New-Object System.Drawing.Size(240, 20)
$playlistCheckBox.Text = "Download hele playlist"
$generalGroupBox.Controls.Add($playlistCheckBox)

# Create download location button
$downloadLocationButton = New-Object System.Windows.Forms.Button
$downloadLocationButton.Location = New-Object System.Drawing.Point(20, 150)
$downloadLocationButton.Size = New-Object System.Drawing.Size(120, 25)
$downloadLocationButton.Text = "Download locatie"
$downloadLocationButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $savePathLabel.Text = $folderBrowser.SelectedPath
        $global:savePath = $folderBrowser.SelectedPath # Store the selected path globally
        if ($folderBrowser.SelectedPath) {
            Write-Log "Geselecteerde opslaglocatie: $($folderBrowser.SelectedPath)"
        } else {
            Write-Log "Geen opslaglocatie geselecteerd."
        }
    }
})
$generalGroupBox.Controls.Add($downloadLocationButton)

# Create a label to display the selected save path (read-only)
$savePathLabel = New-Object System.Windows.Forms.Label
$savePathLabel.Location = New-Object System.Drawing.Point(150, 152)
$savePathLabel.Size = New-Object System.Drawing.Size(290, 20)
$savePathLabel.Text = (Get-Location).Path + "\Downloads"  # Default to Downloads subfolder
$savePathLabel.AutoEllipsis = $true  # Add ellipsis if text is too long
$generalGroupBox.Controls.Add($savePathLabel)

# Create download location open button
$openLocationButton = New-Object System.Windows.Forms.Button
$openLocationButton.Location = New-Object System.Drawing.Point(20, 180)
$openLocationButton.Size = New-Object System.Drawing.Size(150, 25)
$openLocationButton.Text = "Download locatie openen"
$openLocationButton.Add_Click({
    $pathToOpen = if ($global:savePath) { $global:savePath } else { (Get-Location).Path + "\Downloads" }
    if (Test-Path $pathToOpen) {
        Start-Process explorer.exe -ArgumentList $pathToOpen
        Write-Log "Download locatie geopend: $pathToOpen"
    } else {
        [System.Windows.Forms.MessageBox]::Show("Download locatie bestaat niet: $pathToOpen", "Fout", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        Write-Log "Kan download locatie niet openen: $pathToOpen (bestaat niet)"
    }
})
$generalGroupBox.Controls.Add($openLocationButton)

# Create advanced settings group box
$advancedGroupBox = New-Object System.Windows.Forms.GroupBox
$advancedGroupBox.Location = New-Object System.Drawing.Point(20, 345)
$advancedGroupBox.Size = New-Object System.Drawing.Size(460, 140)
$advancedGroupBox.Text = "Geavanceerde instellingen"
$form.Controls.Add($advancedGroupBox)

# Add bitrate label and dropdown
$bitrateLabel = New-Object System.Windows.Forms.Label
$bitrateLabel.Location = New-Object System.Drawing.Point(20, 30)
$bitrateLabel.Size = New-Object System.Drawing.Size(100, 20)
$bitrateLabel.Text = "Bitrate (MP3):"
$advancedGroupBox.Controls.Add($bitrateLabel)

$bitrateDropdown = New-Object System.Windows.Forms.ComboBox
$bitrateDropdown.Location = New-Object System.Drawing.Point(130, 30)
$bitrateDropdown.Size = New-Object System.Drawing.Size(100, 20)
[void]$bitrateDropdown.Items.AddRange(@("128k", "192k", "256k", "320k", "V0 (VBR)", "V2 (VBR)", "V4 (VBR)"))
$bitrateDropdown.SelectedIndex = 3 # Default to 320k
$advancedGroupBox.Controls.Add($bitrateDropdown)

# Add checkbox for keeping original file
$keepOriginalCheckBox = New-Object System.Windows.Forms.CheckBox
$keepOriginalCheckBox.Location = New-Object System.Drawing.Point(20, 70)
$keepOriginalCheckBox.Size = New-Object System.Drawing.Size(240, 20)
$keepOriginalCheckBox.Text = "Origineel bestand behouden"
$keepOriginalCheckBox.Checked = $true
$advancedGroupBox.Controls.Add($keepOriginalCheckBox)

# Add checkbox for showing files when done
$showFilesCheckBox = New-Object System.Windows.Forms.CheckBox
$showFilesCheckBox.Location = New-Object System.Drawing.Point(20, 90)
$showFilesCheckBox.Size = New-Object System.Drawing.Size(240, 20)
$showFilesCheckBox.Text = "Bestanden tonen wanneer klaar"
$showFilesCheckBox.Checked = $true
$advancedGroupBox.Controls.Add($showFilesCheckBox)

# Add checkbox for using cookies
$cookieCheckBox = New-Object System.Windows.Forms.CheckBox
$cookieCheckBox.Location = New-Object System.Drawing.Point(270, 30)
$cookieCheckBox.Size = New-Object System.Drawing.Size(120, 20)
$cookieCheckBox.Text = "Cookies gebruiken"
$cookieCheckBox.Checked = $false
$advancedGroupBox.Controls.Add($cookieCheckBox)

# Add browser dropdown for cookies
$browserDropdown = New-Object System.Windows.Forms.ComboBox
$browserDropdown.Location = New-Object System.Drawing.Point(270, 50)
$browserDropdown.Size = New-Object System.Drawing.Size(100, 20)
[void]$browserDropdown.Items.AddRange(@("Firefox", "Chrome", "Edge"))
$browserDropdown.SelectedIndex = 0  # Default to Firefox
$browserDropdown.Enabled = $false  # Initially disabled
$advancedGroupBox.Controls.Add($browserDropdown)

# Enable/disable browser dropdown based on cookie checkbox
$cookieCheckBox.Add_CheckedChanged({
    $browserDropdown.Enabled = $cookieCheckBox.Checked
})

# Add checkbox for enabling logging to file
$enableLoggingCheckBox = New-Object System.Windows.Forms.CheckBox
$enableLoggingCheckBox.Location = New-Object System.Drawing.Point(20, 110)
$enableLoggingCheckBox.Size = New-Object System.Drawing.Size(240, 20)
$enableLoggingCheckBox.Text = "Loggen naar bestand"
$enableLoggingCheckBox.Checked = $global:enableLogging  # Set based on command line parameter
$advancedGroupBox.Controls.Add($enableLoggingCheckBox)

# Create a log textbox - moved down to make room for advanced settings
$logTextBox = New-Object System.Windows.Forms.RichTextBox
$logTextBox.Location = New-Object System.Drawing.Point(20, 710)
$logTextBox.Size = New-Object System.Drawing.Size(460, 100)
$logTextBox.ReadOnly = $true
$logTextBox.BackColor = [System.Drawing.Color]::White
$logTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
$form.Controls.Add($logTextBox)

# Create a status strip (vervangt StatusBar)
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Gereed"
[void]$statusStrip.Items.Add($statusLabel)
$form.Controls.Add($statusStrip)

# Create a GO button
$goButton = New-Object System.Windows.Forms.Button
$goButton.Location = New-Object System.Drawing.Point(160, 500)
$goButton.Size = New-Object System.Drawing.Size(200, 200)
$caviaIcon = [System.Drawing.Image]::FromFile("$PSScriptRoot\icons\go-caviaPirate.png")
#$goButton.Text = "GO"
$goButton.image = $caviaIcon
$goButton.imageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$goButton.BackColor = [System.Drawing.Color]::Black
$goButton.Add_Click({
    # Validate input (URL or batch file)
    if ($batchFileCheckBox.Checked) {
        if ([string]::IsNullOrEmpty($batchFileTextBox.Text) -or -not (Test-Path $batchFileTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Selecteer een geldig bestand met URLs", "Fout", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    } else {
        if ([string]::IsNullOrEmpty($urlTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Voer een URL in", "Fout", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    }
    
    # Check if at least one format is selected
    if (-not ($mp3CheckBox.Checked -or $mp4CheckBox.Checked -or $wavCheckBox.Checked)) {
        [System.Windows.Forms.MessageBox]::Show("Selecteer tenminste één formaat", "Fout", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    # Function to add cookie parameters to yt-dlp command
    function Add-CookieParameters {
        param([string]$command)
        if ($cookieCheckBox.Checked) {
            $browser = $browserDropdown.SelectedItem.ToString().ToLower()
            $command += " --cookies-from-browser $browser"
        }
        return $command
    }
    
    # Get the URL or batch file
    if ($batchFileCheckBox.Checked) {
        $batchFile = $batchFileTextBox.Text
    } else {
        $url = $urlTextBox.Text
    }
    
    # Determine selected formats and create optimized download strategy
    $selectedFormats = @()
    if ($mp3CheckBox.Checked) { $selectedFormats += "MP3" }
    if ($mp4CheckBox.Checked) { $selectedFormats += "MP4" }
    if ($wavCheckBox.Checked) { $selectedFormats += "WAV" }
    
    $downloadCommands = @()
    
    if ($selectedFormats.Count -gt 1) {
        # Multiple formats selected - download once with keep original, then convert
        $baseCommand = ".\tools\yt-dlp.exe -k --ffmpeg-location .\tools\ffmpeg.exe"
        $baseCommand = Add-CookieParameters -command $baseCommand
        if ($playlistCheckBox.Checked) { $baseCommand += " --yes-playlist" }
        if ($batchFileCheckBox.Checked) {
            $baseCommand += ' -a "' + $batchFile + '"'
        } else {
            $baseCommand += ' "' + $url + '"'
        }
        $downloadCommands += @{ Format = "BASE"; Command = $baseCommand }
        
        # Add conversion commands for each format
        foreach ($format in $selectedFormats) {
            if ($format -eq "MP3") {
                $selectedBitrate = $bitrateDropdown.SelectedItem
                $convertCommand = "CONVERT_MP3"
                if ($selectedBitrate -like "*VBR*") {
                    switch ($selectedBitrate) {
                        "V0 (VBR)" { $convertCommand += "_V0" }
                        "V2 (VBR)" { $convertCommand += "_V2" }
                        "V4 (VBR)" { $convertCommand += "_V4" }
                    }
                } else {
                    $convertCommand += "_CBR_$selectedBitrate"
                }
                $downloadCommands += @{ Format = $format; Command = $convertCommand }
            }
            elseif ($format -eq "WAV") {
                $downloadCommands += @{ Format = $format; Command = "CONVERT_WAV" }
            }
            elseif ($format -eq "MP4") {
                $downloadCommands += @{ Format = $format; Command = "CONVERT_MP4" }
            }
        }
    } else {
        # Single format selected - use direct download
        if ($mp3CheckBox.Checked) {
            $selectedBitrate = $bitrateDropdown.SelectedItem
            $mp3Command = ".\tools\yt-dlp.exe -x --audio-format mp3 --ffmpeg-location .\tools\ffmpeg.exe"
            $mp3Command = Add-CookieParameters -command $mp3Command
            
            # Handle bitrate settings
            if ($selectedBitrate -like "*VBR*") {
                # VBR settings
                switch ($selectedBitrate) {
                    "V0 (VBR)" { $mp3Command += " --audio-quality 0" }
                    "V2 (VBR)" { $mp3Command += " --audio-quality 2" }
                    "V4 (VBR)" { $mp3Command += " --audio-quality 4" }
                }
            } else {
                # CBR settings
                $mp3Command += " --audio-quality 0 --postprocessor-args `"-b:a $selectedBitrate`""
            }
            
            if ($playlistCheckBox.Checked) { $mp3Command += " --yes-playlist" }
            if ($batchFileCheckBox.Checked) {
                $mp3Command += ' -a "' + $batchFile + '"'
            } else {
                $mp3Command += ' "' + $url + '"'
            }
            $downloadCommands += @{ Format = "MP3"; Command = $mp3Command }
        }
        
        if ($mp4CheckBox.Checked) {
            $mp4Command = ".\tools\yt-dlp.exe -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'"
            $mp4Command = Add-CookieParameters -command $mp4Command
            if ($playlistCheckBox.Checked) { $mp4Command += " --yes-playlist" }
            if ($batchFileCheckBox.Checked) {
                $mp4Command += ' -a "' + $batchFile + '"'
            } else {
                $mp4Command += ' "' + $url + '"'
            }
            
            $downloadCommands += @{ Format = "MP4"; Command = $mp4Command }
        }
        
        if ($wavCheckBox.Checked) {
            $wavCommand = ".\tools\yt-dlp.exe -x --audio-format wav --audio-quality 0 --ffmpeg-location .\tools\ffmpeg.exe"
            $wavCommand = Add-CookieParameters -command $wavCommand
            if ($playlistCheckBox.Checked) { $wavCommand += " --yes-playlist" }
            if ($batchFileCheckBox.Checked) {
                $wavCommand += ' -a "' + $batchFile + '"'
            } else {
                $wavCommand += ' "' + $url + '"'
            }
            $downloadCommands += @{ Format = "WAV"; Command = $wavCommand }
        }
    }
    
    # Disable GO button during download
    $goButton.Enabled = $false
    $statusLabel.Text = "Bezig met downloaden..."
    $logTextBox.Text = ""
    
    # Log session start and settings
    Write-Log "=== NIEUWE DOWNLOADSESSIE GESTART ==="
    Write-Log "URL: $url"
    Write-Log "Geselecteerde formaten: $($selectedFormats -join ', ')"
    Write-Log "MP3 bitrate: $($bitrateDropdown.SelectedItem)"
    Write-Log "Playlist download: $($playlistCheckBox.Checked)"
    Write-Log "Cookies gebruiken: $($cookieCheckBox.Checked)"
    if ($cookieCheckBox.Checked) {
        Write-Log "Browser voor cookies: $($browserDropdown.SelectedItem)"
    }
    Write-Log "Origineel behouden: $($keepOriginalCheckBox.Checked)"
    Write-Log "Bestanden tonen: $($showFilesCheckBox.Checked)"
    Write-Log "Opslaglocatie: $global:savePath"
    Write-Log "Logbestand: $global:logFile"
    Write-Log "=================================="
    
    # Execute downloads and conversions
    $originalFile = $null
    $downloadedFiles = @()
    
    foreach ($downloadInfo in $downloadCommands) {
        $format = $downloadInfo["Format"]
        $command = $downloadInfo["Command"]

        try {
            if ($format -eq "BASE") {
                # Initial download with keep original
                $command += " -o `"$global:savePath/%(title)s.%(ext)s`""
                Write-Log "Download origineel bestand..."
                Write-Log "Uitvoeren: $command"
                
                $output = Invoke-Expression $command 2>&1 | Out-String
                Write-Log $output
                
                # Find the downloaded file - prefer the merged .webm file which contains both video and audio
                $originalFile = Get-ChildItem -Path $global:savePath -Filter "*.webm" | Where-Object { $_.Name -notlike "*f[0-9][0-9][0-9].webm" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if (-not $originalFile) {
                    # Fallback to other formats if no merged webm found
                    $originalFile = Get-ChildItem -Path $global:savePath -Filter "*.*" | Where-Object { $_.Extension -in @('.webm', '.mp4', '.mkv', '.m4a') } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                }
                Write-Log "Origineel bestand: $($originalFile.FullName)"
                
            } elseif ($command -like "CONVERT_*") {
                # Handle conversions
                if ($originalFile -eq $null) {
                    Write-Log "Fout: Geen origineel bestand gevonden voor conversie"
                    continue
                }
                
                Write-Log "Converteer naar $format..."
                $outputFile = $null
                
                if ($command.StartsWith("CONVERT_MP3")) {
                    $outputFile = [System.IO.Path]::ChangeExtension($originalFile.FullName, "mp3")
                    $ffmpegCommand = ".\tools\ffmpeg.exe -i `"$($originalFile.FullName)`" -vn"
                    
                    if ($command -eq "CONVERT_MP3_V0") {
                        $ffmpegCommand += " -q:a 0"
                    } elseif ($command -eq "CONVERT_MP3_V2") {
                        $ffmpegCommand += " -q:a 2"
                    } elseif ($command -eq "CONVERT_MP3_V4") {
                        $ffmpegCommand += " -q:a 4"
                    } elseif ($command -like "CONVERT_MP3_CBR_*") {
                        $bitrate = $command.Replace("CONVERT_MP3_CBR_", "")
                        $ffmpegCommand += " -b:a $bitrate"
                    }
                    
                    $ffmpegCommand += " `"$outputFile`""
                    
                } elseif ($command -eq "CONVERT_WAV") {
                    $outputFile = [System.IO.Path]::ChangeExtension($originalFile.FullName, "wav")
                    $ffmpegCommand = ".\tools\ffmpeg.exe -i `"$($originalFile.FullName)`" -vn -ar 44100 -ac 2 `"$outputFile`""
                    
                } elseif ($command -eq "CONVERT_MP4") {
                    if ($originalFile.Extension -ne ".mp4") {
                        $outputFile = [System.IO.Path]::ChangeExtension($originalFile.FullName, "mp4")
                        $ffmpegCommand = ".\tools\ffmpeg.exe -i `"$($originalFile.FullName)`" -c copy `"$outputFile`""
                    } else {
                        Write-Log "Bestand is al MP4, conversie overgeslagen"
                        continue
                    }
                }
                
                if ($ffmpegCommand) {
                    Write-Log "Uitvoeren: $ffmpegCommand"
                    try {
                        Write-Log "Input bestand: $($originalFile.FullName)"
                        Write-Log "Input bestand bestaat: $(Test-Path $originalFile.FullName)"
                        if (Test-Path $originalFile.FullName) {
                            Write-Log "Input bestand grootte: $((Get-Item $originalFile.FullName).Length) bytes"
                        }
                        
                        # First check what streams are available
                        Write-Log "Checking streams in input file..."
                        $streamCheck = cmd /c ".\tools\ffmpeg.exe -i `"$($originalFile.FullName)`" 2>&1"
                        Write-Log "Stream info:"
                        Write-Log ($streamCheck | Out-String)
                        
                        # Build correct ffmpeg command based on format
                        if ($command.StartsWith("CONVERT_MP3")) {
                            if ($command -eq "CONVERT_MP3_V0") {
                                $args = "-i `"$($originalFile.FullName)`" -vn -q:a 0 -y `"$outputFile`""
                            } elseif ($command -eq "CONVERT_MP3_V2") {
                                $args = "-i `"$($originalFile.FullName)`" -vn -q:a 2 -y `"$outputFile`""
                            } elseif ($command -eq "CONVERT_MP3_V4") {
                                $args = "-i `"$($originalFile.FullName)`" -vn -q:a 4 -y `"$outputFile`""
                            } elseif ($command -like "CONVERT_MP3_CBR_*") {
                                $bitrate = $command.Replace("CONVERT_MP3_CBR_", "")
                                $args = "-i `"$($originalFile.FullName)`" -vn -b:a $bitrate -y `"$outputFile`""
                            }
                        } elseif ($command -eq "CONVERT_WAV") {
                            $args = "-i `"$($originalFile.FullName)`" -vn -ar 44100 -ac 2 -y `"$outputFile`""
                        } elseif ($command -eq "CONVERT_MP4") {
                            $args = "-i `"$($originalFile.FullName)`" -c copy -y `"$outputFile`""
                        }
                        
                        $ffmpegOutput = cmd /c ".\tools\ffmpeg.exe $args 2>&1"
                        Write-Log "FFmpeg volledige output:"
                        Write-Log ($ffmpegOutput | Out-String)
                        
                        # Check if output file was created
                        if (Test-Path $outputFile) {
                            $fileSize = (Get-Item $outputFile).Length
                            Write-Log "$format conversie voltooid: $outputFile (${fileSize} bytes)"
                            $downloadedFiles += $outputFile
                        } else {
                            Write-Log "FOUT: $format bestand niet aangemaakt: $outputFile"
                        }
                    } catch {
                        Write-Log "FOUT bij $format conversie: $($_.Exception.Message)"
                    }
                }
                
            } else {
                # Regular single-format download
                $command += " -o `"$global:savePath/%(title)s.%(ext)s`""
                Write-Log "Start download in $format formaat..."
                Write-Log "Uitvoeren: $command"
                
                $output = Invoke-Expression $command 2>&1 | Out-String
                Write-Log $output
                Write-Log "$format download voltooid."
                
                # Track downloaded files for single format downloads
                $downloadedFile = Get-ChildItem -Path $global:savePath -Filter "*.$($format.ToLower())" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($downloadedFile) {
                    $downloadedFiles += $downloadedFile.FullName
                }
            }
            
            $logTextBox.ScrollToCaret()
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Log "Fout bij ${format}: $errorMessage"
        }
    }
    
    # Clean up original files if multiple formats were processed and keep original is not checked
    if ($originalFile -and $selectedFormats.Count -gt 1 -and !$keepOriginalCheckBox.Checked) {
        try {
            # Remove both the main file and any additional files like .f251.webm
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($originalFile.Name)
            $originalDir = $originalFile.Directory.FullName
            $filesToRemove = Get-ChildItem -Path $originalDir -Filter "$baseName.*" | Where-Object { $_.Extension -in @('.webm', '.mkv', '.m4a') -or $_.Name -like "*f[0-9][0-9][0-9].webm" }
            
            foreach ($fileToRemove in $filesToRemove) {
                Remove-Item $fileToRemove.FullName -Force
                Write-Log "Origineel bestand verwijderd: $($fileToRemove.Name)"
            }
        } catch {
            Write-Log "Kon originele bestanden niet verwijderen: $($_.Exception.Message)"
        }
    }
    
    # Show files in explorer if requested
    if ($showFilesCheckBox.Checked) {
        try {
            Write-Log "Opening Windows Explorer met download locatie..."
            
            # Try to select a specific downloaded file
            $fileToSelect = $null
            if ($downloadedFiles.Count -gt 0) {
                $fileToSelect = $downloadedFiles[0] # Select first downloaded/converted file
            } elseif ($originalFile) {
                $fileToSelect = $originalFile.FullName # Fallback to original file
            }
            
            if ($fileToSelect -and (Test-Path $fileToSelect)) {
                Write-Log "Selecteer bestand: $fileToSelect"
                Start-Process "explorer.exe" -ArgumentList "/select,`"$fileToSelect`""
            } else {
                # Fallback: just open the folder
                Write-Log "Geen specifiek bestand om te selecteren, open folder..."
                Start-Process "explorer.exe" -ArgumentList "`"$global:savePath`""
            }
        } catch {
            try {
                # Final fallback: just open the folder
                Write-Log "Fallback: Opening folder in Explorer..."
                Start-Process "explorer.exe" -ArgumentList "`"$global:savePath`""
            } catch {
                Write-Log "Fout bij openen van Explorer: $($_.Exception.Message)"
            }
        }
    }
    
    # Re-enable GO button
    $goButton.Enabled = $true
    $statusLabel.Text = "Downloads voltooid"
})
$form.Controls.Add($goButton)

# Add a clear button
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Location = New-Object System.Drawing.Point(20, 340)
$clearButton.Size = New-Object System.Drawing.Size(80, 30)
$clearButton.Text = "Wissen"
$clearButton.Add_Click({
    $urlTextBox.Text = ""
    $logTextBox.Text = ""
    $statusLabel.Text = "Gereed"
})
$form.Controls.Add($clearButton)

# Add an about button
$aboutButton = New-Object System.Windows.Forms.Button
$aboutButton.Location = New-Object System.Drawing.Point(400, 340)
$aboutButton.Size = New-Object System.Drawing.Size(80, 30)
$aboutButton.Text = "Info"
$aboutButton.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Pirate Cavia, HAR HAR`nGebruik yt-dlp om content te downloaden`nVersie 1.0", "Over de applicatie")
})
$form.Controls.Add($aboutButton)

# Adjust button positions to ensure visibility - moved down to accommodate all elements
$goButton.Location = New-Object System.Drawing.Point(160, 500) # Adjusted position to center between 'Wissen' and 'Info'
$clearButton.Location = New-Object System.Drawing.Point(20, 500)
$aboutButton.Location = New-Object System.Drawing.Point(400, 500)

# Voeg een knop toe om een opslaglocatie te selecteren - moved down to avoid overlap
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Location = New-Object System.Drawing.Point(20, 175)
$browseButton.Size = New-Object System.Drawing.Size(80, 30)
$browseButton.Text = "Bladeren"

# Voeg een label toe om de geselecteerde map weer te geven - moved down to avoid overlap
$savePathLabel = New-Object System.Windows.Forms.Label
$savePathLabel.Location = New-Object System.Drawing.Point(120, 175)
$savePathLabel.Size = New-Object System.Drawing.Size(360, 30)
$savePathLabel.Text = "standaard locatie: " + (Get-Location).Path + "\Downloads" # Default to Downloads subfolder
$form.Controls.Add($savePathLabel)
$form.Controls.Add($browseButton)

# Voeg functionaliteit toe aan de bladerknop
$browseButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $savePathLabel.Text = "Geselecteerde locatie: " + $folderBrowser.SelectedPath
        $global:savePath = $folderBrowser.SelectedPath # Store the selected path globally
        Write-Log "Geselecteerde opslaglocatie: $($folderBrowser.SelectedPath)"
    }
})

# Process startup updates if requested
if ($startupUpdates.UpdateYtDlp -or $startupUpdates.UpdateFFmpeg) {
    # Create a simple progress form
    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Text = "Updates uitvoeren..."
    $progressForm.Size = New-Object System.Drawing.Size(300, 100)
    $progressForm.StartPosition = "CenterScreen"
    $progressForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $progressForm.MaximizeBox = $false
    $progressForm.MinimizeBox = $false
    
    $progressLabel = New-Object System.Windows.Forms.Label
    $progressLabel.Location = New-Object System.Drawing.Point(20, 20)
    $progressLabel.Size = New-Object System.Drawing.Size(250, 30)
    $progressLabel.Text = "Updates worden uitgevoerd..."
    $progressForm.Controls.Add($progressLabel)
    
    $progressForm.Show()
    $progressForm.Refresh()
    
    if ($startupUpdates.UpdateYtDlp) {
        $progressLabel.Text = "yt-dlp updaten..."
        $progressForm.Refresh()
        
        try {
            $updateScript = ".\tools\updaters\update-ytdlp.ps1"
            $ytdlPath = ".\tools"
            if (Test-Path $updateScript) {
                & powershell.exe -ExecutionPolicy Bypass -File $updateScript -DownloadPath $ytdlPath | Out-Null
            }
        } catch {
            # Continue even if update fails
        }
    }
    
    if ($startupUpdates.UpdateFFmpeg) {
        $progressLabel.Text = "FFmpeg updaten..."
        $progressForm.Refresh()
        
        try {
            $updateScript = ".\tools\updaters\update-ffmpeg.ps1"
            $ffmpegPath = ".\tools"
            if (Test-Path $updateScript) {
                & powershell.exe -ExecutionPolicy Bypass -File $updateScript -DownloadPath $ffmpegPath | Out-Null
            }
        } catch {
            # Continue even if update fails
        }
    }
    
    $progressForm.Close()
    $progressForm.Dispose()
}

# Show the form
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()

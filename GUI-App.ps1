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

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Pirate Cavia, HAR HAR"
$form.Size = New-Object System.Drawing.Size(700, 820) # Increased height to accommodate extra checkbox
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(460, 30)
$label.Text = "Pirate Cavia - Voer URL in"
$label.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($label)

# Create a URL textbox
$urlTextBox = New-Object System.Windows.Forms.TextBox
$urlTextBox.Location = New-Object System.Drawing.Point(20, 60)
$urlTextBox.Size = New-Object System.Drawing.Size(460, 30)
$urlTextBox.PlaceholderText = "Voer URL in..."
$form.Controls.Add($urlTextBox)

# Create format option group box
$formatGroupBox = New-Object System.Windows.Forms.GroupBox
$formatGroupBox.Location = New-Object System.Drawing.Point(20, 100)
$formatGroupBox.Size = New-Object System.Drawing.Size(460, 120)
$formatGroupBox.Text = "Download Format"
$form.Controls.Add($formatGroupBox)

# Create MP3 checkbox
$mp3CheckBox = New-Object System.Windows.Forms.CheckBox
$mp3CheckBox.Location = New-Object System.Drawing.Point(20, 30)
$mp3CheckBox.Size = New-Object System.Drawing.Size(100, 20)
$mp3CheckBox.Text = "MP3"
$mp3CheckBox.Checked = $true
$formatGroupBox.Controls.Add($mp3CheckBox)

# Create MP4 checkbox
$mp4CheckBox = New-Object System.Windows.Forms.CheckBox
$mp4CheckBox.Location = New-Object System.Drawing.Point(20, 60)
$mp4CheckBox.Size = New-Object System.Drawing.Size(100, 20)
$mp4CheckBox.Text = "MP4"
$formatGroupBox.Controls.Add($mp4CheckBox)

# Create WAV checkbox
$wavCheckBox = New-Object System.Windows.Forms.CheckBox
$wavCheckBox.Location = New-Object System.Drawing.Point(20, 90)
$wavCheckBox.Size = New-Object System.Drawing.Size(100, 20)
$wavCheckBox.Text = "WAV"
$formatGroupBox.Controls.Add($wavCheckBox)


# Create playlist checkbox
$playlistCheckBox = New-Object System.Windows.Forms.CheckBox
$playlistCheckBox.Location = New-Object System.Drawing.Point(200, 30)
$playlistCheckBox.Size = New-Object System.Drawing.Size(240, 20)
$playlistCheckBox.Text = "Download hele playlist"
$formatGroupBox.Controls.Add($playlistCheckBox)

# create a button to select the save path in the format group box right below the playlist checkbox
$savePathButton = New-Object System.Windows.Forms.Button
$savePathButton.Location = New-Object System.Drawing.Point(200, 70) # Adjusted position to be below the savePathTextBox
$savePathButton.Size = New-Object System.Drawing.Size(240, 30)
$savePathButton.Text = "Bladeren"
$savePathButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $savePathTextBox.Text = $folderBrowser.SelectedPath
        $global:savePath = $folderBrowser.SelectedPath # Store the selected path globally
        if ($folderBrowser.SelectedPath) {
            Write-Log "Geselecteerde opslaglocatie: $($folderBrowser.SelectedPath)"
        } else {
            Write-Log "Geen opslaglocatie geselecteerd."
        }
    }
})
# Create a textbox to display the selected save path
$savePathTextBox = New-Object System.Windows.Forms.TextBox
$savePathTextBox.Location = New-Object System.Drawing.Point(200, 50)
$savePathTextBox.Size = New-Object System.Drawing.Size(240, 40)
$savePathTextBox.Text = ("standaard locatie: {0}\Downloads" -f (Get-Location).Path)  # Default to Downloads subfolder
$formatGroupBox.Controls.Add($savePathTextBox)
$formatGroupBox.Controls.Add($savePathButton)

# Create advanced settings group box
$advancedGroupBox = New-Object System.Windows.Forms.GroupBox
$advancedGroupBox.Location = New-Object System.Drawing.Point(20, 230)
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
$bitrateDropdown.Items.AddRange(@("128k", "192k", "256k", "320k", "V0 (VBR)", "V2 (VBR)", "V4 (VBR)"))
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

# Create a log textbox - moved down to make room for advanced settings
$logTextBox = New-Object System.Windows.Forms.RichTextBox
$logTextBox.Location = New-Object System.Drawing.Point(20, 380)
$logTextBox.Size = New-Object System.Drawing.Size(460, 100)
$logTextBox.ReadOnly = $true
$logTextBox.BackColor = [System.Drawing.Color]::White
$logTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
$form.Controls.Add($logTextBox)

# Create a status strip (vervangt StatusBar)
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Gereed"
$statusStrip.Items.Add($statusLabel)
$form.Controls.Add($statusStrip)

# Create a GO button
$goButton = New-Object System.Windows.Forms.Button
$goButton.Location = New-Object System.Drawing.Point(100, 150)
$goButton.Size = New-Object System.Drawing.Size(200, 200)
$caviaIcon = [System.Drawing.Image]::FromFile("icons/go-caviaPirate.png")
#$goButton.Text = "GO"
$goButton.image = $caviaIcon
$goButton.imageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$goButton.BackColor = [System.Drawing.Color]::Black
$goButton.Add_Click({
    # Validate URL
    if ([string]::IsNullOrEmpty($urlTextBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Voer een URL in", "Fout", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    # Check if at least one format is selected
    if (-not ($mp3CheckBox.Checked -or $mp4CheckBox.Checked -or $wavCheckBox.Checked)) {
        [System.Windows.Forms.MessageBox]::Show("Selecteer tenminste één formaat", "Fout", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    # Get the URL
    $url = $urlTextBox.Text
    
    # Determine selected formats and create optimized download strategy
    $selectedFormats = @()
    if ($mp3CheckBox.Checked) { $selectedFormats += "MP3" }
    if ($mp4CheckBox.Checked) { $selectedFormats += "MP4" }
    if ($wavCheckBox.Checked) { $selectedFormats += "WAV" }
    
    $downloadCommands = @()
    
    if ($selectedFormats.Count -gt 1) {
        # Multiple formats selected - download once with keep original, then convert
        $baseCommand = ".\ytdl\yt-dlp.exe -k --ffmpeg-location .\tools\ffmpeg.exe"
        if ($playlistCheckBox.Checked) { $baseCommand += " --yes-playlist" }
        $baseCommand += ' "' + $url + '"'
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
            $mp3Command = ".\ytdl\yt-dlp.exe -x --audio-format mp3 --ffmpeg-location .\tools\ffmpeg.exe"
            
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
            $mp3Command += ' "' + $url + '"'
            $downloadCommands += @{ Format = "MP3"; Command = $mp3Command }
        }
        
        if ($mp4CheckBox.Checked) {
            $mp4Command = ".\ytdl\yt-dlp.exe -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'"
            if ($playlistCheckBox.Checked) { $mp4Command += " --yes-playlist" }
            $mp4Command += ' "' + $url + '"'
            $downloadCommands += @{ Format = "MP4"; Command = $mp4Command }
        }
        
        if ($wavCheckBox.Checked) {
            $wavCommand = ".\ytdl\yt-dlp.exe -x --audio-format wav --audio-quality 0 --ffmpeg-location .\tools\ffmpeg.exe"
            if ($playlistCheckBox.Checked) { $wavCommand += " --yes-playlist" }
            $wavCommand += ' "' + $url + '"'
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

# Create a menu bar
$menuBar = New-Object System.Windows.Forms.MenuStrip
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "Bestand"

$newItem = New-Object System.Windows.Forms.ToolStripMenuItem
$newItem.Text = "Nieuw"
$newItem.Add_Click({
    $urlTextBox.Text = ""
    $mp3CheckBox.Checked = $true
    $mp4CheckBox.Checked = $false
    $wavCheckBox.Checked = $false
    $playlistCheckBox.Checked = $false
    $logTextBox.Text = ""
    $statusLabel.Text = "Gereed"
})

$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitItem.Text = "Afsluiten"
$exitItem.Add_Click({
    $form.Close()
})

$fileMenu.DropDownItems.Add($newItem)
$fileMenu.DropDownItems.Add($exitItem)

$helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenu.Text = "Help"

$aboutItem = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutItem.Text = "Over"
$aboutItem.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Pirate Cavia, HAR HAR `nVersie 1.0", "Over")
})

$helpMenu.DropDownItems.Add($aboutItem)

$menuBar.Items.Add($fileMenu)
$menuBar.Items.Add($helpMenu)
$form.MainMenuStrip = $menuBar
$form.Controls.Add($menuBar)

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

# Show the form
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()

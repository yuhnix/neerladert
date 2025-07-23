# Changelog

All notable changes to Pirate Cavia will be documented in this file.

## [Unreleased]

### Added
- Batch file URL input support - Users can now select a text file containing multiple URLs using the "Gebruik bestand met URLs" checkbox
- Browse button for batch file selection with file dialog filtering for .txt files
- Automatic input validation for batch files (checks file existence)
- Mutual exclusion between single URL input and batch file input modes
- Support for yt-dlp -a parameter for batch downloads in all formats (MP3, MP4, WAV)
- Restored complete menu bar with File and Help menus
- Auto-update functionality for yt-dlp via Help menu with progress tracking
- Auto-update functionality for FFmpeg via Help menu with progress tracking
- Logging checkbox in advanced settings for runtime control
- "Nieuw" menu item to clear all inputs and reset application state
- "Over Pirate Cavia" dialog in Help menu

### Fixed
- Fixed icon path issue by using $PSScriptRoot for absolute path resolution
- Corrected yt-dlp.exe path from ytdl/ to tools/ directory to match project structure
- Fixed GUI layout issues where batch file controls were not accessible
- Fixed overlapping control positions after menu bar addition

### Changed
- Reorganized "Download Format" groupbox to "Algemeen" with better layout
- Batch file controls now properly integrated in main groupbox
- Format checkboxes (MP3, MP4, WAV) arranged horizontally for better space usage
- Adjusted all GUI element positions to accommodate menu bar
- Form dimensions optimized for all controls (520x820)
- Menu-driven workflow for updates instead of separate buttons

## [Previous Versions]

*Changelog history for previous versions to be added*
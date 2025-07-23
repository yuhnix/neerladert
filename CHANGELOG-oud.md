# Changelog

All notable changes to Pirate Cavia will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Auto-update functionality for yt-dlp via Help menu
- Auto-update functionality for FFmpeg via Help menu
- Logging checkbox in GUI advanced settings for runtime control
- Installation script with admin rights management
- Desktop shortcut creation option in installer
- PATH environment variable configuration
- User permissions setup for installation directory
- Hidden PowerShell console when launching via run-gui.cmd
- Comprehensive project changelog (CHANGELOG.md)

### Changed
- **BREAKING**: Reorganized folder structure - yt-dlp.exe moved to `/tools/` directory
- **BREAKING**: Update scripts moved to `/tools/updaters/` directory
- Logging is now optional (command-line parameter `-log` or GUI checkbox)
- run-gui.cmd now hides PowerShell console window with `-WindowStyle Hidden`
- Advanced settings group box expanded to accommodate logging checkbox
- Help menu reorganized with update options and separator
- Log textbox position adjusted for larger advanced settings group
- All download commands now reference yt-dlp.exe in tools directory
- Installation script updated for new folder structure

### Fixed
- Write-Log function now checks both command-line parameter and GUI checkbox
- Dynamic log file creation when logging enabled via checkbox
- Proper parameter passing through run-gui.cmd with `%*`
- **CRITICAL**: Fixed WebClient DownloadProgressChanged compatibility issue in update scripts
- **CRITICAL**: Fixed DateTime parsing errors in FFmpeg update script
- Update scripts now use Invoke-WebRequest instead of WebClient for better compatibility
- Improved error handling and fallback mechanisms in date parsing
- All script references updated to new folder structure

## [1.0.0] - Initial Release

### Added
- Windows Forms GUI application for media downloading
- Support for multiple formats: MP3, MP4, WAV
- Quality options: CBR bitrates (128k-320k) and VBR options (V0, V2, V4)
- Playlist download support
- Configurable save locations with folder browser
- Advanced settings for bitrate, file management, and display options
- Real-time logging in GUI textbox
- File logging with timestamps (when enabled)
- Progress tracking and status updates
- Windows Explorer integration for showing downloaded files
- Menu system with File and Help menus
- Icon-based GO button with pirate cavia theme
- Multiple format download optimization (downloads once, converts to multiple formats)
- File backup and cleanup functionality
- Error handling and user feedback dialogs

### Technical Features
- Built with PowerShell and Windows Forms
- Uses yt-dlp for core download functionality
- Uses FFmpeg suite for media conversion
- Git LFS integration for executable files
- Comprehensive logging system
- Session-based log files with unique timestamps
- Proper parameter handling for various download scenarios

### Dependencies
- yt-dlp.exe for video/audio downloading
- FFmpeg, FFplay, FFprobe for media processing
- Windows PowerShell 5.0 or later
- Windows Forms (built into Windows)

### Project Structure
- Main application: GUI-App.ps1 and GUI-App.exe
- Batch launcher: run-gui.cmd
- Tools directory with FFmpeg executables
- YouTube downloader directory with yt-dlp.exe
- Icons directory for GUI graphics
- Logs directory for session logs (when enabled)
- Downloads directory for output files (default)
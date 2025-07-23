# Pirate Cavia 🏴‍☠️

Een gebruiksvriendelijke Windows PowerShell GUI applicatie voor het downloaden van media content van URLs met behulp van yt-dlp en FFmpeg. "HAR HAR!"

## 📋 Overzicht

Pirate Cavia biedt een intuïtieve grafische interface voor het downloaden van video's en audio in verschillende formaten (MP3, MP4, WAV) met configureerbare kwaliteitsinstellingen. De applicatie gebruikt een geoptimaliseerde downloadstrategie en ondersteunt zowel enkele bestanden als complete playlists.

## ✨ Functies

- **Meerdere formaten**: MP3 (met bitrate opties), MP4, WAV
- **Kwaliteitsopties**: CBR bitrates (128k-320k) en VBR opties (V0, V2, V4)
- **Playlist ondersteuning**: Download complete playlists in één keer
- **Batch downloads**: Upload een tekstbestand met meerdere URLs voor bulk downloads
- **Bestandsbeheer**: Configureerbare opslaglocaties, optionele bestandsopruiming
- **Gebruikerservaring**: Voortgang tracking, Windows Explorer integratie
- **Automatische updates**: Ingebouwde update functionaliteit voor yt-dlp en FFmpeg via Help menu
- **Flexibele logging**: Optionele bestandslogging (command-line parameter of GUI checkbox)
- **Nederlandse interface**: Volledig in het Nederlands

## 📦 Installatie

### Automatische installatie (Aanbevolen)

1. Clone of download deze repository

2. **Open PowerShell als Administrator** (belangrijk!):
   
   **Windows 10/11:**
   - Druk op `Windows toets + X`
   - Selecteer "Windows PowerShell (Admin)" of "Terminal (Admin)"
   - Klik "Ja" bij de UAC waarschuwing
   
   **Alternatieve methode (alle Windows versies):**
   - Klik op Start menu
   - Type "powershell"
   - Rechtermuisklik op "Windows PowerShell"
   - Selecteer "Als administrator uitvoeren"
   - Klik "Ja" bij de UAC waarschuwing

3. Navigeer naar de project directory:
   ```powershell
   cd "C:\pad\naar\jouw\pirate-cavia-directory"
   ```

4. Voer het installatiescript uit:
   ```powershell
   powershell -ExecutionPolicy Bypass -File install.ps1
   ```

### Handmatige installatie

1. Zorg ervoor dat je Windows PowerShell hebt (standaard aanwezig op Windows)
2. Download de nieuwste versies van de externe tools:
   - [yt-dlp](https://github.com/yt-dlp/yt-dlp) - Plaats `yt-dlp.exe` in de `tools/` map
   - [FFmpeg](https://github.com/FFmpeg/FFmpeg) - Plaats `ffmpeg.exe`, `ffplay.exe`, en `ffprobe.exe` in de `tools/` map

## 🚀 Gebruik

### Applicatie starten

**Basis gebruik:**
```cmd
run-gui.cmd
```

**Met logging ingeschakeld:**
```cmd
run-gui.cmd -log
```

**Direct via PowerShell:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File GUI-App.ps1
```

**Met logging via PowerShell:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File GUI-App.ps1 -log
```

### Download proces

1. **URL invoeren**: Plak de URL van de video/playlist in het URL veld
   - **Alternatief**: Selecteer "Gebruik bestand met URLs" voor batch downloads
2. **Formaat selecteren**: Kies uit MP3, MP4, of WAV
3. **Kwaliteit instellen**: Selecteer gewenste bitrate of kwaliteitsinstelling
4. **Opslaglocatie**: Kies waar de bestanden opgeslagen moeten worden
5. **Download starten**: Klik op de download knop en volg de voortgang

### Batch Downloads

Voor het downloaden van meerdere URLs tegelijk:

1. **Maak een tekstbestand** (.txt) met URLs:
   ```
   https://www.youtube.com/watch?v=dQw4w9WgXcQ
   https://www.youtube.com/watch?v=oHg5SJYRHA0
   https://vimeo.com/12345678
   ```

2. **Selecteer batch modus**: Vink "Gebruik bestand met URLs" aan
3. **Kies bestand**: Klik "Bladeren" en selecteer je tekstbestand
4. **Configureer opties**: Stel formaat en kwaliteit in zoals gewoonlijk
5. **Start download**: De applicatie downloadt alle URLs in het bestand

**Tips voor batch files:**
- Eén URL per regel
- Ondersteunt alle websites die yt-dlp ondersteunt
- Kan gecombineerd worden met playlist opties
- Lege regels worden genegeerd

### Download strategie

De applicatie gebruikt een geoptimaliseerde benadering:
- **Enkel formaat**: Directe download in doelformaat
- **Meerdere formaten**: Eenmalige download, daarna conversie met FFmpeg
- **Playlists**: Ondersteunt volledige playlist downloads

## 📁 Projectstructuur

```
├── GUI-App.ps1          # Hoofd PowerShell GUI applicatie
├── GUI-App.exe          # Gecompileerde executable (Git LFS)
├── run-gui.cmd          # Batch launcher (verborgen PowerShell venster)
├── install.ps1          # Installatiescript
├── CLAUDE.md            # Project instructies voor Claude Code
├── CHANGELOG.md         # Project changelog
├── tools/               # Externe tools directory
│   ├── ffmpeg.exe       # Media conversie tool
│   ├── ffplay.exe       # Media speler
│   ├── ffprobe.exe      # Media analyse tool
│   ├── yt-dlp.exe       # YouTube download tool
│   └── updaters/        # Update scripts directory
│       ├── update-ytdlp.ps1  # yt-dlp update script
│       └── update-ffmpeg.ps1 # FFmpeg update script
├── ytdl/               # Legacy directory (kan error logs bevatten)
├── icons/              # Applicatie iconen
├── logs/               # Applicatie log bestanden (optioneel)
└── Downloads/          # Standaard download directory
```

## 🔧 Afhankelijkheden

### Externe Tools

- **[yt-dlp](https://github.com/yt-dlp/yt-dlp)**: Kern download functionaliteit
  - Een fork van youtube-dl met extra functies en snellere updates
  - Ondersteunt 1000+ websites
- **[FFmpeg](https://github.com/FFmpeg/FFmpeg)**: Media conversie en verwerking
  - Krachtige multimedia framework
  - Gebruikt voor audio/video conversie en optimalisatie

### Systeem Vereisten

- **Besturingssysteem**: Windows 7 of nieuwer
- **PowerShell**: Versie 3.0 of nieuwer (standaard op moderne Windows)
- **Windows Forms**: Ingebouwd in Windows
- **.NET Framework**: 4.5 of nieuwer (meestal al aanwezig)

## 📝 Logging

De applicatie biedt flexibele logging opties:

### GUI Logging
- Altijd beschikbaar in de applicatie interface
- Real-time weergave van download voortgang en status
- Error meldingen en debugging informatie

### Bestandslogging (Optioneel)
- Ingeschakeld met `-log` parameter of GUI checkbox
- Sessie-gebaseerde log bestanden met timestamps
- Opgeslagen in `logs/pirate-cavia-YYYY-MM-DD-HHMM.log`
- Uitgebreide debugging informatie voor troubleshooting

### Legacy Logs
- `ytdl/error.log`: yt-dlp specifieke errors (legacy locatie)

## 🛠️ Ontwikkeling

Dit is een standalone PowerShell applicatie zonder build systeem.

### Belangrijke operaties:
- **Applicatie draaien**: `.\run-gui.cmd`
- **Met logging**: `.\run-gui.cmd -log`
- **Logs bekijken**: Check `logs/` directory (alleen met `-log` parameter)
- **Updates**: Via Help menu in de applicatie

### Configuratie
De applicatie slaat instellingen op in globale PowerShell variabelen tijdens runtime:
- `$global:savePath`: Download directory
- `$global:logFile`: Huidige sessie log bestand
- `$global:logDir`: Log directory pad

## 🔄 Updates

De applicatie heeft ingebouwde update functionaliteit:
- **yt-dlp updates**: Via Help → Update yt-dlp
- **FFmpeg updates**: Via Help → Update FFmpeg
- Updates worden automatisch gedownload naar de `tools/` directory

## 📋 Ondersteunde Sites

Dankzij yt-dlp ondersteunt Pirate Cavia 1000+ websites, waaronder:
- YouTube
- Vimeo
- Twitch
- Facebook
- Instagram
- En vele anderen...

Voor een volledige lijst, zie: [yt-dlp supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)

## 🐛 Troubleshooting

### Veel voorkomende problemen:

1. **PowerShell ExecutionPolicy errors**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Missing external tools**:
   - Controleer of `yt-dlp.exe` en FFmpeg bestanden in `tools/` staan
   - Gebruik de automatische updaters via het Help menu

3. **Download errors**:
   - Controleer internet verbinding
   - Verifieer of de URL geldig is
   - Bekijk log bestanden voor details (gebruik `-log` parameter)

4. **Conversion failures**:
   - Zorg ervoor dat FFmpeg correct geïnstalleerd is
   - Controleer beschikbare schijfruimte

## 📄 Licentie

Dit project gebruikt externe tools met hun eigen licenties:
- **yt-dlp**: [Unlicense](https://github.com/yt-dlp/yt-dlp/blob/master/LICENSE)
- **FFmpeg**: [LGPL/GPL](https://github.com/FFmpeg/FFmpeg/blob/master/COPYING.LGPLv3)

## 🤝 Bijdragen

Voor vragen, bugs, of feature requests, open een issue in deze repository.

## 🔗 Nuttige Links

- [yt-dlp GitHub Repository](https://github.com/yt-dlp/yt-dlp)
- [yt-dlp Documentatie](https://github.com/yt-dlp/yt-dlp#readme)
- [FFmpeg GitHub Repository](https://github.com/FFmpeg/FFmpeg)
- [FFmpeg Documentatie](https://ffmpeg.org/documentation.html)
- [PowerShell Documentatie](https://docs.microsoft.com/en-us/powershell/)

---

**Pirate Cavia - HAR HAR! 🏴‍☠️**
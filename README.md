# Cool Retro Terminal - Windows .NET Framework Edition

A retro-style terminal emulator for Windows, built with .NET Framework 4.8 and WPF. This Windows-only port brings the nostalgic CRT monitor aesthetic to modern Windows systems.

|> Default Amber|> Default Green|> Classic White|
|---|---|---|
|![Amber Theme](https://via.placeholder.com/300x200/ffbf00/000000?text=Amber+Theme)|![Green Theme](https://via.placeholder.com/300x200/00ff00/000000?text=Green+Theme)|![White Theme](https://via.placeholder.com/300x200/ffffff/000000?text=White+Theme)|

## Description

Cool Retro Terminal - Windows Edition is a terminal emulator that recreates the authentic look and feel of old CRT monitors. Built specifically for Windows using .NET Framework 4.8, it provides:

- **Authentic CRT Effects**: Scanlines, glow, and screen curvature simulation
- **Windows Integration**: Native Windows Command Prompt integration  
- **Customizable Appearance**: Multiple color schemes, fonts, and visual effects
- **Modern Performance**: Leverages .NET Framework capabilities for optimal performance
- **Windows-Only Focus**: Designed specifically for Windows without cross-platform bloat

## Features

- ✨ **Retro Visual Effects**: Realistic CRT monitor simulation with scanlines, glow, and curvature
- 🎨 **Customizable Themes**: Built-in color schemes (Amber, Green, White) with custom color support
- 🖥️ **Windows Command Prompt Integration**: Full access to Windows command line tools
- ⌨️ **Modern Terminal Features**: Copy/paste, command history, zoom controls
- 🎯 **Native Windows Performance**: Built with .NET Framework for optimal Windows integration
- 📝 **Settings Persistence**: Automatic saving and loading of user preferences

## Installation

### Prerequisites
- Windows 10 or Windows 11
- .NET Framework 4.8 (usually pre-installed on modern Windows)

### Download & Install

1. **Download from Releases**
   - Go to the [Releases](../../releases) page
   - Download the latest `CoolRetroTerm-Setup.exe`
   - Run the installer and follow the installation wizard

2. **Portable Version**
   - Download `CoolRetroTerm-Portable.zip`
   - Extract to any folder
   - Run `CoolRetroTerm.exe`

### Build from Source

Requirements:
- Visual Studio 2019 or 2022 with .NET Framework development workload
- .NET Framework 4.8 SDK

Steps:
```batch
# Clone the repository
git clone https://github.com/y7thangeru/cool-retro-term-WIN.git
cd cool-retro-term-WIN

# Build the solution
msbuild CoolRetroTerm.sln /p:Configuration=Release

# Run the application
src\CoolRetroTerm\bin\Release\CoolRetroTerm.exe
```

## Usage

### Getting Started

1. **Launch the Application**
   - Double-click `CoolRetroTerm.exe` or use the Start Menu shortcut
   - The terminal opens with a retro amber theme by default

2. **Basic Commands**
   ```
   help          - Show available commands
   clear / cls   - Clear the screen  
   exit          - Exit the application
   ver           - Show version information
   ```

3. **Windows Commands**
   - All standard Windows Command Prompt commands are available
   - `dir`, `cd`, `copy`, `del`, `ping`, etc.

### Keyboard Shortcuts

- **F11**: Toggle fullscreen mode
- **Ctrl+C**: Copy selected text
- **Ctrl+V**: Paste from clipboard
- **Ctrl+A**: Select all text
- **↑/↓**: Navigate command history
- **Ctrl+Plus/Minus**: Zoom in/out
- **Ctrl+0**: Reset zoom to default

### Customization

#### Changing Color Schemes
1. Go to **Settings** → **Color Scheme**
2. Choose from predefined themes or create custom colors
3. Changes apply immediately

#### Font Settings  
1. Go to **Settings** → **Font Settings**
2. Select from available monospace fonts
3. Adjust font size as needed

#### Visual Effects
1. Go to **Settings** → **Effects**
2. Toggle scanlines, glow, and screen curvature
3. Adjust effect intensity

### Configuration

Settings are automatically saved to:
```
%AppData%\CoolRetroTerm\settings.json
```

Example settings file:
```json
{
  "FontFamily": "Consolas",
  "FontSize": 14,
  "ForegroundColor": "#00FF00",
  "BackgroundColor": "#000000",
  "EnableScanlines": true,
  "EnableGlow": true,
  "EnableCurvature": true
}
```

## Troubleshooting

### Common Issues

**"Application won't start"**
- Ensure .NET Framework 4.8 is installed
- Check Windows Event Viewer for error details

**"Commands don't work"**
- Try running as Administrator
- Check Windows PATH environment variable

**"Text appears blurry"**
- Disable Windows DPI scaling for the application
- Right-click exe → Properties → Compatibility → Change high DPI settings

### Performance Tips

- Disable unnecessary visual effects if performance is slow
- Use hardware acceleration if available
- Close other applications if experiencing lag

## Development

Built with:
- **.NET Framework 4.8**: Core application framework
- **WPF (Windows Presentation Foundation)**: UI framework
- **System.Diagnostics.Process**: Windows Command Prompt integration
- **System.Drawing**: Font and graphics handling

Architecture:
- **MVVM Pattern**: Clean separation of concerns
- **Services**: Font management, file I/O, terminal communication
- **Custom Controls**: Retro terminal control with CRT effects
- **Settings Management**: JSON-based configuration persistence

## License

This project is licensed under the GNU General Public License v3.0 - see the [gpl-3.0.txt](gpl-3.0.txt) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)  
5. Open a Pull Request

## Acknowledgments

- Original cool-retro-term by Filippo Scognamiglio
- Inspiration from classic terminal emulators and CRT monitors
- Windows .NET Framework community for excellent documentation

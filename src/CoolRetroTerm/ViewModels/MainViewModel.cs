using System.ComponentModel;
using System.IO;
using CoolRetroTerm.Models;
using CoolRetroTerm.Services;

namespace CoolRetroTerm.ViewModels
{
    /// <summary>
    /// Main view model for the terminal application
    /// </summary>
    public class MainViewModel : INotifyPropertyChanged
    {
        private readonly TerminalService _terminalService;
        private readonly FontManagerService _fontManager;
        private readonly FileIOService _fileIOService;
        private TerminalSettings _settings;
        private string _statusText = "Ready";

        public MainViewModel(TerminalService terminalService)
        {
            _terminalService = terminalService;
            _fontManager = new FontManagerService();
            _fileIOService = new FileIOService();
            _settings = new TerminalSettings();

            LoadSettings();
        }

        public TerminalSettings Settings
        {
            get => _settings;
            set
            {
                _settings = value;
                OnPropertyChanged(nameof(Settings));
            }
        }

        public string StatusText
        {
            get => _statusText;
            set
            {
                _statusText = value;
                OnPropertyChanged(nameof(StatusText));
            }
        }

        public FontManagerService FontManager => _fontManager;

        private void LoadSettings()
        {
            // Load settings from application data directory
            var settingsPath = Path.Combine(
                _fileIOService.GetApplicationDataDirectory(),
                "settings.json");

            if (_fileIOService.FileExists(settingsPath))
            {
                try
                {
                    var json = _fileIOService.ReadFile(settingsPath);
                    // Simple JSON parsing would go here
                    // For now, use defaults
                }
                catch
                {
                    // Use default settings if loading fails
                }
            }

            // Ensure we have a valid monospace font
            var bestFont = _fontManager.GetBestMonospaceFont();
            if (!string.IsNullOrEmpty(bestFont))
            {
                Settings.FontFamily = bestFont;
            }
        }

        public void SaveSettings()
        {
            var settingsPath = Path.Combine(
                _fileIOService.GetApplicationDataDirectory(),
                "settings.json");

            try
            {
                // Simple JSON serialization would go here
                // For now, just create a basic settings file
                var settingsContent = $@"{{
    ""FontFamily"": ""{Settings.FontFamily}"",
    ""FontSize"": {Settings.FontSize},
    ""ForegroundColor"": ""{Settings.ForegroundColor}"",
    ""BackgroundColor"": ""{Settings.BackgroundColor}"",
    ""Opacity"": {Settings.Opacity},
    ""EnableScanlines"": {Settings.EnableScanlines.ToString().ToLower()},
    ""EnableGlow"": {Settings.EnableGlow.ToString().ToLower()},
    ""EnableCurvature"": {Settings.EnableCurvature.ToString().ToLower()}
}}";

                _fileIOService.WriteFile(settingsPath, settingsContent);
            }
            catch
            {
                // Ignore save errors for now
            }
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        protected virtual void OnPropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
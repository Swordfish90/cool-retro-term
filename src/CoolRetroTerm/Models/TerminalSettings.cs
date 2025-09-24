using System.ComponentModel;

namespace CoolRetroTerm.Models
{
    /// <summary>
    /// Terminal configuration settings
    /// </summary>
    public class TerminalSettings : INotifyPropertyChanged
    {
        private string _fontFamily = "Consolas";
        private int _fontSize = 14;
        private string _foregroundColor = "#00FF00";
        private string _backgroundColor = "#000000";
        private double _opacity = 0.9;
        private bool _enableScanlines = true;
        private bool _enableGlow = true;
        private bool _enableCurvature = true;
        private int _scanlineIntensity = 50;
        private int _glowIntensity = 30;

        public string FontFamily
        {
            get => _fontFamily;
            set
            {
                _fontFamily = value;
                OnPropertyChanged(nameof(FontFamily));
            }
        }

        public int FontSize
        {
            get => _fontSize;
            set
            {
                _fontSize = value;
                OnPropertyChanged(nameof(FontSize));
            }
        }

        public string ForegroundColor
        {
            get => _foregroundColor;
            set
            {
                _foregroundColor = value;
                OnPropertyChanged(nameof(ForegroundColor));
            }
        }

        public string BackgroundColor
        {
            get => _backgroundColor;
            set
            {
                _backgroundColor = value;
                OnPropertyChanged(nameof(BackgroundColor));
            }
        }

        public double Opacity
        {
            get => _opacity;
            set
            {
                _opacity = value;
                OnPropertyChanged(nameof(Opacity));
            }
        }

        public bool EnableScanlines
        {
            get => _enableScanlines;
            set
            {
                _enableScanlines = value;
                OnPropertyChanged(nameof(EnableScanlines));
            }
        }

        public bool EnableGlow
        {
            get => _enableGlow;
            set
            {
                _enableGlow = value;
                OnPropertyChanged(nameof(EnableGlow));
            }
        }

        public bool EnableCurvature
        {
            get => _enableCurvature;
            set
            {
                _enableCurvature = value;
                OnPropertyChanged(nameof(EnableCurvature));
            }
        }

        public int ScanlineIntensity
        {
            get => _scanlineIntensity;
            set
            {
                _scanlineIntensity = value;
                OnPropertyChanged(nameof(ScanlineIntensity));
            }
        }

        public int GlowIntensity
        {
            get => _glowIntensity;
            set
            {
                _glowIntensity = value;
                OnPropertyChanged(nameof(GlowIntensity));
            }
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        protected virtual void OnPropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
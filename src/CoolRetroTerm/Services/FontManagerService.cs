using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;

namespace CoolRetroTerm.Services
{
    /// <summary>
    /// Font management service - replaces Qt font functionality
    /// Cross-platform version for demonstration
    /// </summary>
    public class FontManagerService : IDisposable
    {
        private List<string> _monospaceFonts = new();

        public FontManagerService()
        {
            RefreshMonospaceFonts();
        }

        /// <summary>
        /// Get list of monospace fonts installed on the system
        /// </summary>
        /// <returns>List of monospace font family names</returns>
        public List<string> GetMonospaceFonts()
        {
            return _monospaceFonts?.ToList() ?? new List<string>();
        }

        /// <summary>
        /// Check if a font is monospaced (simplified for demo)
        /// </summary>
        /// <param name="fontFamily">Font family name</param>
        /// <returns>True if the font is monospaced</returns>
        public bool IsMonospaceFont(string fontFamily)
        {
            // Simplified check - in real implementation would measure character widths
            var knownMonospaceFonts = new[]
            {
                "Cascadia Code", "Fira Code", "JetBrains Mono", "Source Code Pro",
                "Consolas", "Courier New", "Monaco", "Menlo", "DejaVu Sans Mono",
                "Liberation Mono", "Ubuntu Mono", "Roboto Mono", "Inconsolata"
            };

            return knownMonospaceFonts.Any(f => 
                string.Equals(f, fontFamily, StringComparison.OrdinalIgnoreCase));
        }

        /// <summary>
        /// Get the best available monospace font
        /// </summary>
        /// <returns>Font family name of the best monospace font</returns>
        public string GetBestMonospaceFont()
        {
            // Priority order of preferred monospace fonts
            var preferredFonts = new[]
            {
                "Cascadia Code",
                "Fira Code", 
                "JetBrains Mono",
                "Source Code Pro",
                "Consolas",
                "Courier New",
                "Monaco",
                "Menlo",
                "DejaVu Sans Mono",
                "Liberation Mono"
            };

            foreach (var fontName in preferredFonts)
            {
                if (_monospaceFonts.Contains(fontName))
                    return fontName;
            }

            // Return first available monospace font if none of the preferred ones are available
            return _monospaceFonts.FirstOrDefault() ?? "Courier New";
        }

        /// <summary>
        /// Refresh the list of monospace fonts
        /// </summary>
        public void RefreshMonospaceFonts()
        {
            _monospaceFonts = new List<string>();

            // Common monospace fonts across platforms
            var commonMonospaceFonts = new[]
            {
                "Cascadia Code", "Cascadia Mono",
                "Fira Code", "Fira Mono", 
                "JetBrains Mono",
                "Source Code Pro",
                "Roboto Mono",
                "Ubuntu Mono",
                "DejaVu Sans Mono",
                "Liberation Mono",
                "Inconsolata",
                "Monaco",
                "Menlo",
                "Consolas",
                "Courier New",
                "Courier",
                "Lucida Console"
            };

            // In a real implementation, we would query the system for installed fonts
            // For this demo, we'll simulate having some common fonts
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                _monospaceFonts.AddRange(new[] 
                {
                    "Consolas", "Courier New", "Lucida Console"
                });
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                _monospaceFonts.AddRange(new[] 
                {
                    "DejaVu Sans Mono", "Liberation Mono", "Ubuntu Mono"
                });
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            {
                _monospaceFonts.AddRange(new[] 
                {
                    "Monaco", "Menlo", "Courier New"
                });
            }

            // Add some commonly available modern fonts
            _monospaceFonts.AddRange(new[]
            {
                "Cascadia Code", "Fira Code", "JetBrains Mono", "Source Code Pro"
            });

            _monospaceFonts = _monospaceFonts.Distinct().OrderBy(f => f).ToList();
        }

        /// <summary>
        /// Check if a font family is installed
        /// </summary>
        /// <param name="fontFamilyName">Font family name</param>
        /// <returns>True if the font is installed</returns>
        public bool IsFontInstalled(string fontFamilyName)
        {
            return _monospaceFonts.Any(f => 
                string.Equals(f, fontFamilyName, StringComparison.OrdinalIgnoreCase));
        }

        /// <summary>
        /// Get all installed font families
        /// </summary>
        /// <returns>List of all font family names</returns>
        public List<string> GetAllFonts()
        {
            return _monospaceFonts.ToList();
        }

        public void Dispose()
        {
            // No resources to dispose in this simplified version
        }
    }
}
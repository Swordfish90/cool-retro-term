using System;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using CoolRetroTerm.Services;

namespace CoolRetroTerm
{
    /// <summary>
    /// Cool Retro Terminal - Windows .NET Edition
    /// Entry point for the console version (for demonstration purposes)
    /// The actual Windows version would use WPF as shown in the other files
    /// </summary>
    class Program
    {
        private static readonly CancellationTokenSource cancellationTokenSource = new();
        private static TerminalService? terminalService;
        private static FontManagerService? fontManager;
        private static FileIOService? fileIOService;

        static Task Main(string[] args)
        {
            Console.WriteLine("Cool Retro Terminal - Windows .NET Edition");
            Console.WriteLine("==========================================");
            Console.WriteLine();
            
            // Parse command line arguments
            ParseArguments(args);
            
            // Initialize services
            terminalService = new TerminalService();
            fontManager = new FontManagerService();
            fileIOService = new FileIOService();
            
            Console.WriteLine("Available monospace fonts:");
            var fonts = fontManager.GetMonospaceFonts();
            foreach (var font in fonts.Take(5)) // Show first 5 fonts
            {
                Console.WriteLine($"  - {font}");
            }
            if (fonts.Count > 5)
            {
                Console.WriteLine($"  ... and {fonts.Count - 5} more fonts");
            }
            Console.WriteLine();
            
            Console.WriteLine("Terminal service initialized.");
            Console.WriteLine("In the actual Windows WPF version, this would show a graphical retro terminal.");
            Console.WriteLine();
            Console.WriteLine("Features that would be available in the WPF version:");
            Console.WriteLine("  ✓ Retro CRT visual effects (scanlines, glow, curvature)");
            Console.WriteLine("  ✓ Windows Command Prompt integration");
            Console.WriteLine("  ✓ Customizable color schemes (Amber, Green, White)");
            Console.WriteLine("  ✓ Font selection from monospace fonts");
            Console.WriteLine("  ✓ Copy/paste support");
            Console.WriteLine("  ✓ Command history navigation");
            Console.WriteLine("  ✓ Fullscreen mode");
            Console.WriteLine("  ✓ Zoom controls");
            Console.WriteLine("  ✓ Settings persistence");
            Console.WriteLine();
            
            // Test file I/O service
            var appDataDir = fileIOService.GetApplicationDataDirectory();
            Console.WriteLine($"Settings would be saved to: {appDataDir}");
            
            // Test settings file creation
            var settingsPath = Path.Combine(appDataDir, "demo-settings.json");
            var demoSettings = @"{
  ""FontFamily"": ""Consolas"",
  ""FontSize"": 14,
  ""ForegroundColor"": ""#00FF00"",
  ""BackgroundColor"": ""#000000"",
  ""EnableScanlines"": true,
  ""EnableGlow"": true,
  ""EnableCurvature"": true
}";
            
            if (fileIOService.WriteFile(settingsPath, demoSettings))
            {
                Console.WriteLine($"Demo settings file created: {settingsPath}");
            }
            
            Console.WriteLine();
            Console.WriteLine("This console demo shows the .NET services and architecture.");
            Console.WriteLine("The full Windows version uses WPF for the graphical interface.");
            Console.WriteLine();
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
            
            // Cleanup
            terminalService?.Dispose();
            fontManager?.Dispose();

            return Task.CompletedTask;
        }
        
        private static void ParseArguments(string[] args)
        {
            foreach (var arg in args)
            {
                switch (arg.ToLower())
                {
                    case "-h":
                    case "--help":
                        ShowHelp();
                        break;
                    case "--version":
                        ShowVersion();
                        break;
                    case "--demo":
                        Console.WriteLine("Running in demo mode...");
                        break;
                }
            }
        }
        
        private static void ShowHelp()
        {
            Console.WriteLine("Cool Retro Term - Windows Edition");
            Console.WriteLine();
            Console.WriteLine("Usage: CoolRetroTerm.exe [options]");
            Console.WriteLine();
            Console.WriteLine("Options:");
            Console.WriteLine("  --help          Show this help message");
            Console.WriteLine("  --version       Show version information");
            Console.WriteLine("  --demo          Run in demo mode (this console version)");
            Console.WriteLine("  --fullscreen    Start in fullscreen mode (WPF version only)");
            Console.WriteLine();
        }
        
        private static void ShowVersion()
        {
            Console.WriteLine("Cool Retro Term Windows Edition v1.0.0");
            Console.WriteLine("Built with .NET 8.0");
            Console.WriteLine();
            Console.WriteLine("A retro-style terminal emulator for Windows");
            Console.WriteLine("Ported from the original Qt/QML version to .NET Framework");
            Console.WriteLine();
        }
    }
}
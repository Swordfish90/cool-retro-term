using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading.Tasks;

namespace CoolRetroTerm.Services
{
    /// <summary>
    /// Terminal emulation service using Windows Command Prompt
    /// </summary>
    public class TerminalService : IDisposable
    {
        private Process? _currentProcess;
        private StreamWriter? _inputWriter;
        private bool _disposed = false;

        public event EventHandler<string>? OutputReceived;
        public event EventHandler<string>? ErrorReceived;
        public event EventHandler? ProcessExited;

        /// <summary>
        /// Start a new terminal session
        /// </summary>
        public void Start()
        {
            StartNewSession();
        }

        /// <summary>
        /// Start a new Command Prompt session
        /// </summary>
        public void StartNewSession()
        {
            try
            {
                // Close existing process if any
                CloseCurrentSession();

                // Set up process start info for Windows Command Prompt
                var startInfo = new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    UseShellExecute = false,
                    RedirectStandardInput = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                    StandardOutputEncoding = Encoding.UTF8,
                    StandardErrorEncoding = Encoding.UTF8
                };

                _currentProcess = new Process { StartInfo = startInfo };

                // Set up event handlers
                _currentProcess.OutputDataReceived += (sender, e) =>
                {
                    if (!string.IsNullOrEmpty(e.Data))
                        OutputReceived?.Invoke(this, e.Data);
                };

                _currentProcess.ErrorDataReceived += (sender, e) =>
                {
                    if (!string.IsNullOrEmpty(e.Data))
                        ErrorReceived?.Invoke(this, e.Data);
                };

                _currentProcess.Exited += (sender, e) =>
                {
                    ProcessExited?.Invoke(this, EventArgs.Empty);
                };

                _currentProcess.EnableRaisingEvents = true;

                // Start the process
                _currentProcess.Start();
                
                // Get input stream
                _inputWriter = _currentProcess.StandardInput;
                
                // Start reading output asynchronously
                _currentProcess.BeginOutputReadLine();
                _currentProcess.BeginErrorReadLine();
            }
            catch (Exception ex)
            {
                ErrorReceived?.Invoke(this, $"Failed to start terminal session: {ex.Message}");
            }
        }

        /// <summary>
        /// Send input to the terminal
        /// </summary>
        /// <param name="input">Input text to send</param>
        public void SendInput(string input)
        {
            try
            {
                if (_inputWriter != null && !_inputWriter.BaseStream.CanWrite == false)
                {
                    _inputWriter.WriteLine(input);
                    _inputWriter.Flush();
                }
            }
            catch (Exception ex)
            {
                ErrorReceived?.Invoke(this, $"Failed to send input: {ex.Message}");
            }
        }

        /// <summary>
        /// Send a character to the terminal
        /// </summary>
        /// <param name="character">Character to send</param>
        public void SendCharacter(char character)
        {
            try
            {
                if (_inputWriter != null && !_inputWriter.BaseStream.CanWrite == false)
                {
                    _inputWriter.Write(character);
                    _inputWriter.Flush();
                }
            }
            catch (Exception ex)
            {
                ErrorReceived?.Invoke(this, $"Failed to send character: {ex.Message}");
            }
        }

        /// <summary>
        /// Close the current terminal session
        /// </summary>
        public void CloseCurrentSession()
        {
            try
            {
                if (_currentProcess != null && !_currentProcess.HasExited)
                {
                    _currentProcess.Kill();
                }
            }
            catch
            {
                // Ignore errors when killing process
            }
            finally
            {
                _inputWriter?.Dispose();
                _currentProcess?.Dispose();
                _inputWriter = null;
                _currentProcess = null;
            }
        }

        /// <summary>
        /// Check if terminal session is running
        /// </summary>
        public bool IsSessionRunning => _currentProcess != null && !_currentProcess.HasExited;

        /// <summary>
        /// Execute a command in the terminal
        /// </summary>
        /// <param name="command">Command to execute</param>
        public void ExecuteCommand(string command)
        {
            if (!IsSessionRunning)
                StartNewSession();

            SendInput(command);
        }

        /// <summary>
        /// Change working directory
        /// </summary>
        /// <param name="directory">Directory path</param>
        public void ChangeDirectory(string directory)
        {
            if (Directory.Exists(directory))
            {
                ExecuteCommand($"cd /d \"{directory}\"");
            }
        }

        public void Dispose()
        {
            if (!_disposed)
            {
                CloseCurrentSession();
                _disposed = true;
            }
        }
    }
}
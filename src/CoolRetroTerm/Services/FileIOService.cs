using System;
using System.IO;

namespace CoolRetroTerm.Services
{
    /// <summary>
    /// File I/O operations service - replaces Qt FileIO functionality
    /// </summary>
    public class FileIOService
    {
        /// <summary>
        /// Write text data to a file
        /// </summary>
        /// <param name="filePath">Path to the file</param>
        /// <param name="data">Text data to write</param>
        /// <returns>True if successful, false otherwise</returns>
        public bool WriteFile(string filePath, string data)
        {
            try
            {
                if (string.IsNullOrEmpty(filePath))
                    return false;

                // Create directory if it doesn't exist
                var directory = Path.GetDirectoryName(filePath);
                if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                }

                File.WriteAllText(filePath, data);
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        /// <summary>
        /// Read text data from a file
        /// </summary>
        /// <param name="filePath">Path to the file</param>
        /// <returns>File content or empty string if file doesn't exist or error occurs</returns>
        public string ReadFile(string filePath)
        {
            try
            {
                if (string.IsNullOrEmpty(filePath) || !File.Exists(filePath))
                    return string.Empty;

                return File.ReadAllText(filePath);
            }
            catch (Exception)
            {
                return string.Empty;
            }
        }

        /// <summary>
        /// Check if a file exists
        /// </summary>
        /// <param name="filePath">Path to check</param>
        /// <returns>True if file exists</returns>
        public bool FileExists(string filePath)
        {
            return !string.IsNullOrEmpty(filePath) && File.Exists(filePath);
        }

        /// <summary>
        /// Delete a file
        /// </summary>
        /// <param name="filePath">Path to the file to delete</param>
        /// <returns>True if successful</returns>
        public bool DeleteFile(string filePath)
        {
            try
            {
                if (!string.IsNullOrEmpty(filePath) && File.Exists(filePath))
                {
                    File.Delete(filePath);
                    return true;
                }
                return false;
            }
            catch (Exception)
            {
                return false;
            }
        }

        /// <summary>
        /// Get application data directory for storing settings
        /// </summary>
        /// <returns>Path to application data directory</returns>
        public string GetApplicationDataDirectory()
        {
            var appDataPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "CoolRetroTerm");

            if (!Directory.Exists(appDataPath))
            {
                Directory.CreateDirectory(appDataPath);
            }

            return appDataPath;
        }
    }
}
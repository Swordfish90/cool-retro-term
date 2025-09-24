@echo off
echo Building Cool Retro Term - Windows Edition...

REM Check for MSBuild
where msbuild >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: MSBuild not found in PATH. Please install Visual Studio or Build Tools.
    echo See: https://visualstudio.microsoft.com/downloads/
    pause
    exit /b 1
)

REM Check for .NET Framework 4.8
reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Version >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: .NET Framework 4.8 is required but not found.
    echo Please install .NET Framework 4.8 from Microsoft.
    pause
    exit /b 1
)

echo Building solution...
msbuild CoolRetroTerm.sln /p:Configuration=Release /p:Platform="Any CPU" /nologo

if %errorlevel% equ 0 (
    echo.
    echo Build successful!
    echo Executable location: src\CoolRetroTerm\bin\Release\CoolRetroTerm.exe
    echo.
    echo Run the application? (Y/N)
    choice /c YN /n
    if !errorlevel! equ 1 (
        start src\CoolRetroTerm\bin\Release\CoolRetroTerm.exe
    )
) else (
    echo.
    echo Build failed. Please check the error messages above.
    pause
)

pause
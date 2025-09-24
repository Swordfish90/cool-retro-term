#!/bin/bash

echo "Building Cool Retro Term - Windows Edition..."

# Check for .NET CLI
if ! command -v dotnet &> /dev/null; then
    echo "Error: .NET CLI not found. Please install .NET 8.0 or later."
    echo "See: https://dotnet.microsoft.com/download"
    exit 1
fi

# Check .NET version
DOTNET_VERSION=$(dotnet --version)
echo "Using .NET version: $DOTNET_VERSION"

echo "Building solution..."
dotnet build CoolRetroTerm.sln --configuration Release --nologo

if [ $? -eq 0 ]; then
    echo ""
    echo "Build successful!"
    echo "Executable location: src/CoolRetroTerm/bin/Release/net8.0/CoolRetroTerm"
    echo ""
    echo "Run the application with:"
    echo "  dotnet run --project src/CoolRetroTerm/CoolRetroTerm.csproj"
    echo "  OR"
    echo "  dotnet src/CoolRetroTerm/bin/Release/net8.0/CoolRetroTerm.dll"
else
    echo ""
    echo "Build failed. Please check the error messages above."
    exit 1
fi
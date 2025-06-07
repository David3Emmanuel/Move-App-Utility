# Move App Utility

A tool for relocating application data and program files to an alternate storage location while maintaining functionality through junction points. This is useful for:

- Freeing up space on your system drive
- Moving large applications to a faster or more spacious drive
- Managing disk space across multiple storage devices

## How It Works

The utility uses PowerShell to:

1. Stop running processes of the target application
2. Move application folders to a designated target location
3. Create junction points that redirect from the original location to the new location

This ensures applications continue to function normally while their files are physically located elsewhere.

## Included Configurations

The Move App Utility includes configurations for:

- **Fusion360** - Moves Autodesk Fusion 360 data folders
- **Unity** - Moves Unity and Unity Hub program files and data folders

## Requirements

- Windows operating system
- PowerShell
- Administrator privileges (required to create junction points)

## Usage

1. Open Command Prompt or PowerShell as Administrator
2. Navigate to the Move App Utility folder
3. Run the script with the name of the application configuration:

```
powershell -ExecutionPolicy Bypass -File .\Move-App.ps1 -ConfigName Unity
```

OR

```
powershell -ExecutionPolicy Bypass -File .\Move-App.ps1 -ConfigName Fusion360
```

## Configuration Files

Each `.json` configuration file includes:

- `AppName`: Name of the application
- `ProcessesToKill`: List of processes to stop before moving files
- `TargetBasePath`: Base path where files will be moved to
- `FoldersToMove`: List of folders to relocate, including:
  - `SourcePath`: Original path of the folder
  - `TargetRelativePath`: Relative path to append to the TargetBasePath

## Creating Custom Configurations

You can create custom configurations for other applications by creating new JSON files following the same structure as the provided examples.

Example configuration structure:

```json
{
  "AppName": "Example App",
  "ProcessesToKill": ["ExampleProcess1", "ExampleProcess2"],
  "TargetBasePath": "E:\\ExampleData",
  "FoldersToMove": [
    {
      "SourcePath": "C:\\Program Files\\Example",
      "TargetRelativePath": "Program Files\\Example"
    },
    {
      "SourcePath": "C:\\Users\\USERNAME\\AppData\\Local\\Example",
      "TargetRelativePath": "Local\\Example"
    }
  ]
}
```

## Warning

Always make sure you have backups of important data before using this utility. While the script is designed to safely move your files, unexpected issues may occur.

## License

This project is provided as-is for personal use.

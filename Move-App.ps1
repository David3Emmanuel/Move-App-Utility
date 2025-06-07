# Move-App.ps1
# Run this script as Administrator
# This script moves application folders to a target location and creates junction points
# Usage: .\Move-App.ps1 -ConfigName <AppName>
# Example: .\Move-App.ps1 -ConfigName Unity

param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigName
)

# Find the configuration file
$ConfigPath = Join-Path $PSScriptRoot "$ConfigName.json"
if (-Not (Test-Path $ConfigPath)) {
    Write-Host "Configuration file not found: $ConfigPath" -ForegroundColor Red
    Write-Host "Please create a JSON configuration file for $ConfigName" -ForegroundColor Yellow
    Write-Host "Example configuration structure:" -ForegroundColor Cyan
    $ExampleConfig = @{
        "AppName" = "Example App"
        "ProcessesToKill" = @("ExampleProcess1", "ExampleProcess2")
        "TargetBasePath" = "E:\ExampleData"
        "FoldersToMove" = @(
            @{
                "SourcePath" = "C:\Program Files\Example"
                "TargetRelativePath" = "Program Files\Example"
            },
            @{
                "SourcePath" = "C:\Users\USERNAME\AppData\Local\Example"
                "TargetRelativePath" = "Local\Example"
            }
        )
    } | ConvertTo-Json -Depth 10
    Write-Host $ExampleConfig -ForegroundColor Cyan
    exit
}

# Load configuration
try {
    $Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    Write-Host "Loaded configuration for $($Config.AppName)" -ForegroundColor Green
}
catch {
    Write-Host "Error loading configuration: $_" -ForegroundColor Red
    exit
}

# Replace USERNAME placeholder with actual username
$UserName = $env:USERNAME
$Config.FoldersToMove | ForEach-Object {
    if ($_.SourcePath -match 'USERNAME') {
        $_.SourcePath = $_.SourcePath -replace 'USERNAME', $UserName
    }
}

# Function to move folder and create junction
function Move-And-Junction {
    param (
        [string]$SourcePath,
        [string]$TargetPath
    )

    # Check if source exists
    if (-Not (Test-Path $SourcePath)) {
        Write-Host "Source path does not exist: $SourcePath" -ForegroundColor Yellow
        return
    }
    
    # Check if source is already a junction point
    $item = Get-Item $SourcePath -Force -ErrorAction SilentlyContinue
    if ($item -and $item.Attributes.ToString() -match "ReparsePoint") {
        Write-Host "Source path is already a junction point: $SourcePath" -ForegroundColor Cyan
        Write-Host "Skipping this path as it's already been moved and linked." -ForegroundColor Cyan
        return
    }

    # Create target parent folder if it doesn't exist
    $TargetParent = Split-Path $TargetPath
    if (-Not (Test-Path $TargetParent)) {
        New-Item -ItemType Directory -Path $TargetParent -Force | Out-Null
    }
    
    # Move the folder to target location
    Write-Host "Moving $SourcePath to $TargetPath"
    try {
        # Check if target already exists
        if (Test-Path -Path $TargetPath) {
            Write-Host "Target already exists, merging contents..." -ForegroundColor Yellow
            # For directories that already exist, we'll need to copy content instead of moving directly
            Copy-Item -Path "$SourcePath\*" -Destination $TargetPath -Force -Recurse
            Remove-Item -Path $SourcePath -Force -Recurse
        } else {
            Move-Item -Path $SourcePath -Destination $TargetPath -Force -ErrorAction Stop
        }
    }
    catch {
        Write-Host "Error moving $SourcePath to $TargetPath" -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Red
        Write-Host "You may need to move this folder manually." -ForegroundColor Yellow
        return
    }
    
    # Create junction from source to target
    Write-Host "Creating junction from $SourcePath to $TargetPath"
    try {
        cmd /c "mklink /J `"$SourcePath`" `"$TargetPath`"" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create junction with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Host "Error creating junction from $SourcePath to $TargetPath" -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Red
        Write-Host "You may need to create this junction manually." -ForegroundColor Yellow
    }
}

# Stop processes if running
Write-Host "Stopping $($Config.AppName) processes..." -ForegroundColor Cyan
foreach ($ProcessName in $Config.ProcessesToKill) {
    Write-Host "Stopping process: $ProcessName" -ForegroundColor Yellow
    Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Stop-Process -Force
}

# Move and link each folder
foreach ($Folder in $Config.FoldersToMove) {
    $SourcePath = $Folder.SourcePath
    $TargetPath = Join-Path $Config.TargetBasePath $Folder.TargetRelativePath
    
    Move-And-Junction -SourcePath $SourcePath -TargetPath $TargetPath
}

Write-Host "$($Config.AppName) data folders moved and junctions created successfully." -ForegroundColor Green
Write-Host "You can now start $($Config.AppName). Verify everything works correctly." -ForegroundColor Green

# Version Management Helper for Play Store Uploads
# Increments version and build number for new releases

param(
    [string]$Type = "build"  # "build", "patch", "minor", "major"
)

cd C:\Projects\nuclear-motd-mobile

Write-Host "=== Version Management ===" -ForegroundColor Cyan
Write-Host ""

# Read current version
$pubspecContent = Get-Content pubspec.yaml -Raw
if ($pubspecContent -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $build = [int]$matches[4]
    
    Write-Host "Current version: $major.$minor.$patch+$build" -ForegroundColor Gray
    Write-Host ""
    
    # Calculate new version based on type
    switch ($Type) {
        "major" {
            $major++
            $minor = 0
            $patch = 0
            $build++
        }
        "minor" {
            $minor++
            $patch = 0
            $build++
        }
        "patch" {
            $patch++
            $build++
        }
        default {  # just increment build number
            $build++
        }
    }
    
    $newVersion = "$major.$minor.$patch+$build"
    Write-Host "New version: $newVersion" -ForegroundColor Green
    Write-Host ""
    
    # Ask for confirmation
    $confirm = Read-Host "Update version to $newVersion? (y/n)"
    
    if ($confirm -eq 'y') {
        # Update pubspec.yaml
        $newContent = $pubspecContent -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion"
        Set-Content -Path pubspec.yaml -Value $newContent
        
        Write-Host "Version updated!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Run: .\build_for_playstore.ps1" -ForegroundColor Cyan
        Write-Host "  2. Upload the AAB to Play Console" -ForegroundColor Cyan
    } else {
        Write-Host "Version update cancelled." -ForegroundColor Yellow
    }
} else {
    Write-Host "ERROR: Could not parse version from pubspec.yaml" -ForegroundColor Red
}

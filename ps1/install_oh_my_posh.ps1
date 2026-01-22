# Install Oh My Posh and configure PowerShell 7
# Run as Administrator

Write-Host "PowerShell Enhancement Setup" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    exit 1
}

# Step 1: Install PowerShell 7
Write-Host "`n[1/3] Installing PowerShell 7..." -ForegroundColor Yellow
try {
    winget install Microsoft.PowerShell -e --accept-source-agreements --accept-package-agreements
    Write-Host "PowerShell 7 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to install PowerShell 7: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Install Oh My Posh
Write-Host "`n[2/3] Installing Oh My Posh..." -ForegroundColor Yellow
try {
    winget install JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements
    Write-Host "Oh My Posh installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to install Oh My Posh: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Update PowerShell profile
Write-Host "`n[3/3] Configuring PowerShell profile..." -ForegroundColor Yellow

$profilePath = $PROFILE
$profileDir = Split-Path -Parent $profilePath

# Create profile directory if it doesn't exist
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Profile content
$profileContent = @"
# Auto-start SSH agent and load codespace key
if ((Get-Service ssh-agent).Status -ne 'Running') {
    Start-Service ssh-agent
}

# Add codespace key if it exists and isn't already loaded
if (Test-Path "`$env:USERPROFILE\.ssh\codespaces.auto") {
    `$keyLoaded = ssh-add -l 2>`$null | Select-String "codespaces.auto"
    if (-not `$keyLoaded) {
        ssh-add "`$env:USERPROFILE\.ssh\codespaces.auto" 2>`$null
    }
}

# Oh My Posh - Modern prompt theme
oh-my-posh init pwsh | Out-String | Invoke-Expression

# PSReadLine - Autocompletion and history
Import-Module PSReadLine

# Enable autocompletion with history
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# Keybindings for better experience
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
"@

# Write or append to profile
if (Test-Path $profilePath) {
    # Check if Oh My Posh is already configured
    $existingContent = Get-Content $profilePath -Raw
    if ($existingContent -notlike "*oh-my-posh*") {
        Add-Content -Path $profilePath -Value "`n$profileContent"
        Write-Host "Profile updated successfully" -ForegroundColor Green
    } else {
        Write-Host "Profile already configured with Oh My Posh" -ForegroundColor Green
    }
} else {
    Set-Content -Path $profilePath -Value $profileContent
    Write-Host "Profile created successfully" -ForegroundColor Green
}

Write-Host "`n=============================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Close this PowerShell window" -ForegroundColor White
Write-Host "2. Open PowerShell 7 (pwsh.exe)" -ForegroundColor White
Write-Host "3. Enjoy your enhanced shell!" -ForegroundColor White

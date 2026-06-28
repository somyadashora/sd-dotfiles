#Requires -Version 5.1
<#
.SYNOPSIS
    Dotfiles install script for Windows (Neovim only).
.DESCRIPTION
    Links the repo's nvim/ directory to %LOCALAPPDATA%\nvim so Neovim picks up
    this configuration. The Windows counterpart to install.sh (which also handles
    tmux/bash — not applicable on Windows).

    Uses a directory junction by default, which does NOT require administrator
    rights or Developer Mode. Pass -Copy to copy the files instead of linking
    (useful if the repo lives on a drive that can't be junctioned).
.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -Copy
#>
[CmdletBinding()]
param(
    # Copy the nvim/ folder instead of creating a junction.
    [switch]$Copy
)

$ErrorActionPreference = 'Stop'

$DotfilesDir = $PSScriptRoot
$Source      = Join-Path $DotfilesDir 'nvim'
$Target      = Join-Path $env:LOCALAPPDATA 'nvim'

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Could not find nvim config at: $Source"
}

Write-Host "Installing Neovim config..." -ForegroundColor Cyan
Write-Host "  source: $Source"
Write-Host "  target: $Target"

# If the target already links to the right place, we're done.
$existing = Get-Item -LiteralPath $Target -ErrorAction SilentlyContinue
if ($existing -and $existing.LinkType -and $existing.Target -contains $Source) {
    Write-Host "Link already exists and points to the correct location." -ForegroundColor Green
    return
}

# Back up / clear whatever is already there.
if ($existing) {
    if ($existing.LinkType) {
        Write-Host "Removing existing $($existing.LinkType): $Target" -ForegroundColor Yellow
        # Remove the link itself without touching its contents.
        cmd /c rmdir "$Target" | Out-Null
    }
    else {
        $backup = "$Target.backup"
        if (Test-Path -LiteralPath $backup) {
            $backup = "$Target.backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
        }
        Write-Host "Backing up existing config: $Target -> $backup" -ForegroundColor Yellow
        Move-Item -LiteralPath $Target -Destination $backup
    }
}

# Make sure the parent (%LOCALAPPDATA%) exists.
$parent = Split-Path -Parent $Target
if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

if ($Copy) {
    Copy-Item -LiteralPath $Source -Destination $Target -Recurse
    Write-Host "Copied nvim config to: $Target" -ForegroundColor Green
    Write-Host "Note: re-run this script (or 'getdotfiles' + copy) to pick up future updates." -ForegroundColor DarkGray
}
else {
    New-Item -ItemType Junction -Path $Target -Target $Source | Out-Null
    Write-Host "Created junction: $Target -> $Source" -ForegroundColor Green
}

Write-Host ""
Write-Host "Neovim install complete. Launch 'nvim' and let lazy.nvim sync plugins." -ForegroundColor Cyan
Write-Host "External tools to install separately on Windows:" -ForegroundColor DarkGray
Write-Host "  git, ripgrep (rg), fd, a C compiler (for treesitter), and a Nerd Font." -ForegroundColor DarkGray

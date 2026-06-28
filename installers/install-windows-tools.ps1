#Requires -Version 5.1
<#
.SYNOPSIS
    Windows, no-admin installer for this dotfiles/Neovim setup.
.DESCRIPTION
    The Windows counterpart to install-linux-tools.sh. Uses Scoop
    (https://scoop.sh) — a user-local package manager that needs no
    administrator rights, matching the Linux script's no-sudo philosophy.

    Bootstraps Scoop if missing, adds the 'extras' and 'nerd-fonts' buckets,
    then installs the CLI tools Neovim expects. SystemVerilog tooling that Scoop
    does not carry (Verible, slang-server) is fetched best-effort straight from
    GitHub releases into %LOCALAPPDATA%\sd-tools and shimmed via Scoop.

    Re-running is safe: Scoop skips already-current packages. Pass -Force to
    update everything to the latest version.
.EXAMPLE
    .\install-windows-tools.ps1
.EXAMPLE
    .\install-windows-tools.ps1 -Force -SkipFonts
#>
[CmdletBinding()]
param(
    # Update tools to the latest version even if already installed.
    [switch]$Force,
    # Do not install the Meslo Nerd Font.
    [switch]$SkipFonts,
    # Do not install a C compiler (gcc) for nvim-treesitter parser builds.
    [switch]$SkipCompiler
)

$ErrorActionPreference = 'Stop'

function Log  { param($m) Write-Host "==> $m" -ForegroundColor Blue }
function Ok   { param($m) Write-Host "OK  $m"  -ForegroundColor Green }
function Warn { param($m) Write-Warning $m }
function Die  { param($m) Write-Error $m; exit 1 }

function Test-Cmd { param($name) [bool](Get-Command $name -ErrorAction SilentlyContinue) }

# ---------------------------------------------------------------------------
# Scoop bootstrap + packages
# ---------------------------------------------------------------------------

function Install-Scoop {
    if (Test-Cmd scoop) { Ok "scoop already installed."; return }
    Log "Bootstrapping Scoop (user-local, no admin)"
    # Scoop refuses to install as admin without an explicit flag; the user-local
    # install is the supported path here.
    Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression
    if (-not (Test-Cmd scoop)) { Die "Scoop bootstrap failed." }
    Ok "Installed scoop."
}

function Add-Bucket {
    param($name)
    $buckets = scoop bucket list | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue
    if ($buckets -contains $name) { return }
    Log "Adding scoop bucket: $name"
    scoop bucket add $name
}

function Install-ScoopApp {
    param([string]$App, [string]$Label = $App)
    # `scoop list` exit code isn't reliable; grep its output instead.
    $installed = (scoop list $App 6>$null | Out-String) -match [regex]::Escape($App)
    if ($installed -and -not $Force) {
        Ok "$Label already installed."
        return
    }
    if ($installed -and $Force) {
        Log "Updating $Label"
        scoop update $App
    } else {
        Log "Installing $Label"
        scoop install $App
    }
}

# ---------------------------------------------------------------------------
# Best-effort GitHub-release tools (not in Scoop): Verible, slang-server
# ---------------------------------------------------------------------------

$OptDir  = Join-Path $env:LOCALAPPDATA 'sd-tools'
$ShimDir = Join-Path $env:USERPROFILE 'scoop\shims'

function Get-LatestRelease {
    param($Repo)
    $headers = @{ 'User-Agent' = 'sd-dotfiles-installer' }
    if ($env:GITHUB_TOKEN) { $headers['Authorization'] = "Bearer $($env:GITHUB_TOKEN)" }
    Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$Repo/releases/latest"
}

# Download the first release asset whose name matches $Pattern, unzip it into
# $OptDir\<dir>, and register a Scoop shim for the produced exe.
function Install-GhZip {
    param(
        [string]$Repo,
        [string]$Pattern,   # regex matched against asset names
        [string]$DirName,   # subdir under $OptDir
        [string]$ExeName,   # exe to shim (searched recursively)
        [string]$Label
    )
    Log "Resolving latest $Label release ($Repo)"
    try { $release = Get-LatestRelease $Repo }
    catch { Warn "Could not query $Repo releases ($_); skipping $Label."; return }

    $asset = $release.assets | Where-Object { $_.name -match $Pattern } | Select-Object -First 1
    if (-not $asset) { Warn "No Windows asset matching /$Pattern/ for $Label; skipping."; return }

    $dest = Join-Path $OptDir $DirName
    $marker = Join-Path $dest '.tag'
    if ((Test-Path $marker) -and -not $Force -and (Get-Content $marker) -eq $release.tag_name) {
        Ok "$Label is current ($($release.tag_name))."
        return
    }

    $tmp = Join-Path $env:TEMP "sd-$DirName-$([guid]::NewGuid().ToString('N')).zip"
    Log "Downloading $($asset.name)"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tmp -UseBasicParsing
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Expand-Archive -Path $tmp -DestinationPath $dest -Force
    Remove-Item $tmp -Force

    $exe = Get-ChildItem -Path $dest -Recurse -Filter $ExeName | Select-Object -First 1
    if (-not $exe) { Warn "$ExeName not found in $Label archive; skipping shim."; return }

    Set-Content -Path $marker -Value $release.tag_name
    if (Test-Cmd scoop) {
        # `scoop shim add` makes <ExeName-less> shims on PATH via ~\scoop\shims.
        $shimName = [IO.Path]::GetFileNameWithoutExtension($ExeName)
        scoop shim add $shimName $exe.FullName 2>$null | Out-Null
    }
    Ok "Installed $Label $($release.tag_name)."
}

function Install-Verible {
    # Verible ships verible-vX-win64.zip with all binaries under .\<dir>\bin\.
    Install-GhZip -Repo 'chipsalliance/verible' -Pattern 'win64\.zip$' `
        -DirName 'verible' -ExeName 'verible-verilog-ls.exe' -Label 'Verible'
    # Shim the rest of the verible-* tools too (formatter, lint, syntax, ...).
    $bin = Get-ChildItem -Path (Join-Path $OptDir 'verible') -Recurse -Filter 'verible-*.exe' -ErrorAction SilentlyContinue
    foreach ($exe in $bin) {
        if (Test-Cmd scoop) {
            scoop shim add ([IO.Path]::GetFileNameWithoutExtension($exe.Name)) $exe.FullName 2>$null | Out-Null
        }
    }
}

function Install-SlangServer {
    # hudson-trading/slang-server may or may not publish a Windows asset; best effort.
    Install-GhZip -Repo 'hudson-trading/slang-server' -Pattern '(win|windows).*\.zip$' `
        -DirName 'slang-server' -ExeName 'slang-server.exe' -Label 'slang-server'
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Log "Installing Neovim tooling for Windows (user-local via Scoop)"

Install-Scoop
Add-Bucket 'main'
Add-Bucket 'extras'
if (-not $SkipFonts) { Add-Bucket 'nerd-fonts' }

# Core CLI tools (Scoop app names).
Install-ScoopApp 'neovim'      'Neovim'
Install-ScoopApp 'git'         'git'
Install-ScoopApp 'lazygit'     'lazygit'
Install-ScoopApp 'fzf'         'fzf'
Install-ScoopApp 'ripgrep'     'ripgrep (rg)'
Install-ScoopApp 'fd'          'fd'
Install-ScoopApp 'bat'         'bat'
Install-ScoopApp 'delta'       'delta'
Install-ScoopApp 'tree-sitter' 'tree-sitter'

if (-not $SkipCompiler) {
    # nvim-treesitter compiles parsers; gcc (mingw) is the simplest no-admin cc.
    Install-ScoopApp 'gcc' 'gcc (treesitter compiler)'
}

if (-not $SkipFonts) {
    Install-ScoopApp 'Meslo-NF' 'MesloLGS Nerd Font'
}

# SystemVerilog tooling not packaged by Scoop.
Install-Verible
Install-SlangServer

Write-Host ""
Ok "Done."
Write-Host @"

Open a NEW terminal so PATH (~\scoop\shims) is picked up, then verify:
  nvim --version
  lazygit --version
  fzf --version
  rg --version
  fd --version
  bat --version
  delta --version
  tree-sitter --version
  verible-verilog-ls --version
  slang-server --version   (only if a Windows build was available)

Set a Nerd Font (e.g. 'MesloLGS NF') as your terminal font for icons to render.
"@ -ForegroundColor DarkGray

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
    [switch]$SkipCompiler,
    # Do not write a transcript of this run to $OptDir\install-windows-tools.log.
    [switch]$NoLog,
    # Do not wait for a keypress at the end when a step failed.
    [switch]$NoPause
)

# Refuse to be dot-sourced. A fatal error here ends the shell it is dot-sourced
# into, and Start-Transcript below would outlive the run in that session.
if ($MyInvocation.InvocationName -eq '.') {
    Write-Warning 'Run this script, do not dot-source it: .\install-windows-tools.ps1'
    return
}

$ErrorActionPreference = 'Stop'

# Defined up here because the transcript starts before anything else does.
$OptDir  = Join-Path $env:LOCALAPPDATA 'sd-tools'
$ShimDir = Join-Path $env:USERPROFILE 'scoop\shims'
$LogFile = Join-Path $OptDir 'install-windows-tools.log'

function Log  { param($m) Write-Host "==> $m" -ForegroundColor Blue }
function Ok   { param($m) Write-Host "OK  $m"  -ForegroundColor Green }
function Warn { param($m) Write-Warning $m }
# `throw`, not `exit 1`: an exit here closes the window when the script was
# launched by double-click / "Run with PowerShell", taking the error message
# with it. A throw is caught by Invoke-Step, which reports it and carries on.
function Die  { param($m) throw $m }

function Test-Cmd { param($name) [bool](Get-Command $name -ErrorAction SilentlyContinue) }

# Isolate each tool, the way run_step does in install-linux-tools.sh: one step
# that throws — a moved release URL, a bucket that will not add, a Die — must
# cost that tool and nothing after it. Without this the script was one
# $ErrorActionPreference = 'Stop' away from ending at its first bad download,
# and on a double-clicked window that ending is invisible.
$script:FailedSteps = @()
function Invoke-Step {
    param([string]$Name, [scriptblock]$Body)
    try { & $Body }
    catch {
        Warn "$Name failed: $($_.Exception.Message)"
        $script:FailedSteps += $Name
    }
}

# Terminal scrollback is not evidence you can rely on: a double-clicked
# PowerShell window closes the instant the script ends, error and all. The
# transcript is still on disk afterwards.
function Start-RunTranscript {
    if ($NoLog) { return }
    try {
        if (-not (Test-Path $OptDir)) { New-Item -ItemType Directory -Path $OptDir -Force | Out-Null }
        Start-Transcript -Path $LogFile -Append | Out-Null
        Log "Transcript of this run: $LogFile"
    }
    catch { Warn "Could not start a transcript ($($_.Exception.Message)); continuing without one." }
}

function Stop-RunTranscript {
    if ($NoLog) { return }
    try { Stop-Transcript | Out-Null } catch { }
}

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

# Plain-web release resolution — no GitHub API, no tokens (api.github.com
# rate-limits and scoped CI tokens 403). If a project moves hosts, only these
# URLs need to change.
function Get-LatestTag {
    param($Repo)
    # releases/latest 302-redirects to releases/tag/<TAG> — same "latest
    # published release" semantics as the API.
    $resp = Invoke-WebRequest -Uri "https://github.com/$Repo/releases/latest" `
        -Method Head -UseBasicParsing
    # Final URL after redirects: .NET Framework (PS5) vs HttpClient (PS7).
    $final = $resp.BaseResponse.ResponseUri.AbsoluteUri
    if (-not $final) { $final = $resp.BaseResponse.RequestMessage.RequestUri.AbsoluteUri }
    if ($final -match '/releases/tag/(.+)$') {
        return [uri]::UnescapeDataString($Matches[1])
    }
    return $null
}

function Get-ReleaseAssetUrls {
    param($Repo, $Tag)
    # expanded_assets is the plain-web fragment GitHub renders the release
    # asset list from; its hrefs are /<repo>/releases/download/<tag>/<asset>.
    $enc = [uri]::EscapeDataString($Tag)
    $html = (Invoke-WebRequest -Uri "https://github.com/$Repo/releases/expanded_assets/$enc" `
        -UseBasicParsing).Content
    [regex]::Matches($html, 'href="(/' + [regex]::Escape($Repo) + '/releases/download/[^"]+)"') |
        ForEach-Object { "https://github.com$($_.Groups[1].Value)" }
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
    try {
        $tag = Get-LatestTag $Repo
        if (-not $tag) { throw "no /releases/tag/ redirect" }
        $assetUrls = Get-ReleaseAssetUrls $Repo $tag
    }
    catch { Warn "Could not query $Repo releases ($_); skipping $Label."; return }

    $assetUrl = $assetUrls | Where-Object { ($_ -split '/')[-1] -match $Pattern } | Select-Object -First 1
    if (-not $assetUrl) { Warn "No Windows asset matching /$Pattern/ for $Label; skipping."; return }
    $assetName = [uri]::UnescapeDataString(($assetUrl -split '/')[-1])

    $dest = Join-Path $OptDir $DirName
    $marker = Join-Path $dest '.tag'
    if ((Test-Path $marker) -and -not $Force -and (Get-Content $marker) -eq $tag) {
        Ok "$Label is current ($tag)."
        return
    }

    $tmp = Join-Path $env:TEMP "sd-$DirName-$([guid]::NewGuid().ToString('N')).zip"
    Log "Downloading $assetName"
    Invoke-WebRequest -Uri $assetUrl -OutFile $tmp -UseBasicParsing
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Expand-Archive -Path $tmp -DestinationPath $dest -Force
    Remove-Item $tmp -Force

    $exe = Get-ChildItem -Path $dest -Recurse -Filter $ExeName | Select-Object -First 1
    if (-not $exe) { Warn "$ExeName not found in $Label archive; skipping shim."; return }

    Set-Content -Path $marker -Value $tag
    if (Test-Cmd scoop) {
        # `scoop shim add` makes <ExeName-less> shims on PATH via ~\scoop\shims.
        $shimName = [IO.Path]::GetFileNameWithoutExtension($ExeName)
        scoop shim add $shimName $exe.FullName 2>$null | Out-Null
    }
    Ok "Installed $Label $tag."
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

Start-RunTranscript

Log "Installing Neovim tooling for Windows (user-local via Scoop)"

Invoke-Step 'scoop' { Install-Scoop }

if (Test-Cmd scoop) {
    Invoke-Step 'bucket main'   { Add-Bucket 'main' }
    Invoke-Step 'bucket extras' { Add-Bucket 'extras' }
    if (-not $SkipFonts) { Invoke-Step 'bucket nerd-fonts' { Add-Bucket 'nerd-fonts' } }

    # Core CLI tools (Scoop app names). Each scriptblock holds literals rather
    # than loop variables on purpose: a PowerShell scriptblock is not a closure,
    # and `& $Body` inside Invoke-Step resolves names through the CALLER's scope,
    # where Invoke-Step's own [string]$Name param shadows an outer $name.
    Invoke-Step 'Neovim'          { Install-ScoopApp 'neovim'      'Neovim' }
    Invoke-Step 'git'             { Install-ScoopApp 'git'         'git' }
    Invoke-Step 'lazygit'         { Install-ScoopApp 'lazygit'     'lazygit' }
    Invoke-Step 'fzf'             { Install-ScoopApp 'fzf'         'fzf' }
    Invoke-Step 'ripgrep'         { Install-ScoopApp 'ripgrep'     'ripgrep (rg)' }
    Invoke-Step 'fd'              { Install-ScoopApp 'fd'          'fd' }
    Invoke-Step 'bat'             { Install-ScoopApp 'bat'         'bat' }
    Invoke-Step 'delta'           { Install-ScoopApp 'delta'       'delta' }
    Invoke-Step 'tree-sitter'     { Install-ScoopApp 'tree-sitter' 'tree-sitter' }

    if (-not $SkipCompiler) {
        # nvim-treesitter compiles parsers; gcc (mingw) is the simplest no-admin cc.
        Invoke-Step 'gcc'         { Install-ScoopApp 'gcc' 'gcc (treesitter compiler)' }
    }
    if (-not $SkipFonts) {
        Invoke-Step 'Meslo-NF'    { Install-ScoopApp 'Meslo-NF' 'MesloLGS Nerd Font' }
    }
}
else {
    # Everything Scoop-installed is out of reach, but the GitHub-release tools
    # below only need Scoop for their shims — they still install without it.
    Warn "scoop is not available; skipping the Scoop-installed tools."
}

# SystemVerilog tooling not packaged by Scoop.
Invoke-Step 'Verible'      { Install-Verible }
Invoke-Step 'slang-server' { Install-SlangServer }

Write-Host ""
if ($script:FailedSteps.Count -gt 0) {
    Warn "Finished with failed steps: $($script:FailedSteps -join ', ') (everything else installed)."
}
else {
    Ok "Done."
}
if (-not $NoLog) { Log "Full transcript: $LogFile" }
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

Stop-RunTranscript

# A double-clicked window closes the moment this script ends. When something
# failed, that is exactly the moment the output was worth reading — so hold the
# window open, but only when a person is actually there to read it.
if ($script:FailedSteps.Count -gt 0 -and -not $NoPause -and [Environment]::UserInteractive) {
    Read-Host 'Some steps failed. Press Enter to close'
}

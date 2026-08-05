#requires -Version 5.1
<##
.SYNOPSIS
  PowerShell entry point for the provider-neutral workspace initializer.
##>

$ErrorActionPreference = 'Stop'

$candidates = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LocalAppData\Programs\Git\bin\bash.exe"
)

try {
    $whereBash = (Get-Command bash -ErrorAction Stop).Source
    if ($whereBash -and $whereBash -notlike "$env:windir\System32\*") {
        $candidates += $whereBash
    }
} catch {
    # Fall through to the known Git for Windows locations.
}

$bashExe = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $bashExe) {
    Write-Error "Could not locate bash.exe. Install Git for Windows or put bash on PATH."
    exit 1
}

$bashScript = Join-Path $PSScriptRoot 'init.sh'
if (-not (Test-Path $bashScript)) {
    Write-Error "Missing bash entry point at $bashScript"
    exit 1
}

& $bashExe -lc "bash '$bashScript' $args"
exit $LASTEXITCODE

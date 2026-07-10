$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent $PSScriptRoot
$workspaceDir = Split-Path -Parent (Split-Path -Parent $projectDir)
$portableMaven = Join-Path $workspaceDir "work\tools\apache-maven-3.9.16\bin\mvn.cmd"

if (Get-Command mvn -ErrorAction SilentlyContinue) {
    $mavenCommand = "mvn"
}
elseif (Test-Path -LiteralPath $portableMaven) {
    $mavenCommand = $portableMaven
}
else {
    throw "Maven was not found. Install Maven or download the portable Maven used by this workspace."
}

$userGpgKey = [Environment]::GetEnvironmentVariable("MAVEN_GPG_KEY", "User")
$userGpgPassphrase = [Environment]::GetEnvironmentVariable("MAVEN_GPG_PASSPHRASE", "User")
$gpgKeyPath = Join-Path $HOME ".m2\jiavva-maven-gpg-key.asc"

if ([string]::IsNullOrWhiteSpace($env:MAVEN_GPG_KEY) -and -not [string]::IsNullOrWhiteSpace($userGpgKey)) {
    $env:MAVEN_GPG_KEY = $userGpgKey
}

if ([string]::IsNullOrWhiteSpace($env:MAVEN_GPG_KEY) -and (Test-Path -LiteralPath $gpgKeyPath)) {
    $env:MAVEN_GPG_KEY = Get-Content -Raw -LiteralPath $gpgKeyPath
}

if ([string]::IsNullOrWhiteSpace($env:MAVEN_GPG_PASSPHRASE) -and -not [string]::IsNullOrWhiteSpace($userGpgPassphrase)) {
    $env:MAVEN_GPG_PASSPHRASE = $userGpgPassphrase
}

if ([string]::IsNullOrWhiteSpace($env:MAVEN_GPG_KEY)) {
    throw "MAVEN_GPG_KEY is missing. Run .\scripts\configure-gpg-signing.ps1 first."
}

Write-Host "Uploading and publishing release bundle to Central Portal."
Write-Host "POM is configured with autoPublish=true and waitUntil=published."
Write-Host ""

& $mavenCommand -B -Prelease deploy

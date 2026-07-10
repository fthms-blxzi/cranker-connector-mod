$ErrorActionPreference = "Stop"

$settingsPath = Join-Path $HOME ".m2\settings.xml"
$gpgKeyPath = Join-Path $HOME ".m2\jiavva-maven-gpg-key.asc"
$hasCentralServer = $false
$mavenGpgKey = if ([string]::IsNullOrWhiteSpace($env:MAVEN_GPG_KEY)) {
    $userValue = [Environment]::GetEnvironmentVariable("MAVEN_GPG_KEY", "User")
    if ([string]::IsNullOrWhiteSpace($userValue) -and (Test-Path -LiteralPath $gpgKeyPath)) {
        Get-Content -Raw -LiteralPath $gpgKeyPath
    }
    else {
        $userValue
    }
}
else {
    $env:MAVEN_GPG_KEY
}

$mavenGpgPassphrase = if ([string]::IsNullOrWhiteSpace($env:MAVEN_GPG_PASSPHRASE)) {
    [Environment]::GetEnvironmentVariable("MAVEN_GPG_PASSPHRASE", "User")
}
else {
    $env:MAVEN_GPG_PASSPHRASE
}

if (Test-Path -LiteralPath $settingsPath) {
    try {
        [xml]$settingsXml = Get-Content -Raw -LiteralPath $settingsPath
        $ns = New-Object System.Xml.XmlNamespaceManager($settingsXml.NameTable)
        $ns.AddNamespace("m", "http://maven.apache.org/SETTINGS/1.2.0")
        $hasCentralServer = $null -ne $settingsXml.SelectSingleNode("//m:server[m:id='central']", $ns)
    }
    catch {
        $hasCentralServer = $false
    }
}

$checks = @(
    @{ Name = "Maven settings.xml"; Value = Test-Path -LiteralPath $settingsPath },
    @{ Name = "Maven settings server central"; Value = $hasCentralServer },
    @{ Name = "Local GPG key file"; Value = Test-Path -LiteralPath $gpgKeyPath },
    @{ Name = "MAVEN_GPG_KEY"; Value = -not [string]::IsNullOrWhiteSpace($mavenGpgKey) }
)

$failed = $false
foreach ($check in $checks) {
    if ($check.Value) {
        Write-Host "[OK]   $($check.Name)"
    }
    else {
        Write-Host "[MISS] $($check.Name)"
        $failed = $true
    }
}

Write-Host ""

$projectDir = Split-Path -Parent $PSScriptRoot
$workspaceDir = Split-Path -Parent (Split-Path -Parent $projectDir)
$portableMaven = Join-Path $workspaceDir "work\tools\apache-maven-3.9.16\bin\mvn.cmd"

if (Get-Command mvn -ErrorAction SilentlyContinue) {
    Write-Host "[OK]   Maven command found in PATH"
}
elseif (Test-Path -LiteralPath $portableMaven) {
    Write-Host "[OK]   Portable Maven found"
    Write-Host "       $portableMaven"
}
else {
    Write-Host "[MISS] Maven command not found in PATH or portable tools"
    $failed = $true
}

if (Get-Command gpg -ErrorAction SilentlyContinue) {
    Write-Host "[OK]   GPG command found"
}
else {
    Write-Host "[WARN] GPG command not found in PATH"
    Write-Host "       This is only needed to generate/export a signing key locally."
}

if ([string]::IsNullOrWhiteSpace($mavenGpgPassphrase)) {
    Write-Host "[INFO] MAVEN_GPG_PASSPHRASE is not set"
    Write-Host "       This is fine for an unprotected CI-style signing key."
}
else {
    Write-Host "[OK]   MAVEN_GPG_PASSPHRASE"
}

if ($failed) {
    exit 1
}

Write-Host "Release environment looks ready."

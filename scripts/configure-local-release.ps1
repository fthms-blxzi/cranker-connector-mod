param(
    [switch] $SkipGpgKey
)

$ErrorActionPreference = "Stop"

function Read-PlainSecret {
    param([string] $Prompt)

    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

Write-Host "Configuring local Maven Central release credentials for jiavva."
Write-Host "Generate a Central Portal token at: https://central.sonatype.com/usertoken"
Write-Host "The token page gives you two values: username and password."
Write-Host ""

$centralUsername = Read-Host -Prompt "Central token username"
$centralPassword = Read-PlainSecret -Prompt "Central token password"
$escapedCentralUsername = [Security.SecurityElement]::Escape($centralUsername)
$escapedCentralPassword = [Security.SecurityElement]::Escape($centralPassword)

$m2Dir = Join-Path $HOME ".m2"
$settingsPath = Join-Path $m2Dir "settings.xml"
New-Item -ItemType Directory -Path $m2Dir -Force | Out-Null

$settingsXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd">
  <servers>
    <server>
      <id>central</id>
      <username>$escapedCentralUsername</username>
      <password>$escapedCentralPassword</password>
    </server>
  </servers>
</settings>
"@

Set-Content -LiteralPath $settingsPath -Value $settingsXml -Encoding UTF8

Write-Host ""
Write-Host "Wrote Maven settings to: $settingsPath"

if (-not $SkipGpgKey) {
    Write-Host ""
    Write-Host "Generate or export your GPG key, then paste the ASCII-armored private key."
    Write-Host "Command example: gpg --armor --export-secret-keys YOUR_KEY_ID"
    Write-Host "Also publish the public key: gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_KEY_ID"
    Write-Host "Expected first line: -----BEGIN PGP PRIVATE KEY BLOCK-----"
    Write-Host "Paste the full private key block, then enter a line containing only ENDKEY."
    Write-Host ""

    $keyLines = New-Object System.Collections.Generic.List[string]
    while ($true) {
        $line = Read-Host
        if ($line -eq "ENDKEY") {
            break
        }
        $keyLines.Add($line)
    }

    $gpgKey = $keyLines -join "`n"
    if (-not $gpgKey.StartsWith("-----BEGIN PGP PRIVATE KEY BLOCK-----")) {
        throw "The pasted key does not look like an ASCII-armored PGP private key."
    }

    $gpgPassphrase = Read-PlainSecret -Prompt "GPG private key passphrase"

    [Environment]::SetEnvironmentVariable("MAVEN_GPG_KEY", $gpgKey, "User")
    [Environment]::SetEnvironmentVariable("MAVEN_GPG_PASSPHRASE", $gpgPassphrase, "User")

    $env:MAVEN_GPG_KEY = $gpgKey
    $env:MAVEN_GPG_PASSPHRASE = $gpgPassphrase
}

[Environment]::SetEnvironmentVariable("CENTRAL_TOKEN_USERNAME", $centralUsername, "User")
[Environment]::SetEnvironmentVariable("CENTRAL_TOKEN_PASSWORD", $centralPassword, "User")

$env:CENTRAL_TOKEN_USERNAME = $centralUsername
$env:CENTRAL_TOKEN_PASSWORD = $centralPassword

Write-Host ""
Write-Host "Done. New terminals will inherit the User environment variables."
Write-Host "In this terminal, run: .\scripts\check-release-env.ps1"

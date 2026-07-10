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

Write-Host "Configuring GPG signing for Maven Central release."
Write-Host ""
Write-Host "Install GPG for Windows from: https://gpg4win.org/download.html"
Write-Host "Generate/export commands:"
Write-Host "  gpg --gen-key"
Write-Host "  gpg --list-secret-keys --keyid-format LONG"
Write-Host "  gpg --armor --export-secret-keys YOUR_KEY_ID"
Write-Host "  gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_KEY_ID"
Write-Host ""
Write-Host "Paste the full ASCII-armored private key block, then enter a line containing only ENDKEY."
Write-Host "Expected first line: -----BEGIN PGP PRIVATE KEY BLOCK-----"
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

if (-not $gpgKey.TrimEnd().EndsWith("-----END PGP PRIVATE KEY BLOCK-----")) {
    throw "The pasted key does not end with an ASCII-armored PGP private key footer."
}

$gpgPassphrase = Read-PlainSecret -Prompt "GPG private key passphrase (leave empty for an unprotected key)"

[Environment]::SetEnvironmentVariable("MAVEN_GPG_KEY", $gpgKey, "User")
$env:MAVEN_GPG_KEY = $gpgKey

$gpgKeyPath = Join-Path $HOME ".m2\jiavva-maven-gpg-key.asc"
New-Item -ItemType Directory -Path (Split-Path -Parent $gpgKeyPath) -Force | Out-Null
Set-Content -LiteralPath $gpgKeyPath -Value $gpgKey -Encoding ascii

if ([string]::IsNullOrEmpty($gpgPassphrase)) {
    [Environment]::SetEnvironmentVariable("MAVEN_GPG_PASSPHRASE", $null, "User")
    Remove-Item Env:\MAVEN_GPG_PASSPHRASE -ErrorAction SilentlyContinue
}
else {
    [Environment]::SetEnvironmentVariable("MAVEN_GPG_PASSPHRASE", $gpgPassphrase, "User")
    $env:MAVEN_GPG_PASSPHRASE = $gpgPassphrase
}

Write-Host ""
Write-Host "GPG signing environment variables are set for the current user."
Write-Host "Open a new terminal, or keep using this terminal, then run:"
Write-Host "  .\scripts\check-release-env.ps1"

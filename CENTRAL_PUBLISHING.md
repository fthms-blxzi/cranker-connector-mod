# Central Publishing Notes

This project is configured for Sonatype Central Portal publishing with Maven.
The release profile uses:

```xml
<publishingServerId>central</publishingServerId>
```

That means Maven reads publishing credentials from the `central` server in
`settings.xml`, not from the POM.

## Permission Model

The token is only an authentication credential. Publishing authorization comes
from namespace permissions in Central Portal.

For `cc.u-0:jiavva:0.1.0`:

1. Confirm namespace `cc.u-0` is verified in Central Portal.
2. Make sure the account that owns the token is a publisher for `cc.u-0`.
3. Generate a user token at `https://central.sonatype.com/usertoken`.

If the token authenticates but the account is not a publisher for `cc.u-0`, the
upload can fail with a permission-style error such as `403 Forbidden`.

## Local Settings

Use `settings-central-template.xml` as a template for:

```text
~/.m2/settings.xml
```

or on Windows:

```text
%USERPROFILE%\.m2\settings.xml
```

The important server block is:

```xml
<server>
  <id>central</id>
  <username>YOUR_TOKEN_USERNAME</username>
  <password>YOUR_TOKEN_PASSWORD</password>
</server>
```

The fastest Windows setup path is:

```powershell
.\scripts\configure-local-release.ps1
.\scripts\check-release-env.ps1
```

The script asks for the Central token username/password and optionally the
ASCII-armored GPG private key. It writes `~/.m2/settings.xml` and stores signing
values as User environment variables.

If `~/.m2/settings.xml` is already configured and only GPG signing is missing:

```powershell
.\scripts\configure-gpg-signing.ps1
.\scripts\check-release-env.ps1
```

## GPG

Central also requires signed artifacts. Keep the GPG private key and passphrase
outside the repository. The release profile signs artifacts during `verify`.

The POM is configured for the Maven GPG Plugin BC signer:

```xml
<signer>bc</signer>
<keyEnvName>MAVEN_GPG_KEY</keyEnvName>
<passphraseEnvName>MAVEN_GPG_PASSPHRASE</passphraseEnvName>
```

So CI and non-interactive local releases should provide:

```text
MAVEN_GPG_KEY
MAVEN_GPG_PASSPHRASE
```

`MAVEN_GPG_PASSPHRASE` may be omitted when the exported private key is
unprotected.

The Windows helper scripts also support a local key file:

```text
%USERPROFILE%\.m2\jiavva-maven-gpg-key.asc
```

That file is outside the repository and is loaded into `MAVEN_GPG_KEY` only for
the release process.

Export the secret key with:

```sh
gpg --armor --export-secret-keys YOUR_KEY_ID
```

Publish the matching public key so Central users can verify signatures:

```sh
gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_KEY_ID
```

Central currently documents `keyserver.ubuntu.com`, `keys.openpgp.org`, and
`pgp.mit.edu` as supported keyservers.

Typical local flow:

```sh
gpg --list-secret-keys --keyid-format LONG
mvn -Prelease deploy
```

## CI Secrets

Store these as CI secrets:

```text
CENTRAL_TOKEN_USERNAME
CENTRAL_TOKEN_PASSWORD
MAVEN_GPG_KEY
MAVEN_GPG_PASSPHRASE
```

Then import the GPG private key and write a temporary Maven settings file before
running:

```sh
mvn -Prelease deploy
```

The current POM sets `autoPublish` to `true`, so a successful deploy uploads,
validates, and publishes the deployment.

On Windows, after `check-release-env.ps1` is clean:

```powershell
.\scripts\release-upload.ps1
```

This runs `mvn -B -Prelease deploy` with the Maven available on PATH or the
portable Maven downloaded into this workspace.

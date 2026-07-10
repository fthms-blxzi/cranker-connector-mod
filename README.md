# Jiavva

Tiny Java utility package prepared for Maven Central under the `u-0.cc`
namespace.

This project is intentionally a plain Maven project with a single `pom.xml`.
Its publishing layout follows the same general shape as the HSBC Cranker
packages: Central-ready metadata, attached sources, attached Javadocs, and a
release profile for signing and uploading.

## Coordinates

```xml
<dependency>
  <groupId>cc.u-0</groupId>
  <artifactId>jiavva</artifactId>
  <version>0.1.0</version>
</dependency>
```

The Maven `groupId` mirrors the domain exactly as `cc.u-0`. Java package names
cannot contain hyphens, so the source package is `cc.u_0.jiavva`. The optional
JPMS automatic module name is `cc.u0.jiavva`.

## Usage

```java
import cc.u_0.jiavva.Jiavva;

String greeting = Jiavva.hello("Central");
String marker = Jiavva.marker("My First Release");
```

## Build

```sh
mvn clean verify
```

## Prepare Maven Central

1. Confirm the namespace `cc.u-0` is verified in Central Portal.
2. Generate a Central Portal publishing user token.
3. Configure Maven `settings.xml` with that token.
4. Generate or select a GPG key for artifact signing.

## Local Credential Setup

Generate a Central Portal token here:

```text
https://central.sonatype.com/usertoken
```

The token is shown once and has two fields:

```text
CENTRAL_TOKEN_USERNAME = generated token username
CENTRAL_TOKEN_PASSWORD = generated token password
```

Generate or export a GPG private key:

```sh
gpg --gen-key
gpg --list-secret-keys --keyid-format LONG
gpg --armor --export-secret-keys YOUR_KEY_ID
gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_KEY_ID
```

The `MAVEN_GPG_KEY` value must be the full ASCII-armored private key block:

```text
-----BEGIN PGP PRIVATE KEY BLOCK-----
...
-----END PGP PRIVATE KEY BLOCK-----
```

The `MAVEN_GPG_PASSPHRASE` value is the passphrase for that private key. Leave
it unset for an unprotected CI-style signing key.
For local Windows publishing, the helper scripts can also store the private key
at `%USERPROFILE%\.m2\jiavva-maven-gpg-key.asc`, outside this repository.
Publish the matching public key to a supported keyserver such as
`keyserver.ubuntu.com` or `keys.openpgp.org`.

On Windows, run the helper script from this project directory:

```powershell
.\scripts\configure-local-release.ps1
.\scripts\check-release-env.ps1
```

If the Central token is already installed and you only need signing, run:

```powershell
.\scripts\configure-gpg-signing.ps1
.\scripts\check-release-env.ps1
```

The helper writes `%USERPROFILE%\.m2\settings.xml` and sets user environment
variables for GPG signing. Do not paste these secrets into chat or commit them
to the repository.

## Publishing Permission and Credentials

For current Maven Central publishing, this project uses Central Portal, not a
legacy `oss.sonatype.org` staging repository. The important pieces are:

- `cc.u-0` must be verified in Central Portal as a namespace for `u-0.cc`.
- Your Central Portal account must be listed as a publisher for that namespace.
- The Portal user token inherits the permissions of that account.
- The token is not your Sonatype login password.
- The Maven server id must match the POM release plugin configuration:
  `central`.

The release profile in `pom.xml` contains:

```xml
<publishingServerId>central</publishingServerId>
```

So your Maven `settings.xml` must contain a matching server entry:

```xml
<settings>
  <servers>
    <server>
      <id>central</id>
      <username>YOUR_TOKEN_USERNAME</username>
      <password>YOUR_TOKEN_PASSWORD</password>
    </server>
  </servers>
</settings>
```

There is also a template in `settings-central-template.xml`. Do not commit a
filled-in settings file with real credentials.

If publishing fails with `403 Forbidden` or `does not allow updating artifact`,
check the namespace first: the token may be valid, but the token's account may
not have publisher permission for `cc.u-0`.

For CI, store the token username/password and GPG passphrase as CI secrets, then
generate a temporary Maven settings file during the job.

The GPG release profile uses the Maven GPG Plugin BC signer, so signing material
is read from environment variables:

```text
MAVEN_GPG_KEY
MAVEN_GPG_PASSPHRASE
```

Export the private key with:

```sh
gpg --armor --export-secret-keys YOUR_KEY_ID
```

Use that entire ASCII-armored private key as `MAVEN_GPG_KEY`.

## Upload for Validation

This command builds sources, Javadocs, signatures, uploads the bundle to
Central Portal, and publishes it after validation.

```sh
mvn -Prelease deploy
```

Once a version is published to Maven Central, treat it as immutable; release a
new version for fixes.

On Windows you can also run:

```powershell
.\scripts\release-upload.ps1
```

The POM uses `autoPublish=true`, so this uploads the signed bundle, waits for
Central validation, and publishes it.

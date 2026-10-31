# Personal Homebrew tap

This tap builds CLIProxyAPI from its official `main` branch with two temporary compatibility patches.
The Claude search recovery patch restores rejected web-search history after an account change.
The auth-file validation patch ignores JSON without a nonempty string `type` field, unless a plugin recognizes the file.
It preserves custom provider IDs.

## Install

```sh
brew tap darfink/tap
brew trust --formula darfink/tap/cliproxyapi
brew install --HEAD darfink/tap/cliproxyapi
brew services start darfink/tap/cliproxyapi
```

If another tap already provides `cliproxyapi`, Homebrew requires you to uninstall that package before this installation.
The config remains at `$(brew --prefix)/etc/cliproxyapi.conf`.
The formula uses the existing credential and plugin paths in that config.

## Update

```sh
brew update
brew upgrade --fetch-HEAD darfink/tap/cliproxyapi && brew services restart darfink/tap/cliproxyapi
```

Each build downloads the latest `main`, applies both patches, and runs the Claude regression tests and auth-loader tests.
A patch or test error stops the installation.
The restart command runs only after a successful upgrade.

If the patch changes without a new commit on `main`, force a rebuild:

```sh
brew reinstall darfink/tap/cliproxyapi && brew services restart darfink/tap/cliproxyapi
```

## Recovery patch

The patch handles the three documented HTTP 400 errors for rejected encrypted search results and citation indexes.
It retries once before output starts, with the same credential.
The retry converts all assistant hosted-search calls, results, and citations into readable historical references.
It does not depend on error coordinates, block layouts, matching identifiers, or search results beside their citations.
Ordinary answers, images, thinking, function calls, function results, document citations, and cache controls remain intact.
The fallback also converts complete prior searches because the proxy cannot decrypt their opaque fields to determine which are invalid.
Encrypted page contents cannot be reconstructed; Claude can search again.
New searches remain enabled, and identical history produces identical reference text.
Successful requests and saved transcripts remain unchanged.

Related work: [CLIProxyAPI PR #6447](https://github.com/router-for-me/CLIProxyAPI/pull/6447).
The tests cover streaming, non-streaming, payload rules, request signatures, split search and citation turns, and repeated errors.
They also cover duplicate identifiers, inaccurate error coordinates, and newer searches with repeated block layouts.

The formula builds with the `debug` tag and CGO for native plugins.
The version includes a fingerprint of both patches.
The regression tests use mock HTTP servers and require no provider credentials.
The optional captured-log test skips without `CLIPROXY_SEARCH_REPLAY_LOG`.
This repository contains no captured conversations or credentials.

Once the official implementation covers these cases, remove the patch or return to the core formula.
The patch can require changes after incompatible edits on `main`.

## Credential backups

Store auth-file backups in `~/Library/Application Support/CLIProxyAPI/backups`.
Do not store backups under the configured `auth-dir`.
The auth directory is scanned recursively. Backup credentials can become live accounts, so keep all maintenance files elsewhere.

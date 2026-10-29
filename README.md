# Personal Homebrew tap

This tap builds CLIProxyAPI from its official `main` branch with one temporary compatibility patch.
The patch recovers rejected Claude web-search history after an account change.

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

Each build downloads the latest `main`, applies the patch, and runs the Claude regression tests.
A patch or test error stops the installation.
The restart command runs only after a successful upgrade.

If the patch changes without a new commit on `main`, force a rebuild:

```sh
brew reinstall darfink/tap/cliproxyapi && brew services restart darfink/tap/cliproxyapi
```

## Recovery patch

The patch handles specific HTTP 400 errors for rejected encrypted search results and citation indexes.
It retries before output starts, with the same credential, and permits at most three recoveries per request.
An exact error location identifies the search turn to recover.
If the error index differs from the submitted history, recovery converts incomplete citation history into readable references together.
Complete native searches remain unchanged during this fallback.
Successful requests and saved transcripts remain unchanged.

Related work: [CLIProxyAPI PR #6447](https://github.com/router-for-me/CLIProxyAPI/pull/6447).
The fallback uses unique artifact identities and refuses ambiguous identities during request rebuilds.
The tests cover streaming, non-streaming, payload rules, request signatures, ambiguous history, and repeated errors.
They also cover a newer complete search with the same block layout as an older incomplete search.

The formula builds with the `debug` tag and CGO for native plugins.
The version includes a fingerprint of the recovery patch.
The regression tests use mock HTTP servers and require no provider credentials.
The optional captured-log test skips without `CLIPROXY_SEARCH_REPLAY_LOG`.
This repository contains no captured conversations or credentials.

Once the official implementation covers these cases, remove the patch or return to the core formula.
The patch can require changes after incompatible edits on `main`.

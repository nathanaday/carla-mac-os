# Sikarugir: what it is, and why we trust it

CARLA has no macOS build. Running it on Apple Silicon means running the Windows binary under
Wine, which means installing an unsigned, closed-source wrapper tool from a third-party Homebrew
tap. This document records what that tool is, what was checked before installing it, and what was
knowingly accepted.

Re-run every check here with `scripts/verify-sources.sh`.

## Why this tool

| Tool | Status |
|---|---|
| **Sikarugir** | In use. Maintained fork of Wineskin. Creates Wine wrappers that bundle D3DMetal. |
| Kegworks | The previous name of the same project. Cannot create a wrapper on macOS 26 — it fails with "no wrapper installed". |
| Whisky | Archived 11 May 2025, before macOS 26 shipped. Bundles the same D3DMetal. Unmaintained. |
| CrossOver | Commercial. Not tested here. |

Kegworks was renamed to Sikarugir in August 2025. The tap history shows the rename in place:
commit `1663fcd`, "Update and rename kegworks.rb to sikarugir.rb".

## What was verified

Checked on 2026-09-10, against cask version 1.0.1.

**The hash chain holds.** Three independent points agree on
`187825e4e6bf96f294cf9ccb65e53049432b3ee2925480e8ad1cbca12a96e819`: the `sha256` pinned in the
cask, a fresh download of the release asset, and the copy in the local Homebrew cache. A release
asset replaced in place under an unchanged tag would break this.

**One maintainer, with a track record.** 21 of the 22 tap commits are from Dean M Greer
(`Gcenx`), who also published the release asset. He maintains the Wine engine builds and the
upstream WineHQ macOS packages that most of this ecosystem depends on. The `Sikarugir` repo has
3,617 stars; the release asset has over 102,000 downloads.

**The app only talks to its own project.** Every URL extracted from the app's binaries:

```
https://raw.githubusercontent.com/Sikarugir-App/Engines/main/EngineList.txt
https://raw.githubusercontent.com/Sikarugir-App/Wrapper/main/NewestVersion.txt
https://github.com/Sikarugir-App/Engines/releases/download/v1.0/
https://github.com/Sikarugir-App/Wrapper/releases/download/v1.0/
```

No telemetry endpoint, and no reference to `sikarugir.com` — a site the project's own install
caveat warns is unaffiliated and distributes malware.

## What was accepted, not solved

**The app is not notarized, and the cask bypasses Gatekeeper deliberately.** As shipped it is
ad-hoc signed with no Team ID, and `spctl` rejects it. The cask's postflight then strips the
quarantine attribute and re-signs ad hoc:

```ruby
run "/usr/bin/xattr", args: ["-drs", "com.apple.quarantine", "{{appdir}}/Sikarugir Creator.app"]
run "/usr/bin/codesign", args: ["--force", "--deep", "-s", "-", "{{appdir}}/Sikarugir Creator.app"]
```

This is normal for Wineskin-lineage tools, which rewrite their own bundles and so cannot hold a
stable signature. The effect is still that Apple has never scanned this binary. Trust here rests
on the maintainer's identity, not on a cryptographic one.

**The Creator app is closed source.** `Sikarugir-App/Creator` contains a README and nothing else.
The wrapper tooling is LGPL-2.1; the Creator is not. You can verify what it downloads. You cannot
read what it does.

**None of the repos carry a license.** `Sikarugir`, `Engines`, and `Wrapper` all report no SPDX
license.

## Trust scope in Homebrew

Homebrew requires explicit trust for third-party taps. Grant it per cask, not per tap:

```bash
brew trust --cask Sikarugir-App/sikarugir/sikarugir    # correct
brew trust Sikarugir-App/sikarugir                     # too broad
```

Whole-tap trust covers every cask and command in that tap, including ones added later. The cask
grant covers only what you actually install. Trust state lives in `~/.homebrew/trust.json` and can
be edited by hand.

## Choosing a Wine engine

`Sikarugir Creator.app` offers about a dozen engines at wrapper-creation time. The names decode
as follows, per the maintainer in
[Kegworks discussion #24](https://github.com/orgs/Kegworks-App/discussions/24):

| Name part | Meaning |
|---|---|
| `WS11` / `WS12` | Wineskin engine series. WS12 is the newer line. |
| `WineCX` | Built from CrossOver sources. |
| `WineSikarugir` | The project's own Wine build. The number is the Wine version. |
| `WineGPTK` | Apple's Game Porting Toolkit 1.1. |
| `WhiskyWine` | Whisky's Wine build, with Homebrew dylibs removed. |
| `32Bit` | 32-bit software only. |
| `_N` suffix | Rebuild number, not a Wine version. `24.0.7_7` is the 7th rebuild of CrossOver 24.0.7. |

**Use `WS12WineSikarugir10.0_6`.** It is a WS12 engine, it is the entry `Sikarugir Creator` lists
first, and it is the most recently revised WS12 build (10 April 2026). Verified to carry
`winemetal`, which D3DMetal requires.

Fallbacks, in order: `WS12WineCX24.0.7_7` (CrossOver 24.0.7, 20 November 2025), then
`WS12WineGPTK1.1_3`.

**Never pick a `32Bit` engine.** CARLA ships 64-bit binaries only.

`WS11WineSikarugir11.0` is the newest upload (3 September 2026) and the newest Wine version, but it
sits on the older WS11 series at revision 0. It is not the safe default.

All three engines inspected — `WS12WineSikarugir10.0_6`, `WS12WineCX24.0.7_7`, and
`WS11WineSikarugir11.0` — contain `winemetal`, so D3DMetal is available on any of them.

## Where the real risk sits

The Creator is 793 KB of closed-source Swift. It is not the interesting attack surface.

The engine is ~160 MB of Wine, pulled at wrapper-creation time from a release published in 2024.
After that you run an 8 GB Windows binary inside it. Wine maps your home directory to `Z:` by
default, so anything running in the wrapper can read it. CARLA itself arrives from
`downloads.carlasim.com` over TLS and publishes no checksums, so its integrity rests on TLS alone.

`checksums/known-good.txt` records the hashes verified here so that later drift is detectable.
When you add an engine or a CARLA version, record its hash there too.

## Re-verifying

```bash
scripts/verify-sources.sh              # cask pin, publisher, app signature, endpoints
scripts/verify-sources.sh engine       # default engine: download, hash, winemetal check
scripts/verify-sources.sh engine WS12WineCX24.0.7_7
scripts/verify-sources.sh all
```

The script exits non-zero on any failure. Run the `cask` check before accepting a Sikarugir update
— a changed pin means the cask was updated, and the diff is worth reading before you install it.

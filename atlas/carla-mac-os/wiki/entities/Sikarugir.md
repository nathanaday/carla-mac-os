---
type: entity
title: "Sikarugir"
status: developing
assessment: accepted
created: 2026-09-23
updated: 2026-09-23
aliases:
  - Sikarugir Creator
  - CARLA.app wrapper
tags:
  - entity
  - carla-on-macos
  - wine
---

# Sikarugir

The Wine wrapper tool that [[CARLA on macOS]] uses. This page records it only as it applies to
CARLA.

## Overview

Sikarugir is a maintained fork of the Wineskin wrapper tool. It was named Kegworks until August
2025. `Sikarugir Creator.app` creates a wrapper, an app bundle that holds a Wine engine, a Windows
prefix, and D3DMetal. The CARLA wrapper is `~/Applications/Sikarugir/CARLA.app`. Its settings app
is `CARLA.app/Contents/Configure.app`. The Creator only makes new wrappers; open `Configure.app` to
change an existing one ([[Sikarugir trust notes]], "Why this tool";
[[Run CARLA on Apple Silicon guide]], Steps 1-3).

| Tool | Status for CARLA |
|---|---|
| Sikarugir | In use. |
| Kegworks | Same project, old name. Fails on macOS 26 with "no wrapper installed". |
| Whisky | Archived 11 May 2025, before macOS 26. |
| CrossOver | Commercial. Not tested. |

## Engine choice

From [[Sikarugir trust notes]], "Choosing a Wine engine":

- **macOS 26:** `WS12WineSikarugir10.0_6`. The default.
- **macOS 15 or earlier:** start with `WS12WineCX24.0.7_7`, then `WS12WineGPTK1.1_3`. The default
  engine is built against the macOS 26 D3DMetal.
- Never a `32Bit` engine. CARLA ships 64-bit binaries only.
- `WS12` is the newer Wineskin series. The `_N` suffix is a rebuild number, not a Wine version.
- Engines reach D3DMetal in one of two ways: Wine-native builds ship `winemetal.dll`; the Game
  Porting Toolkit build ships a `d3dmetal_force` marker instead.

## CARLA wrapper setup

From [[Run CARLA on Apple Silicon guide]], Steps 3-7:

- Install `vcrun2022` only, through Winetricks. `vcrun2019` alongside it causes a fatal error on
  Test Run under macOS 26.
- Set the executable to `CarlaUE4.exe`, not the `CarlaUE4-Win64-Shipping.exe` it launches.
- Put launch flags in the `Program Flags` field, never in the executable path. The Configure UI
  claims the path field accepts flags; it does not.
- Check **D3DMetal**. `-quality-level=Low` fixes freezing; `-RenderOffScreen` runs with no window.

## Trust

From [[Sikarugir trust notes]], "What was verified" and "What was accepted, not solved" (checked
2026-09-22 against cask 1.0.2):

- Verified: the cask's `sha256` pin matches a fresh download of the release asset. One maintainer,
  Dean M Greer (`Gcenx`), wrote 21 of 22 tap commits and published the release. Every URL in the
  app points at the `Sikarugir-App` organization.
- Accepted: the app is not notarized, and the cask removes the quarantine flag on purpose. The
  Creator is closed source. None of the repos carry a license.
- Grant Homebrew trust per cask (`brew trust --cask Sikarugir-App/sikarugir/sikarugir`), not per
  tap.
- The larger risk is the ~160 MB Wine engine and the 8 GB CARLA binary. Wine maps the home
  directory to `Z:`, so code in the wrapper can read it.
- `scripts/verify-sources.sh` re-runs the checks. `checksums/known-good.txt` records the hashes.

## Relationships

- Hosts the server and the [[CARLA Wine Python client]] for [[CARLA on macOS]].
- Several of the [[CARLA on macOS failure modes]] come from wrapper settings.

## Sources

- [[Sikarugir trust notes]]
- [[Run CARLA on Apple Silicon guide]]

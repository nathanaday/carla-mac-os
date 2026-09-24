---
type: source
title: "Sikarugir trust notes"
status: developing
created: 2026-09-23
updated: 2026-09-23
tags:
  - source
  - carla-on-macos
source_type: documentation
author: nathanaday (this project)
date_published: 2026-09-22
url: docs/sikarugir.md
source_id: src-65d202898c7bdff14249
---

# Sikarugir trust notes

The project's record of why [[Sikarugir]] is trusted for [[CARLA on macOS]]. It stays in the
repository as `docs/sikarugir.md`.

## Summary

It compares Sikarugir with Kegworks, Whisky, and CrossOver, lists what was verified about the
install and what was accepted without a fix, explains Homebrew trust scope, decodes the Wine engine
names, and says where the real risk sits.

## Key claims

- Checked on 2026-09-22 against cask 1.0.2: the cask pin and a fresh download agree on the
  `sha256` ("What was verified").
- The app talks only to the `Sikarugir-App` organization on GitHub ("What was verified").
- The app is not notarized, and the Creator is closed source ("What was accepted, not solved").
- On macOS 26 use `WS12WineSikarugir10.0_6`; on macOS 15 or earlier start with
  `WS12WineCX24.0.7_7` ("Choosing a Wine engine").
- Engines reach D3DMetal through `winemetal.dll` or a `d3dmetal_force` marker ("How each engine
  reaches D3DMetal").

## Notes

- `scripts/verify-sources.sh` re-runs every check in the document.

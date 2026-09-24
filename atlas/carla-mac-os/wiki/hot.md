---
type: meta
title: Hot Cache
status: developing
created: 2026-09-20
updated: 2026-09-23
tags:
  - meta
  - hot-cache
---

# Recent Context

## Last Updated

2026-09-23: filed the setup guide, the Sikarugir notes, and the examples README under the [[CARLA on macOS]] hub.

## Key Recent Facts

- CARLA 0.9.16's Windows build runs on Apple Silicon under Wine in a [[Sikarugir]] wrapper, with D3DMetal. Every confirmed success runs macOS 26.x.
- The [[CARLA Wine Python client]] runs from a macOS Terminal through `scripts/carla-python`. It needs `numpy<2` and the server's Wine sync settings.
- `BasicAgent` drives in synchronous mode: 300 ticks in about 6 s on an M4 Pro.
- Many failures print nothing. [[CARLA on macOS failure modes]] maps each symptom to its cause.
- Agents on other machines are planned but untested; see [[Remote CARLA clients]].

## Recent Changes

- Added the hub [[CARLA on macOS]], [[Sikarugir]], [[CARLA Wine Python client]], [[CARLA on macOS failure modes]], and three source pages.
- Linked [[Remote CARLA clients]] to the hub.

## Active Threads

- No open threads.

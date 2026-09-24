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

2026-09-23: saved [[Remote CARLA clients]].

## Key Recent Facts

- The Python client and CARLA's driving agents run in the Wine wrapper. `scripts/carla-python` runs them from a macOS Terminal.
- The Wine client needs `numpy<2`. numpy 2.x crashes on import under Wine with no message.
- An x86 Linux board can run agents against the Mac server with the PyPI `manylinux_2_31_x86_64` wheel.
- A Jetson has no `carla` wheel. Either build the client from source, or keep the CARLA client on the x86 board and send sensor frames to the Jetson.
- Not yet tested: remote access to ports 2000 and 2001 on the Wine server, and remote sensor streaming.

## Recent Changes

- Added [[Remote CARLA clients]].

## Active Threads

- No open threads.

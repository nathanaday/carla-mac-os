---
type: source
title: "Run CARLA on Apple Silicon guide"
status: developing
created: 2026-09-23
updated: 2026-09-23
tags:
  - source
  - carla-on-macos
source_type: documentation
author: nathanaday (this project)
date_published: 2026-09-23
url: carla-on-apple-silicon.md
source_id: src-78f1265a6186c2979cb4
---

# Run CARLA on Apple Silicon guide

The project's setup walkthrough for [[CARLA on macOS]]. It stays in the repository as
`carla-on-apple-silicon.md`; this page summarizes it.

## Summary

A step-by-step guide from a clean Mac to a running CARLA 0.9.16 server and Python client. Steps 1-7
build the [[Sikarugir]] wrapper and start the server. Steps 8-10 set up the
[[CARLA Wine Python client]] and the driving agents. It ends with a troubleshooting table, a
black-screen triage, the architecture, and its community sources.

## Key claims

- The Windows build of CARLA runs under Wine with D3DMetal on Apple Silicon; there is no native
  macOS build of the server or the client (intro).
- Every confirmed success runs macOS 26.x; 24 GB of memory is needed for 0.9.15 and later
  ("Requirements").
- 0.9.16 is the default version; 0.10.0 runs at only 10-15 fps ("Choose a CARLA version").
- The client needs `numpy<2`, and the launcher must match the server's Wine sync settings
  (Step 8).
- Agents should run in synchronous mode (Step 10).
- The failures and fixes are collected on [[CARLA on macOS failure modes]].

## Notes

- It draws on [CARLA discussion #9037](https://github.com/carla-simulator/carla/discussions/9037),
  a PDF by @nveshaan, a comment by @canibal1, and fixes and videos by @potatocodex.
- It mixes steps tested in this project with community reports, and says which is which.
- Captured on 2026-09-23 at the state after commit `d1dd139`.

---
type: concept
title: "CARLA on macOS failure modes"
status: developing
assessment: provisional
created: 2026-09-23
updated: 2026-09-23
tags:
  - concept
  - carla-on-macos
  - troubleshooting
---

# CARLA on macOS failure modes

Part of [[CARLA on macOS]].

## Definition

The failures seen when running CARLA under Wine on a Mac, with their causes and fixes. Many of
them show no error message, so the symptom alone is misleading. Source for the whole page:
[[Run CARLA on Apple Silicon guide]], "Troubleshooting" and "Black screen: which half failed".

## Why it matters

Most of the time lost in this setup went to failures that print nothing. Knowing the cause of each
one saves hours.

## Symptoms, causes, and fixes

| Symptom | Cause | Fix |
|---|---|---|
| "No wrapper installed" | Kegworks on macOS 26 | Use [[Sikarugir]] |
| `EngineDownloadError error 1` | Failed engine download | Retry once, or place the tarball by hand |
| Test Run does nothing: no window, no error, no process | Flags typed into the executable path | Move them to `Program Flags` |
| Fatal error on Test Run | `vcrun2019` installed with `vcrun2022` | Install `vcrun2022` only |
| Fatal error, `CarlaUE4-Win64-Shipping.exe` opens | Wrapper points at the shipping binary | Point it at `CarlaUE4.exe` |
| Freezing, very low fps | Default quality too high | `-quality-level=Low` |
| Added maps not found | Maps zip extracted in Finder | Extract from Terminal |
| Client script ends at once, prints nothing | numpy 2.x crashes under Wine | `numpy<2` |
| `wine` from Terminal exits with status 136 | Sync settings differ from the running `wineserver` | Use `scripts/carla-python` |
| `No module named 'agents'` | Agents are not in the wheel | Run through `scripts/carla-python` |
| Client calls time out, port 2000 open | An old server survived closing `CARLA.app` | **Kill Wine Processes**, then restart |
| Paths with `CARLA_0.9.16` not found | Folder created as `CARLA_0` | Use the real folder name |
| World freezes after a script dies | Synchronous mode left on | Run a client to completion, or restart `CARLA.app` |

Found on this machine on 2026-09-23: the numpy crash, the status 136 exit, the missing `agents`
module, the surviving old server, and the `CARLA_0` folder name. The frozen world follows from how
CARLA's synchronous mode works; it was not seen here. The other rows come from the guide's earlier
setup work and the community discussion.

## Black screen triage

A black window means the processes started, not that the level loaded. The server binds its RPC
port only after the level is loaded, so the port tells the two failures apart:

- **Port 2000 opens.** The server runs; only the picture is missing. The fault is in the D3DMetal
  display path. Check that D3DMetal is on. On macOS 15 or earlier, try the other engines listed on
  [[Sikarugir]]. If none renders, macOS 26 is the fix. Meanwhile, run with `-RenderOffScreen` and
  drive from the [[CARLA Wine Python client]].
- **Port 2000 never opens.** The level did not load: memory or shader compilation. The first
  launch can take 20-30 minutes while D3DMetal compiles shaders. Watch `sysctl vm.swapusage`,
  shrink the job with low quality and a small window, then try 0.9.15 or 0.9.9.4.

Open case: an M4 with 16 GB on macOS 15.6 shows a black window and heavy swapping. It differs from
the tested setup in both memory and macOS version, and the cause is not known.

## Related

- [[CARLA on macOS]]
- [[Sikarugir]]
- [[CARLA Wine Python client]]

## Sources

- [[Run CARLA on Apple Silicon guide]]

---
type: concept
title: "CARLA on macOS"
status: developing
assessment: accepted
created: 2026-09-23
updated: 2026-09-23
aliases:
  - CARLA on Apple Silicon
  - carla-mac-os
tags:
  - concept
  - carla-on-macos
  - hub
---

# CARLA on macOS

This is the hub page for running the CARLA driving simulator on an Apple Silicon Mac. Every page
about this topic links here. Details about Wine, D3DMetal, and the Mac graphics stack stay on the
pages below and are scoped to CARLA.

## Definition

CARLA publishes builds for Ubuntu and Windows only. This project runs the **Windows** build of
CARLA 0.9.16 on an Apple Silicon Mac. The server and the Python client both run under Wine, inside
one [[Sikarugir]] wrapper app, `CARLA.app`. Apple's D3DMetal translates the server's Direct3D 12
calls to Metal. There is no native macOS build of the server and no macOS wheel for the `carla`
Python package ([[Run CARLA on Apple Silicon guide]], intro).

```
macOS (arm64)
└── Sikarugir wrapper: CARLA.app
    ├── Wine + D3DMetal
    ├── CarlaUE4.exe          server, RPC on ports 2000 and 2001
    └── Python 3.10 (win64)   client, carla wheel, agents from PythonAPI/carla
        ▲
        └── scripts/carla-python   runs the client from a macOS Terminal
```

## What works

Tested in this project:

- The server loads Town10 and renders it through D3DMetal on macOS 26
  ([[Run CARLA on Apple Silicon guide]], Steps 1-7).
- The Wine Python client connects, and CARLA's driving agents run. `BasicAgent` drove a vehicle in
  synchronous mode: 300 ticks (15 s simulated) in about 6 s on an M4 Pro. See
  [[CARLA Wine Python client]].
- CARLA's example scripts run from the repository through the launcher. Four scripts are checked
  so far ([[CARLA 0.9.16 example scripts README]]).

Reported by the community in [CARLA discussion #9037](https://github.com/carla-simulator/carla/discussions/9037):
the same stack on macOS 26.2 with 0.9.16, on a MacBook Air M4 (24 GB) and a Mac Mini M4 (16 GB),
and 0.9.15 at 30-60 fps on a Mac Mini M4 ([[Run CARLA on Apple Silicon guide]], intro).

## What does not work, or is not covered

- **ROS and ROS2.** Nobody in the discussion got ROS working. ROS inside Wine failed. ROS in Docker
  works, but DDS multicast stays inside the Docker network.
- **CARLA 0.10.0 (Unreal Engine 5).** It runs at only 10-15 fps on a Mac Mini M4.
- **Building CARLA from source.** The Windows release package is the only practical input.
- **macOS 15.** A black window on an M4, 16 GB, macOS 15.6 is reported and not solved. Every
  confirmed success runs macOS 26.x.
- **A Docker client.** Reported to work in the discussion, not tested here.

Source: [[Run CARLA on Apple Silicon guide]], "Not covered here", "Reported failures", and
"Architecture".

## Requirements

| Item | Value |
|---|---|
| Hardware | Apple Silicon. M4 handles 0.9.15 and 0.9.16. M1 and M2 are reported to need 0.9.14 or older. |
| Memory | 24 GB for 0.9.15 and later. |
| macOS | 26 recommended. |
| Free disk | 45 GB at peak. |
| Other | Homebrew, Rosetta 2 |

Source: [[Run CARLA on Apple Silicon guide]], "Requirements".

## Key lessons

- Choose the wrapper tool and engine with care: Sikarugir, not Kegworks; a `WS12` engine; never
  `32Bit`. See [[Sikarugir]].
- Many failures show no error message. A black window, a Test Run that does nothing, and a client
  script that exits at once each have a specific cause. See [[CARLA on macOS failure modes]].
- The Wine client needs `numpy<2` and the same Wine sync settings as the running server. See
  [[CARLA Wine Python client]].
- The client talks to the server over TCP, so agents can also run on other machines. See
  [[Remote CARLA clients]].

## Related

- [[Sikarugir]] — the Wine wrapper tool, its engines, and why it is trusted
- [[CARLA Wine Python client]] — the Python client, the launcher, and the driving agents
- [[CARLA on macOS failure modes]] — symptoms, causes, and fixes
- [[Remote CARLA clients]] — agents on an x86 board or a Jetson

## Sources

- [[Run CARLA on Apple Silicon guide]]
- [[Sikarugir trust notes]]
- [[CARLA 0.9.16 example scripts README]]

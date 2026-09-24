---
type: concept
title: "CARLA Wine Python client"
status: developing
assessment: accepted
created: 2026-09-23
updated: 2026-09-23
aliases:
  - carla-python launcher
tags:
  - concept
  - carla-on-macos
  - python-client
---

# CARLA Wine Python client

Part of [[CARLA on macOS]].

## Definition

The CARLA Python client runs as a Windows Python 3.10 inside the same [[Sikarugir]] wrapper as the
server. `scripts/carla-python` runs it from a normal macOS Terminal. CARLA's driving agents run in
the same client ([[Run CARLA on Apple Silicon guide]], Steps 8-10).

## Why it matters

There is no macOS wheel for `carla`, so the client must run under Wine or somewhere else on the
network. With this client, scripts and agents live in the repository and run with one command.

## What we learned

From [[Run CARLA on Apple Silicon guide]], Steps 8-10, all tested in this project:

- **Python 3.10.** It is the only version with a Windows `carla` wheel for both 0.9.15 and 0.9.16.
- **Pin `numpy<2`.** numpy 2.x calls `ucrtbase.dll.crealf`, which this Wine build does not
  implement. Python crashes on `import numpy`. In the `Configure.app` command window the crash
  prints nothing, so the script seems to run and do nothing.
- **Match the Wine sync settings.** The running `wineserver` uses `WINEMSYNC=1` and
  `WINEESYNC=1`. A Wine process without them exits at once with status 136 and no message. The
  launcher sets the same environment that Sikarugir uses.
- **The agents are not in the wheel.** They ship as source in `PythonAPI/carla/agents`. The
  launcher puts `PythonAPI/carla` on `PYTHONPATH`. They need `networkx` and `shapely`.
- **The CARLA folder name can differ.** "Move a Folder Inside" can create `CARLA_0` instead of
  `CARLA_0.9.16`. The launcher finds either.
- **Use synchronous mode for agents.** The server advances only on `world.tick()`, so agent
  behavior does not depend on how fast the client runs under Wine. Restore the settings in a
  `finally` block: a script that dies in synchronous mode leaves the world frozen.

## Agents

| Agent | Behavior |
|---|---|
| `BasicAgent` | Follows a route at a target speed. Stops for vehicles and red lights. |
| `BehaviorAgent` | Adds tailgating, lane changes, and speed limits. Profiles: `cautious`, `normal`, `aggressive`. |
| `ConstantVelocityAgent` | Holds a fixed speed. For testing. |

`examples/basic_agent.py` drives one vehicle with `BasicAgent` and a following camera. On an M4
Pro, 300 ticks (15 s simulated) take about 6 s ([[Run CARLA on Apple Silicon guide]], Step 10).

## Example scripts

CARLA's 30 example scripts are copied, unchanged, into `examples/carla/`. The `nvidia/` folder is
left out because it needs a CUDA GPU. `manual_control_chrono.py` and `open3d_lidar.py` are expected
to fail ([[CARLA 0.9.16 example scripts README]]).

## Related

- [[CARLA on macOS]]
- [[Sikarugir]]
- [[CARLA on macOS failure modes]]
- [[Remote CARLA clients]] — the same client on another machine

## Sources

- [[Run CARLA on Apple Silicon guide]]
- [[CARLA 0.9.16 example scripts README]]

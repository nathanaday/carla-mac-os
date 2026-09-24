---
type: concept
title: "Remote CARLA clients"
status: seed
assessment: provisional
created: 2026-09-23
updated: 2026-09-23
tags:
  - concept
  - carla-on-macos
  - python-client
  - networking
  - hardware
---

# Remote CARLA clients

Part of [[CARLA on macOS]].

## Definition

A remote CARLA client is a Python client, such as a driving agent, that runs on another machine and
connects to the CARLA server over the network. In this project the server runs under Wine on the
Mac. The candidate client machines are an x86 single-board computer and an NVIDIA Jetson board.

The CARLA client needs only TCP access to the server: port 2000 for RPC and port 2001 for sensor
data. So an agent can run on any machine that can reach the Mac. The local alternative is the
[[CARLA Wine Python client]].

## Why it matters

It moves agent and model compute off the Mac, onto hardware close to what a real vehicle carries.
The Mac then only runs the simulator.

## x86 single-board computer

This is the direct path.

- PyPI has `carla==0.9.16` wheels for `manylinux_2_31_x86_64` and `win_amd64`, for Python 3.10,
  3.11, and 3.12. Checked against the PyPI JSON API on 2026-09-23.
- `manylinux_2_31` needs glibc 2.31 or later, which means Ubuntu 20.04 or newer.
- Install: `pip install carla==0.9.16 "numpy<2" networkx shapely`. The numpy crash seen in the
  Wine client came from Wine, so native Linux may not need the pin. CARLA's own
  `PythonAPI/examples/requirements.txt` pins `numpy<2.0.0`, so keep it.
- The `agents` package is not in the wheel. Copy `PythonAPI/carla/agents` to the board and put
  its parent folder on `PYTHONPATH`.
- Connect with the Mac's LAN address, for example
  `python examples/basic_agent.py --host <mac-ip>`.

## Jetson

The Jetson is `aarch64`. PyPI has no ARM Linux wheel for `carla` 0.9.16. There are two options:

1. **Build the client library on the Jetson.** CARLA's build scripts target x86 Linux and Windows.
   The dependencies (Boost, rpclib, Recast) need changes for ARM. This is a real project. No
   research has been done yet on whether a working 0.9.16 Jetson build exists.
2. **Run no CARLA client on the Jetson.** The x86 board runs the CARLA client, sends sensor
   frames to the Jetson over a separate link (for example ZeroMQ), and receives controls back. The
   Jetson runs only the model. This avoids the build and adds one network hop per tick. It also
   matches a real vehicle, where perception hardware receives sensor data and does not know about
   the simulator.

Recommendation at the time of writing: start with option 2 if the Jetson's purpose is neural
network inference.

## Constraints

- **Version match.** Every client must run the same CARLA version as the server, 0.9.16.
- **Ports.** The Mac must accept incoming TCP on 2000 and 2001. The macOS firewall may ask whether
  to allow `wine`.
- **Bandwidth.** One 800×600 RGBA camera at 20 Hz is about 38 MB/s, roughly 300 Mbit/s. Use wired
  gigabit Ethernet. Wi-Fi is likely to drop frames or slow synchronous mode.
- **One clock owner.** In synchronous mode exactly one client calls `world.tick()`. With agents on
  several boards, one board ticks and the others only read state and send controls.
- **Traffic Manager.** It runs inside the client process that starts it and listens on port 8000.
  If traffic runs on one board and agents on another, both must use the same Traffic Manager port,
  and port 8000 must be open between them.

## Open questions

None of these are tested yet:

- Does the server under Wine bind ports 2000 and 2001 on all interfaces, or only on `127.0.0.1`?
  Test: `nc -z <mac-ip> 2000` from a board while CARLA runs.
- Does sensor streaming on port 2001 work for a remote client when the server runs under Wine?
  Test a camera sensor, not only driving.
- Has anyone published a working CARLA 0.9.16 client build for Jetson?

Proposed first test: set up the x86 board, run `examples/basic_agent.py` against the Mac, then add
a camera sensor. That one run tests the network, the Wine port binding, and sensor streaming.

## Related

- [[CARLA on macOS]]
- [[CARLA Wine Python client]] — the local client on the Mac
- Repository: `scripts/carla-python`, `examples/basic_agent.py`, and `carla-on-apple-silicon.md`,
  Steps 8-10.

## Sources

- Conversation with the assistant on 2026-09-23 (synthetic). The PyPI wheel list was checked in
  that session. The other claims are the assistant's synthesis from CARLA's documented client and
  server model, and are not yet tested on this setup. No source in the vault supports them.

# CARLA on Apple Silicon

Run the [CARLA driving simulator](https://github.com/carla-simulator/carla) on an Apple M-series
Mac.

## About

CARLA ships builds for Ubuntu and Windows only. On a Mac the usual answers are to rent a Linux
box, keep a Windows machine around, or give up on the simulator entirely.

You do not have to. The Windows build runs on Apple Silicon through a Wine wrapper, with Apple's
Game Porting Toolkit translating the graphics calls to Metal. It is fast enough for real work.

This project collects the steps that make that work, and the tools to make it repeatable. The
community figured most of this out in a [GitHub discussion](https://github.com/carla-simulator/carla/discussions/9037);
what lives here is a current, tested walkthrough plus scripts to verify what you install.

Status: **in development**. The setup is documented and working end to end. Automation is in
progress.

## Tested on

| | |
|---|---|
| Machine | MacBook Pro, M4 Pro, 48 GB |
| macOS | 26.6.2 |
| CARLA | 0.9.16 |
| Renderer | D3DMetal 3.0 (Game Porting Toolkit), D3D12 |
| Result | 57.75 fps, Town10 |

Reports from the community confirm the same approach on the M4 Mac Mini and MacBook Air, and on
older M1 and M2 machines with earlier CARLA releases.

## Getting started

Read **[carla-on-apple-silicon.md](carla-on-apple-silicon.md)**. It takes you from a clean Mac to a
running simulator with a working Python client, and it covers the mistakes that cost the most time.

Plan for around 40 GB of free disk and an afternoon, most of it spent downloading.

Before installing the wrapper tool, check what you are about to pull:

```bash
scripts/verify-sources.sh
```

## Documentation

- [Setup walkthrough](carla-on-apple-silicon.md) — the full install, start to finish
- [Sikarugir notes](docs/sikarugir.md) — the Wine wrapper: what it is, what was verified before
  trusting it, and how to pick an engine
- [Known-good checksums](checksums/known-good.txt) — hashes for every binary this project installs

External:

- [CARLA](https://github.com/carla-simulator/carla) — the simulator
- [CARLA discussion #9037](https://github.com/carla-simulator/carla/discussions/9037) — where this
  approach came from
- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir) — the Wine wrapper tool

## Caveats

- **The server runs under Wine. The Python client does too.** There is no native macOS build of
  either. The client works well inside the same wrapper; see the walkthrough.
- **ROS and ROS2 are unsolved.** Nobody in the community discussion has gotten a ROS bridge
  working with this setup. If your project depends on ROS, this is not yet a replacement for a
  Linux machine.

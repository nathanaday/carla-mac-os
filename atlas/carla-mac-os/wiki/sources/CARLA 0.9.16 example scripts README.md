---
type: source
title: "CARLA 0.9.16 example scripts README"
status: developing
created: 2026-09-23
updated: 2026-09-23
tags:
  - source
  - carla-on-macos
source_type: documentation
author: nathanaday (this project)
date_published: 2026-09-23
url: examples/carla/README.md
source_id: src-f381225007de478adf46
---

# CARLA 0.9.16 example scripts README

The README for the copied CARLA example scripts, part of [[CARLA on macOS]]. It stays in the
repository as `examples/carla/README.md`.

## Summary

It says that `examples/carla/` holds CARLA 0.9.16's example scripts, unchanged and MIT licensed.
They run through the launcher described on [[CARLA Wine Python client]]. It records which scripts
are tested, what was left out, and how to copy them again after an upgrade.

## Key claims

- `automatic_control.py`, `generate_traffic.py`, `manual_control.py`, and `dynamic_weather.py`
  load and parse arguments. They are not yet run against the server from this folder.
- `manual_control_chrono.py` and `open3d_lidar.py` are expected to fail.
- `invertedai_traffic.py` needs the `invertedai` package and an API key.
- `PythonAPI/examples/nvidia/` (159 MB) is left out; it needs a CUDA GPU.

## Notes

- The status table is meant to grow as scripts are tested.

# CARLA 0.9.16 example scripts

Copies of the scripts in `PythonAPI/examples` from the CARLA 0.9.16 Windows release, unchanged.
CARLA publishes them under the MIT license in [LICENSE](LICENSE).

Run any of them with the launcher, from the repository root, while `CARLA.app` is running:

```bash
scripts/carla-python examples/carla/generate_traffic.py
scripts/carla-python examples/carla/automatic_control.py --agent Behavior
```

The launcher puts CARLA's `agents` package on `PYTHONPATH`, so the scripts do not need to sit in
the CARLA folder.

## Status on this setup

| Script | Status |
|---|---|
| `automatic_control.py`, `generate_traffic.py`, `manual_control.py`, `dynamic_weather.py` | Load and parse arguments. Not yet run against the server from this folder. |
| `manual_control_chrono.py` | Expected to fail. It reads `Co-Simulation/Chrono` relative to the CARLA folder. |
| `open3d_lidar.py` | Expected to fail. It needs `open3d`, which is not installed in the wrapper. |
| `invertedai_traffic.py` | Needs the `invertedai` package and an Inverted AI API key. |
| All others | Not yet tested. |

Update this table as scripts are tested.

## Left out

`PythonAPI/examples/nvidia/` (159 MB) is not copied. It holds the NVIDIA Cosmos and NuRec
integrations, which need a CUDA GPU.

## Refreshing

To copy the scripts again after a CARLA upgrade:

```bash
src=~/Applications/Sikarugir/CARLA.app/Contents/SharedSupport/prefix/drive_c/Program\ Files/CARLA_0/PythonAPI/examples
cp "$src"/*.py "$src"/requirements.txt "$src"/cosmos_aov.yaml examples/carla/
```

Change `CARLA_0` to the folder name in your wrapper.

# Run CARLA on Apple Silicon

CARLA publishes builds for Ubuntu and Windows only. This guide runs the **Windows** build of the
CARLA server on an Apple Silicon Mac inside a Wine wrapper, using Apple's D3DMetal to translate
Direct3D 12 calls to Metal. The Python client and CARLA's driving agents run inside the same
wrapper.

There is no native macOS build of the CARLA server, and no macOS wheel for the `carla` Python
package. Both halves run under Wine.

Community reports in [carla-simulator/carla#9037](https://github.com/carla-simulator/carla/discussions/9037)
confirm this stack on macOS 26.2 with CARLA 0.9.16, on a MacBook Air M4 (24 GB) and a Mac Mini
M4 (16 GB). Earlier reports put CARLA 0.9.15 at 30-60 fps on a Mac Mini M4.

## Not covered here

- **ROS / ROS2.** Nobody in the discussion got ROS working with this setup. ROS inside Wine failed.
  ROS inside Docker works, but DDS multicast stays inside the Docker network.
- **CARLA 0.10.0 (Unreal Engine 5).** It runs, at 10-15 fps on a Mac Mini M4. Use 0.9.16.
- **Building CARLA from source.** The Windows release package is the only practical input.

## Requirements

| Item | Value |
|---|---|
| Hardware | Apple Silicon Mac. M4 handles CARLA 0.9.15 and 0.9.16. M1 and M2 machines are reported to need 0.9.14 or older. |
| Memory | 24 GB for 0.9.15 and later. 16 GB has failed; see Reported failures. |
| macOS | 26 recommended. Sikarugir itself runs on 14 or later, but every confirmed CARLA success is on macOS 26.x. See Reported failures. |
| Free disk | 45 GB at peak. The 0.9.16 Windows zip is 7.8 GB, the extracted folder is larger, and Step 4 copies it a second time into the wrapper. The additional maps are another 7.3 GB. |
| Other | Homebrew, Rosetta 2 |

Install Rosetta 2 if it is missing:

```bash
/usr/sbin/softwareupdate --install-rosetta --agree-to-license
```

That command prints nothing when Rosetta is already present, so it is not proof.
Confirm it separately:

```bash
/usr/bin/arch -x86_64 /usr/bin/true && echo "rosetta ok" || echo "ROSETTA MISSING"
```

### Reported failures

| Machine | CARLA | Result |
|---|---|---|
| M4, 16 GB, macOS 15.6 | 0.9.16 | Wine starts both processes, a `CarlaUE4` window opens and stays solid black, and the host swaps heavily. Town10 never appears. ([issue #1](https://github.com/nathanaday/carla-mac-os/issues/1)) |

Two things differ from the tested configuration in that report: the memory, and
the macOS version. Do not assume it is the memory. Every confirmed success in
this project and in the community thread runs macOS 26.x, where D3DMetal is
version 3.0, and the engines are built against it. If you are on macOS 15 and
get a black screen, run the check in
[Black screen: which half failed](#black-screen-which-half-failed) before you
spend an afternoon downloading other CARLA versions.

## Choose a CARLA version

| Version | Use it when |
|---|---|
| **0.9.16** | Default choice. Latest release, reported working on macOS 26.2. |
| 0.9.15 | Fall back here if 0.9.16 fails to finish loading. Confirm that is the failure first; a black screen alone does not mean the CARLA version is wrong. Most widely reported version in the thread. |
| 0.9.11-0.9.14 | M1 or M2 hardware. |
| 0.10.0 | Skip. Unreal Engine 5, 10-15 fps on M4. |

The rest of this guide uses 0.9.16. Substitute the version number where it appears in paths.

## Step 1: Install Sikarugir

Sikarugir is a maintained fork of the Wineskin wrapper tool. Use it rather than Kegworks —
Kegworks fails to create a wrapper on macOS 26 with a "no wrapper installed" error.

```bash
brew upgrade
brew trust --cask Sikarugir-App/sikarugir/sikarugir
brew install --cask Sikarugir-App/sikarugir/sikarugir
```

Trust the cask, not the whole tap. `brew trust Sikarugir-App/sikarugir` also works and is what the
project's README shows, but it covers every cask and command in that tap, now and in the future.

Before or after installing, verify what you pulled:

```bash
scripts/verify-sources.sh
```

That checks the cask's pinned hash against a fresh download, confirms the publisher, and lists
every network endpoint embedded in the app. See [docs/sikarugir.md](docs/sikarugir.md) for what
the checks prove, and for the two things about this install that are worth knowing: the app is not
notarized, and the Creator is closed source.

## Step 2: Create a blank wrapper

1. Open **Sikarugir Creator.app**.
2. Click **Install Engine** and choose **`WS12WineSikarugir10.0_6`**.
3. Click **Update Wrapper**.
4. Click **Create New Blank Wrapper**. Name it `CARLA`.

The engine list is not sorted by recency, and the names mix a Wineskin series number, a Wine
source, and a rebuild counter. Three rules cover it:

- Take a **`WS12`** engine. That is the newer Wineskin series.
- Never take a **`32Bit`** engine. CARLA ships 64-bit binaries only.
- The trailing `_6` is a rebuild number, not a version.

`WS12WineCX24.0.7_7` is the fallback if the default engine misbehaves.
[docs/sikarugir.md](docs/sikarugir.md) decodes the full list. To check an engine before using it:

```bash
scripts/verify-sources.sh engine WS12WineSikarugir10.0_6
```

The wrapper is an app bundle, written to `~/Applications/Sikarugir/CARLA.app`. Everything from here
happens inside it.

If **Install Engine** fails with `Sikarugir_Creator.EngineDownloadError error 1`, retry it once.
The same download usually succeeds on a second attempt. If it keeps failing, place the tarball by
hand and reopen the Creator:

```bash
mkdir -p ~/Library/Application\ Support/Sikarugir/Engines
curl -fL -o ~/Library/Application\ Support/Sikarugir/Engines/WS12WineSikarugir10.0_6.tar.xz \
  https://github.com/Sikarugir-App/Engines/releases/download/v1.0/WS12WineSikarugir10.0_6.tar.xz
scripts/verify-sources.sh engine WS12WineSikarugir10.0_6
```

## Step 3: Install the Visual C++ runtime

1. Right-click `CARLA.app` and choose **Show Package Contents**.
2. Open `Contents/Configure.app`.
3. Open **Winetricks** (under **Tools** on the Advanced screen in some builds).
4. Search for `vcrun`. Select **`vcrun2022` only**. Uncheck **silent**. Click **Run**.

Watch the installer window that appears and confirm it finishes without an error.

> **Do not install `vcrun2019`.** The original setup notes call for both, but installing 2019
> alongside 2022 produces a fatal error on Test Run under macOS 26.

If Winetricks reports problems later, `win10` and `cmd` are also worth installing.

## Step 4: Install CARLA into the wrapper

1. Download [CARLA_0.9.16.zip](https://downloads.carlasim.com/Windows/CARLA_0.9.16.zip) and extract it.
2. In `Configure.app`, click **Install Software**.
3. Click **Move a Folder Inside** and select the extracted folder.

The folder lands in `C:\Program Files` inside the wrapper. Check its name before you continue:

```bash
ls ~/Applications/Sikarugir/CARLA.app/Contents/SharedSupport/prefix/drive_c/Program\ Files
```

The name can be `CARLA_0` instead of `CARLA_0.9.16`: the move can cut the name at the first dot.
This guide writes `CARLA_0.9.16`. Use the name you find in every path from here on.

## Step 5: Set the executable

In `Configure.app`, set the Windows executable to:

```
C:\Program Files\CARLA_0.9.16\CarlaUE4.exe
```

> **Point at `CarlaUE4.exe`, not `CarlaUE4\Binaries\Win64\CarlaUE4-Win64-Shipping.exe`.**
> The shipping binary is the launcher's target, not the launcher. Running it directly is the most
> common cause of the fatal-error dialog on Test Run.

Put the path here and nothing else. Launch flags go in a separate field, covered in Step 7.

## Step 6: Enable D3DMetal and test

1. In `Configure.app`, check **D3DMetal**.
2. Optionally check **Performance HUD** to display fps, GPU, and memory on the CARLA window.
3. Click **Test Run**.

CARLA should open a window showing Town10 with a free camera. Drag to look around.

Once Test Run succeeds, close `Configure.app`. Launch `CARLA.app` from Finder like any other Mac
application.

## Step 7: Set launch flags

`Configure.app` stores the executable and its flags in two separate fields. Flags go in the second
one.

> **Do not append flags to the executable path.** The Configure UI says the Windows app field
> "also takes command line switches." It does not. Whatever you type there is stored whole in
> `Program Name and Path`, and `Program Flags` stays empty. Wine then looks for an executable whose
> filename contains the flags, finds nothing, and exits. **Test Run appears to do nothing: no
> window, no error dialog, no `wineserver` process.**

| Field | Value |
|---|---|
| `Program Name and Path` | `/Program Files/CARLA_0.9.16/CarlaUE4.exe` |
| `Program Flags` | `-quality-level=Low` |

Editing the executable text field again re-merges the flags into the path. If a launch that used to
work stops working right after you touched that field, read the two values back:

```bash
plist=~/Applications/Sikarugir/CARLA.app/Contents/Info
defaults read "$plist" "Program Name and Path"
defaults read "$plist" "Program Flags"
```

Leave the `.plist` extension off; `defaults` adds it. Set them directly if the UI keeps merging
them:

```bash
defaults write "$plist" "Program Name and Path" "/Program Files/CARLA_0.9.16/CarlaUE4.exe"
defaults write "$plist" "Program Flags" "-quality-level=Low -windowed -ResX=1280 -ResY=720"
```

Available flags:

| Flag | Effect |
|---|---|
| `-quality-level=Low` | Fixes freezing and slow rendering. Try this first if the window stutters. |
| `-RenderOffScreen` | Runs the server with no window. Use when a client script drives everything. |
| `-carla-rpc-port=2000` | Sets the RPC port. Default is 2000. |
| `-windowed -ResX=1280 -ResY=720` | Runs at a fixed smaller resolution. |

With `-RenderOffScreen` there is no window to close. Stop the server with **Kill Wine Processes**
in the `Configure.app` Tools window.

## Step 8: Install the Python client

The client runs inside the same wrapper, against a Windows Python.

Python 3.10 is the version to install. It is the only release with a Windows `carla` wheel for both
0.9.15 and 0.9.16:

| CARLA | Windows wheels on PyPI |
|---|---|
| 0.9.15 | 3.7, 3.8, 3.9, 3.10 |
| 0.9.16 | 3.10, 3.11, 3.12 |

1. Download the **Windows 64-bit** installer for Python 3.10 from python.org.
2. In `Configure.app`, click **Install Software**, then **Choose Setup Executable**, and select the
   Python installer.
3. In the Python installer, click **Customize installation**. Check every optional feature. On the
   next screen check **Install for all users** and **Add Python to environment variables**. Install.

Start `CARLA.app`. Then install the client from a macOS Terminal, in this repository:

```bash
scripts/carla-python -m pip install --upgrade pip
scripts/carla-python -m pip install carla==0.9.16 "numpy<2" pygame networkx shapely
```

> **Pin `numpy<2`.** numpy 2.x calls `ucrtbase.dll.crealf`, a function this Wine build does not
> implement. Python crashes on `import numpy`, before the script connects to the server. In the
> `Configure.app` command window the crash prints nothing, so the script looks like it ran and
> did nothing. CARLA's own `PythonAPI/examples/requirements.txt` also pins `numpy<2.0.0`.

`networkx` and `shapely` are for the driving agents (Step 10). The `carla` wheel does not pull them
in.

### The launcher

`scripts/carla-python` runs the wrapper's Windows Python from a normal macOS Terminal. It takes the
same arguments as `python.exe`. It does three things:

- It sets the environment that Sikarugir uses when it launches CARLA.
- It puts the CARLA agents package, `PythonAPI/carla`, on `PYTHONPATH`.
- It converts a macOS path to a `.py` file into the Windows path Wine expects.

It finds the wrapper at `~/Applications/Sikarugir/CARLA.app`. Set `CARLA_APP` to use another one.

A bare call to the wrapper's `wine` binary does not work while CARLA is running. The running
`wineserver` uses `WINEMSYNC=1` and `WINEESYNC=1`. A Wine process without the same settings exits
at once with status 136 and no message. The launcher sets both.

**Command Line** in `Configure.app` still works as a fallback. Use `python` and `pip` there
directly, but you must set `PYTHONPATH` yourself to use the agents.

## Step 9: Run a client script

Start `CARLA.app`. Then, from this repository:

```bash
scripts/carla-python "C:\Program Files\CARLA_0.9.16\PythonAPI\examples\generate_traffic.py"
```

`manual_control.py` and `vehicle_gallery.py` work the same way. Their pygame windows open on the
Mac desktop.

Stop `generate_traffic.py` with Ctrl+C in the Terminal. It turns on synchronous mode by default
and restores the server settings only when it exits cleanly. If the script dies in another way, the
server stays in synchronous mode and waits for ticks that never come: the world freezes. Run any
client script to completion, or restart `CARLA.app`, to recover.

A `ModuleNotFoundError` means an example needs a dependency that the wheel does not pull in. Install
it and re-run:

```bash
scripts/carla-python -m pip install <module>
```

## Step 10: Drive with an agent

CARLA ships its driving agents as source in `PythonAPI/carla/agents`, not in the `carla` wheel.
The launcher puts them on `PYTHONPATH`, so `from agents.navigation.basic_agent import BasicAgent`
works in any script it runs.

| Agent | Behavior |
|---|---|
| `BasicAgent` | Follows a route to a destination at a target speed. Stops for other vehicles and red lights. |
| `BehaviorAgent` | Adds tailgating, lane changes, and speed limits. Profiles: `cautious`, `normal`, `aggressive`. |
| `ConstantVelocityAgent` | Holds a fixed speed and ignores physics limits. For testing. |

Run the example in this repository. It drives one vehicle across Town10 in synchronous mode, and
the camera follows the car:

```bash
scripts/carla-python examples/basic_agent.py            # 600 ticks, 30 s simulated
scripts/carla-python examples/basic_agent.py --ticks 0  # until the car arrives
```

Expected output:

```
driving Location(x=-64.64, y=24.47, z=0.60) -> Location(x=109.52, y=89.84, z=0.60)
tick     0    3.5 km/h  ...
tick   100   29.9 km/h  ...
```

On an M4 Pro, 300 ticks (15 s simulated) take about 6 s of wall time.

CARLA's own demo uses `BehaviorAgent` with a pygame view:

```bash
scripts/carla-python "C:\Program Files\CARLA_0.9.16\PythonAPI\examples\automatic_control.py" --agent Behavior --behavior normal
```

Use synchronous mode in your own agent scripts, as `examples/basic_agent.py` does. The server then
advances only when the client calls `world.tick()`. Agent behavior no longer depends on how fast
the client runs under Wine. Restore the original settings in a `finally` block, for the reason
given in Step 9.

## Optional: additional maps

1. Download [AdditionalMaps_0.9.16.zip](https://downloads.carlasim.com/Windows/AdditionalMaps_0.9.16.zip).
2. Find the wrapper's Windows drive:

```bash
find ~/Applications -maxdepth 6 -type d -name drive_c
```

3. Unzip into the CARLA root folder **from Terminal**:

```bash
unzip AdditionalMaps_0.9.16.zip -d "<drive_c>/Program Files/CARLA_0.9.16"
```

Extracting through Finder produces a layout where the client cannot find the new maps.

## Troubleshooting

| Symptom | Fix |
|---|---|
| "No wrapper installed", cannot create a wrapper | You are on Kegworks. Use Sikarugir (Step 1). |
| `EngineDownloadError error 1` on Install Engine | Retry once, or place the tarball by hand (Step 2). |
| Test Run does nothing: no window, no error, no process | Flags are glued onto the executable path. Split them into `Program Flags` (Step 7). |
| Fatal error on Test Run | Install `vcrun2022` only, not `vcrun2019` (Step 3). |
| Fatal error, and `CarlaUE4-Win64-Shipping.exe` opens | Point the wrapper at `CarlaUE4.exe` (Step 5). |
| Black screen, no crash | Find out which half failed before changing anything. See below. |
| Freezing, very low fps | Add `-quality-level=Low` (Step 7). |
| Client cannot find added maps | Re-extract the maps zip from Terminal (Optional section). |
| Client script ends at once, prints nothing, and the world does not change | numpy 2.x crashed on import. Install `numpy<2` (Step 8). |
| `wine` from Terminal exits with status 136 and prints nothing | Wine's sync settings do not match the running `wineserver`. Use `scripts/carla-python` (Step 8). |
| `No module named 'agents'` | Run the script through `scripts/carla-python`, or add `PythonAPI\carla` to `PYTHONPATH` (Step 10). |
| World freezes after a client script dies | The script left synchronous mode on. Run a client to completion, or restart `CARLA.app` (Step 9). |
| Paths with `CARLA_0.9.16` are not found | The folder may be `CARLA_0`. Check the name (Step 4). |
| macOS reports a downloaded package as damaged | Settings → Privacy & Security → **Open Anyway**. |

### Black screen: which half failed

A black window means the processes started. It does not say whether CARLA finished loading the
level. Those are two different failures with two different fixes, and the server tells you which
one you have: it binds its RPC port only after the level is loaded.

Leave the black window open. In Terminal on the Mac host:

```bash
for i in $(seq 1 180); do
  nc -z 127.0.0.1 2000 && { echo "RPC UP after $((i*10))s"; break; }
  sleep 10
done
```

**The port opens.** The server loaded and is running. Only the picture is missing, so the fault is
in the D3DMetal display path, not in CARLA and not in your memory. In order:

1. Confirm **D3DMetal** is still checked in `Configure.app` (Step 6).
2. On macOS 15 or earlier, try the `WS12WineCX24.0.7_7` engine, then `WS12WineGPTK1.1_3`. The
   default engine is built against the macOS 26 D3DMetal.
3. If neither renders, macOS 26 is the fix. Every confirmed success runs it.

You can keep working in the meantime. Add `-RenderOffScreen` (Step 7) and drive the simulator
entirely from the Python client (Steps 8-10) — no window is needed.

**The port never opens.** The level never finished loading. That is memory or shader compilation.

1. **Wait longer on the first launch.** D3DMetal translates every shader the first time and caches
   the result. First load of Town10 can take 20-30 minutes on a memory-tight machine. The second
   launch is far cheaper. Let it run before deciding it is stuck.
2. Free memory: quit everything else, and check `sysctl vm.swapusage` while CARLA loads. Steady
   growth in swap means the machine is thrashing.
3. Shrink the job: `-quality-level=Low -windowed -ResX=640 -ResY=480 -nosound`.
4. Drop to **0.9.15**, then **0.9.9.4** to confirm the wrapper itself works.

## Architecture

```
macOS (arm64)
└── Sikarugir wrapper: CARLA.app
    ├── Wine + D3DMetal
    ├── CarlaUE4.exe          server, RPC on port 2000
    └── Python 3.10 (win64)   client, carla wheel from PyPI, agents from PythonAPI/carla
        ▲
        └── scripts/carla-python   runs the client from a macOS Terminal
```

The client talks to the server over TCP on ports 2000 and 2001, so it can live anywhere that can
reach those ports. The alternative to Wine Python is a `linux/amd64` Docker container running the
manylinux wheel, connecting to `host.docker.internal`. The discussion reports that this works. This
project has not tested it, and the discussion's author moved away from it once the Wine client
worked. Sensor data arrives on port 2001 at an address the server reports, so test a camera sensor
before you rely on the Docker path.

## Sources

- [CARLA discussion #9037](https://github.com/carla-simulator/carla/discussions/9037) — the full thread
- "CARLA Server on Apple Silicon Mac" PDF by @nveshaan, attached to that thread
- Python client inside the wrapper: [@canibal1's comment](https://github.com/carla-simulator/carla/discussions/9037#discussioncomment-13964038)
- macOS 26 fixes (Sikarugir, `vcrun2022`, `CarlaUE4.exe`): [@potatocodex](https://github.com/carla-simulator/carla/discussions/9037)
- Video walkthroughs by @potatocodex: [server](https://youtu.be/1ioMz-HHmEI), [Python client](https://youtu.be/581klnkqgO8)

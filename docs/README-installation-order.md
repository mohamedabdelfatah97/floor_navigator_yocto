# README — Floor Navigator Pollux installation order

> **Purpose:** A single ordered route through the tested Yocto/Weston desktop and Floor Navigator software baseline.
>
> **Verified target:** PHYTEC phyBOARD-Pollux i.MX8MP, `MACHINE=phyboard-pollux-imx8mp-3`, PHYTEC `PD24.1.0`, `DISTRO=ampliphy-vendor-xwayland`.
>
> **Important limitation:** The working board was assembled through a mix of Yocto builds and manual target deployments. **Do not claim that one fresh-image build already reproduces all installed applications.** In particular, the complete initial PCManFM isolated-runtime assembly is still not published as a fully reproducible installer.

See [Documentation index](README.md), [Workspace layout](workspace-layout.md), and [Python libraries from scratch](README-python-libraries.md).

## 1. The dependency order

| Order | Install / configure | Guide to follow | Board-baseline status |
| --- | --- | --- | --- |
| 1 | Initialize the matching PHYTEC Yocto BSP, machine, distro, and host build tools | [Workspace layout](workspace-layout.md) | Verified existing workspace |
| 2 | Enable and validate the `meta-floor-nav` custom layer; build/boot the appropriate Weston/XWayland image | [Workspace layout](workspace-layout.md), project recipes | Tested existing BSP image; not a complete fresh-image recipe for every extra app |
| 3 | Establish board access (SSH/serial), Weston session and graphical terminal | BSP / board image | Available on tested board |
| 4 | Build/deploy Chromium 117 and its Weston launcher | [Chromium on Pollux](chromium-pollux.md); [release notes](chromium-release-notes.md) | Browser, GPU acceleration, sandbox, persistent launcher verified |
| 5 | Build/deploy Geany 1.38 and its Weston launcher | [Geany on Pollux](geany-pollux.md) | Editing/saving and persistent launcher verified |
| 6 | Build/deploy PCManFM 1.3.2 isolated XWayland runtime; menu-cache, icon, MIME defaults and launcher | [PCManFM on Pollux](pcmanfm-pollux.md) | Folder browsing and `.txt` → Geany verified; initial runtime assembly not fully scripted |
| 7 | Verify system Python 3.12.6, NumPy 1.26.4, OpenCV 4.9.0 and the original Floor Navigator source copy | Section 3 below | Core synthetic ORB/SE(2) test passed |
| 8 | Deploy scientific, stdlib bootstrap, and neural ARM64 dependencies under `/opt/floor-nav-pydeps/` | [Python libraries from scratch](README-python-libraries.md) | SciPy, pandas, Matplotlib, Torch CPU, Kornia and HardNet smoke tests passed |
| 9 | Run the final non-destructive baseline checklist | Section 4 below | Tested software baseline; not a live-camera validation |

Steps 4–6 can have overlapping build dependencies, but the **practical order** above gives you Geany before configuring PCManFM's text-file associations. Install the libraries after the working base image and system OpenCV are established.

## 2. Set up the Yocto workspace and desktop applications

### 2.1 Host / BSP

The original working directory is:

```text
~/floor_navigator_yocto/
├── sources/   # Yocto BSP and OpenEmbedded layers
├── build/     # Existing build artifacts and configuration
└── github/floor_navigator_yocto/  # Git repository including docs/ and meta-floor-nav/
```

For the original workspace on Ubuntu:

```bash
cd ~/floor_navigator_yocto
source buildtools/environment-setup-x86_64-pokysdk-linux
source sources/poky/oe-init-build-env build
bitbake-layers show-layers | grep meta-floor-nav
bitbake -e | grep -E '^(MACHINE|DISTRO|TMPDIR|DEPLOY_DIR_RPM)='
```

The configured distro's RPM feed is normally under `build/deploy-ampliphy-vendor-xwayland/rpm`, **not** `build/tmp/deploy/rpm`. Prefer the values reported by BitBake over hardcoded guesses. Do not move the existing `sources/` or `build/` trees casually.

### 2.2 Boot the board and establish remote access

Follow the PHYTEC BSP flashing/boot instructions for your specific storage medium/image. The tested board accepted SSH as `root@172.16.0.193` (an example, not a fixed factory address):

```bash
ssh root@172.16.0.193 'uname -m; cat /etc/os-release; python3 --version'
```

Before modifying the Weston panel, **back up** `/etc/xdg/weston/weston.ini`. Preserve the image's hardware-specific Weston configuration and add launcher sections rather than replacing the entire file.

### 2.3 Desktop applications in order

**Chromium first:** use [chromium-pollux.md](chromium-pollux.md) for Chromium 117's tested local bundle, GPU settings, sandbox check and launcher. The precompiled binary was **not published** as a public GitHub Release; use locally available assets or build as documented. Chromium 117 is old and should not be used for sensitive accounts/untrusted browsing.

**Geany second:** use [geany-pollux.md](geany-pollux.md). Geany 1.38 was built with Yocto and installed on the matching board, then given a Weston launcher. File creation, editing, saving, and opening `.txt` from PCManFM were verified. Existing RPM command options may bypass checks; review compatibility before repeating on a different image.

**PCManFM third:** use [pcmanfm-pollux.md](pcmanfm-pollux.md). This is a GTK3 X11/XWayland application deployed through an isolated runtime at `/opt/floor-pcmanfm`, not a standard one-command package install. The final tested setup used `menu-cached`, `menu-cache-gen`, `libfm-extra`, `XDG_MENU_PREFIX=lxde-`, `XDG_CURRENT_DESKTOP=LXDE`, and system MIME defaults for Geany. Folder browsing and opening a text file in Geany were verified after the earlier crash was fixed. **A fresh-board assembly script for the complete PCManFM runtime is still missing.**

**Terminal:** use the graphical terminal already provided by the Weston image. A separate terminal installation procedure was not required/recorded in this baseline; do not invent one.

## 3. Stage the Floor Navigator source and Python libraries

### 3.1 Preserve the original source and use a separate compatibility test copy

The tested board had these separate paths:

```text
/opt/floor-nav-prototype/      # Original source and calibration files (unchanged)
/opt/floor-nav-compat-test/    # Copy with import-only compatibility fixes
```

The original source archive excluded bulky model weights and datasets, and included the Python `src/` tree, `calibration/*.yaml` and `requirements.txt`. Its original transfer was a manual staging step, **not** a production install recipe bundled with the Yocto layer. Do not copy all research datasets or alter the original Ubuntu source project just to make the board import modules.

Two compatibility changes on the *separate test copy* removed unused eager imports from `PlaneSe2Pipeline.py` and deferred importing torch/Kornia until a neural mode is selected in `FeatureDetector.py`. Neither change altered SE(2), feature matching, or pose-estimation math. Their unchanged originals remained under `/opt/floor-nav-prototype` and were checksum-matched against the Ubuntu reference files.

If rebuilding a board from scratch, transfer the source archive to the **prototype** path first, make an isolated copy, then apply only the audited import compatibility patch to that test copy; do not assume this repo currently includes an automated source-deployment script.

### 3.2 Scientific and neural dependencies

Follow **[README-python-libraries.md](README-python-libraries.md)** after the base image and OpenCV are working. It records the tested cross-platform ARM64 wheel process from scratch, including its two genuine problems and their fixes:

- minimal Yocto stdlib missing `getpass` and `zoneinfo` → extract the matching Yocto Python modules into isolated `bootstrap/`;
- host pip incorrectly resolving PyTorch's x86-64 CUDA dependencies → download an explicit AArch64 CPU-side list with `--no-deps`.

The resulting target layout is:

```text
/opt/floor-nav-pydeps/bootstrap/
/opt/floor-nav-pydeps/science/
/opt/floor-nav-pydeps/neural/
```

No host CUDA, GPU drivers, system Python, or workstation machine-learning environments need changing. On Pollux, activate the isolated runtime only for Floor Navigator tests:

```bash
export PYTHONPATH=/opt/floor-nav-pydeps/bootstrap:/opt/floor-nav-pydeps/neural:/opt/floor-nav-pydeps/science:/opt/floor-nav-compat-test/src
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 MPLBACKEND=Agg
```

## 4. Final baseline checklist

These are software-level checks. The detailed Python functional test is in [README-python-libraries.md](README-python-libraries.md).

```bash
# Run from Ubuntu; read-only checks, except creating a temporary plot in /tmp
ssh root@172.16.0.193 'sh -s' <<'BOARD'
set -eu
echo '=== BOARD / BSP ==='
uname -m
python3 --version

echo '=== SYSTEM NUMPY / OPENCV ==='
env -u PYTHONPATH python3 -c \
  'import numpy, cv2; print(numpy.__version__, cv2.__version__)'

echo '=== ISOLATED PACKAGES ==='
export PYTHONPATH=/opt/floor-nav-pydeps/bootstrap:/opt/floor-nav-pydeps/neural:/opt/floor-nav-pydeps/science:/opt/floor-nav-compat-test/src
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 MPLBACKEND=Agg
python3 - <<'PY'
import numpy, cv2, scipy, pandas, matplotlib, torch, kornia, kornia_rs
from utils.PlaneSe2Pipeline import PlaneSe2Pipeline
from utils.FeatureDetector import FeatureDetector
print('NumPy', numpy.__version__, 'OpenCV', cv2.__version__)
print('SciPy', scipy.__version__, 'pandas', pandas.__version__)
print('Matplotlib', matplotlib.__version__, 'PyTorch', torch.__version__)
print('Kornia', kornia.__version__, 'kornia_rs imported')
print('PASS: Floor Navigator module imports')
PY

echo '=== INSTALLED GUI LAUNCHER FILES ==='
for cmd in /usr/local/bin/floor-chromium /usr/local/bin/floor-geany /usr/local/bin/floor-pcmanfm; do
    if [ -x "$cmd" ]; then echo "FOUND: $cmd"; else echo "CHECK: $cmd"; fi
done
BOARD
```

**Graphical checks require using the actual Weston desktop** (SSH alone does not prove the UI works): open Chromium, Geany, the terminal, and PCManFM from their icons; browse folders; open a `.txt` file in Geany from PCManFM; verify the launchers remain present after reboot.

## 5. What this baseline does—and does not—claim

**Verified:** Weston/XWayland environment; Chromium 117 with GPU/sandbox; Geany 1.38; PCManFM 1.3.2 file navigation and text opening; Python 3.12.6; NumPy/OpenCV system baseline; SciPy/pandas/Matplotlib; PyTorch 2.8.0+cpu/Kornia/kornia_rs; synthetic CPU HardNet inference; Floor Navigator ORB/SIFT extraction and synthetic ORB SE(2) operation.

**Not yet established:** full fresh-image reproducibility for all apps, complete PCManFM clean install, live camera (none was connected/recognized during the previous audit), pretrained HardNet/HardNet++ weights, or accuracy on a real sequence of floor images.

This is the **working software installation baseline**, not a claim that the complete camera-localization product is finished.

## 6. Guide index

- [Yocto workspace and custom layer](workspace-layout.md)
- [Chromium on Pollux](chromium-pollux.md)
- [Geany on Pollux](geany-pollux.md)
- [PCManFM on Pollux](pcmanfm-pollux.md)
- [Cross-platform Python package installation](README-python-libraries.md)
- [Build versions](build-versions.txt)
- [Documentation index](README.md)

# README — Scientific and neural Python libraries on Pollux

> **Verified:** 17 November 2026 on the PHYTEC phyBOARD-Pollux i.MX8MP.
>
> **Audience:** Someone starting with the **already prepared** PHYTEC PD24.1.0 `ampliphy-vendor-xwayland` image, with Python 3.12.6, NumPy 1.26.4 and OpenCV 4.9.0 present.
>
> **Deployment:** Cross-download AArch64 Python wheels on Ubuntu, extract them into temporary staging folders on Ubuntu, and transfer resulting archives to isolated directories on Pollux. **Do not install these packages into the Ubuntu host environment or into the target system Python.**
>
> **Status:** All imports and functional smoke tests in this guide passed on the original Pollux. This is a software baseline, not evidence of live camera or real-floor localization performance.

Related: [Overall setup order](README-installation-order.md) · [Documentation index](README.md) · [Yocto workspace](workspace-layout.md).

## 1. Verified versions and layout

| Component | Version / status on the board |
| --- | --- |
| CPU architecture | `aarch64`, i.MX8MP Cortex-A53 |
| BSP | `BSP-Yocto-NXP-i.MX8MP-PD24.1.0` |
| Yocto machine | `phyboard-pollux-imx8mp-3` |
| Yocto distribution | `ampliphy-vendor-xwayland` |
| Python | 3.12.6 |
| glibc | 2.39 |
| System NumPy / OpenCV | 1.26.4 / 4.9.0 (preserved) |
| Staged scientific packages | NumPy 1.26.4, SciPy 1.16.3, pandas 2.2.3, Matplotlib 3.10.1 |
| Staged neural packages | PyTorch 2.8.0+cpu, Kornia 0.8.1, kornia_rs 0.1.9 |
| RAM | ~3.5 GiB, no swap; CPU-only inference |

```text
/opt/floor-nav-pydeps/
├── bootstrap/       # Yocto-built Python stdlib add-ons: zoneinfo, getpass
├── science/         # ARM64 NumPy, SciPy, pandas, Matplotlib and dependencies
└── neural/          # ARM64 PyTorch, Kornia and CPU-side dependencies

/opt/floor-nav-prototype/    # Untouched original Floor Navigator source copy
/opt/floor-nav-compat-test/  # Separate import-compatibility test copy
```

**Important:** The `PYTHONPATH` in the verification section is required each time the isolated modules are used, or can be exported in a dedicated *board-only* launcher. Nothing here changes the target's default imports globally.

## 2. Prerequisites / safety

- Ubuntu host already has `python3 -m pip` (the tested host used pip 24.0 and Python 3.12).
- A matching configured PHYTEC Yocto workspace at `~/floor_navigator_yocto/` and SSH access to `root@172.16.0.193` (replace the IP as needed).
- On the board, `python3 --version`, `python3 -c 'import numpy, cv2'` and `uname -m` should succeed **before** proceeding.
- Have several hundred MiB of space on the board; the verified neural directory occupied ~483 MB after extraction.
- Run all **HOST** commands on Ubuntu and **BOARD** commands via SSH. Never run `pip install` without `--target` on the host for this procedure. Do not use `sudo pip`.
- Do not overwrite any populated `/opt/floor-nav-pydeps/*` directory. The examples stop if a target exists.

```bash
ssh root@172.16.0.193 'uname -m; python3 --version; python3 -c "import numpy, cv2; print(numpy.__version__, cv2.__version__)"; free -h; df -h /opt'
```

## 3. Stage the scientific wheels on the Ubuntu host

The explicit AArch64 platform/ABI flags prevent pip from selecting the workstation's x86-64 wheels. Resolving the scientific dependencies is safe here because no PyTorch/CUDA packages are involved.

```bash
# HOST — produces /tmp/floor-nav-science-runtime.tar.gz
bash <<'HOST'
set -eu
WHEELS=/tmp/floor-nav-science-wheels
OUTPUT=/tmp/floor-nav-science-runtime.tar.gz

if [ -e "$OUTPUT" ]; then
    echo "Archive already exists; preserving it: $OUTPUT"
    exit 1
fi
mkdir -p "$WHEELS"
cat > "$WHEELS/requirements-science.txt" <<'REQ'
numpy==1.26.4
scipy==1.16.3
pandas==2.2.3
matplotlib==3.10.1
REQ

python3 -m pip download --only-binary=:all: \
    --platform manylinux_2_28_aarch64 \
    --platform manylinux_2_17_aarch64 \
    --platform manylinux2014_aarch64 \
    --python-version 3.12 --implementation cp --abi cp312 \
    --dest "$WHEELS" -r "$WHEELS/requirements-science.txt"

STAGE=$(mktemp -d /tmp/floor-nav-science-stage.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT
python3 -m pip install --no-index --find-links="$WHEELS" \
    --only-binary=:all: \
    --platform manylinux_2_28_aarch64 \
    --platform manylinux_2_17_aarch64 \
    --platform manylinux2014_aarch64 \
    --python-version 3.12 --implementation cp --abi cp312 \
    --target "$STAGE" --ignore-installed --no-compile \
    -r "$WHEELS/requirements-science.txt"

for pkg in numpy scipy pandas matplotlib; do test -d "$STAGE/$pkg"; done
tar -czf "$OUTPUT" -C "$STAGE" .
ls -lh "$OUTPUT"; sha256sum "$OUTPUT"
HOST
```

The original run produced an ~80 MB archive, SHA-256 `5d890e564dae40a94d7061a3127950678c8af44b02854cb8cb9fa5cae3394194`. That checksum is a **historical result**, not an expected value for newly resolved dependency versions. Save the hash printed by your own build.

Copy to the target and extract in isolation:

```bash
# HOST
scp /tmp/floor-nav-science-runtime.tar.gz root@172.16.0.193:/tmp/

# HOST -> BOARD
ssh root@172.16.0.193 'sh -s' <<'BOARD'
set -eu
ARCHIVE=/tmp/floor-nav-science-runtime.tar.gz
DEST=/opt/floor-nav-pydeps/science
test -f "$ARCHIVE"
tar -tzf "$ARCHIVE" >/dev/null
if [ -e "$DEST" ]; then echo "Already exists: $DEST; stop"; exit 1; fi
mkdir -p "$DEST"
tar -xzf "$ARCHIVE" -C "$DEST" --no-same-owner
for pkg in numpy scipy pandas matplotlib; do test -d "$DEST/$pkg"; done
printf 'Scientific runtime staged at %s\n' "$DEST"
BOARD
```

## 4. Add the two missing Python standard-library components

The minimal Yocto image had **no** `getpass` or `zoneinfo`. Attempting to bootstrap pip from its wheel directly on the board failed on `getpass`; importing pandas then failed on `zoneinfo`. The successful approach was to extract the matching Yocto-built files to a **separate** bootstrap path.

First ensure the current BSP has packaged Python 3.12.6; if the `packages-split` directories are absent, build the existing Yocto Python recipe (`bitbake python3`) in the configured workspace. Consult [workspace-layout.md](workspace-layout.md) to source the Yocto environment. Do **not** change the host's system Python. If BitBake fails with `/proc/self/uid_map: Operation not permitted` on Ubuntu 24.04, see troubleshooting below.

```bash
# HOST — from the same BSP workspace used to build the target image
bash <<'HOST'
set -eu
WORK="$HOME/floor_navigator_yocto/build/tmp-ampliphy-vendor-xwayland/work"
OUT=/tmp/floor-nav-stdlib-addons.tar.gz
if [ -e "$OUT" ]; then echo "Preserving existing archive: $OUT"; exit 1; fi
ZONE_PKG=$(find "$WORK" -type d -path '*/packages-split/python3-zoneinfo' -print -quit)
UNIX_PKG=$(find "$WORK" -type d -path '*/packages-split/python3-unixadmin' -print -quit)
test -n "$ZONE_PKG" && test -n "$UNIX_PKG"
ZONE_LIB="$ZONE_PKG/usr/lib/python3.12"
UNIX_LIB="$UNIX_PKG/usr/lib/python3.12"
test -f "$ZONE_LIB/zoneinfo/__init__.py"
test -f "$UNIX_LIB/getpass.py"
STAGE=$(mktemp -d /tmp/floor-nav-stdlib-stage.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT
cp -a "$ZONE_LIB/zoneinfo" "$STAGE/"
cp -a "$UNIX_LIB/getpass.py" "$STAGE/"
for f in "$ZONE_LIB"/lib-dynload/_zoneinfo*.so; do
    if [ -f "$f" ]; then cp -a "$f" "$STAGE/"; fi
done
tar -czf "$OUT" -C "$STAGE" .
ls -lh "$OUT"; sha256sum "$OUT"
HOST

scp /tmp/floor-nav-stdlib-addons.tar.gz root@172.16.0.193:/tmp/
ssh root@172.16.0.193 'sh -s' <<'BOARD'
set -eu
ARCHIVE=/tmp/floor-nav-stdlib-addons.tar.gz
DEST=/opt/floor-nav-pydeps/bootstrap
test -f "$ARCHIVE"
tar -tzf "$ARCHIVE" >/dev/null
if [ -e "$DEST" ]; then echo "Already exists: $DEST; stop"; exit 1; fi
mkdir -p "$DEST"
tar -xzf "$ARCHIVE" -C "$DEST" --no-same-owner
test -f "$DEST/zoneinfo/__init__.py" && test -f "$DEST/getpass.py"
BOARD
```

**Note:** This procedure does not install `python3-pip`, `python3-unixadmin` or `python3-zoneinfo` as target RPMs. The original board's RPM database appeared empty despite working system packages, so we deliberately avoided trying to repair its package database or force RPM dependency installation. A successful `bitbake python3 python3-pip` was used to obtain the Python package-split output; the pip RPM was not installed on Pollux.

## 5. Stage the CPU-only PyTorch / Kornia wheels on Ubuntu

**Do not use automatic dependency resolution for the cross-platform PyTorch download.** pip's Ubuntu-host marker handling attempted to download x86-64-only NVIDIA CUDA dependencies and failed on cuDNN. The working method pinned CPU-side dependencies and used `--no-deps`, leaving out CUDA, Triton and NVIDIA packages.

```bash
# HOST — produces /tmp/floor-nav-neural-runtime.tar.gz
bash <<'HOST'
set -eu
WHEELS=/tmp/floor-nav-neural-wheels
OUTPUT=/tmp/floor-nav-neural-runtime.tar.gz
if [ -e "$OUTPUT" ]; then echo "Archive already exists: $OUTPUT"; exit 1; fi
mkdir -p "$WHEELS"
cat > "$WHEELS/requirements-neural-cpu.txt" <<'REQ'
torch==2.8.0
kornia==0.8.1
kornia_rs==0.1.9
filelock==3.19.1
typing_extensions==4.13.2
setuptools==78.1.0
sympy==1.14.0
networkx==3.5
Jinja2==3.1.6
fsspec==2025.7.0
mpmath==1.3.0
MarkupSafe==3.0.2
REQ

PIP_NO_CACHE_DIR=1 python3 -m pip download --no-deps --only-binary=:all: \
    --platform manylinux_2_28_aarch64 \
    --platform manylinux_2_17_aarch64 \
    --platform manylinux2014_aarch64 \
    --python-version 3.12 --implementation cp --abi cp312 \
    --dest "$WHEELS" -r "$WHEELS/requirements-neural-cpu.txt"

STAGE=$(mktemp -d /tmp/floor-nav-neural-stage.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT
PIP_NO_CACHE_DIR=1 python3 -m pip install \
    --no-index --no-deps --find-links="$WHEELS" --only-binary=:all: \
    --platform manylinux_2_28_aarch64 \
    --platform manylinux_2_17_aarch64 \
    --platform manylinux2014_aarch64 \
    --python-version 3.12 --implementation cp --abi cp312 \
    --target "$STAGE" --ignore-installed --no-compile \
    -r "$WHEELS/requirements-neural-cpu.txt"

for pkg in torch kornia kornia_rs; do test -e "$STAGE/$pkg"; done
file "$STAGE"/torch/_C*.so   # must report ELF 64-bit ARM aarch64
tar -czf "$OUTPUT" -C "$STAGE" .
ls -lh "$OUTPUT"; sha256sum "$OUTPUT"
HOST
```

The verified Torch wheel was `torch-2.8.0-cp312-cp312-manylinux_2_28_aarch64.whl` with SHA-256 `e2fab4153768d433f8ed9279c8133a114a034a61e77a3a104dcdf54388838705`. The original neural transfer archive was ~104 MB compressed and ~483 MB extracted. Verify checksums for any reused archives before installing.

```bash
# HOST
scp /tmp/floor-nav-neural-runtime.tar.gz root@172.16.0.193:/tmp/

# HOST -> BOARD
ssh root@172.16.0.193 'sh -s' <<'BOARD'
set -eu
ARCHIVE=/tmp/floor-nav-neural-runtime.tar.gz
DEST=/opt/floor-nav-pydeps/neural
test -f "$ARCHIVE"
tar -tzf "$ARCHIVE" >/dev/null
if [ -e "$DEST" ]; then echo "Already exists: $DEST; stop"; exit 1; fi
mkdir -p "$DEST"
tar -xzf "$ARCHIVE" -C "$DEST" --no-same-owner
test -d "$DEST/torch" && test -d "$DEST/kornia"
test -e "$DEST/kornia_rs" || test -n "$(find "$DEST" -maxdepth 1 -name 'kornia_rs*.so' -print -quit)"
du -sh "$DEST"
BOARD
```

## 6. Verify everything on the board (no file changes)

This executes a very small CPU-only inference. The HardNet model in this smoke test is instantiated **without pretrained weights**; it tests that neural CPU execution works, not localization quality.

```bash
ssh root@172.16.0.193 'sh -s' <<'BOARD'
set -eu
export PYTHONPATH=/opt/floor-nav-pydeps/bootstrap:/opt/floor-nav-pydeps/neural:/opt/floor-nav-pydeps/science:/opt/floor-nav-compat-test/src
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 MPLBACKEND=Agg
python3 - <<'PY'
import numpy as np, scipy, pandas as pd, matplotlib, cv2
from scipy.spatial.transform import Rotation
print('NumPy', np.__version__, 'SciPy', scipy.__version__, 'pandas', pd.__version__)
print('Matplotlib', matplotlib.__version__, 'OpenCV', cv2.__version__)
assert Rotation.from_euler('z', 30, degrees=True).as_matrix().shape == (3, 3)
assert pd.DataFrame({'x': [1, 2, 3]}).shape == (3, 1)
import matplotlib.pyplot as plt
fig, ax = plt.subplots(); ax.plot([0, 1], [0, 1])
fig.savefig('/tmp/floor-nav-matplotlib-test.png'); plt.close(fig)
kp, desc = cv2.ORB_create(nfeatures=500).detectAndCompute(
    np.random.default_rng(42).integers(0, 256, (480, 640), dtype=np.uint8), None)
print('ORB keypoints', len(kp))
import torch, kornia, kornia_rs
from kornia.feature import HardNet
print('Torch', torch.__version__, 'Kornia', kornia.__version__)
torch.set_num_threads(1)
a = torch.tensor([[1., 2.], [3., 4.]])
assert (a @ a).tolist() == [[7., 10.], [15., 22.]]
with torch.inference_mode():
    descriptor = HardNet(pretrained=False).eval()(torch.rand(1, 1, 32, 32))
assert tuple(descriptor.shape) == (1, 128)
from utils.PlaneSe2Pipeline import PlaneSe2Pipeline
from utils.FeatureDetector import FeatureDetector
print('PASS: scientific, neural, ORB, SE(2) and FeatureDetector imports')
PY

echo '=== BOARD SYSTEM PYTHON UNAFFECTED ==='
env -u PYTHONPATH python3 -c \
  'import numpy, cv2; print(numpy.__version__, cv2.__version__)'
BOARD
```

Expected verified results: Torch `2.8.0+cpu`; Kornia `0.8.1`; descriptor shape `(1, 128)`; system NumPy `1.26.4` and system OpenCV `4.9.0`. A separate earlier synthetic image-pair test also returned valid ORB/SE(2) pose estimates; it did **not** establish live-camera operation.

## 7. Troubleshooting and limits

| Symptom | Explanation / response |
| --- | --- |
| `python3 -m pip` missing on Pollux | Expected on the tested minimal image. Do the cross-platform pip staging on **Ubuntu** and transfer archives. |
| `ModuleNotFoundError: getpass` from pip wheel | Minimal target stdlib lacks `getpass`; using pip directly on the board was abandoned. |
| `ModuleNotFoundError: zoneinfo` when importing pandas | Copy matching Yocto `python3-zoneinfo` + `python3-unixadmin` files into isolated `bootstrap/` and put it first on `PYTHONPATH`. |
| pip tries to download `nvidia-cudnn-cu12` | Do **not** install CUDA on i.MX8MP. Use the explicit `--no-deps` ARM64 neural wheel list above. |
| `bitbake` fails at `/proc/self/uid_map` | Ubuntu 24.04 AppArmor restriction can block unprivileged user namespaces. Confirm via `sysctl kernel.apparmor_restrict_unprivileged_userns` and `unshare --user --map-root-user true`. Only if essential for the build, temporarily relax this **host-wide security setting**, then restore its original value immediately, even on failure. Do not leave it disabled. |
| `build/tmp/deploy/rpm` missing | This PHYTEC distro uses `build/deploy-ampliphy-vendor-xwayland/rpm`; get the exact value with `bitbake -e python3-pip | grep '^DEPLOY_DIR_RPM='`. |
| `rpm -qa` empty on board | It was empty on the tested image even though Python/GTK packages worked. Do not force-install RPMs just to make pip available. |
| `ImportError` for Python native `.so` | Verify `aarch64`, Python `cp312` ABI, glibc, and native shared-library dependencies before replacing anything. |
| Library imports fail in another terminal | Export the full `PYTHONPATH` in that terminal; no global site-packages were changed. |

**Not established by this guide:** live downward-facing camera acquisition, real floor-sequence localization accuracy, pretrained HardNet or HardNet++ checkpoints, NPU acceleration, fresh BSP image containing all runtime libraries, or reproducible PCManFM bundle assembly. Those are separate tasks.

## 8. Preserving the Ubuntu workstation

- `pip download` and `pip install --target /tmp/...` operate on isolated files; there is **no** `sudo pip install`, no host PyTorch replacement, and no CUDA/driver manipulation in this guide.
- The only intentional Ubuntu changes for these steps are new temporary archives/staging files and, if necessary, Yocto build artifacts in the existing BSP workspace.
- The original camera-fingerprint source files were verified byte-for-byte against the untouched `/opt/floor-nav-prototype` copies after reversing prior import-only edits; do not edit them during package deployment.
- The separate `/opt/floor-nav-compat-test` source tree contains minimal **import-only** changes. Its algorithm was not altered. Keep that distinction when reporting test results.

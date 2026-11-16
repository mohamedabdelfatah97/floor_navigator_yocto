# Geany 1.38 on PHYTEC phyBOARD-Pollux (i.MX8MP)

> **Status:** Built with Yocto, installed on the physical Pollux, and verified for editing, saving, and opening `.txt` files from PCManFM.
>
> **Deployment:** Tested as a manually installed RPM with a Weston launcher; not yet included in a verified fresh image build.

## Overview

This guide covers installing Geany 1.38 as a lightweight GTK3 code/text editor. Geany uses the native Wayland GTK backend in its tested launcher. The PCManFM file manager can open supported text/code files through the separately configured system MIME defaults.

## Tested environment

| Component | Tested configuration |
| --- | --- |
| Board / machine | PHYTEC phyBOARD-Pollux i.MX8MP / `phyboard-pollux-imx8mp-3` |
| BSP | `BSP-Yocto-NXP-i.MX8MP-PD24.1.0` |
| Distribution | `ampliphy-vendor-xwayland` |
| Architecture | AArch64 / Cortex-A53 |
| Application | Geany 1.38 |
| Graphical session | Weston / GTK3 native Wayland |
| Executable | `/usr/bin/geany` |
| Panel launcher | `/usr/local/bin/floor-geany` |

## Prerequisites

- An initialized PHYTEC Yocto workspace with `meta-oe` enabled and the matching Geany recipe.
- Access to the generated AArch64 RPM (or the ability to run `bitbake geany`).
- SSH access to the matching Pollux board, with Weston running as the `weston` user.
- This repository's [`board/pollux/floor-geany`](../board/pollux/floor-geany) launcher.

**Note:** The original board's RPM database was initially empty, even though much of the required GTK3 runtime was installed. The special installation flags below were used only after inspecting the RPM scripts and verifying architecture compatibility.

## Installation

### Step 1 — Build Geany on the Ubuntu host

From the established workspace:

```bash
WS="$HOME/floor_navigator_yocto"
cd "$WS"
source buildtools/environment-setup-x86_64-pokysdk-linux
source sources/poky/oe-init-build-env build
bitbake geany
```

The original BSP setup also used PHYTEC's `TEMPLATECONF=../meta-phytec/conf/templates/default` on first initialization. Follow PHYTEC's instructions if creating a new build from scratch; do not replace an already working `build/conf` directory.

### Step 2 — Locate and transfer the RPM

The tested package was `geany-1.38-r0.cortexa53_crypto.rpm` in the Yocto RPM deploy directory:

```bash
REPO="$HOME/floor_navigator_yocto/github/floor_navigator_yocto"
WS="$HOME/floor_navigator_yocto"
BOARD=root@172.16.0.193  # Replace if the board address changes

RPM="$WS/build/deploy-ampliphy-vendor-xwayland/rpm/cortexa53_crypto/geany-1.38-r0.cortexa53_crypto.rpm"
ls -lh "$RPM"
scp "$RPM" "$BOARD:/tmp/"
```

Check the actual generated RPM name if your build has a different package revision or architecture suffix.

### Step 3 — Install the RPM on the matching board

On the **tested** image, installation succeeded with:

```bash
ssh "$BOARD" 'rpm -Uvh --nodeps --ignorearch --noscripts \
  /tmp/geany-1.38-r0.cortexa53_crypto.rpm && \
  /sbin/ldconfig && rpm -q geany'
```

`--nodeps`, `--ignorearch`, and `--noscripts` bypass important package checks. **Do not copy this command to an unknown image without checking compatibility, scripts, and dependencies first.** The executable was verified as ELF64 AArch64. Post-install scripts were skipped because `update-desktop-database` was missing.

### Step 4 — Install the Weston launcher

Copy the repository launcher to the board:

```bash
cd "$REPO"
scp board/pollux/floor-geany "$BOARD:/tmp/floor-geany"

ssh "$BOARD" 'sh -s' <<'BOARD'
set -eu
CFG=/etc/xdg/weston/weston.ini
LAUNCHER=/usr/local/bin/floor-geany

install -m 755 /tmp/floor-geany "$LAUNCHER"
[ -e "$CFG.before-floor-geany" ] || cp -a "$CFG" "$CFG.before-floor-geany"

if ! grep -Fq "path=$LAUNCHER" "$CFG"; then
  printf '\n[launcher]\nicon=/usr/share/icons/hicolor/32x32/apps/geany.png\ndisplayname=Geany\npath=%s\n' \
    "$LAUNCHER" >> "$CFG"
fi
sh -n "$LAUNCHER"
BOARD
```

Restart Weston or reboot the board to load the new panel icon. This launcher runs Geany with Wayland settings and changes to `/home/weston` so the graphical user can save files there.

### Step 5 — Optional: Open code and text files from PCManFM

The existing `geany.desktop` advertises source/text MIME types. To set defaults **system-wide**, follow the [PCManFM MIME integration guide](pcmanfm-pollux.md), which installs the repository's `board/pollux/mimeapps.list` as `/etc/xdg/mimeapps.list`.

This is a separate integration step, not a requirement for Geany itself to launch.

## Verification

On the board, use the Geany Weston icon and confirm:

1. Geany opens and accepts keyboard input.
2. Text files can be created, edited, and saved in `/home/weston`.
3. The launcher still works after restarting Weston or rebooting.
4. If PCManFM/MIME defaults are installed, double-clicking `/home/weston/geany-test.txt` opens Geany and leaves PCManFM running.

The original test file contained:

```text
Hello from Geany on the Pollux!
```

The `.txt` file-opening test was confirmed end to end. Other text/code MIME defaults have been queried using `gio mime`, but not individually double-click tested.

## Troubleshooting

| Symptom | Cause or finding | Tested remedy / status |
| --- | --- | --- |
| `PermissionError` mentioning `/proc/self/uid_map` during the host build | Ubuntu AppArmor blocked unprivileged user namespaces. | On the original host, AppArmor restriction was temporarily disabled for the build, then restored. See note below. |
| RPM architecture mismatch (`cortexa53_crypto` vs `aarch64`) | The target RPM tool did not use the same architecture label. | Confirmed ELF64 AArch64 and reviewed scripts before using `--ignorearch` on the matching board. |
| `update-desktop-database` not available | Minimal target image lacks desktop-file-utils. | Skipped RPM post-install scripts for the verified manual installation; future Yocto image should package the utility appropriately. |
| GTK cursor-theme warnings | Theme resources are incomplete on the minimal image. | Observed as nonfatal; Geany continued to work. |
| Files do not open automatically from PCManFM | No system MIME default or incomplete application discovery. | Follow [PCManFM's menu and MIME setup](pcmanfm-pollux.md). |

**Host security note:** The original AppArmor workaround was:

```bash
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
bitbake geany
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=1
```

This temporarily relaxes a host security restriction system-wide. Prefer resolving the underlying build/host compatibility issue; if the workaround is necessary, check the original sysctl value and restore it afterward.

## Limitations and security

- The verified manual RPM deployment is specific to the matching image; it does not establish a reproducible clean-image installation.
- Skipping RPM dependency and script checks is not a recommended general installation method.
- PCManFM associations do not imply that every source-file MIME type has been tested.

## Related documentation

- [PCManFM installation, menu cache, and MIME defaults](pcmanfm-pollux.md)
- [Workspace setup and layout](workspace-layout.md)
- [Chromium installation guide](chromium-pollux.md)

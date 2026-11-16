# PCManFM 1.3.2 on PHYTEC phyBOARD-Pollux (i.MX8MP)

> **Status:** Tested on the physical board: Weston launcher, folder browsing, XDG menu generation, and `.txt` → Geany opening work.
>
> **Deployment:** **Partial manual installation guide.** The initial `/opt/floor-pcmanfm` runtime assembly and complete dependency closure are not automated in this repository. The commands below complete and verify an already assembled runtime; they do **not** install PCManFM on a fresh image by themselves.

## Overview

PCManFM runs with GTK3's X11 backend under **Weston + XWayland**. Geany separately uses GTK3's native Wayland backend. The integration includes `menu-cache`, `libfm-extra`, an XDG application menu, system-wide text/code MIME defaults, and a persistent Weston folder icon.

## Tested environment

| Component | Tested configuration |
| --- | --- |
| Board / machine | PHYTEC phyBOARD-Pollux i.MX8MP / `phyboard-pollux-imx8mp-3` |
| BSP / distribution | `PD24.1.0` / `ampliphy-vendor-xwayland` |
| Application | PCManFM 1.3.2 |
| Supporting packages | menu-cache 1.1.0, `libfm-extra` 1.3.2 |
| Graphical session | Weston, XWayland, GTK3 built with X11 support |
| Isolated runtime | `/opt/floor-pcmanfm` |
| Panel launcher | `/usr/local/bin/floor-pcmanfm` |
| Menu definition | `/etc/xdg/menus/lxde-applications.menu` |
| System MIME defaults | `/etc/xdg/mimeapps.list` |

## Prerequisites

- Matching PHYTEC Yocto workspace with this repository's `meta-floor-nav` layer enabled.
- A **previously assembled and deployed** runtime containing `/opt/floor-pcmanfm/usr/bin/pcmanfm` and its supporting GTK3/libfm resources. The original assembled bundle is not distributed by this Git repository.
- Build artifacts for `pcmanfm`, `menu-cache`, and `libfm-extra` from the matching target build.
- SSH access to the Pollux Weston image. The commands use `root@172.16.0.193` as the example address.

The tested runtime also used these resource links when the target paths did not already exist:

```text
/usr/share/pcmanfm -> /opt/floor-pcmanfm/usr/share/pcmanfm
/usr/share/libfm   -> /opt/floor-pcmanfm/usr/share/libfm
```

## Installation

### Step 1 — Build the target packages

The repository's [`gtk+3_%.bbappend`](../meta-floor-nav/recipes-gnome/gtk+/gtk+3_%.bbappend) enables GTK3's X11 backend while preserving the existing Wayland backend.

```bash
WS="$HOME/floor_navigator_yocto"
cd "$WS"
source buildtools/environment-setup-x86_64-pokysdk-linux
source sources/poky/oe-init-build-env build

bitbake pcmanfm menu-cache libfm-extra
```

Building these recipes does **not** place the runtime on the existing board. The original PCManFM executable, libraries, and supporting resources were assembled manually into `/opt/floor-pcmanfm/usr/`; the full packaging/deployment procedure has not yet been captured as a reproducible script.

### Step 2 — Confirm the previously deployed runtime

```bash
BOARD=root@172.16.0.193  # Replace if needed
ssh "$BOARD" 'test -x /opt/floor-pcmanfm/usr/bin/pcmanfm && \
  ls -l /opt/floor-pcmanfm/usr/bin/pcmanfm'
```

**If this check fails, stop here.** Do not run the later steps expecting them to create the missing runtime. Packaging PCManFM and its full runtime dependencies into Yocto is future work.

### Step 3 — Install the missing menu-cache executables and libfm-extra

The original crash was caused by absent `menu-cached`/`menu-cache-gen` executables. A subsequent menu-generation test exposed a missing `libfm-extra.so.4`. These were recovered from the existing Yocto `packages-split` build output:

```bash
WS="$HOME/floor_navigator_yocto"
BOARD=root@172.16.0.193
PKG="$WS/build/tmp-ampliphy-vendor-xwayland/work/cortexa53-crypto-phytec-linux"
MC="$PKG/menu-cache/1.1.0/packages-split/menu-cache/usr/libexec/menu-cache"
FM="$PKG/libfm-extra/1.3.2/packages-split/libfm-extra/usr/lib/libfm-extra.so.4"

ls -l "$MC/menu-cached" "$MC/menu-cache-gen" "$FM"
scp "$MC/menu-cached" "$MC/menu-cache-gen" "$FM" "$BOARD:/tmp/"

ssh "$BOARD" 'sh -s' <<'BOARD'
set -eu
install -d -m 755 /usr/libexec/menu-cache /opt/floor-pcmanfm/usr/lib
install -m 755 /tmp/menu-cached /usr/libexec/menu-cache/menu-cached
install -m 755 /tmp/menu-cache-gen /usr/libexec/menu-cache/menu-cache-gen
install -m 755 /tmp/libfm-extra.so.4 /opt/floor-pcmanfm/usr/lib/libfm-extra.so.4

for name in pcmanfm libfm; do
  source="/opt/floor-pcmanfm/usr/share/$name"
  target="/usr/share/$name"
  if [ -d "$source" ] && [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ln -s "$source" "$target"
  fi
done
BOARD
```

These commands are a record of a **verified dependency repair**, not a substitute for package-managed deployment. Check the AArch64 architecture and dynamic dependencies when using build artifacts from another workspace.

### Step 4 — Install the launcher, menu, icon, and system MIME defaults

From the Git checkout:

```bash
REPO="$HOME/floor_navigator_yocto/github/floor_navigator_yocto"
BOARD=root@172.16.0.193
cd "$REPO"

scp \
  board/pollux/floor-pcmanfm \
  board/pollux/icons/floor-pcmanfm.png \
  board/pollux/menus/lxde-applications.menu \
  board/pollux/mimeapps.list \
  "$BOARD:/tmp/"

ssh "$BOARD" 'sh -s' <<'BOARD'
set -eu
CFG=/etc/xdg/weston/weston.ini
LAUNCHER=/usr/local/bin/floor-pcmanfm
ICON=/usr/local/share/floor-nav/icons/floor-pcmanfm.png

[ -e "$CFG.backup-before-pcmanfm" ] || cp -a "$CFG" "$CFG.backup-before-pcmanfm"
[ ! -f /etc/xdg/mimeapps.list ] || [ -e /etc/xdg/mimeapps.list.pre-floor-nav ] || \
  cp -a /etc/xdg/mimeapps.list /etc/xdg/mimeapps.list.pre-floor-nav

install -d -m 755 /usr/local/bin /usr/local/share/floor-nav/icons /etc/xdg/menus
install -m 755 /tmp/floor-pcmanfm "$LAUNCHER"
install -m 644 /tmp/floor-pcmanfm.png "$ICON"
install -m 644 /tmp/lxde-applications.menu /etc/xdg/menus/lxde-applications.menu
install -m 644 /tmp/mimeapps.list /etc/xdg/mimeapps.list
install -d -o weston -g weston -m 755 /home/weston/Templates

if ! grep -Fq "path=$LAUNCHER" "$CFG"; then
  printf '\n[launcher]\nicon=%s\ndisplayname=PCManFM\npath=%s\n' \
    "$ICON" "$LAUNCHER" >> "$CFG"
fi
sh -n "$LAUNCHER"
BOARD
```

This is a **system-wide** MIME configuration. It associates common text and source-code types with the existing `geany.desktop`, not with individual filenames. Other applications can be registered through their `.desktop` entries and MIME defaults in future. Back up and merge existing MIME defaults rather than overwriting a customized system configuration without review.

### Step 5 — Restart the graphical session

Restart Weston or reboot the board after changing its `[launcher]` entries. The icon may look larger than the other panel icons; resizing was deferred in the original setup. Do not replace the entire board's `weston.ini` with `board/pollux/weston.ini.reference` without comparing hardware-specific settings.

## Verification

First, check menu generation with the **unprefixed** menu name:

```bash
ssh root@172.16.0.193 'sh -s' <<'BOARD'
set -eu
export HOME=/home/weston
export LD_LIBRARY_PATH=/opt/floor-pcmanfm/usr/lib
export XDG_DATA_DIRS=/opt/floor-pcmanfm/usr/share:/usr/local/share:/usr/share
export XDG_CONFIG_DIRS=/opt/floor-pcmanfm/etc/xdg:/etc/xdg
export XDG_MENU_PREFIX=lxde-
export XDG_CURRENT_DESKTOP=LXDE

/usr/libexec/menu-cache/menu-cache-gen \
  -v -i applications.menu -o /tmp/floor-menu-test.cache
grep -i geany /tmp/floor-menu-test.cache
gio mime text/plain
BOARD
```

With `XDG_MENU_PREFIX=lxde-`, `-i applications.menu` locates `lxde-applications.menu`. Using `-i lxde-applications.menu` incorrectly searches for `lxde-lxde-applications.menu`.

Then test on the Pollux display:

1. Open PCManFM from its permanent Weston folder icon.
2. Browse directories without a crash.
3. Double-click `/home/weston/geany-test.txt`. Geany should open and PCManFM should stay open.
4. Confirm the result persists after restarting Weston or rebooting.

The tested menu generator produced a cache containing `geany.desktop` and `geany %F`. GIO reported Geany as the default for `text/plain`, `text/x-python`, `application/json`, `text/x-c++src`, `text/x-shellscript`, and `text/markdown`; only the `.txt` double-click test was confirmed end to end.

Inspect the launcher log if a graphical step fails:

```bash
ssh root@172.16.0.193 'tail -n 80 /home/weston/pcmanfm-launch.log'
```

## Troubleshooting

| Symptom | Cause or finding | Tested remedy / status |
| --- | --- | --- |
| PCManFM exits with code `133` when opening a file | `Menu-Cache-ERROR: failed to find menu-cached`. | Install both matching `menu-cached` and `menu-cache-gen` executables. |
| `menu-cache-gen` cannot load `libfm-extra.so.4` | Runtime dependency absent from isolated library path. | Install matching `libfm-extra.so.4` under `/opt/floor-pcmanfm/usr/lib` and export `LD_LIBRARY_PATH`. |
| Menu generator looks for `lxde-lxde-applications.menu` | `XDG_MENU_PREFIX=lxde-` was applied twice. | Pass `-i applications.menu`. |
| Installed Applications chooser is empty | XDG menu was missing even though `geany.desktop` existed. | Install `lxde-applications.menu` and set the XDG environment in the launcher. |
| File opens Choose Application instead of Geany | No system-wide default exists for the MIME type. | Install `board/pollux/mimeapps.list` as `/etc/xdg/mimeapps.list`, and verify with `gio mime`. |
| GTK theme / SVG pixbuf / modules warnings | Minimal GTK/icon modules and loaders are incomplete. | Nonfatal on the tested board; not yet fully resolved. |

Nonfatal log messages include `modules directory is not accessible`, deprecated `GtkWidget:focus-padding` / `GtkWidget:focus-line-width`, and a missing Adwaita SVG pixbuf loader.

## Limitations and security

- A full **fresh-board PCManFM installer** and a reproducible image recipe are not yet available.
- The isolated runtime and selected library fixes were deployed manually; dependencies must be packaged properly before production use.
- Image/video/PDF viewers, thumbnails, additional MIME handlers, and video decoding are not yet integrated. `feh`, `mpv`, and `desktop-file-utils` recipes exist in the BSP source tree but were not built or validated as applications on the board.
- GStreamer `playbin` and `waylandsink` were detected; this alone does not prove successful video playback.
- Remaining GTK/icon warnings and the panel icon sizing are pending cleanup.

## Related documentation

- [Geany build and installation](geany-pollux.md)
- [Chromium build and installation](chromium-pollux.md)
- [Workspace setup and layout](workspace-layout.md)

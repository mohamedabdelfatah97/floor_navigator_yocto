# PCManFM 1.3.2 — PHYTEC Pollux i.MX8MP

## Scope and tested state (16 November 2026)

PCManFM 1.3.2 was built using the PHYTEC Yocto environment and deployed as an isolated runtime to the physical board. It runs through **Weston + XWayland**, whereas Geany runs natively using GTK3/Wayland in the separately tested launcher.

**Verified on the physical board:** PCManFM starts from its permanent Weston folder icon after reboot; directories can be browsed; opening `/home/weston/geany-test.txt` launches Geany without closing PCManFM. The installed-applications menu generator recognizes Geany. The initial file-opening crash was fixed.

**Not yet verified:** a fresh image containing all of these pieces; other code-type double-click behaviors; image/video/PDF handlers, thumbnails, or cleanup of all GTK warnings.

| Component | Version or location |
| --- | --- |
| Board | PHYTEC phyBOARD-Pollux i.MX8MP (`phyboard-pollux-imx8mp-3`) |
| BSP / distro | PD24.1.0 / `ampliphy-vendor-xwayland` |
| File manager | PCManFM 1.3.2 |
| Menu cache | menu-cache 1.1.0 |
| `libfm-extra` | 1.3.2 |
| Graphical environment | Weston, XWayland, GTK3 with X11 support |
| Isolated runtime | `/opt/floor-pcmanfm` |
| Weston launcher | `/usr/local/bin/floor-pcmanfm` |
| Menu definition | `/etc/xdg/menus/lxde-applications.menu` |
| System MIME defaults | `/etc/xdg/mimeapps.list` |

## 1. Build and runtime arrangement

In the matching configured PHYTEC Yocto build environment, `bitbake pcmanfm` was run. The `meta-floor-nav/recipes-gnome/gtk+/gtk+3_%.bbappend` adds X11 to GTK3's `PACKAGECONFIG`; Wayland continues to serve other applications. The isolated runtime contains the PCManFM binary and its supporting libraries/resources (under `/opt/floor-pcmanfm/usr/`).

The *original PCManFM runtime assembly and all of its dependency closure are not automated in this repository*. Previously assembled bundles exist only in ignored local artifacts. **Do not assume the following steps alone install PCManFM on a fresh board**; they document and validate the subsequent fixes on the tested board.

Selected paths on the board:

```text
/opt/floor-pcmanfm/usr/bin/pcmanfm
/opt/floor-pcmanfm/usr/lib/libmenu-cache.so.3
/opt/floor-pcmanfm/usr/lib/libfm-extra.so.4
/usr/libexec/menu-cache/menu-cached
/usr/libexec/menu-cache/menu-cache-gen
/usr/local/bin/floor-pcmanfm
/usr/local/share/floor-nav/icons/floor-pcmanfm.png
/etc/xdg/menus/lxde-applications.menu
/etc/xdg/mimeapps.list
```

For the isolated installation, resource links were also created when the target paths did not already exist:

```text
/usr/share/pcmanfm -> /opt/floor-pcmanfm/usr/share/pcmanfm
/usr/share/libfm   -> /opt/floor-pcmanfm/usr/share/libfm
```

These are board-side changes, not a claim that the custom layer already installs them.

## 2. Why opening files initially crashed

Initially, directory navigation worked but opening a source/text file terminated PCManFM. The launcher log contained:

```text
Menu-Cache-ERROR **: failed to find menu-cached
=== PCManFM exited with code 133 ===
```

The `menu-cached` and `menu-cache-gen` ARM64 executables were already available in the Yocto `packages-split` output for `menu-cache/1.1.0`, but missing from the board. They were installed under `/usr/libexec/menu-cache/`. A later standalone `menu-cache-gen` diagnostic failed because `libfm-extra.so.4` was also absent. The matching ARM64 `libfm-extra.so.4` from `libfm-extra/1.3.2/packages-split` was added to `/opt/floor-pcmanfm/usr/lib`.

A reproducible deployment should install the appropriate Yocto runtime packages and dependencies rather than copying hand-picked ELF files without checking the full dependency closure.

### Diagnostic commands (existing build workspace)

On the Ubuntu host:

```bash
WS="$HOME/floor_navigator_yocto"
find "$WS/build/tmp-ampliphy-vendor-xwayland/work/cortexa53-crypto-phytec-linux"   -path '*/packages-split/*/usr/libexec/menu-cache/menu-cached' -o   -path '*/packages-split/*/usr/lib/libfm-extra.so.4'
```

On the board:

```sh
ls -l /usr/libexec/menu-cache/menu-cached       /usr/libexec/menu-cache/menu-cache-gen       /opt/floor-pcmanfm/usr/lib/libfm-extra.so.4
```

## 3. Application discovery (XDG menu)

The application chooser originally showed an empty *Installed Applications* list although `/usr/share/applications/geany.desktop` existed. The repository now includes:

```text
board/pollux/menus/lxde-applications.menu
board/pollux/floor-pcmanfm
```

The installed menu is `/etc/xdg/menus/lxde-applications.menu`. The PCManFM launcher exports:

```sh
export XDG_MENU_PREFIX=lxde-
export XDG_CURRENT_DESKTOP=LXDE
export XDG_DATA_DIRS=/opt/floor-pcmanfm/usr/share:/usr/local/share:/usr/share
export XDG_CONFIG_DIRS=/opt/floor-pcmanfm/etc/xdg:/etc/xdg
export LD_LIBRARY_PATH=/opt/floor-pcmanfm/usr/lib
```

The generator was verified to create a ~1.1 KB cache containing `geany.desktop` and `geany %F`:

```sh
export HOME=/home/weston
export LD_LIBRARY_PATH=/opt/floor-pcmanfm/usr/lib
export XDG_DATA_DIRS=/opt/floor-pcmanfm/usr/share:/usr/local/share:/usr/share
export XDG_CONFIG_DIRS=/opt/floor-pcmanfm/etc/xdg:/etc/xdg
export XDG_MENU_PREFIX=lxde-
export XDG_CURRENT_DESKTOP=LXDE
/usr/libexec/menu-cache/menu-cache-gen     -v -i applications.menu -o /tmp/floor-menu-test.cache
grep -i geany /tmp/floor-menu-test.cache
```

**Important:** With `XDG_MENU_PREFIX=lxde-`, `-i applications.menu` resolves `lxde-applications.menu`. Passing `-i lxde-applications.menu` causes the incorrect lookup `lxde-lxde-applications.menu`.

## 4. System-wide MIME defaults

`gio info` reported `text/plain` for `geany-test.txt`, but `gio mime` initially found no default application. The repository's `board/pollux/mimeapps.list` was installed as `/etc/xdg/mimeapps.list`, setting Geany defaults/added associations for common text and source-code MIME types.

A follow-up `gio mime` check returned `geany.desktop` as the default for `text/plain`, `text/x-python`, `application/json`, `text/x-c++src`, `text/x-shellscript`, and `text/markdown`. Double-clicking the `.txt` test file in PCManFM then successfully opened Geany; both applications remained open.

This is a **system-wide default**, not a hard-coded per-file command. Individual users can still override MIME defaults in their own configuration. Not every file extension has been tested; recognition depends on the shared MIME database.

## 5. Weston launcher

The verified PCManFM launcher is tracked at `board/pollux/floor-pcmanfm`, installed on the board as `/usr/local/bin/floor-pcmanfm` (mode 755). It sets the `weston` user's session paths, `DISPLAY=:0`, `GDK_BACKEND=x11` and the isolated library/data paths. It starts PCManFM with `--no-desktop --new-win /home/weston` and appends diagnostic output to `/home/weston/pcmanfm-launch.log`.

The generated 64×64 folder icon is stored at `board/pollux/icons/floor-pcmanfm.png` and installed at `/usr/local/share/floor-nav/icons/floor-pcmanfm.png`.

Weston's `/etc/xdg/weston/weston.ini` contains:

```ini
[launcher]
icon=/usr/local/share/floor-nav/icons/floor-pcmanfm.png
displayname=PCManFM
path=/usr/local/bin/floor-pcmanfm
```

The icon was verified after reboot. The icon appears somewhat large; resizing is optional and was not performed. Do not overwrite the entire board Weston configuration with the repository's `weston.ini.reference` without checking board-specific sections.

## 6. Remaining warnings and future work

Nonfatal messages observed in the launcher log include:

```text
modules directory is not accessible
Gtk-WARNING: GtkWidget:focus-padding is deprecated
Gtk-WARNING: GtkWidget:focus-line-width is deprecated
Could not load a pixbuf from .../bullet-symbolic.svg
```

These are **not yet resolved**. The missing `/home/weston/Templates` directory was created on the tested board. Image/video viewers, media codecs, thumbnailers and PDF/HTML associations are also pending.

Candidate Yocto recipes in the configured BSP include `feh_3.10.2.bb`, `mpv_0.35.1.bb` and `desktop-file-utils_0.27.bb`; their presence in the source tree does not mean those applications are installed or validated on the board. GStreamer `playbin` and `waylandsink` were detected, but actual video playback/decoding has not been tested.

## 7. Reproducibility checklist

Before declaring a fresh image equivalent to the tested board:

- Package PCManFM and **all** runtime dependencies through Yocto, including menu-cache, libfm-extra, GTK modules and required icon loaders.
- Install the resources and system MIME/menu configuration as part of the image.
- Add appropriate desktop entries for viewers and test their execution in the Weston user session.
- Re-test PCManFM browsing, Geany file opening, menu population and the Weston icon after reboot.
- Verify additional file types, video codecs and thumbnails separately.

This document records the *tested manual integration*; it does not claim an automated fresh-image installer is already available.

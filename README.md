# Floor Navigator — Yocto & Embedded Linux

Embedded Linux software and desktop integration for the **PHYTEC phyBOARD-Pollux i.MX8MP** running the PHYTEC **PD24.1.0** Yocto BSP.

This repository contains a custom Yocto layer, board-side launcher/configuration files, deployment helpers, and notes from tests on the physical board. It is **not** a complete BSP checkout or a ready-to-flash image.

## Tested platform

| Item | Configuration |
| --- | --- |
| Board / machine | PHYTEC phyBOARD-Pollux i.MX8MP / `phyboard-pollux-imx8mp-3` |
| BSP | `BSP-Yocto-NXP-i.MX8MP-PD24.1.0` |
| Distribution | `ampliphy-vendor-xwayland` |
| Architecture | AArch64 |
| Desktop | Weston / Wayland with XWayland |
| Board session | `weston` user (`/home/weston`) |

## Applications and verified status

| Application | Status on physical Pollux | Integration |
| --- | --- | --- |
| Chromium 117.0.5938.132 | GPU acceleration, sandbox and Weston launcher tested | Yocto bbappend + separately deployed runtime bundle |
| Geany 1.38 | Editing, saving, Weston launcher and opening a `.txt` file from PCManFM tested | Yocto-built RPM + manual deployment |
| PCManFM 1.3.2 | File browsing, Weston launcher, menu-cache discovery and `.txt` → Geany tested | Isolated `/opt/floor-pcmanfm` runtime + manual dependencies/configuration |
| Image/video/PDF handlers | Not yet configured or validated through PCManFM | Future work |

PCManFM's system-wide `/etc/xdg/mimeapps.list` currently establishes Geany defaults for several text/code MIME types. Only the `.txt` double-click behavior has been explicitly tested end to end; other associations were queried using `gio mime`.

**Reproducibility boundary:** These applications work on the tested board, but the complete desktop stack is **not yet packaged into a clean, reproducible Yocto image**. In particular, runtime files such as `menu-cached`, `menu-cache-gen`, `libfm-extra.so.4`, launchers and MIME/menu configuration were deployed manually. Avoid assuming `bitbake` of the image alone will reproduce the board.

## Repository layout

```text
board/pollux/       Weston launcher scripts, desktop menu, icon, MIME defaults, configuration reference
docs/               Chromium, Geany, PCManFM and workspace documentation
meta-floor-nav/     BSP-specific Yocto recipe append files and patches
scripts/            Chromium bundle packaging and deployment helpers
```

The *local development workspace* is kept outside Git tracking: `~/floor_navigator_yocto/build`, `sources`, and `buildtools`, with this repository at `~/floor_navigator_yocto/github/floor_navigator_yocto`. Local `local/` and `releases/` directories inside the Git checkout are ignored. See [workspace layout](docs/workspace-layout.md).

## Documentation

Start with the [documentation index](docs/README.md) for installation guides, verification, and reference material.

- [Chromium build, installation and troubleshooting](docs/chromium-pollux.md)
- [Chromium release notes](docs/chromium-release-notes.md) and [source provenance](docs/chromium-source-provenance.md)
- [Geany 1.38 build and installation](docs/geany-pollux.md)
- [PCManFM, menu-cache and system-wide MIME integration](docs/pcmanfm-pollux.md)
- [Yocto workspace and repository layout](docs/workspace-layout.md)
- [Build versions and upstream layer revisions](docs/build-versions.txt)

## Next steps

1. Create verified Yocto recipes/package integration for the manually installed PCManFM runtime, desktop entries, menu-cache dependencies and system-wide configuration.
2. Add and validate image, video, PDF and HTML viewers/handlers (and thumbnails where feasible).
3. Clean up remaining nonfatal GTK/icon warnings and consider a smaller Weston panel icon.
4. Verify a clean image build and deployment on a separate test image before declaring end-to-end reproducibility.

## Security and redistribution

**Chromium 117 is obsolete.** Do not use it for sensitive or untrusted browsing; the working Chromium sandbox does not replace security updates. Board-specific prebuilt binaries require an appropriate third-party licensing and source-availability review before public release. Do not commit BSP downloads, build outputs, passwords, SSH keys, local RPMs or deployment archives.

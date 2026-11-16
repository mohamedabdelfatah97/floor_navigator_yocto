# Yocto workspace setup — Floor Navigator

> **Status:** Local workspace layout verified; the configured BitBake build recognizes the relocated `meta-floor-nav` layer.

## Overview

The project has one parent directory for the PHYTEC BSP, Yocto build output, and Git repository. The large existing build was left in place to preserve paths embedded in Yocto artifacts. Paths below describe the development host, not a portable requirement for other machines.

## Workspace layout

```text
~/floor_navigator_yocto/
├── build/                          # Existing PHYTEC BitBake build (not in Git)
├── buildtools/                     # BSP/Yocto host tools
├── sources/                        # Poky, PHYTEC, upstream OpenEmbedded layers
├── tools/                          # BSP utilities
├── .repo/                          # BSP repo manifest metadata
└── github/
    └── floor_navigator_yocto/      # Git checkout
        ├── board/                  # Weston launchers, MIME/menu configuration
        ├── docs/                   # Guides and provenance
        ├── meta-floor-nav/         # Custom Yocto layer
        ├── scripts/                # Build/deployment helpers
        ├── local/                  # Ignored logs, backups, local runtime bundles
        └── releases/               # Ignored generated release archives
```

The checkout previously lived at `~/projects/floor_navigator_yocto`. After relocation, the corresponding `meta-floor-nav` entry in `build/conf/bblayers.conf` was updated. `OEROOT`, `TMPDIR`, and the large BSP build were **not** moved.

## Prerequisites

- A configured, matching PHYTEC Yocto BSP and build-tools environment.
- A Git checkout at the path shown above, or updated layer references if using a different path.
- Enough available disk space for the existing BSP build and downloads.

## Setup and daily use

### Open the Git checkout

```bash
cd ~/floor_navigator_yocto/github/floor_navigator_yocto
git status -sb
```

### Enter the existing Yocto build environment

```bash
cd ~/floor_navigator_yocto
source buildtools/environment-setup-x86_64-pokysdk-linux
source sources/poky/oe-init-build-env build
```

### Check the custom layer

```bash
bitbake-layers show-layers | grep meta-floor-nav
```

The verified layer entry resolves to:

```text
~/floor_navigator_yocto/github/floor_navigator_yocto/meta-floor-nav
```

When preparing a *new* BSP workspace, follow PHYTEC's initialization instructions and add the layer only if it isn't already present:

```bash
bitbake-layers add-layer \
  "$HOME/floor_navigator_yocto/github/floor_navigator_yocto/meta-floor-nav"
```

## Verification

Check that `git status -sb` works in the repository and `bitbake-layers show-layers` resolves `meta-floor-nav` at its current location. These checks establish a valid checkout and layer configuration, not a fully reproducible board image.

## Troubleshooting

| Symptom | Likely cause | Action |
| --- | --- | --- |
| Missing `meta-floor-nav` after moving the checkout | Old absolute path remains in `bblayers.conf`. | Review and correct only the affected layer entry; keep a backup of the original config. |
| `bitbake-layers` command unavailable | Yocto build environment not initialized. | Source the host buildtools environment and `oe-init-build-env` from the BSP workspace. |
| Git status shows huge archives or build files | Build output accidentally copied into the checkout. | Keep build products under ignored `local/`, `releases/`, or the existing BSP build tree. |

## Limitations and safety

- Do not casually move the existing `build/` or `sources/` trees: generated build files can embed absolute paths.
- Keep the BSP checkout and local binary artifacts out of Git; inspect license obligations before publishing third-party binaries.
- Never commit passwords, SSH keys, secrets, vendor-restricted files, or large build products.
- Avoid running a second BitBake build while the first is active.
- Organizing the workspace does not automatically make the target image reproducible.

## Related documentation

- [Documentation index](README.md)
- [Chromium installation](chromium-pollux.md)
- [Geany installation](geany-pollux.md)
- [PCManFM integration](pcmanfm-pollux.md)

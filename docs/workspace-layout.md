# Floor Navigator Yocto workspace layout

The developer's working environment was consolidated on 16 November 2026 without moving the large Yocto build directory. The paths below describe that local workspace; they are **examples**, not portable build requirements.

```text
~/floor_navigator_yocto/
├── build/                          # Existing PHYTEC BitBake build; not tracked by Git
├── buildtools/                     # BSP/Yocto host tools
├── sources/                        # Poky, PHYTEC and upstream OE layers
├── tools/                          # BSP tools
├── .repo/                          # BSP repo manifest metadata
└── github/
    └── floor_navigator_yocto/      # This Git checkout
        ├── board/
        ├── docs/
        ├── meta-floor-nav/
        ├── scripts/
        ├── local/                  # Ignored local logs/backups/runtime bundles
        └── releases/               # Ignored generated release archives
```

Previously the Git checkout was under `~/projects/floor_navigator_yocto`. It was moved to `~/floor_navigator_yocto/github/floor_navigator_yocto`; the only known necessary BitBake configuration change was updating the `meta-floor-nav` entry in `build/conf/bblayers.conf`. `OEROOT` and `TMPDIR` were not relocated.

After the move, `bitbake-layers show-layers` confirmed:

```text
meta-floor-nav  ~/floor_navigator_yocto/github/floor_navigator_yocto/meta-floor-nav
```

## Using the workspace

```bash
# Work on the Git repository:
cd ~/floor_navigator_yocto/github/floor_navigator_yocto
git status -sb

# Enter the existing BSP build environment:
cd ~/floor_navigator_yocto
source sources/poky/oe-init-build-env build
bitbake-layers show-layers
```

If required in a fresh shell, first initialize the PHYTEC buildtools environment per the BSP documentation. The existing build configuration identifies the target machine and distro.

## Rules for future work

- Keep the **large existing `build/` and `sources/` trees in place**. Yocto build artifacts can embed absolute paths; moving them is not equivalent to relocating the Git checkout.
- Keep board configuration files and source patches under this Git repository; do not commit the entire BSP checkout.
- Keep local logs, tarballs, RPMs and backups under ignored `local/` or `releases/`; publishing third-party binaries requires a separate license review.
- Don't add passwords, SSH private keys, credentials or vendor-restricted files to Git.
- Validate with `bitbake-layers show-layers` after changing any layer path.
- The workspace being consolidated does **not** by itself mean the board image is reproducible from this one repository.

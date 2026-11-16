# Chromium 117 on PHYTEC phyBOARD-Pollux (i.MX8MP)

> **Status:** Built and tested on physical hardware with GPU acceleration, an enabled Chromium sandbox, and a Weston launcher.
>
> **Security:** Chromium 117 is obsolete. Do not use this build for sensitive accounts or untrusted browsing.
>
> **Distribution:** The precompiled archive is **not published as a GitHub Release**. Installation from an existing local bundle is possible on the matching board/BSP; public release instructions are conditional on publication and licensing review.

## Overview

This guide covers building, installing, launching, and troubleshooting Chromium 117.0.5938.132 on the tested Pollux Yocto image. The deployment is an isolated `/opt/floor-chromium` runtime, not a new flash image. Other ARM64 devices and different BSP versions are not automatically compatible.

## Tested environment

| Component | Tested configuration |
| --- | --- |
| Board / machine | PHYTEC phyBOARD-Pollux i.MX8MP / `phyboard-pollux-imx8mp-3` |
| BSP | `BSP-Yocto-NXP-i.MX8MP-PD24.1.0` |
| Distribution | `ampliphy-vendor-xwayland` |
| Architecture | AArch64 |
| Application | `chromium-ozone-wayland` 117.0.5938.132 |
| Graphical session | Weston / Wayland, `weston` user |
| GPU | Vivante GC7000UL / OpenGL ES 3.1 |
| Important GN settings | `use_imxgpu=true`, `ozone_platform_wayland=true`, `enable_validating_command_decoder=true` |
| Launcher options | `--ozone-platform=wayland --use-gl=egl --use-cmd-decoder=validating` |
| Runtime | `/opt/floor-chromium` |
| Panel launcher | `/usr/local/bin/floor-chromium` |

## Prerequisites

- Matching PHYTEC BSP and a booted, SSH-accessible Pollux running Weston.
- Linux host with `ssh`, `scp`, `tar`, and `sha256sum`; `rpm2cpio` and `cpio` are additionally needed to assemble the bundle.
- This Git checkout, which provides `scripts/make-chromium-bundle.sh`, `scripts/install-chromium-pollux.sh`, `scripts/configure-chromium-weston.sh`, and `board/pollux/floor-chromium`.
- Either a previously built bundle or the required Chromium/runtime RPMs from the matching Yocto build.

The original board used `/home/weston`, user ID 1000, and Wayland socket `wayland-1`. Adapt the launcher if your image differs. **The installer refuses to overwrite an existing `/opt/floor-chromium`.**

## Installation

### Option A — Install from a locally generated bundle (available in the tested workspace)

On the Ubuntu host, enter the Git checkout and assemble the archive from matching Yocto RPMs:

```bash
REPO="$HOME/floor_navigator_yocto/github/floor_navigator_yocto"
WS="$HOME/floor_navigator_yocto"
cd "$REPO"

./scripts/make-chromium-bundle.sh "$WS/build"
(cd releases && sha256sum -c pollux-chromium-117-gpu.tar.gz.sha256)
```

The bundle script requires the `chromium-ozone-wayland`, `libcxx`, `nss`, `nspr`, and `libxslt` RPMs to have been generated in the matching build. It creates `releases/pollux-chromium-117-gpu.tar.gz` and a SHA-256 file. If the RPMs are missing, use the source-build procedure below first.

Stage the bundle, installer, and Weston launcher together. Replace the example address if your board IP changes:

```bash
BOARD=root@172.16.0.193
ssh "$BOARD" 'mkdir -p /opt/floor-nav-setup'

scp \
  releases/pollux-chromium-117-gpu.tar.gz \
  scripts/install-chromium-pollux.sh \
  scripts/configure-chromium-weston.sh \
  board/pollux/floor-chromium \
  "$BOARD:/opt/floor-nav-setup/"
```

Run the two repository scripts on the board:

```bash
ssh "$BOARD" 'sh /opt/floor-nav-setup/install-chromium-pollux.sh \
  /opt/floor-nav-setup/pollux-chromium-117-gpu.tar.gz && \
  sh /opt/floor-nav-setup/configure-chromium-weston.sh \
  /opt/floor-nav-setup/floor-chromium'
```

The installer checks required files and dynamic libraries, installs under `/opt/floor-chromium`, and sets the root-owned `chrome-sandbox` helper to mode `4755`. The Weston configuration script backs up the existing configuration and installs the launcher at `/usr/local/bin/floor-chromium`. **Do not** copy the launcher directly onto the `/opt/floor-chromium` directory.

### Option B — Install from a future GitHub binary Release (not currently available)

Once release `chromium-pollux-117-gpu-v1` and the required redistribution materials are published, download and check its archive:

```bash
mkdir -p releases
gh release download chromium-pollux-117-gpu-v1 \
  --repo mohamedabdelfatah97/floor_navigator_yocto \
  --dir releases \
  --pattern 'pollux-chromium-117-gpu.tar.gz*'

(cd releases && sha256sum -c pollux-chromium-117-gpu.tar.gz.sha256)
```

Then follow the staging and installation commands in Option A. **Do not expect the download to succeed until the release is actually published.**

### Option C — Build Chromium from Yocto source

A complete clean-room build using only this published custom layer has **not yet been verified**. The original Chromium RPM was built and tested in the configured PHYTEC workspace; the Blink patch was validated independently.

Start with the matching PHYTEC BSP and a configured build environment:

```bash
WS="$HOME/floor_navigator_yocto"
REPO="$WS/github/floor_navigator_yocto"
cd "$WS"
source buildtools/environment-setup-x86_64-pokysdk-linux
source sources/poky/oe-init-build-env build

# Check the layer rather than adding it twice if it is already present:
bitbake-layers show-layers | grep meta-floor-nav

bitbake chromium-ozone-wayland
bitbake -c package_write_rpm libcxx nss nspr libxslt

cd "$REPO"
./scripts/make-chromium-bundle.sh "$WS/build"
```

If the layer is missing, add it using `bitbake-layers add-layer "$REPO/meta-floor-nav"` from the initialized build shell before building. On a new BSP checkout, follow PHYTEC's initial configuration instructions first.

The repository's `.bbappend` adds native LLVM dependencies and selects the validating GPU decoder; `fix-blink-eloc-proto.patch` addresses the invalid Blink GN `ELOC_PROTO` mnemonic. See [`build-versions.txt`](build-versions.txt) and [source provenance](chromium-source-provenance.md).

## Verification

On the board, reboot or restart Weston after installing the panel launcher:

```bash
ssh "$BOARD" reboot
```

On the HDMI display, open Chromium from the Weston panel. Check:

1. `chrome://version` — executable path should be `/opt/floor-chromium/usr/lib/chromium/chromium-bin`.
2. `chrome://gpu` — Vivante GC7000UL and accelerated compositing/WebGL should be reported; check for GPU process failures.
3. `chrome://sandbox` — the tested configuration reported **“You are adequately sandboxed”**, including PID/network namespaces and Seccomp-BPF.

Hardware compositing, rasterization, WebGL/WebGL2, and a GPU process crash count of zero were observed during the original validation. This is functional verification, not a security certification or long-duration stability test. Hardware video decoding remains unverified.

## Troubleshooting

| Symptom | Cause or finding | Tested remedy / status |
| --- | --- | --- |
| Native LLVM/Clang failed with missing `<cmath>` | Required `libcxx`/compiler-rt native dependencies were missing; an upstream dependency append used `DEPEND` rather than `DEPENDS`. | Added `DEPENDS:append:runtime-llvm = " compiler-rt-native libcxx-native"` in the custom `.bbappend`. |
| GN error around `ELOC_PROTO` in `third_party/blink/renderer/core/BUILD.gn` | Incompatible Blink GN mnemonic assignment. | Applied `fix-blink-eloc-proto.patch` through the custom layer. |
| Chromium loader cannot find `libc++.so.1`, `libnss3.so`, `libnspr4.so`, or `libxslt.so.1` | The base image lacks matching runtime libraries. | Bundle the target RPM contents and verify with `/lib/ld-linux-aarch64.so.1 --list`. |
| `Passthrough is not supported, GL is egl` GPU crash | Compiled validating command decoder was disabled. | Build with `enable_validating_command_decoder=true` and run `--use-gl=egl --use-cmd-decoder=validating`. |
| Missing local `chromium/libGLESv2.so` | The fallback lookup did not match the board's system EGL/GLES libraries. | The validated GPU decoder configuration avoided the original failure; random GLES library copying was not required. |
| D-Bus/UPower/portal warnings | Optional embedded desktop services are absent or incomplete. | Session bus is exported by the launcher; nonfatal warnings may remain. |
| Browser initially required `--no-sandbox` | Sandbox helper was not root-owned after extraction. | Installer sets `chrome-sandbox` owner to root and mode `4755`; validated without `--no-sandbox`. |
| `scp` cannot overwrite `/opt/floor-chromium` | That path is an installation directory, not a filename. | Copy launcher and scripts to `/opt/floor-nav-setup/` first. |
| Weston panel lacks a Chromium icon | No registered Weston launcher. | Run `configure-chromium-weston.sh` and restart Weston. |
| BusyBox `ps` rejects `-ww` | The board has BusyBox rather than full procps. | Use `ps -o pid,args` on the board. |

## Limitations and security

- Chromium 117 is no longer security-maintained. Its sandbox does not replace browser security updates.
- This runtime depends on the matching BSP, glibc, Vivante GBM/EGL/GLES, and board graphics stack.
- Hardware video decoding has not been established.
- The locally generated bundle does not automatically contain complete third-party license notices. Review source-availability obligations and notices **before** publishing any binary Release.
- A clean reproducible image build and source-only reproduction remain separate future validation tasks.

## Related documentation

- [Chromium release notes](chromium-release-notes.md)
- [Chromium source provenance](chromium-source-provenance.md)
- [Workspace setup and layout](workspace-layout.md)
- [Build versions and upstream layer revisions](build-versions.txt)
- [PHYTEC BSP manual](https://phytec.github.io/doc-bsp-yocto/bsp/imx8/imx8mp/pd24.1.0_nxp.html)

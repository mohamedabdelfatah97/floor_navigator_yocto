# Chromium on PHYTEC phyBOARD-Pollux (i.MX8MP)

> **Status:** Tested on physical hardware with GPU acceleration, a working Chromium sandbox, and a Weston panel launcher. **Chromium 117 is obsolete and must not be treated as a security-maintained browser.**
>
> **Binary download status:** The source layer and installation scripts are on GitHub. The precompiled binary archive has **not yet been published as a GitHub Release**. The release-download steps below will work only **after** the archive, checksum, and required redistribution notices have been published.

## Tested configuration

| Component | Verified configuration |
| --- | --- |
| Board | PHYTEC phyBOARD-Pollux i.MX8MP (`phyboard-pollux-imx8mp-3`) |
| BSP | `BSP-Yocto-NXP-i.MX8MP-PD24.1.0` |
| Distribution | `ampliphy-vendor-xwayland` |
| CPU architecture | AArch64 |
| Browser | `chromium-ozone-wayland` 117.0.5938.132 |
| Desktop | Weston / Wayland (`weston` user) |
| Graphics | Vivante GC7000UL, OpenGL ES 3.1 |
| Crucial GN settings | `use_imxgpu=true`, `ozone_platform_wayland=true`, `enable_validating_command_decoder=true` |
| Runtime flags | `--ozone-platform=wayland --use-gl=egl --use-cmd-decoder=validating` |
| Browser installation | `/opt/floor-chromium` |
| Weston launcher | `/usr/local/bin/floor-chromium` |

Hardware compositing, rasterization, and WebGL/WebGL2 were reported as accelerated in `chrome://gpu`. Chromium's `chrome://sandbox` reported **“You are adequately sandboxed”** with PID/network namespaces and Seccomp-BPF enabled. On the tested board, the GPU process crash count was **0** during validation. This is functional testing, not a long-term stress or security certification. Hardware video decoding was **not** established.

## Quick install from GitHub (after a binary Release is published)

This is intended for **the same compatible Pollux/BSP environment**, not arbitrary ARM64 devices. You need an Ubuntu/Linux host with `git`, `gh` (GitHub CLI), `ssh`, and `scp`; an SSH-accessible Pollux; and a running Weston graphical session on the board. The Pollux user used in the tested launcher is `weston` (UID 1000), and its Wayland socket was `wayland-1`. Adapt the launcher if your image differs.

### 1. Clone the repository on your Linux host

```bash
git clone https://github.com/mohamedabdelfatah97/floor_navigator_yocto.git
cd floor_navigator_yocto
```

If the repository or binary Release is private, authenticate with GitHub first (`gh auth login`).

### 2. Download and verify the release archive

**Not available until release `chromium-pollux-117-gpu-v1` is published.** Do not run this expecting success before then.

```bash
mkdir -p releases
gh release download chromium-pollux-117-gpu-v1 \
  --repo mohamedabdelfatah97/floor_navigator_yocto \
  --dir releases \
  --pattern 'pollux-chromium-117-gpu.tar.gz*'

(cd releases && sha256sum -c pollux-chromium-117-gpu.tar.gz.sha256)
```

The expected files are `pollux-chromium-117-gpu.tar.gz` (approximately 128 MB) and `pollux-chromium-117-gpu.tar.gz.sha256`.

### 3. Transfer the package and installers to the board

Replace the example IP with your board's SSH address. Keep all files in a separate staging folder; **do not copy the launcher named `floor-chromium` directly to `/opt/`**, because `/opt/floor-chromium` is an installation directory.

```bash
BOARD=root@192.168.1.100   # REPLACE with your board's address
ssh "$BOARD" 'mkdir -p /opt/floor-nav-setup'

scp \
  releases/pollux-chromium-117-gpu.tar.gz \
  scripts/install-chromium-pollux.sh \
  scripts/configure-chromium-weston.sh \
  board/pollux/floor-chromium \
  "$BOARD:/opt/floor-nav-setup/"
```

### 4. Install Chromium and the Weston panel icon

```bash
ssh "$BOARD" 'sh -eu -c '\''
  sh /opt/floor-nav-setup/install-chromium-pollux.sh \
     /opt/floor-nav-setup/pollux-chromium-117-gpu.tar.gz
  sh /opt/floor-nav-setup/configure-chromium-weston.sh \
     /opt/floor-nav-setup/floor-chromium
'\'''
```

The installer resolves startup shared libraries, installs into `/opt/floor-chromium`, and configures the root-owned setuid `chrome-sandbox` helper. The launcher setup backs up the existing Weston configuration and adds a Chromium icon without removing the terminal icon.

**Important:** The installer currently **refuses to overwrite** an existing `/opt/floor-chromium`. It is intended for a fresh installation. Back up or manage an existing installation manually rather than forcibly deleting it.

### 5. Restart Weston and verify

Close browser windows and reboot the Pollux when convenient:

```bash
ssh "$BOARD" reboot
```

On its HDMI display, click the Chromium icon in Weston's top panel. In Chromium:

- `chrome://version`: **Executable Path** should be `/opt/floor-chromium/usr/lib/chromium/chromium-bin`.
- `chrome://gpu`: look for **Vivante GC7000UL**, hardware-accelerated compositing and WebGL. Confirm the GPU process is not crashing.
- `chrome://sandbox`: look for **“You are adequately sandboxed.”**

These checks matter: a successful linker test or visible web page alone does not prove hardware acceleration or sandboxing.

## Install using a locally generated bundle (available now)

Until the GitHub Release exists, the tested bundle can be generated from a configured Yocto workspace, or reused from the original development host if you already have it. From your Linux host, with the repository checked out:

```bash
cd /path/to/floor_navigator_yocto   # Git repository
./scripts/make-chromium-bundle.sh /path/to/phytec-yocto-workspace/build
(cd releases && sha256sum -c pollux-chromium-117-gpu.tar.gz.sha256)
```

Then follow **steps 3–5 above**. This package is assembled from the target RPMs `chromium-ozone-wayland`, `libcxx`, `nss`, `nspr`, and `libxslt`. The target image must already supply other core graphics and system libraries. No full image reflash is required for the tested configuration.

## Rebuild Chromium from source (Yocto)

**Source-only reproducibility is not yet fully proven with a clean build.** The Chromium RPM was successfully built and tested on this workstation, and the Blink patch has been validated separately against the extracted source. A complete clean-room rebuild using only the published layer is still a follow-up test.

Start with PHYTEC's matching **PD24.1.0** BSP for `phyboard-pollux-imx8mp-3` and `ampliphy-vendor-xwayland`; follow PHYTEC's BSP setup instructions before using these commands:

```bash
# On the Linux build host. Adjust this to your BSP workspace.
cd /path/to/phytec-yocto-workspace
source buildtools/environment-setup-x86_64-pokysdk-linux
TEMPLATECONF=../meta-phytec/conf/templates/default \
  . sources/poky/oe-init-build-env

# Add this repository's separate layer; adjust to its location.
bitbake-layers add-layer /path/to/floor_navigator_yocto/meta-floor-nav

# Build Chromium, then write the runtime RPMs needed by the bundle script.
bitbake chromium-ozone-wayland
bitbake -c package_write_rpm libcxx nss nspr libxslt

# From the repository root, assemble the archive.
cd /path/to/floor_navigator_yocto
./scripts/make-chromium-bundle.sh /path/to/phytec-yocto-workspace/build
```

The layer contains:

- `recipes-browser/chromium/chromium-ozone-wayland_117.0.5938.132.bbappend`: native LLVM dependencies (`compiler-rt-native`, `libcxx-native`) and validating decoder GN option.
- `recipes-browser/chromium/files/fix-blink-eloc-proto.patch`: removes the invalid `ELOC_PROTO` GN mnemonic.

The tested upstream revisions are recorded in [`build-versions.txt`](build-versions.txt).

## Problems encountered and how we addressed them

| Symptom / log | Diagnosis | Fix / status |
| --- | --- | --- |
| Native LLVM/Clang compilation failed with missing `<cmath>` | Required native `libcxx`/compiler-rt dependencies were not included; upstream `chromium-gn.inc` used `DEPEND:append:runtime-llvm` rather than `DEPENDS:append:runtime-llvm`. | Added `DEPENDS:append:runtime-llvm = " compiler-rt-native libcxx-native"` in our custom `.bbappend`; original third-party layer left unmodified. |
| GN error around `mnemonic = "ELOC_PROTO"` in `third_party/blink/renderer/core/BUILD.gn` | Chromium 117 Blink GN configuration contained a problematic mnemonic assignment. | Added `fix-blink-eloc-proto.patch` to `SRC_URI`. The patch independently applied to a reconstructed unmodified source file. |
| Chromium failed to launch because `libc++.so.1`, `libnss3.so`, `libnspr4.so`, or `libxslt.so.1` was missing | The installed Yocto image did not include all Chromium runtime libraries. | Built the matching runtime RPMs, extracted them into the isolated `/opt` installation, and verified with `/lib/ld-linux-aarch64.so.1 --list`. |
| GPU crash: `FATAL:gpu_init.cc(500)] Passthrough is not supported, GL is egl, ANGLE is` | Compiled `ENABLE_VALIDATING_COMMAND_DECODER` was `0`; passthrough decoder incompatible with the tested EGL initialization. | Added `enable_validating_command_decoder=true`, rebuilt incrementally, and launched with `--use-gl=egl --use-cmd-decoder=validating`. Hardware acceleration was verified in `chrome://gpu`. |
| `Failed to load GLES library: .../chromium/libGLESv2.so` | Occurred during the original GPU process fallback; the path did not exist. The board did provide system EGL/GLES libraries. | The validating-decoder GPU configuration avoided the original failure; we did **not** solve this by copying random GLES libraries into Chromium's directory. |
| D-Bus/UPower/desktop portal errors appeared in browser logs | Services or session bus configuration absent/incomplete on the embedded image. | Set the user's session bus address in the launcher. Nonfatal optional-service warnings may remain; they did not block the verified browser tests. |
| Browser required `--no-sandbox` during early experiments | The test sandbox helper had been extracted under the unprivileged user's ownership. | Made the installation root-owned, set `chrome-sandbox` to root-owned mode `4755`, removed `--no-sandbox`, and checked `chrome://sandbox`. |
| `scp` failed when copying `floor-chromium` into `/opt/` | `/opt/floor-chromium` already existed as a **directory**, conflicting with the launcher's filename. | Transfer all setup files into `/opt/floor-nav-setup/`; install the launcher into `/usr/local/bin/floor-chromium`. |
| Weston desktop initially had only a terminal icon | Chromium was started manually rather than registered as a desktop launcher. | Added a `[launcher]` entry in `/etc/xdg/weston/weston.ini`, preserving its existing terminal launcher. |
| BusyBox `ps` rejected `-ww` | Target image provides BusyBox utilities rather than full GNU procps. | Use `ps -o pid,args` on the board. |

## Deployment architecture

```text
Linux build host
  ├─ PHYTEC Yocto BSP + meta-floor-nav
  ├─ BitBake produces Chromium and runtime RPMs
  ├─ scripts/make-chromium-bundle.sh
  └─ pollux-chromium-117-gpu.tar.gz + SHA-256
                    │
                    ▼  SSH / SCP
PHYTEC phyBOARD-Pollux (Weston)
  ├─ /opt/floor-chromium/usr/lib/chromium/
  ├─ /usr/local/bin/floor-chromium
  └─ /etc/xdg/weston/weston.ini → Chromium panel icon
```

## Security, compatibility, and redistribution

- **Chromium 117 (2023) is outdated.** The sandbox is a defense-in-depth measure, not a substitute for current browser security fixes. Do **not** use this build for personal accounts, credentials, or sensitive untrusted web browsing.
- This is a **board/BSP-specific** runtime bundle. It expects the matching graphics stack (Vivante GBM/EGL/GLES), glibc and other system libraries. Another ARM64 board may require its own build and flags.
- The binary archive currently contains no accompanying license/notice files. **Review the Yocto license outputs and applicable third-party obligations, and package appropriate notices/source-availability information, before publicly publishing the binary Release.**
- The example installation script assumes a fresh `/opt/floor-chromium`, root SSH access, the tested Weston configuration, and a Linux host with `scp`/`ssh`. It intentionally does not modify image partitions or install RPMs into an empty RPM database.

## References

- [PHYTEC BSP PD24.1.0 manual](https://phytec.github.io/doc-bsp-yocto/bsp/imx8/imx8mp/pd24.1.0_nxp.html)
- [OSSystems/meta-browser upstream repository](https://github.com/OSSystems/meta-browser)
- [Chromium i.MX EGL discussion (meta-browser issue #711)](https://github.com/OSSystems/meta-browser/issues/711)

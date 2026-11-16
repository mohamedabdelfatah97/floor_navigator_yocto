# Chromium 117 release notes — PHYTEC phyBOARD-Pollux (i.MX8MP)

> **Status:** Chromium 117.0.5938.132 was tested on the physical board. The precompiled GitHub binary Release has **not been published**.
>
> **Security:** Chromium 117 is obsolete and is not suitable for sensitive or untrusted browsing.

## Overview

These notes summarize the tested Chromium bundle, its compatibility, and release limitations. For actual build/deployment commands, use the [Chromium installation guide](chromium-pollux.md).

## Tested environment

| Component | Tested configuration |
| --- | --- |
| Board | PHYTEC phyBOARD-Pollux i.MX8MP |
| BSP / distribution | `BSP-Yocto-NXP-i.MX8MP-PD24.1.0` / `ampliphy-vendor-xwayland` |
| Architecture | AArch64 |
| Browser | Chromium 117.0.5938.132 |
| Graphical session | Weston / Wayland |
| GPU | Vivante GC7000UL |

## Installation

**There is no downloadable GitHub binary Release yet.** To install on a matching board, generate or reuse the verified local bundle and follow the instructions in [Chromium — Installation](chromium-pollux.md#installation). The guide documents the bundle builder, SHA-256 verification, SSH transfer, target installer, Weston launcher, and source-build alternative.

Do not treat the existence of local `releases/` archives as evidence that those binaries are published or redistributable.

## Verification

The following were observed on the tested board:

- Hardware-accelerated compositing and WebGL/WebGL2.
- OpenGL ES 3.1 with the Vivante graphics stack.
- Validating GPU command decoder configuration.
- Chromium sandbox reported enabled protections.
- Permanent Weston launcher and browser launch without reflashing.

For repeatable checks use `chrome://version`, `chrome://gpu`, and `chrome://sandbox`, as detailed in the [installation guide](chromium-pollux.md#verification).

## Troubleshooting

The [Chromium troubleshooting table](chromium-pollux.md#troubleshooting) covers missing native LLVM dependencies, Blink GN patching, runtime libraries, GPU decoder failures, sandbox ownership, and Weston launcher setup.

## Limitations and security

- Chromium 117 does not receive current security updates.
- This bundle is specific to the tested Pollux BSP/graphics stack, not a generic ARM64 package.
- Hardware video decoding remains unverified.
- Complete clean-room reproduction from the published custom Yocto layer is not yet established.
- License notices and applicable source availability must be reviewed before releasing binaries publicly.

## Related documentation

- [Chromium installation guide](chromium-pollux.md)
- [Chromium source provenance](chromium-source-provenance.md)
- [Build versions and upstream revisions](build-versions.txt)

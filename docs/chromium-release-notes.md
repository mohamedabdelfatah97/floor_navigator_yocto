# Chromium 117 — PHYTEC Pollux i.MX8MP

Tested Chromium 117.0.5938.132 build for the PHYTEC
phyBOARD-Pollux i.MX8MP.

## Compatibility

- BSP: BSP-Yocto-NXP-i.MX8MP-PD24.1.0
- Architecture: AArch64
- Distro: ampliphy-vendor-xwayland
- Display: Weston / Wayland
- GPU: Vivante GC7000UL

## Verified features

- Hardware-accelerated compositing and WebGL
- OpenGL ES 3.1 rendering
- Chromium validating GPU command decoder
- Linux sandbox protections
- Weston desktop launcher
- Installation without reflashing

## Installation

See [the Chromium installation guide](https://github.com/mohamedabdelfatah97/floor_navigator_yocto/blob/main/docs/chromium-pollux.md)
in the repository.

The GitHub Release contains the precompiled Chromium bundle,
SHA-256 checksum, and generated license notices.

## Limitations

Chromium 117 is outdated and no longer receives current
security fixes. Do not use it for sensitive browsing.

This binary is board/BSP-specific, not a universal ARM64 build.

Hardware video decoding has not been validated.

A complete clean-room Yocto rebuild using only the custom
GitHub layer has not yet been verified.

## Licensing

License notices are provided in a separate archive.
Additional source-distribution obligations must be reviewed
before public redistribution.

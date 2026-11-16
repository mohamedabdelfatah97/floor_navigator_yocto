# Floor Navigator — Yocto & Embedded Linux

Yocto Linux BSP customization, software builds, cross-compilation,
system configuration, and development tools for the PHYTEC
phyBOARD-Pollux i.MX8MP.

## Target hardware

- Board: PHYTEC phyBOARD-Pollux i.MX8MP
- BSP: BSP-Yocto-NXP-i.MX8MP-PD24.1.0
- Architecture: ARM64 (AArch64)
- Display system: Weston / Wayland

## Projects

### Chromium Browser

- Chromium 117.0.5938.132
- Native Wayland integration
- Vivante GC7000UL GPU acceleration
- OpenGL ES 3.1
- Validating GPU command decoder
- Linux sandbox protection
- Weston desktop launcher

## Repository structure

- `meta-floor-nav/` - Custom Yocto layer and patches
- `board/pollux/` - Board configuration and launcher reference
- `scripts/` - Build and packaging scripts
- `docs/` - Build documentation and verified versions

## Current status

Chromium has been successfully tested on the physical Pollux.

The custom layer and source patch are prepared. A completely
fresh Yocto build using only this repository has not yet been
verified.

The automated binary installer is still under development.

## Security

Chromium 117 is outdated and should not be used for sensitive
web browsing. The working sandbox does not replace browser
security updates.

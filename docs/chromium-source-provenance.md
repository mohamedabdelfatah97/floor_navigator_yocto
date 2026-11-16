# Chromium 117 — Source Provenance

## Build environment

- Hardware: PHYTEC phyBOARD-Pollux i.MX8MP
- BSP: BSP-Yocto-NXP-i.MX8MP-PD24.1.0
- Distro: ampliphy-vendor-xwayland
- Chromium: 117.0.5938.132
- GPU: Vivante GC7000UL

## Upstream sources

| Component | Version | Source |
|---|---|---|
| Chromium | 117.0.5938.132 | https://commondatastorage.googleapis.com/chromium-browser-official/chromium-117.0.5938.132.tar.xz |
| libcxx | 18.1.4 | https://github.com/llvm/llvm-project |
| NSS | 3.98 | https://ftp.mozilla.org/pub/security/nss/releases/NSS_3_98_RTM/src/nss-3.98.tar.gz |
| NSPR | 4.35 | https://ftp.mozilla.org/pub/nspr/releases/v4.35/src/nspr-4.35.tar.gz |
| libxslt | 1.1.39 | https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.39.tar.xz |

LLVM revision:
e6c3289804a67ea0bb6a86fadbe454dd93b8d855

libcxx uses the shared llvm-project-source recipe.

## Build modifications

Chromium was built with patches from:
- The upstream meta-browser layer
- The NXP/PHYTEC BSP layers
- This repository's meta-floor-nav layer

The custom layer contains the Blink ELOC_PROTO fix
and the validating GPU command decoder configuration.

The complete upstream and BSP patch sets are not yet
mirrored in this repository.

## Redistribution

The binary GitHub Release is currently a draft.

License notices are collected separately.

Before publishing, verify access to the corresponding
source code and modifications for applicable licenses,
including MPL/LGPL-covered components.

The source information here documents provenance but
does not by itself establish redistribution compliance.

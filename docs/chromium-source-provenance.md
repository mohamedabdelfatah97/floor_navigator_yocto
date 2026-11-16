# Chromium 117 source provenance — PHYTEC phyBOARD-Pollux (i.MX8MP)

> **Status:** Source and version information for the tested Chromium build; this document does **not** establish complete binary redistribution compliance.

## Overview

This document records source locations, build modifications, and redistribution considerations. For building and installing Chromium, use the [Chromium installation guide](chromium-pollux.md).

## Tested environment

| Component | Tested configuration |
| --- | --- |
| Board | PHYTEC phyBOARD-Pollux i.MX8MP |
| BSP / distribution | `BSP-Yocto-NXP-i.MX8MP-PD24.1.0` / `ampliphy-vendor-xwayland` |
| Chromium | 117.0.5938.132 |
| GPU | Vivante GC7000UL |

## Upstream sources

| Component | Version | Source |
| --- | --- | --- |
| Chromium | 117.0.5938.132 | [Chromium source archive](https://commondatastorage.googleapis.com/chromium-browser-official/chromium-117.0.5938.132.tar.xz) |
| libcxx | 18.1.4 | [llvm-project](https://github.com/llvm/llvm-project) |
| NSS | 3.98 | [NSS archive](https://ftp.mozilla.org/pub/security/nss/releases/NSS_3_98_RTM/src/nss-3.98.tar.gz) |
| NSPR | 4.35 | [NSPR archive](https://ftp.mozilla.org/pub/nspr/releases/v4.35/src/nspr-4.35.tar.gz) |
| libxslt | 1.1.39 | [libxslt archive](https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.39.tar.xz) |

The recorded LLVM revision is `e6c3289804a67ea0bb6a86fadbe454dd93b8d855`. The libcxx recipe shares the `llvm-project-source` source tree. Upstream layer revisions are documented in [`build-versions.txt`](build-versions.txt).

## Installation

This document is a **source manifest**, not a runtime installer. See [Chromium — Installation](chromium-pollux.md#installation) for the locally generated bundle, target scripts, checksum verification, and Yocto rebuild instructions. The GitHub binary Release described there is not yet published.

## Build modifications

The tested build applied patches and configuration from:

- Upstream `meta-browser`.
- NXP/PHYTEC BSP layers.
- This repository's `meta-floor-nav` layer.

The custom layer contains the Blink `ELOC_PROTO` GN fix and settings for the validating GPU command decoder. The complete upstream and vendor patch sets are **not** mirrored in this Git repository.

## Verification

The tested runtime's GPU acceleration and sandbox status are documented in [Chromium — Verification](chromium-pollux.md#verification). Source provenance itself does not establish that every source artifact can be reproduced from this repository alone.

## Troubleshooting

Build-related failures involving native LLVM dependencies and Blink GN configuration are recorded in [Chromium — Troubleshooting](chromium-pollux.md#troubleshooting).

## Limitations and redistribution

- The binary GitHub Release remains unpublished.
- Separate license notices have been collected locally but still require review before redistribution.
- Verify access to corresponding source code and modifications for applicable licenses, including MPL/LGPL-covered components.
- This provenance record is **not** a legal compliance determination.

## Related documentation

- [Chromium installation guide](chromium-pollux.md)
- [Chromium release notes](chromium-release-notes.md)
- [Workspace setup and layout](workspace-layout.md)

# Floor Navigator — Documentation

> **Platform:** PHYTEC phyBOARD-Pollux i.MX8MP, PHYTEC PD24.1.0 BSP, `ampliphy-vendor-xwayland`.
>
> **Scope:** Guides record the tested physical-board setup. The full desktop stack is **not yet reproducible from a single fresh Yocto image build**.

## Installation guides

| Application | What the guide covers | Installation status |
| --- | --- | --- |
| [Chromium 117](chromium-pollux.md) | Bundle generation, target installer, Weston launcher, Yocto build, GPU/sandbox checks | Tested manual deployment; binary GitHub Release not published |
| [Geany 1.38](geany-pollux.md) | Yocto build, RPM installation, Weston launcher, PCManFM file association | Tested manual deployment |
| [PCManFM 1.3.2](pcmanfm-pollux.md) | Runtime prerequisites, menu-cache/libfm fixes, Weston launcher, system MIME defaults | Tested on existing isolated runtime; complete fresh-board installer pending |

## Reference documents

- [Chromium release notes](chromium-release-notes.md) — compatibility, tested features, and release limitations.
- [Chromium source provenance](chromium-source-provenance.md) — source archives, versions, patches, and redistribution caveats.
- [Yocto workspace setup](workspace-layout.md) — where the build, sources, and Git repository live, plus build-environment commands.
- [Build versions](build-versions.txt) — recorded toolchain/library versions and source-layer revisions.

## Guide conventions

Each application guide uses the same structure: **Overview**, **Tested environment**, **Prerequisites**, **Installation**, **Verification**, **Troubleshooting**, **Limitations and security**, and **Related documentation**.

Commands explicitly distinguish the **Ubuntu host** from the **Pollux target board**. Example SSH addresses and local filesystem paths may need adapting. The guides distinguish tested steps from pending work rather than implying every dependency is included in the custom Yocto layer.

## Remaining integration work

- Turn the manually staged PCManFM runtime and dependencies into reproducible Yocto packages/image configuration.
- Add and test image, video, and PDF viewers and their MIME defaults.
- Complete GTK/icon warning cleanup, binary redistribution review, and fresh-image verification.

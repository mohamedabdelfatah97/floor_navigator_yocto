# Geany 1.38 — PHYTEC Pollux i.MX8MP

## Overview

Geany 1.38 was successfully cross-compiled using Yocto,
installed on the physical PHYTEC Pollux, and tested with
the Weston/Wayland graphical desktop.

### Tested environment

| Component | Version |
|---|---|
| Board | PHYTEC phyBOARD-Pollux i.MX8MP |
| BSP | BSP-Yocto-NXP-i.MX8MP-PD24.1.0 |
| Distro | ampliphy-vendor-xwayland |
| Architecture | AArch64 / Cortex-A53 |
| Geany | 1.38 |
| GUI | GTK3 / Wayland |

## 1. Build Geany on the Ubuntu workstation

The Geany recipe is already available in the `meta-oe` layer.

Initialize the Yocto build environment:

```bash
cd ~/floor_navigator_yocto

source buildtools/environment-setup-x86_64-pokysdk-linux

TEMPLATECONF=../meta-phytec/conf/templates/default \
  . sources/poky/oe-init-build-env

bitbake geany
```

### Ubuntu 24.04 AppArmor issue

The initial build failed with:

```text
PermissionError: [Errno 1] Operation not permitted
/proc/self/uid_map
```

The cause was Ubuntu's AppArmor restriction on
unprivileged user namespaces.

For this build, the following temporary workaround was used:

```bash
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
bitbake geany
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=1
```

The original security setting was restored after compilation.

Changing this setting relaxes host security system-wide.
Restore the original value after building.

## 2. Locate the generated RPM

The main Geany package is:

```text
geany-1.38-r0.cortexa53_crypto.rpm
```

It is located under:

```text
build/deploy-ampliphy-vendor-xwayland/rpm/cortexa53_crypto/
```

Transfer the package from Ubuntu to the Pollux:

```bash
scp geany-1.38-r0.cortexa53_crypto.rpm \
  root@172.16.0.193:/tmp/
```

Adjust the source path and board IP address as required.

## 3. Install Geany on the Pollux

The tested Pollux image initially had an empty RPM database,
despite already containing GTK3 and other runtime libraries.

The RPM package architecture was `cortexa53_crypto`,
whereas the RPM tool reported `aarch64`.

The Geany executable was verified as ELF64 AArch64.
Package installation scripts were inspected.

After these checks, installation succeeded using:

```bash
rpm -Uvh --nodeps --ignorearch --noscripts \
  /tmp/geany-1.38-r0.cortexa53_crypto.rpm

/sbin/ldconfig
rpm -q geany
```

These flags bypass RPM safety checks and are specific to
the verified configuration. Do not use them blindly on
other systems.

The post-install scripts were skipped because
`update-desktop-database` was unavailable.

## 4. Weston graphical launcher

The tested launcher is stored in this repository:

```text
board/pollux/floor-geany
```

Install it on the Pollux as:

```text
/usr/local/bin/floor-geany
```

Make it executable:

```bash
chmod 755 /usr/local/bin/floor-geany
```

Add the following section to `/etc/xdg/weston/weston.ini`:

```ini
[launcher]
icon=/usr/share/icons/hicolor/32x32/apps/geany.png
displayname=Geany
path=/usr/local/bin/floor-geany
```

Restart Weston or reboot the board.

The launcher sets the appropriate Wayland environment and
starts Geany from `/home/weston`, avoiding permission errors
when saving files.

## 5. Physical board verification

Successfully verified:

- Geany opens on the Weston desktop.
- Geany works with GTK3's native Wayland backend.
- Text editing and keyboard input work.
- Files can be saved under `/home/weston`.
- The permanent Weston launcher works after reboot.

Test file:

```text
/home/weston/geany-test.txt
```

Verified contents:

```text
Hello from Geany on the Pollux!
```

Minor GTK cursor-theme warnings were observed but did not
prevent operation.

## 6. Current status

Geany 1.38 is fully operational on the tested physical Pollux.

PCManFM 1.3.2 has since been deployed and tested. A text file opened from PCManFM successfully launches Geany, using system-wide MIME defaults. See [PCManFM integration](pcmanfm-pollux.md).

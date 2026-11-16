# Floor Navigator — Chromium for PHYTEC Pollux i.MX8MP

# Fix missing native LLVM dependencies in meta-chromium.
DEPENDS:append:runtime-llvm = " compiler-rt-native libcxx-native"

# Enable the validating GL command decoder for Vivante EGL.
GN_ARGS:append = " enable_validating_command_decoder=true"

# Fix unused GN mnemonic in Chromium 117 Blink configuration.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://fix-blink-eloc-proto.patch"

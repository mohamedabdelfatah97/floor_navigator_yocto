# Enable the X11 backend required by PCManFM.
# Preserve the existing Wayland backend for Geany and other apps.

PACKAGECONFIG:append = " x11"

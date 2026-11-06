#!/bin/bash
# Install the DKMS PRE_BUILD hook so the #1143204 patch is applied automatically
# on every nvidia-current-open DKMS build (new kernels and nvidia upgrades).
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "error: run as root" >&2; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
install -Dm644 "$HERE/0075-backport-NV_PCI_RESIZE_RESOURCE_HAS_EXCLUDE_BARS_ARG.patch" \
    /usr/local/share/nvidia-1143204/0075-backport-NV_PCI_RESIZE_RESOURCE_HAS_EXCLUDE_BARS_ARG.patch
install -Dm755 "$HERE/dkms-hook/nvidia-1143204-prebuild" /usr/local/sbin/nvidia-1143204-prebuild
install -Dm644 "$HERE/dkms-hook/nvidia-current-open.conf" /etc/dkms/nvidia-current-open.conf
echo "installed; remove /etc/dkms/nvidia-current-open.conf once a fixed nvidia package lands"

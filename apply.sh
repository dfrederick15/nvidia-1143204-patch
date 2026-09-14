#!/bin/bash
# Apply the Debian #1143204 fix to the nvidia open kernel DKMS source and rebuild.
# Re-run this after any nvidia-open-kernel-dkms package upgrade.
set -euo pipefail

PATCH="$(cd "$(dirname "$0")" && pwd)/0075-backport-NV_PCI_RESIZE_RESOURCE_HAS_EXCLUDE_BARS_ARG.patch"

if [ "$(id -u)" -ne 0 ]; then
    echo "error: must run as root (sudo $0)" >&2
    exit 1
fi

# Find the nvidia open kernel source tree; there should be exactly one.
mapfile -t TREES < <(find /usr/src -maxdepth 1 -type d -name 'nvidia-*open-*' | sort)
if [ "${#TREES[@]}" -eq 0 ]; then
    echo "error: no nvidia open kernel source found under /usr/src" >&2
    exit 1
elif [ "${#TREES[@]}" -gt 1 ]; then
    echo "error: multiple candidate trees, refusing to guess:" >&2
    printf '  %s\n' "${TREES[@]}" >&2
    exit 1
fi
SRC="${TREES[0]}"
MODULE="$(basename "$SRC")"
NAME="${MODULE%-*}"
VERSION="${MODULE##*-}"

echo "==> source tree: $SRC"

if grep -q NV_PCI_RESIZE_RESOURCE_HAS_EXCLUDE_BARS_ARG "$SRC/nvidia/nv-pci.c"; then
    echo "==> already patched, nothing to do"
    exit 0
fi

if ! patch -p1 -d "$SRC" --dry-run < "$PATCH"; then
    echo "error: patch does not apply cleanly; source may have changed upstream" >&2
    exit 1
fi

echo "==> applying patch (backups: .orig-1143204)"
patch -p1 -d "$SRC" --suffix=.orig-1143204 --backup < "$PATCH"
cp "$PATCH" "$SRC/"

echo "==> rebuilding DKMS module for all installed kernels"
for KVER in $(ls /lib/modules); do
    [ -d "/lib/modules/$KVER/build" ] || continue
    echo "--> $KVER"
    dkms install -m "$NAME" -v "$VERSION" -k "$KVER" --force
done

echo "==> done"
dkms status "$NAME"

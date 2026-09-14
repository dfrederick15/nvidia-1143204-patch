# nvidia-1143204-patch

Local fix for **Debian bug [#1143204](https://bugs.debian.org/1143204)** — `nvidia-open-kernel-dkms`
fails to build on Linux 6.12.100 and newer.

## The problem

Kernel 6.12.100 added a fourth parameter (`exclude_bars`) to `pci_resize_resource()`.
NVIDIA's open kernel modules 550.163.01 call it with three arguments and have no
conftest guard, so the DKMS build dies:

```
error: too few arguments to function 'pci_resize_resource'
```

Because the build fails, the `linux-image` postinst fails too, which blocks kernel
upgrades entirely.

Affected identically across suites:

| Package version | Suite |
|---|---|
| `550.163.01-2` | trixie |
| `550.163.01-4` | sid |
| `550.163.01-4~bpo13+1` | trixie-backports |

## The patch

`0075-backport-NV_PCI_RESIZE_RESOURCE_HAS_EXCLUDE_BARS_ARG.patch` is
[salsa MR !3](https://salsa.debian.org/nvidia-team/nvidia-open-gpu-kernel-modules/-/merge_requests/3)
by Ciel Avenir, which backports upstream NVIDIA commit `2ccbad25e1`. It adds a
conftest probe and wraps the call site:

```c
#if defined(NV_PCI_RESIZE_RESOURCE_HAS_EXCLUDE_BARS_ARG)
    r = pci_resize_resource(pci_dev, NV_GPU_BAR1, requested_size, 0);
#else
    r = pci_resize_resource(pci_dev, NV_GPU_BAR1, requested_size);
#endif
```

It touches three files: `nvidia/nv-pci.c`, `nvidia/nvidia.Kbuild`, `conftest.sh`.

Because the arg count is **detected at build time** rather than hardcoded, the
patched tree builds against kernels on either side of the 6.12.100 change. A new
kernel needs no re-patching.

## Usage

```sh
sudo ./apply.sh
```

This patches `/usr/src/nvidia-current-open-<version>/` in place (keeping
`.orig-1143204` backups) and rebuilds the DKMS module for every installed kernel.

## Re-apply after every nvidia upgrade

This is an unpackaged local change. **Any `nvidia-open-kernel-dkms` package update
overwrites `/usr/src` and silently restores the broken source.** Re-run `apply.sh`
after any nvidia upgrade, until MR !3 lands in a Debian release.

## Status

As of 2026-09-13 the bug is still **open**; no packaged revision in bookworm,
trixie, sid, experimental, or backports fixes it.

Verified building and running on Debian 13 (trixie), driver 550.163.01,
RTX 3060 Laptop, kernels 6.12.105 and 6.12.107.

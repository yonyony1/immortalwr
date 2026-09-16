#!/usr/bin/env python3
"""Build a Hugo U-Boot factory.bin from an ImmortalWrt sysupgrade tar.

Format: FIT kernel padded to 6 MiB, then squashfs rootfs.
Do not append fwtool metadata: that would sit at the overlay start.
"""

from __future__ import annotations

import sys
import tarfile
from pathlib import Path

KERNEL_SIZE = 6144 * 1024
FIT_MAGIC = b"\xd0\x0d\xfe\xed"
SQUASHFS_MAGIC = b"hsqs"


def member_named(members, suffix: str):
    hits = [m for m in members if m.name == suffix or m.name.endswith("/" + suffix)]
    if not hits:
        raise SystemExit(f"sysupgrade tar is missing {suffix}")
    return hits[0]


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("usage: make-factory.py <sysupgrade.bin> [output-dir]")
    src = Path(sys.argv[1])
    dest_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else src.parent
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / src.name.replace("squashfs-sysupgrade.bin", "squashfs-factory.bin")
    if dest == src:
        raise SystemExit(f"refusing to overwrite {src}")

    with tarfile.open(src, "r") as tf:
        members = tf.getmembers()
        kernel = tf.extractfile(member_named(members, "kernel")).read()
        root = tf.extractfile(member_named(members, "root")).read()
        control = tf.extractfile(member_named(members, "CONTROL")).read().decode("utf-8", "replace")

    if "jdcloud_re-ss-01" not in control:
        raise SystemExit(f"unexpected CONTROL: {control.strip()!r}")
    if kernel[:4] != FIT_MAGIC:
        raise SystemExit("kernel is not a FIT/FDT image")
    if b"jdcloud,re-ss-01" not in kernel:
        raise SystemExit("kernel DTB is not jdcloud,re-ss-01")
    if len(kernel) > KERNEL_SIZE:
        raise SystemExit(f"kernel {len(kernel)} exceeds {KERNEL_SIZE}")
    if root[:4] != SQUASHFS_MAGIC:
        raise SystemExit("rootfs is not squashfs")

    factory = kernel + (b"\x00" * (KERNEL_SIZE - len(kernel))) + root
    dest.write_bytes(factory)
    print(
        f"wrote {dest} ({len(factory)} bytes; kernel {len(kernel)}, "
        f"pad {KERNEL_SIZE - len(kernel)}, root {len(root)})"
    )


if __name__ == "__main__":
    main()

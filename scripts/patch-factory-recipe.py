#!/usr/bin/env python3
"""Add a Hugo U-Boot factory.bin recipe to ipq60xx.mk."""

from pathlib import Path
import sys

TAB = "\t"


def main() -> None:
    p = Path(sys.argv[1] if len(sys.argv) > 1 else "target/linux/qualcommax/image/ipq60xx.mk")
    text = p.read_text()
    start = text.find("define Device/jdcloud_re-ss-01")
    if start < 0:
        raise SystemExit("jdcloud_re-ss-01 device definition not found")
    end = text.find("\nendef\n", start)
    if end < 0:
        raise SystemExit("jdcloud_re-ss-01 device block is incomplete")
    end += len("\nendef\n")
    block = text[start:end]
    if "IMAGE/factory.bin" in block:
        print("factory.bin recipe already present")
        return
    if "$(call Device/EmmcImage)" in block:
        raise SystemExit("refusing to patch Device/EmmcImage factory.bin")

    old = "\n".join(
        [
            "define Device/jdcloud_re-ss-01",
            TAB + "$(call Device/FitImage)",
            TAB + "DEVICE_VENDOR := JDCloud",
            TAB + "DEVICE_MODEL := RE-SS-01",
            TAB + "SOC := ipq6000",
            TAB + "BLOCKSIZE := 64k",
            TAB + "KERNEL_SIZE := 6144k",
            TAB + "DEVICE_DTS_CONFIG := config@cp03-c2",
            TAB + "DEVICE_PACKAGES := ipq-wifi-jdcloud_re-ss-01",
            "endef",
            "",
        ]
    )
    new = "\n".join(
        [
            "define Device/jdcloud_re-ss-01",
            TAB + "$(call Device/FitImage)",
            TAB + "DEVICE_VENDOR := JDCloud",
            TAB + "DEVICE_MODEL := RE-SS-01",
            TAB + "SOC := ipq6000",
            TAB + "BLOCKSIZE := 64k",
            TAB + "KERNEL_SIZE := 6144k",
            TAB + "DEVICE_DTS_CONFIG := config@cp03-c2",
            TAB + "DEVICE_PACKAGES := ipq-wifi-jdcloud_re-ss-01",
            TAB + "IMAGES += factory.bin",
            TAB + "IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs",
            "endef",
            "",
        ]
    )
    if old not in text:
        raise SystemExit("unexpected jdcloud_re-ss-01 block, refusing to patch")
    p.write_text(text.replace(old, new, 1))
    print("added Hugo U-Boot factory.bin recipe")


if __name__ == "__main__":
    main()

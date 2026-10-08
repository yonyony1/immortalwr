#!/bin/bash
# Runs after feeds install, inside the OpenWrt tree.
set -e

LUCI_CFG="feeds/luci/modules/luci-base/root/etc/config/luci"
if [ -f "$LUCI_CFG" ]; then
        sed -i "s/option lang 'auto'/option lang 'zh_cn'/" "$LUCI_CFG"
fi

if [ -d files ]; then
        find files/etc/init.d files/usr/sbin -type f -exec chmod 755 {} \; 2>/dev/null || true
fi

mkdir -p package/base-files/files/etc
cat > package/base-files/files/etc/banner << "EOF"
  ImmortalWrt  (JDCloud RE-SS-01)
  USB WAN build: plug portable WiFi, then share over Wi-Fi
 -----------------------------------------------------
EOF

# Hugo U-Boot flashes kernel+rootfs. Do not use Device/EmmcImage
# (that factory.bin is rootfs-only and will not persist).
MK="target/linux/qualcommax/image/ipq60xx.mk"
if [ -f "$MK" ]; then
        python3 "$(cd "$(dirname "$0")" && pwd)/scripts/patch-factory-recipe.py" "$MK"
fi

# ============新增：hostapd 开启 CONFIG_EHT，修复 he_mu_edca 结构体编译错误============
HOSTAPD_MAKEFILE="package/network/services/hostapd/Makefile"
if [ -f "$HOSTAPD_MAKEFILE" ]; then
    # 在 CONFIG_IEEE80211BE 那一行后面插入 CONFIG_EHT=y
    sed -i '/CONFIG_IEEE80211BE=$(HOSTAPD_IEEE80211BE) \\/a \\\tCONFIG_EHT=y \\' "$HOSTAPD_MAKEFILE"
fi

echo "diy-part2 done"

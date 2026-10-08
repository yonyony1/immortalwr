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

# ========== 修复hostapd：sed修改package Makefile，不再使用patch文件 ==========
echo "Add CONFIG_EHT=y to hostapd DRIVER_MAKEOPTS"
sed -i '/CONFIG_IEEE80211BE=$(HOSTAPD_IEEE80211BE) \\/a \\
CONFIG_EHT=y \\' package/network/services/hostapd/Makefile

# 清理hostapd编译缓存
make package/network/services/hostapd clean
rm -rf build_dir/target-*_hostapd*

echo "diy-part2 done"

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

# 修复hostapd he_mu_edca结构体缺失：强制开启 CONFIG_EHT 编译宏
mkdir -p package/network/services/hostapd/patches
cat > package/network/services/hostapd/patches/000-fix-hostapd-eht-compile.patch <<'EOF'
--- a/package/network/services/hostapd/Makefile
+++ b/package/network/services/hostapd/Makefile
@@ -112,6 +112,7 @@ DRIVER_MAKEOPTS= \
 	CONFIG_IEEE80211AC=$(HOSTAPD_IEEE80211AC) \
 	CONFIG_IEEE80211AX=$(HOSTAPD_IEEE80211AX) \
 	CONFIG_IEEE80211BE=$(HOSTAPD_IEEE80211BE) \
+	CONFIG_EHT=y \
 	CONFIG_ACS=y CONFIG_DRIVER_NL80211=y
 EOF

# 清理旧编译缓存，保证补丁重新应用
make package/network/services/hostapd clean
rm -rf build_dir/target-*_hostapd*

echo "diy-part2 done"

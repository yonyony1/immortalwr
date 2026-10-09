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

# ===================== Build/PostPatch：批量注释所有 he_mu_edca 代码 =====================
cat >> package/network/services/hostapd/Makefile <<'EOF'
define Build/PostPatch
	# 注释所有直接访问 he_mu_edca 的代码行
	$(SED) 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/hostapd.c
	$(SED) 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/drv_callbacks.c
	$(SED) 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/ieee802_11_he.c
	$(SED) 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/wmm.c
	$(SED) 's/.*EVENT_UPDATE_MUEDCA_PARAMS.*/\/\/ &/' $(PKG_BUILD_DIR)/src/drivers/driver_nl80211_event.c
endef
EOF

# 清理hostapd缓存
make package/network/services/hostapd clean
rm -rf build_dir/target-*_hostapd*

echo "diy-part2 done"

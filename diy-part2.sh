#!/bin/bash
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

MK="target/linux/qualcommax/image/ipq60xx.mk"
if [ -f "$MK" ]; then
        python3 "$(cd "$(dirname "$0")" && pwd)/scripts/patch-factory-recipe.py" "$MK"
fi

# ========== 删掉旧的Build/PostPatch代码，改用Build/Prepare钩子 ==========
# 覆盖hostapd包的Build/Prepare，解压源码后立刻注释he_mu_edca相关代码
cat > package/network/services/hostapd/Makefile.prepend <<'EOF'
define Build/Prepare
	$(call Build/Prepare/Default)
	# 注释所有包含 he_mu_edca 的代码行
	$(SED) 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/hostapd.c
	$(SED) 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/drv_callbacks.c
	$(SED) 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/ieee802_11_he.c
	$(SED) 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/wmm.c
	$(SED) 's/.*EVENT_UPDATE_MUEDCA_PARAMS.*/\/\/ &/' $(PKG_BUILD_DIR)/src/drivers/driver_nl80211_event.c
endef
EOF
# 把Build/Prepare插入hostapd Makefile开头
sed -i '/^include \.\.\/\.\.\/package\.mk/r package/network/services/hostapd/Makefile.prepend' package/network/services/hostapd/Makefile

# 清理hostapd旧缓存
make package/network/services/hostapd clean
rm -rf build_dir/target-*_hostapd*
rm -f package/network/services/hostapd/patches/0001-fix-he_mu_edca.patch

echo "diy-part2 done"

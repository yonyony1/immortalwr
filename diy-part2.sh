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

# ========== 修复 lua host编译 sed 不存在 ==========
LUA_MK="package/utils/lua/Makefile"
if [ -f "$LUA_MK" ]; then
  sed -i 's|$(STAGING_DIR_HOST)/bin/sed|sed|g' "$LUA_MK"
fi

# ========== hostapd Build/Prepare 安全注入 ==========
H_MK="package/network/services/hostapd/Makefile"
if [ -f "$H_MK" ]; then
  sed -i '/^define Build\/Prepare/,/^endef/d' "$H_MK"
  cat >> "$H_MK" <<'EOF'
define Build/Prepare
	$(call Build/Prepare/Default)
	sed -i 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/hostapd.c
	sed -i 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/drv_callbacks.c
	sed -i 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/ieee802_11_he.c
	sed -i 's/.*he_mu_edca.*/\/\/ &/' $(PKG_BUILD_DIR)/src/ap/wmm.c
	sed -i 's/.*EVENT_UPDATE_MUEDCA_PARAMS.*/\/\/ &/' $(PKG_BUILD_DIR)/src/drivers/driver_nl80211_event.c
endef
EOF
fi
rm -f package/network/services/hostapd/patches/0001-fix-he_mu_edca.patch

echo "diy-part2 done"

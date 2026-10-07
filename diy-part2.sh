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

# ========== 新增：修复uhttpd GCC12 stringop-overread编译报错 ==========
UHTTPD_MK="package/network/services/uhttpd/Makefile"
if [ -f "$UHTTPD_MK" ]; then
    sed -i '/ifneq ($(CONFIG_USE_GLIBC),)/i \
TARGET_CFLAGS += -Wno-error=stringop-overread' "$UHTTPD_MK"
fi

# hostapd 补丁：注释 he_mu_edca，使用patch文件方式（正确时机）
if package_enabled hostapd wpad wpad-full-openssl; then
  echo ">> Create hostapd patch to disable he_mu_edca"
  mkdir -p package/network/services/hostapd/patches
  cat > package/network/services/hostapd/patches/0001-disable-he_mu_edca.patch <<'EOF'
--- a/src/ap/hostapd.c
+++ b/src/ap/hostapd.c
@@ -4681,7 +4681,7 @@ static void hostapd_fill_csa_settings(struct hostapd_data *hapd,
 	conf->csa_ecsa_beacon_tx = params->csa_ecsa_beacon_tx;
 	conf->csa_no_ht = params->csa_no_ht;
 
-	hapd->iface->conf->he_mu_edca.he_qos_info &= 0xfff0;
+	//hapd->iface->conf->he_mu_edca.he_qos_info &= 0xfff0;
 }
 
 static int hostapd_setup_csa(struct hostapd_data *hapd,
EOF
fi


echo "diy-part2 done"

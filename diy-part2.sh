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

# 方案B：打补丁修复hostapd.c源码，无需修改Makefile
mkdir -p package/network/services/hostapd/patches
cat > package/network/services/hostapd/patches/0001-fix-he_mu_edca.patch <<'EOF'
--- a/src/ap/hostapd.c
+++ b/src/ap/hostapd.c
@@ -4681,7 +4681,9 @@ static void hostapd_fill_csa_settings(struct hostapd_iface *iface)
 		if (conf->he_opmode & HE_OPMODE_CHANNEL_WIDTH_MASK)
 			conf->he_opmode &= ~HE_OPMODE_CHANNEL_WIDTH_MASK;
 
+#ifdef CONFIG_EHT
 		hapd->iface->conf->he_mu_edca.he_qos_info &= 0xfff0;
+#endif
 	}
 }
EOF
make package/network/services/hostapd clean
rm -rf build_dir/target-*_hostapd*


echo "diy-part2 done"

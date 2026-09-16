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
  ImmortalWrt Arthur (JDCloud RE-SS-01)
  USB WAN build: plug portable WiFi, then share over Wi-Fi
 -----------------------------------------------------
EOF

echo "diy-part2 done"

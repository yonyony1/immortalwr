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

# diy-part2.sh 添加下面代码，注释报错4684行
cd openwrt
# 解压hostapd源码
make package/network/services/hostapd/prepare V=s
# 找到hostapd.c，注释4684行
HP_C=$(find build_dir/target-*/hostapd-wpad-basic-openssl/hostapd-*/src/ap/hostapd.c)
if [ -f "$HP_C" ]; then
  sed -i '4684 s/^/\/\//' "$HP_C"
fi

echo "diy-part2 done"

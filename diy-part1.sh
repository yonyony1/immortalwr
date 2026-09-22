#!/bin/bash
# Runs before feeds update. Add custom feeds from custom-feeds.conf
set -e

echo "Using official ImmortalWrt feeds, loading custom feeds..."
if [ -f "$GITHUB_WORKSPACE/custom-feeds.conf" ];then
  cat "$GITHUB_WORKSPACE/custom-feeds.conf" >> feeds.conf.default
fi

# 拉取所有feeds源码
./scripts/feeds update -a
# 安装注册包，此时feeds/nss_packages目录文件就绪
./scripts/feeds install -a

# ========== 方案A：修复sed换行丢失endif的bug ==========
# 删除旧的RMNET ifndef~endif代码块
sed -i '/ifndef CONFIG_NSS_DRV_RMNET_ENABLE/,/endif/d' feeds/nss_packages/qca-nss-drv/Makefile
# 插入完整正确代码块
sed -i '/CONFIG_NSS_DRV_RMNET_ENABLE/a\
ifndef CONFIG_NSS_DRV_RMNET_ENABLE\
   DRV_MAKE_OPTS += NSS_DRV_RMNET_ENABLE=n\
else\
   DRV_MAKE_OPTS += NSS_DRV_RMNET_ENABLE=y\
endif' feeds/nss_packages/qca-nss-drv/Makefile

# ECM开启RMNET
sed -i 's/ECM_INTERFACE_RMNET_ENABLE=n/ECM_INTERFACE_RMNET_ENABLE=y/' feeds/nss_packages/qca-nss-ecm/Makefile

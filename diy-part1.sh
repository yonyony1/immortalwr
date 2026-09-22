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

# ========== 方案A：修复nss-drv RMNET编译参数，开启ECM RMNET ==========
# 给nss-drv的RMNET配置增加else分支，CONFIG_NSS_DRV_RMNET_ENABLE=y时传入NSS_DRV_RMNET_ENABLE=y
sed -i '/ifndef CONFIG_NSS_DRV_RMNET_ENABLE/a \
else\n   DRV_MAKE_OPTS += NSS_DRV_RMNET_ENABLE=y' feeds/nss_packages/qca-nss-drv/Makefile

# ECM开启RMNET
sed -i 's/ECM_INTERFACE_RMNET_ENABLE=n/ECM_INTERFACE_RMNET_ENABLE=y/' feeds/nss_packages/qca-nss-ecm/Makefile

# 校验命令，编译日志中可查看修改结果是否生效
echo "==== DRV RMNET CONFIG BLOCK ===="
grep -A3 CONFIG_NSS_DRV_RMNET_ENABLE feeds/nss_packages/qca-nss-drv/Makefile
echo "==== ECM RMNET CONFIG ===="
grep ECM_INTERFACE_RMNET_ENABLE feeds/nss_packages/qca-nss-ecm/Makefile

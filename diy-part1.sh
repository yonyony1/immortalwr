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
QCA_NSS_DRV_MK="feeds/nss_packages/qca-nss-drv/Makefile"
if [ -f "${QCA_NSS_DRV_MK}" ]; then
    # 删除旧的RMNET ifndef~endif代码块
    sed -i '/ifndef CONFIG_NSS_DRV_RMNET_ENABLE/,/endif/d' "${QCA_NSS_DRV_MK}"
    # 插入完整正确代码块
    sed -i '/CONFIG_NSS_DRV_RMNET_ENABLE/a\
ifndef CONFIG_NSS_DRV_RMNET_ENABLE\
   DRV_MAKE_OPTS += NSS_DRV_RMNET_ENABLE=n\
else\
   DRV_MAKE_OPTS += NSS_DRV_RMNET_ENABLE=y\
endif' "${QCA_NSS_DRV_MK}"
    echo "✅ qca-nss-drv RMNET patch done"
else
    echo "⚠️ qca-nss-drv Makefile not found, skip"
fi

QCA_NSS_ECM_MK="feeds/nss_packages/qca-nss-ecm/Makefile"
if [ -f "${QCA_NSS_ECM_MK}" ]; then
    # ECM开启RMNET
    sed -i 's/ECM_INTERFACE_RMNET_ENABLE=n/ECM_INTERFACE_RMNET_ENABLE=y/' "${QCA_NSS_ECM_MK}"
    echo "✅ qca-nss-ecm RMNET patch done"
else
    echo "⚠️ qca-nss-ecm Makefile not found, skip"
fi

# ========== 修复 nss-ifb 编译时序，解决头文件缺失 ==========
NSS_IFB_MK="feeds/nss_packages/nss-ifb/Makefile"
if [ -f "${NSS_IFB_MK}" ]; then
    # 防止重复添加PKG_BUILD_DEPENDS
    if ! grep -q "PKG_BUILD_DEPENDS:=qca-nss-drv" "${NSS_IFB_MK}"; then
        sed -i '/PKG_RELEASE:=3/a \
PKG_BUILD_DEPENDS:=qca-nss-drv' "${NSS_IFB_MK}"
        echo "✅ patched nss-ifb PKG_BUILD_DEPENDS"
    else
        echo "ℹ️ nss-ifb PKG_BUILD_DEPENDS already exists, skip"
    fi
else
    echo "⚠️ nss-ifb Makefile not found, skip nss-ifb patch"
fi

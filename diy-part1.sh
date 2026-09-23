#!/bin/bash
# Runs before feeds update. Add custom feeds from custom-feeds.conf
set -e

echo "Using official ImmortalWrt feeds, loading custom feeds..."
if [ -f "$GITHUB_WORKSPACE/custom-feeds.conf" ];then
  cat "$GITHUB_WORKSPACE/custom-feeds.conf" >> feeds.conf.default
fi

# 1. 拉取feeds源码
./scripts/feeds update -a

# ========== 【重点】所有sed补丁移到 feeds update之后，feeds install之前 ==========
# ========== 方案A：qca-nss-drv RMNET补丁 ==========
QCA_NSS_DRV_MK="feeds/nss_packages/qca-nss-drv/Makefile"
if [ -f "${QCA_NSS_DRV_MK}" ]; then
    # 先清理旧损坏块
    sed -i '/ifndef CONFIG_NSS_DRV_RMNET_ENABLE/,/endif/d' "${QCA_NSS_DRV_MK}"
    # 插入条件块，改用分隔符避免换行bug
    sed -i '/CONFIG_NSS_DRV_RMNET_ENABLE/a \
ifndef CONFIG_NSS_DRV_RMNET_ENABLE \
  DRV_MAKE_OPTS += NSS_DRV_RMNET_ENABLE=n \
else \
  DRV_MAKE_OPTS += NSS_DRV_RMNET_ENABLE=y \
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

# ========== nss-ifb 暂时注释，不用管 ==========
# NSS_IFB_MK="feeds/nss_packages/nss-ifb/Makefile"
# if [ -f "${NSS_IFB_MK}" ]; then
#     # 防止重复添加PKG_BUILD_DEPENDS
#     if ! grep -q "PKG_BUILD_DEPENDS:=qca-nss-drv" "${NSS_IFB_MK}"; then
#         sed -i '/PKG_RELEASE:=3/a \
# PKG_BUILD_DEPENDS:=qca-nss-drv' "${NSS_IFB_MK}"
#         echo "✅ patched nss-ifb PKG_BUILD_DEPENDS"
#     else
#         echo "ℹ️ nss-ifb PKG_BUILD_DEPENDS already exists, skip"
#     fi
# else
#     echo "⚠️ nss-ifb Makefile not found, skip nss-ifb patch"
# fi

# 2. 打完所有补丁之后，再执行 feeds install
./scripts/feeds install -a

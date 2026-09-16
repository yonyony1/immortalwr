# ImmortalWrt Arthur (JDCloud RE-SS-01)

京东云亚瑟自定义 ImmortalWrt 云编译。基于官方 `immortalwrt/immortalwrt` master，给 USB 随身 WiFi 当 WAN 用，再从亚瑟发出 Wi-Fi。

## 刷机

1. 等 GitHub Actions 编译完成，到 [Releases](../../releases) 或 Actions Artifacts 下载
   `immortalwrt-qualcommax-ipq60xx-jdcloud_re-ss-01-squashfs-sysupgrade.bin`
2. 打开 `http://192.168.1.1` -> 系统 -> 备份/升级
3. 第一次建议 **不保留配置** 再刷，避免旧的 USB 网口绑定把新脚本冲掉
4. 刷完后用网线或默认 Wi-Fi 进后台

## 默认设置

- 主题：LuCI Bootstrap（和你现在截图同一套）
- 语言：中文
- 时区：Asia/Shanghai
- 管理地址：`192.168.1.1`
- Wi-Fi：`Arthur` / `Arthur-5G`
- Wi-Fi 密码：`12345678`（进后台改掉）

## USB 随身 WiFi

插上后系统会把 RNDIS / CDC 网卡绑成固定接口 `usbwan`，当作一条网线。后台网络里看到 `usbwan` 即可。

如果接口又没了，先拔插随身 WiFi。固件里有热插拔脚本和 watchdog，会尝试重新识别并复位 USB 网卡。

4G/5G 模块（QMI / MBIM / NCM）驱动和协议页也装了。这类设备不要走 DHCP 的 `usbwan`，在网络接口里选对应协议。

## 重新编译

工作流文件在 `workflow/build.yml`。GitHub 需要它位于 `.github/workflows/build.yml` 才会开始云编译。

如果 Actions 还没出现，在仓库网页新建文件 `.github/workflows/build.yml`，把 `workflow/build.yml` 的内容贴进去并提交。随后打开 Actions -> **Build ImmortalWrt** -> Run workflow。

改 `.config`、`files/` 或 diy 脚本并推到 `main` 也会自动编。

不装 iStore、插件商店和科学上网全家桶。要加包，把 `CONFIG_PACKAGE_xxx=y` 写进 `.config` 再编一次。

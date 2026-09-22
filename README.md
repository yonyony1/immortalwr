# ImmortalWrt (JDCloud RE-SS-01)

京东云亚瑟自定义 ImmortalWrt 云编译。基于官方 `immortalwrt/immortalwrt` master，给USB随身WiFi和4g/5g模块把usb口当WAN用，再从亚瑟发出 Wi-Fi。

## 刷机

1. 到 [Releases](../../releases) 下载
   `*squashfs-factory.bin`
2. 电脑网线接亚瑟LAN口。按住Reset上电，灯闪几下后常亮，浏览器打开
   [http://192.168.1.1](http://192.168.1.1)
3. 只在固件页上传 `*squashfs-factory.bin`。不要打开这些页面：
   - `/uimage.html`：只启动内存系统，重启就没了
   - `/img.html`：刷分区表，不是固件
   - `/uboot.html`：刷 U-Boot 本身
4. openwrt类可以用 `*squashfs-sysupgrade.bin` 从 LuCI 升级。

## 默认设置

- 主题：LuCI Bootstrap
- 语言：中文
- 时区：Asia/Shanghai
- 管理地址：`192.168.1.1`

## USB 随身 WiFi

插上后系统会把 RNDIS / CDC 网卡绑成固定接口 `usbwan`，当作一条网线。后台网络里看到 `usbwan` 即可。

如果接口又没了，先拔插随身 WiFi。固件里有热插拔脚本和 watchdog，会尝试重新识别并复位 USB 网卡。

支持qmodem管理器
4G/5G 模块（QMI / MBIM / NCM）驱动和协议页也装了。这类设备不要走 DHCP 的 `usbwan`，在网络接口里选对应协议。

## 重新编译
打开 Actions -> **Build ImmortalWrt** -> Run workflow。

改 `.config`、`files/` 或 diy 脚本并推到 `main` 也会自动编。

不装 iStore、插件商店和科学上网全家桶。要加包，把 `CONFIG_PACKAGE_xxx=y` 写进 `.config` 再编一次。

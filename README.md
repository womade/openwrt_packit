这是 Flippy 的 Openwrt 打包源码，主要用于制作 Phicomm N1、贝壳云、我家云、微加云、Amlogic S905x3、Amlogic S922x等一系列盒子的 openwrt固件。

一、制作材料：
1. Flippy预编译好的 Arm64 内核 (在 https://t.me/openwrt_flippy  及 https://pan.baidu.com/s/1tY_-l-Se2qGJ0eKl7FZBuQ 提取码：846l)
2. 自己编译的 openwrt rootfs tar.gz 包： openwrt-armvirt-64-default-rootfs.tar.gz , openwrt的源码仓库首选 (https://github.com/coolsnowwolf/lede)  ，当然也可以采用其它第三方源，例如 (https://github.com/Lienol/openwrt) , 也可以采用 openwrt 官方源： (https://github.com/openwrt/openwrt)。

二、环境准备
1. 需要一台 linux 主机， 可以是 x86或arm64架构，可以是物理机或虚拟机（但不支持win10自带的linux环境），需要具备root权限， 并且具备以下基本命令（只列出命令名，不列出命令所在的包名，因不同linux发行版的软件包名、软件包安装命令各有不同，请自己查询)： 
    losetup、lsblk(版本>=2.33)、blkid、uuidgen、fdisk、parted、mkfs.vfat、mkfs.ext4、mkfs.btrfs (列表不一定完整，打包过程中若发生错误，请自行检查输出结果并添加缺失的命令）
    
2. 需要把 Flippy预编译好的 Arm64 内核上传至 /opt/kernel目录（目录需要自己创建）
3. cd  /opt   
   git clone https://github.com/unifreq/openwrt_packit     
4. 把编译好的 openwrt-armvirt-64-default-rootfs.tar.gz 上传至 /opt/openwrt_packit目录中
5. cd /opt/openwrt_packit

   ./mk_xxx.sh  # xxx指代你想要生成的固件类别，例如： ./mk_s905d_n1.sh 表示生成 Phicomm N1所用的固件

   生成好的固件是 .img 格式， 存放在 /opt/openwrt_packit/output 目录中，下载刷机即可
   
   提示:工作临时目录是 /opt/openwrt_packit/tmp, 为了提升IO性能，减少硬盘损耗，可以采用tmpfs文件系统挂载到该目录，最多会占用 1GB 内存， 挂载方法如下:
   ```
   # 开机自动挂载
   echo "none /opt/openwrt_packit/tmp  tmpfs   defaults   0  0" >> /etc/fstab
   mount /opt/openwrt_packit/tmp
   ```
    或者
    ```
    # 手动挂载
    mount -t tmpfs  none /opt/openwrt_packit/tmp
    ```
   
   相关的在线升级脚本在 files/目录下

   相关的 openwrt 示例配置文件在 files/openwrt_config_demo/目录下
6. openwrt rootfs 编译注意事项：

       Target System  ->  QEMU ARM Virtual Machine 
       Subtarget ->  QEMU ARMv8 Virtual Machine (cortex-a53)
       Target Profile  ->  Default
       Target Images  ->   tar.gz
       *** 必选软件包(基础依赖包，仅保证打出的包可以写入EMMC,可以在EMMC上在线升级，不包含具体的应用)： 
       Languages -> Perl               
                    ->  perl-http-date
                    ->  perlbase-getopt
                    ->  perlbase-time
                    ->  perlbase-unicode                              
                    ->  perlbase-utf8        
       Utilities -> Disc -> blkid、fdisk、lsblk、parted            
                 -> Filesystem -> attr、btrfs-progs(Build with zstd support)、chattr、dosfstools、
                                  e2fsprogs、f2fs-tools、f2fsck、lsattr、mkf2fs、xfs-fsck、xfs-mkfs
                 -> Compression -> bsdtar 或 p7zip(非官方源)、pigz
                 -> Shells  ->  bash         
                 -> gawk、getopt、losetup、tar、uuidgen

        * (可选)Wifi基础包：
        *     打出的包可支持博通SDIO无线模块,Firmware不用选，
        *     因为打包源码中已经包含了来自Armbian的firmware，
        *     会自动覆盖openwrt rootfs中已有的firmware
        Kernel modules  ->   Wireless Drivers -> kmod-brcmfmac(SDIO) 
                                              -> kmod-brcmutil
                                              -> kmod-cfg80211
                                              -> kmod-mac80211
        Network  ->  WirelessAPD -> hostapd-common
                                 -> wpa-cli
                                 -> wpad-basic
                 ->  iw
       
    
    除上述必选项以外的软件包可以按需自主选择。
                 
三、其它相关信息请参见我在恩山论坛的贴子：

https://www.right.com.cn/forum/thread-981406-1-1.html

https://www.right.com.cn/forum/thread-4055451-1-1.html

https://www.right.com.cn/forum/thread-4076037-1-1.html

四、TG群友打包的固件地址

暴躁老哥：
https://github.com/breakings/OpenWrt

有一妙计：
https://github.com/HoldOnBro/Actions-OpenWrt/

诸葛先生：
https://github.com/hibuddies/openwrt/

那坨：
https://github.com/Netflixxp/N1HK1dabao

五、Github Actions 打包使用方法
    actions 源码来自 https://github.com/ophub (smith1998)，主脚本为 openwrt_flippy.sh  

在 `.github/workflows/*.yml` 云编译脚本中引入此 Actions 即可使用。详细使用说明：[README.ACTION.md](README.ACTION.md)

```yaml

- name: Package Armvirt as OpenWrt
  uses: unifreq/openwrt_packit@master
  env:
    OPENWRT_ARMVIRT: openwrt/bin/targets/*/*/*.tar.gz
    PACKAGE_SOC: s905d_s905x3_beikeyun
    KERNEL_VERSION_NAME: 5.13.2_5.4.132

```
六、采用 luci-app-amlogic 在线升级
   
   luci-app-amlogic 源码来自 https://github.com/ophub/luci-app-amlogic (smith1998)， 可以集成到openwrt固件中，并与本打包源码紧密结合，可实现在线升级内核和在线升级完整固件。

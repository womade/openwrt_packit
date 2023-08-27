#!/bin/bash

# 克隆源码
git clone https://github.com/unifreq/openwrt_packit packit
mv -n packit/* ./ ; rm -Rf packit

# 修改作者
sed -i 's/ophub/womade/g' action.yml

# 自定义 banner
wget https://github.com/womade/LEDE_actions/raw/main/modify/etc/banner -O files/banner
sed -i '/Base on OpenWrt/,+5d' public_funcs

# 修改仓库
sed -i 's/unifreq/womade/g' openwrt_flippy.sh
sed -i 's/master/main/g' openwrt_flippy.sh

# WHOAMI
sed -i 's/flippy/Y-ZHENG/g' openwrt_flippy.sh

# 修改内核&版本号
sed -i 's|OPENWRT_VER=".*"|OPENWRT_VER="'SN-$(date +%y.%m)'"|g' make.env
sed -i 's/flippy/yuanzheng/g' make.env


sed -i 's|DISTRIB_REVISION_VALUE=".*"|DISTRIB_REVISION_VALUE="'SN-$(date +%y.%m)'"|g' openwrt_flippy.sh
sed -i 's|DISTRIB_DESCRIPTION_VALUE="OpenWrt"|DISTRIB_DESCRIPTION_VALUE="'SuperNet'"|g' openwrt_flippy.sh

exit 0

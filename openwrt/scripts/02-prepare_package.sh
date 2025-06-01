#!/bin/bash -e

# golang - 1.24
rm -rf feeds/packages/lang/golang
pkg_golang=$(curl -s https://github.com/pmkol/openwrt-gh-action-sdk/commit/a67931ef2b14e7c4cf632f277a2263d9c61f980f.patch | awk '/^\+.*packages_lang_golang/ {sub(/^\+/, ""); print}' | sed -n 's/.*git clone https:\/\/github.com\/\(.*\) feeds\/packages\/lang\/golang/\1/p')
git clone https://$github/$pkg_golang --depth 1 feeds/packages/lang/golang
[ "$DEV_BUILD" = "y" ] && sed -i 's/GO_AMD64:=v1/GO_AMD64:=v2/g' feeds/packages/lang/golang/golang-values.mk

# node - prebuilt
rm -rf feeds/packages/lang/node/*
curl -s https://$mirror/openwrt/patch/node/Makefile > feeds/packages/lang/node/Makefile

# boost - bump version
rm -rf feeds/packages/libs/boost
cp -a ../master/packages/libs/boost feeds/packages/libs/boost

# default settings
git clone https://$github/pmkol/default-settings package/new/default-settings -b lite --depth 1
[ "$OPKG_PROXY" = "y" ] && sed -i 's#openwrt-lite.pages.dev/openwrt#git.apad.pro/https://raw.githubusercontent.com/pmkol/openwrt-feeds/opkg-repo/openwrt#g' package/new/default-settings/default/zzz-default-settings

# luci - replace version with build date
[ "$NO_APPS" != "y" ] && sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-23.05\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI openwrt-23.05'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/new/default-settings/default/zzz-default-settings

# coremark - prebuilt
rm -rf feeds/packages/utils/coremark
if [ "$platform" = "rk3568" ]; then
    curl -s https://$mirror/openwrt/patch/coremark/coremark.aarch64-4-threads > ../master/extd-23.05/coremark/src/musl/coremark.aarch64
elif [ "$platform" = "rk3399" ]; then
    curl -s https://$mirror/openwrt/patch/coremark/coremark.aarch64-6-threads > ../master/extd-23.05/coremark/src/musl/coremark.aarch64
fi

# haproxy - bump version
rm -rf feeds/packages/net/haproxy
mv ../master/lite-23.05/haproxy feeds/packages/net/haproxy
sed -i '/ADDON+=USE_QUIC_OPENSSL_COMPAT=1/d' feeds/packages/net/haproxy/Makefile

# mihomo - prebuilt
if curl -s "https://$mirror/openwrt/23-config-common-$cfg_ver" | grep -q "^CONFIG_PACKAGE_luci-app-nikki=y" && [ "$NO_APPS" != "y" ]; then
    mkdir -p files/etc/nikki/run
    if [ "$MINIMAL_BUILD" = "y" ]; then
        curl -Lso files/etc/nikki/run/GeoSite.dat https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
        curl -Lso files/etc/nikki/run/GeoIP.dat https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat
    fi
    curl -Lso files/etc/nikki/run/geoip.metadb https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.metadb
    curl -Lso files/etc/nikki/run/ASN.mmdb https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/GeoLite2-ASN.mmdb
    curl -Lso dist.zip https://$github/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip
    unzip dist.zip
    rm -f dist.zip
    mv dist files/etc/nikki/run/ui
fi

# net-snmp & collectd & rrdtool1 - bump version
rm -rf feeds/packages/net/net-snmp
mv ../master/extd-23.05/net-snmp feeds/packages/net/net-snmp
rm -rf feeds/packages/utils/{collectd,rrdtool1}
mv ../master/extd-23.05/collectd feeds/packages/utils/collectd
mv ../master/extd-23.05/rrdtool1 feeds/packages/utils/rrdtool1

# irqbalance - disable build with numa
if [ "$ENABLE_DPDK" = "y" ]; then
    curl -s https://$mirror/openwrt/patch/irqbalance/011-meson-numa.patch > feeds/packages/utils/irqbalance/patches/011-meson-numa.patch
    sed -i '/-Dcapng=disabled/i\\t-Dnuma=disabled \\' feeds/packages/utils/irqbalance/Makefile
fi

# openssh - bump version
rm -rf feeds/packages/net/openssh
mv ../master/extd-23.05/openssh feeds/packages/net/openssh

# passwall - disable run new dnsmasq
[ "$DEV_BUILD" = "y" ] && sed -i 's/local RUN_NEW_DNSMASQ=1/local RUN_NEW_DNSMASQ=0/' ../master/lite-23.05/luci-app-passwall/root/usr/share/passwall/app.sh

# samba4
rm -rf feeds/packages/{net/samba4,libs/liburing} feeds/luci/applications/luci-app-samba4
# rk3568 bind cpus
[ "$platform" = "rk3568" ] && sed -i 's#/usr/sbin/smbd -F#/usr/bin/taskset -c 1,0 /usr/sbin/smbd -F#' ../master/extd-23.05/samba4/files/samba.init

# sqm - translation
mkdir -p feeds/packages/net/sqm-scripts/patches
curl -s https://$mirror/openwrt/patch/sqm/001-help-translation.patch > feeds/packages/net/sqm-scripts/patches/001-help-translation.patch

# tailscale - prebuilt
if curl -s "https://$mirror/openwrt/23-config-common-$cfg_ver" | grep -q "^CONFIG_PACKAGE_luci-app-tailscale=y" && [ "$NO_APPS" != "y" ]; then
    mkdir -p files/etc/hotplug.d/iface
    curl -s https://$mirror/openwrt/files/etc/hotplug.d/iface/90-tailscale > files/etc/hotplug.d/iface/90-tailscale
fi

# theme - copyright link
sed -i 's/openwrt\/luci/pmkol\/openwrt-lite/g' ../master/extd-23.05/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i 's/openwrt\/luci/pmkol\/openwrt-lite/g' ../master/extd-23.05/luci-theme-argon/luasrc/view/themes/argon/footer_login.htm
sed -i 's/openwrt\/luci/pmkol\/openwrt-lite/g' feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/footer.ut
sed -i 's/openwrt\/luci/pmkol\/openwrt-lite/g' feeds/luci/themes/luci-theme-material/ucode/template/themes/material/footer.ut
sed -i 's/openwrt\/luci/pmkol\/openwrt-lite/g' feeds/luci/themes/luci-theme-openwrt-2020/ucode/template/themes/openwrt2020/footer.ut

# ttyd
rm -rf feeds/luci/applications/luci-app-ttyd
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

# watchcat - clean config
true > feeds/packages/utils/watchcat/files/watchcat.config

# clean up old feeds
rm -rf feeds/luci/applications/{luci-app-aria2,luci-app-frpc,luci-app-frps,luci-app-hd-idle,luci-app-ksmbd,luci-app-natmap,luci-app-nlbwmon,luci-app-smartdns,luci-app-upnp}
rm -rf feeds/packages/admin/netdata
rm -rf feeds/packages/net/{adguardhome,aria2,ddns-scripts,frp,iperf3,ksmbd-tools,microsocks,miniupnpd,nlbwmon,xray-core,v2ray-core,v2ray-geodata,sing-box,shadowsocks-libev,smartdns,tailscale,zerotier}
rm -rf feeds/packages/utils/{lsof,screen,unzip,vim,zstd}

# extd-23.05
mv ../master/extd-23.05 package/new/extd

# lite-23.05
mv ../master/lite-23.05 package/new/lite

#!/bin/bash -e

# Fix build for linux-6.11

# cryptodev-linux
CRYPTODEV_VERSION=1.13
CRYPTODEV_HASH=33b7915c46eb39a37110e88c681423c0dd0df25d784b6e1475ac3196367f0db5
sed -ri "s/(PKG_VERSION:=)[^\"]*/\1$CRYPTODEV_VERSION/;s/(PKG_HASH:=)[^\"]*/\1$CRYPTODEV_HASH/" package/kernel/cryptodev-linux/Makefile
mkdir -p package/kernel/cryptodev-linux/patches
curl -s https://$mirror/openwrt/patch/packages-patches/cryptodev-linux/0001-cryptodev_verbosity-fix-build-for-linux-6.4.patch > package/kernel/cryptodev-linux/patches/0001-cryptodev_verbosity-fix-build-for-linux-6.4.patch
curl -s https://$mirror/openwrt/patch/packages-patches/cryptodev-linux/0002-zero-copy-fix-build-for-linux-6.4.patch > package/kernel/cryptodev-linux/patches/0002-zero-copy-fix-build-for-linux-6.4.patch
curl -s https://$mirror/openwrt/patch/packages-patches/cryptodev-linux/0003-move-recent-linux-version-ifdefs-from-v6.4-to-v6.5.patch > package/kernel/cryptodev-linux/patches/0003-move-recent-linux-version-ifdefs-from-v6.4-to-v6.5.patch
curl -s https://$mirror/openwrt/patch/packages-patches/cryptodev-linux/0004-fix-build-for-linux-6.7-rc1.patch > package/kernel/cryptodev-linux/patches/0004-fix-build-for-linux-6.7-rc1.patch
curl -s https://$mirror/openwrt/patch/packages-patches/cryptodev-linux/0005-Fix-cryptodev_verbosity-sysctl-for-Linux-6.11-rc1.patch > package/kernel/cryptodev-linux/patches/0005-Fix-cryptodev_verbosity-sysctl-for-Linux-6.11-rc1.patch
curl -s https://$mirror/openwrt/patch/packages-patches/cryptodev-linux/0006-Exclude-unused-struct-since-Linux-6.5.patch > package/kernel/cryptodev-linux/patches/0006-Exclude-unused-struct-since-Linux-6.5.patch

# gpio-button-hotplug
curl -s https://$mirror/openwrt/patch/packages-patches/gpio-button-hotplug/fix-linux-6.6.patch | patch -p1
curl -s https://$mirror/openwrt/patch/packages-patches/gpio-button-hotplug/fix-linux-6.11.patch | patch -p1

# gpio-nct5104d
curl -s https://$mirror/openwrt/patch/packages-patches/gpio-nct5104d/fix-build-for-linux-6.6.patch | patch -p1
curl -s https://$mirror/openwrt/patch/packages-patches/gpio-nct5104d/fix-build-for-linux-6.11.patch | patch -p1

# dmx_usb_module
curl -s https://$mirror/openwrt/patch/packages-patches/dmx_usb_module/900-fix-linux-6.6.patch > feeds/packages/libs/dmx_usb_module/patches/900-fix-linux-6.6.patch
[ "$KERNEL_CLANG_LTO" = "y" ] && curl -s https://$mirror/openwrt/patch/packages-patches/dmx_usb_module/Makefile > feeds/packages/libs/dmx_usb_module/Makefile

# jool
curl -s https://$mirror/openwrt/patch/packages-patches/jool/Makefile > feeds/packages/net/jool/Makefile

# mdio-netlink
mkdir -p feeds/packages/kernel/mdio-netlink/patches
curl -s https://$mirror/openwrt/patch/packages-patches/mdio-netlink/001-mdio-netlink-rework-C45-to-work-with-net-next.patch > feeds/packages/kernel/mdio-netlink/patches/001-mdio-netlink-rework-C45-to-work-with-net-next.patch

# ovpn-dco
mkdir -p feeds/packages/kernel/ovpn-dco/patches
curl -s https://$mirror/openwrt/patch/packages-patches/ovpn-dco/100-ovpn-dco-adapt-pre-post_doit-CBs-to-new-signature.patch > feeds/packages/kernel/ovpn-dco/patches/100-ovpn-dco-adapt-pre-post_doit-CBs-to-new-signature.patch
curl -s https://$mirror/openwrt/patch/packages-patches/ovpn-dco/900-fix-linux-6.6.patch > feeds/packages/kernel/ovpn-dco/patches/900-fix-linux-6.6.patch
curl -s https://$mirror/openwrt/patch/packages-patches/ovpn-dco/901-fix-linux-6.11.patch > feeds/packages/kernel/ovpn-dco/patches/901-fix-linux-6.11.patch

# libpfring
rm -rf feeds/packages/libs/libpfring
mkdir -p feeds/packages/libs/libpfring/patches
curl -s https://$mirror/openwrt/patch/packages-patches/libpfring/Makefile > feeds/packages/libs/libpfring/Makefile
pushd feeds/packages/libs/libpfring/patches
  curl -Os https://$mirror/openwrt/patch/packages-patches/libpfring/patches/0001-fix-cross-compiling.patch
  curl -Os https://$mirror/openwrt/patch/packages-patches/libpfring/patches/010-gcc14.patch
  curl -Os https://$mirror/openwrt/patch/packages-patches/libpfring/patches/100-fix-compilation-warning.patch
  curl -Os https://$mirror/openwrt/patch/packages-patches/libpfring/patches/101-kernel-pf_ring-better-define-sa_data-size.patch
  curl -Os https://$mirror/openwrt/patch/packages-patches/libpfring/patches/102-remove-sendpage.patch
popd

# nat46
mkdir -p package/kernel/nat46/patches
curl -s https://$mirror/openwrt/patch/packages-patches/nat46/100-fix-build-with-kernel-6.9.patch > package/kernel/nat46/patches/100-fix-build-with-kernel-6.9.patch

# v4l2loopback - 6.11
mkdir -p feeds/packages/kernel/v4l2loopback/patches
curl -s https://$mirror/openwrt/patch/packages-patches/v4l2loopback/100-fix-build-with-linux-6.11.patch > feeds/packages/kernel/v4l2loopback/patches/100-fix-build-with-linux-6.11.patch

# openvswitch
sed -i '/ovs_kmod_openvswitch_depends/a\\t\ \ +kmod-sched-act-sample \\' feeds/packages/net/openvswitch/Makefile

# ubootenv-nvram - 6.11 (openwrt-23.05.5)
mkdir -p package/kernel/ubootenv-nvram/patches
curl -s https://$mirror/openwrt/patch/packages-patches/ubootenv-nvram/010-make-ubootenv_remove-return-void-for-linux-6.11.patch > package/kernel/ubootenv-nvram/patches/010-make-ubootenv_remove-return-void-for-linux-6.11.patch

# xr_usb_serial_common
curl -s https://$mirror/openwrt/patch/packages-patches/xr_usb_serial_common/0001-xr_usb-kernel-6.1-compile-fix.patch > feeds/packages/libs/xr_usb_serial_common/patches/0001-xr_usb-kernel-6.1-compile-fix.patch
curl -s https://$mirror/openwrt/patch/packages-patches/xr_usb_serial_common/900-fix-linux-6.6.patch > feeds/packages/libs/xr_usb_serial_common/patches/900-fix-linux-6.6.patch

# coova-chilli
curl -s https://$mirror/openwrt/patch/packages-patches/coova-chilli/011-kernel517.patch > feeds/packages/net/coova-chilli/patches/011-kernel517.patch
curl -s https://$mirror/openwrt/patch/packages-patches/coova-chilli/020-libxt_coova-Use-constructor-instead-of-_init.patch > feeds/packages/net/coova-chilli/patches/020-libxt_coova-Use-constructor-instead-of-_init.patch
[ "$KERNEL_CLANG_LTO" = "y" ] && curl -s https://$mirror/openwrt/patch/packages-patches/coova-chilli/Makefile > feeds/packages/net/coova-chilli/Makefile

# xtables-addons
curl -s https://$mirror/openwrt/patch/packages-patches/xtables-addons/202-fix-lua-packetscript-for-linux-6.6.patch > feeds/packages/net/xtables-addons/patches/202-fix-lua-packetscript-for-linux-6.6.patch
curl -s https://$mirror/openwrt/patch/packages-patches/xtables-addons/301-fix-build-with-linux-6.11.patch > feeds/packages/net/xtables-addons/patches/301-fix-build-with-linux-6.11.patch
curl -s https://$mirror/openwrt/patch/packages-patches/xtables-addons/900-mconfig.patch > feeds/packages/net/xtables-addons/patches/900-mconfig.patch
[ "$KERNEL_CLANG_LTO" = "y" ] && curl -s https://$mirror/openwrt/patch/packages-patches/xtables-addons/Makefile > feeds/packages/net/xtables-addons/Makefile

# dahdi-linux
rm -rf feeds/telephony/libs/dahdi-linux
git clone https://$github/pmkol/telephony_libs_dahdi-linux feeds/telephony/libs/dahdi-linux --depth 1

# routing - batman-adv
rm -rf feeds/routing/batman-adv
cp -a ../master/routing/batman-adv feeds/routing/batman-adv

if [ "$KERNEL_CLANG_LTO" = "y" ]; then
    # netatop
    sed -i 's/$(MAKE)/$(KERNEL_MAKE)/g' feeds/packages/admin/netatop/Makefile
    curl -s https://$mirror/openwrt/patch/packages-patches/netatop/900-fix-build-with-clang.patch > feeds/packages/admin/netatop/patches/900-fix-build-with-clang.patch
    # macremapper
    curl -s https://$mirror/openwrt/patch/packages-patches/macremapper/0001-macremapper-fix-clang-build.patch | patch -p1
fi

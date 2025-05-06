#!/bin/bash -e

# OpenWrt - reserve source
sed -i '/mirror2.openwrt.org/a\push @mirrors, '\''https://mirror.apad.pro/sources'\'';' scripts/download.pl

# Rockchip - rkbin & u-boot
if [ "$platform" != "x86_64" ]; then
    rm -rf package/boot/uboot-rockchip package/boot/arm-trusted-firmware-rockchip
    if [ "$platform" = "rk3568" ]; then
        git clone https://$github/pmkol/package_boot_uboot-rockchip package/boot/uboot-rockchip -b v2024.04 --depth 1
        git clone https://$github/pmkol/arm-trusted-firmware-rockchip package/boot/arm-trusted-firmware-rockchip -b 240222 --depth 1
    else
        git clone https://$github/pmkol/package_boot_uboot-rockchip package/boot/uboot-rockchip -b v2023.04 --depth 1
        git clone https://$github/pmkol/arm-trusted-firmware-rockchip package/boot/arm-trusted-firmware-rockchip -b 230419 --depth 1
    fi
fi

######## OpenWrt Patches ########

# tools: add llvm/clang toolchain
curl -s https://$mirror/openwrt/patch/generic/0001-tools-add-llvm-clang-toolchain.patch | patch -p1

# tools: add upx tools
curl -s https://$mirror/openwrt/patch/generic/0002-tools-add-upx-tools.patch | patch -p1

# rootfs: upx compression
# include/rootfs.mk
curl -s https://$mirror/openwrt/patch/generic/0003-rootfs-add-upx-compression-support.patch | patch -p1

# rootfs: add r/w (0600) permissions for UCI configuration files
# include/rootfs.mk
curl -s https://$mirror/openwrt/patch/generic/0004-rootfs-add-r-w-permissions-for-UCI-configuration-fil.patch | patch -p1

# rootfs: Add support for local kmod installation sources
curl -s https://$mirror/openwrt/patch/generic/0005-rootfs-Add-support-for-local-kmod-installation-sourc.patch | patch -p1

# BTF: fix failed to validate module
# config/Config-kernel.in patch
curl -s https://$mirror/openwrt/patch/generic/0006-kernel-add-MODULE_ALLOW_BTF_MISMATCH-option.patch | patch -p1

# kernel: Add support for llvm/clang compiler
curl -s https://$mirror/openwrt/patch/generic/0007-kernel-Add-support-for-llvm-clang-compiler.patch | patch -p1

# toolchain: Add libquadmath to the toolchain
curl -s https://$mirror/openwrt/patch/generic/0008-libquadmath-Add-libquadmath-to-the-toolchain.patch | patch -p1

# build: kernel: add out-of-tree kernel config
if [ "$CLANG_LTO_THIN" = "y" ]; then
    curl -s https://$mirror/openwrt/patch/generic/0009-build-kernel-add-out-of-tree-kernel-config-thin.patch | patch -p1
else
    curl -s https://$mirror/openwrt/patch/generic/0009-build-kernel-add-out-of-tree-kernel-config.patch | patch -p1
fi

# kernel: linux-6.11 config
curl -s https://$mirror/openwrt/patch/generic/0010-include-kernel-add-miss-config-for-linux-6.11.patch | patch -p1

# meson: add platform variable to cross-compilation file
curl -s https://$mirror/openwrt/patch/generic/0011-meson-add-platform-variable-to-cross-compilation-fil.patch | patch -p1

# kernel: enable Multi-Path TCP
curl -s https://$mirror/openwrt/patch/generic/0012-kernel-enable-Multi-Path-TCP-for-SMALL_FLASH-targets.patch | patch -p1

# mold
if [ "$ENABLE_MOLD" = "y" ]; then
    curl -s https://$mirror/openwrt/patch/generic/mold/0001-build-add-support-to-use-the-mold-linker-for-package.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/generic/mold/0002-treewide-opt-out-of-tree-wide-mold-usage.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/generic/mold/0003-toolchain-add-mold-as-additional-linker.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/generic/mold/0004-tools-add-mold-a-modern-linker.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/generic/mold/0005-build-replace-SSTRIP_ARGS-with-SSTRIP_DISCARD_TRAILI.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/generic/mold/0006-config-add-a-knob-to-use-the-mold-linker-for-package.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/generic/mold/0007-rules-prepare-to-use-different-linkers.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/generic/mold/0008-tools-mold-update-to-2.34.1.patch | patch -p1
    # no-mold
    sed -i '/PKG_BUILD_PARALLEL/aPKG_BUILD_FLAGS:=no-mold' feeds/packages/utils/attr/Makefile
fi

######## OpenWrt Patches End ########

# dwarves: Fix a dwarf type DW_ATE_unsigned_1024 to btf encoding issue
mkdir -p tools/dwarves/patches
curl -s https://$mirror/openwrt/patch/openwrt-6.x/dwarves/100-btf_encoder-Fix-a-dwarf-type-DW_ATE_unsigned_1024-to-btf-encoding-issue.patch > tools/dwarves/patches/100-btf_encoder-Fix-a-dwarf-type-DW_ATE_unsigned_1024-to-btf-encoding-issue.patch

# x86 - disable intel_pstate & mitigations
sed -i 's/noinitrd/noinitrd intel_pstate=disable mitigations=off/g' target/linux/x86/image/grub-efi.cfg

# default LAN IP
sed -i "s/192.168.1.1/$LAN/g" package/base-files/files/bin/config_generate

# GCC Optimization level -O3
if [ "$platform" = "x86_64" ]; then
    curl -s https://$mirror/openwrt/patch/target-modify_for_x86_64.patch | patch -p1
	[ "$DEV_BUILD" = "y" ] && curl -s https://$mirror/openwrt/patch/target-modify_for_x86_64-v2.patch | patch -p1
else
    curl -s https://$mirror/openwrt/patch/target-modify_for_rockchip.patch | patch -p1
fi

# DPDK & NUMACTL
if [ "$ENABLE_DPDK" = "y" ]; then
    mkdir -p package/new/{dpdk/patches,numactl}
    curl -s https://$mirror/openwrt/patch/dpdk/dpdk/Makefile > package/new/dpdk/Makefile
    curl -s https://$mirror/openwrt/patch/dpdk/dpdk/Config.in > package/new/dpdk/Config.in
    curl -s https://$mirror/openwrt/patch/dpdk/dpdk/patches/010-dpdk_arm_build_platform_fix.patch > package/new/dpdk/patches/010-dpdk_arm_build_platform_fix.patch
    curl -s https://$mirror/openwrt/patch/dpdk/dpdk/patches/201-r8125-add-r8125-ethernet-poll-mode-driver.patch > package/new/dpdk/patches/201-r8125-add-r8125-ethernet-poll-mode-driver.patch
    curl -s https://$mirror/openwrt/patch/dpdk/numactl/Makefile > package/new/numactl/Makefile
fi

# Mbedtls AES & GCM Crypto Extensions
if [ ! "$platform" = "x86_64" ]; then
    curl -s https://$mirror/openwrt/patch/mbedtls-23.05/200-Implements-AES-and-GCM-with-ARMv8-Crypto-Extensions.patch > package/libs/mbedtls/patches/200-Implements-AES-and-GCM-with-ARMv8-Crypto-Extensions.patch
    curl -s https://$mirror/openwrt/patch/mbedtls-23.05/0001-mbedtls.patch | patch -p1
fi

# util-linux - ntfs3
UTIL_VERSION=2.39.4
UTIL_HASH=6c4f8723dafd41c39d93ecbf16509fc88c33cd5bd3277880ae5a1d97a014fd0e
sed -ri "s/(PKG_VERSION:=)[^\"]*/\1$UTIL_VERSION/;s/(PKG_HASH:=)[^\"]*/\1$UTIL_HASH/" package/utils/util-linux/Makefile
rm -rf package/utils/util-linux/patches/*
curl -s https://$mirror/openwrt/patch/util-linux/001-meson-properly-handle-gettext-non-existence.patch > package/utils/util-linux/patches/001-meson-properly-handle-gettext-non-existence.patch
curl -s https://$mirror/openwrt/patch/util-linux/002-util-linux_ntfs3.patch > package/utils/util-linux/patches/002-util-linux_ntfs3.patch

# fstools - enable any device with non-MTD rootfs_data volume
sed -i 's|$(PROJECT_GIT)/project|https://github.com/openwrt|g' package/system/fstools/Makefile
curl -s https://$mirror/openwrt/patch/fstools/0001-block-mount-add-fstools-depends.patch | patch -p1
mkdir -p package/system/fstools/patches
curl -s https://$mirror/openwrt/patch/fstools/022-fstools-support-extroot-for-non-MTD-rootfs_data.patch > package/system/fstools/patches/022-fstools-support-extroot-for-non-MTD-rootfs_data.patch
curl -s https://$mirror/openwrt/patch/fstools/200-use-ntfs3-instead-of-ntfs.patch > package/system/fstools/patches/200-use-ntfs3-instead-of-ntfs.patch
curl -s https://$mirror/openwrt/patch/fstools/201-fstools-set-ntfs3-utf8.patch > package/system/fstools/patches/201-fstools-set-ntfs3-utf8.patch

# firewall4 - bump version
rm -rf package/network/config/firewall4 feeds/luci/applications/luci-app-firewall
mv ../master/base-23.05/firewall4 package/network/config/firewall4

# libnftnl
rm -rf package/libs/libnftnl
mv ../master/base-23.05/libnftnl package/libs/libnftnl

# nftables
rm -rf package/network/utils/nftables
mv ../master/base-23.05/nftables package/network/utils/nftables

# iproute2
rm -rf package/network/utils/iproute2
mv ../master/base-23.05/iproute2 package/network/utils/iproute2

# libunwind
rm -rf package/libs/libunwind
mv ../master/base-23.05/libunwind package/libs/libunwind

# openssl - quictls
[ "$DEV_BUILD" = "y" ] && rm -rf package/libs/openssl && cp -a ../master/openwrt-23.05/package/libs/openssl package/libs/openssl
pushd package/libs/openssl/patches
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0001-QUIC-Add-support-for-BoringSSL-QUIC-APIs.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0002-QUIC-New-method-to-get-QUIC-secret-length.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0003-QUIC-Make-temp-secret-names-less-confusing.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0004-QUIC-Move-QUIC-transport-params-to-encrypted-extensi.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0005-QUIC-Use-proper-secrets-for-handshake.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0006-QUIC-Handle-partial-handshake-messages.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0007-QUIC-Fix-quic_transport-constructors-parsers.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0008-QUIC-Reset-init-state-in-SSL_process_quic_post_hands.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0009-QUIC-Don-t-process-an-incomplete-message.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0010-QUIC-Quick-fix-s2c-to-c2s-for-early-secret.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0011-QUIC-Add-client-early-traffic-secret-storage.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0012-QUIC-Add-OPENSSL_NO_QUIC-wrapper.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0013-QUIC-Correctly-disable-middlebox-compat.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0014-QUIC-Move-QUIC-code-out-of-tls13_change_cipher_state.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0015-QUIC-Tweeks-to-quic_change_cipher_state.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0016-QUIC-Add-support-for-more-secrets.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0017-QUIC-Fix-resumption-secret.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0018-QUIC-Handle-EndOfEarlyData-and-MaxEarlyData.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0019-QUIC-Fall-through-for-0RTT.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0020-QUIC-Some-cleanup-for-the-main-QUIC-changes.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0021-QUIC-Prevent-KeyUpdate-for-QUIC.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0022-QUIC-Test-KeyUpdate-rejection.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0023-QUIC-Buffer-all-provided-quic-data.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0024-QUIC-Enforce-consistent-encryption-level-for-handsha.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0025-QUIC-add-v1-quic_transport_parameters.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0026-QUIC-return-success-when-no-post-handshake-data.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0027-QUIC-__owur-makes-no-sense-for-void-return-values.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0028-QUIC-remove-SSL_R_BAD_DATA_LENGTH-unused.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0029-QUIC-SSLerr-ERR_raise-ERR_LIB_SSL.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0030-QUIC-Add-compile-run-time-checking-for-QUIC.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0031-QUIC-Add-early-data-support.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0032-QUIC-Make-SSL_provide_quic_data-accept-0-length-data.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0033-QUIC-Process-multiple-post-handshake-messages-in-a-s.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0034-QUIC-Fix-CI.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0035-QUIC-Break-up-header-body-processing.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0036-QUIC-Don-t-muck-with-FIPS-checksums.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0037-QUIC-Update-RFC-references.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0038-QUIC-revert-white-space-change.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0039-QUIC-use-SSL_IS_QUIC-in-more-places.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0040-QUIC-Error-when-non-empty-session_id-in-CH.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0041-QUIC-Update-SSL_clear-to-clear-quic-data.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0042-QUIC-Better-SSL_clear.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0043-QUIC-Fix-extension-test.patch
    curl -sO https://$mirror/openwrt/patch/openssl/quic/0044-QUIC-Update-metadata-version.patch
popd

# openssl urandom
sed -i "/-openwrt/iOPENSSL_OPTIONS += enable-ktls '-DDEVRANDOM=\"\\\\\"/dev/urandom\\\\\"\"\'\n" package/libs/openssl/Makefile

# openssl - lto
if [ "$ENABLE_LTO" = "y" ]; then
    sed -i "s/ no-lto//g" package/libs/openssl/Makefile
    sed -i "/TARGET_CFLAGS +=/ s/\$/ -ffat-lto-objects/" package/libs/openssl/Makefile
fi

# nghttp3
rm -rf feeds/packages/libs/nghttp3
mv ../master/base-23.05/nghttp3 package/libs/nghttp3

# ngtcp2
rm -rf feeds/packages/libs/ngtcp2
mv ../master/base-23.05/ngtcp2 package/libs/ngtcp2

# curl - fix passwall `time_pretransfer` check
rm -rf feeds/packages/net/curl
mv ../master/base-23.05/curl feeds/packages/net/curl

# libpcap
rm -rf package/libs/libpcap
mv ../master/base-23.05/libpcap package/libs/libpcap

# docker
[ "$DEV_BUILD" = "y" ] && docker_branch=main || docker_branch=openwrt-23.05
rm -rf feeds/{luci/applications/luci-app-dockerman,packages/utils/docker-compose}
mv ../master/extd-23.05/docker-compose feeds/packages/utils/docker-compose
if [ "$MINIMAL_BUILD" != "y" ]; then
    rm -rf feeds/packages/utils/{docker,dockerd,containerd,runc,docker-compose}
    git clone https://$github/pmkol/packages_utils_docker feeds/packages/utils/docker -b $docker_branch --depth 1
    git clone https://$github/pmkol/packages_utils_dockerd feeds/packages/utils/dockerd -b $docker_branch --depth 1
    git clone https://$github/pmkol/packages_utils_containerd feeds/packages/utils/containerd -b $docker_branch --depth 1
    git clone https://$github/pmkol/packages_utils_runc feeds/packages/utils/runc -b $docker_branch --depth 1
    sed -i '/sysctl.d/d' feeds/packages/utils/dockerd/Makefile
fi

# cgroupfs-mount
# fix unmount hierarchical mount
pushd feeds/packages
    curl -s https://$mirror/openwrt/patch/cgroupfs-mount/0001-fix-cgroupfs-mount.patch | patch -p1
popd
# mount cgroup v2 hierarchy to /sys/fs/cgroup/cgroup2
mkdir -p feeds/packages/utils/cgroupfs-mount/patches
curl -s https://$mirror/openwrt/patch/cgroupfs-mount/900-mount-cgroup-v2-hierarchy-to-sys-fs-cgroup-cgroup2.patch > feeds/packages/utils/cgroupfs-mount/patches/900-mount-cgroup-v2-hierarchy-to-sys-fs-cgroup-cgroup2.patch
curl -s https://$mirror/openwrt/patch/cgroupfs-mount/901-fix-cgroupfs-umount.patch > feeds/packages/utils/cgroupfs-mount/patches/901-fix-cgroupfs-umount.patch
# docker systemd support
curl -s https://$mirror/openwrt/patch/cgroupfs-mount/902-mount-sys-fs-cgroup-systemd-for-docker-systemd-suppo.patch > feeds/packages/utils/cgroupfs-mount/patches/902-mount-sys-fs-cgroup-systemd-for-docker-systemd-suppo.patch

# netkit-ftp
mv ../master/base-23.05/ftp package/new/ftp

# nethogs
mv ../master/base-23.05/nethogs package/new/nethogs

# procps-ng - top
sed -i 's/enable-skill/enable-skill --disable-modern-top/g' feeds/packages/utils/procps-ng/Makefile

# opkg - disable hsts
mkdir -p package/system/opkg/patches
curl -s https://$mirror/openwrt/patch/opkg/900-opkg-download-disable-hsts.patch > package/system/opkg/patches/900-opkg-download-disable-hsts.patch

# rpcd - fix timeout
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js

# luci-mod extra
pushd feeds/luci
    curl -s https://$mirror/openwrt/patch/luci/0001-luci-mod-system-add-modal-overlay-dialog-to-reboot.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/luci/0002-luci-mod-status-displays-actual-process-memory-usage.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/luci/0003-luci-mod-status-storage-index-applicable-only-to-val.patch | patch -p1
    [ "$MINIMAL_BUILD" != "y" ] && curl -s https://$mirror/openwrt/patch/luci/0004-luci-mod-status-firewall-disable-legacy-firewall-rul.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/luci/0005-luci-mod-system-add-refresh-interval-setting.patch | patch -p1
    [ "$MINIMAL_BUILD" != "y" ] && curl -s https://$mirror/openwrt/patch/luci/0006-luci-mod-system-mounts-add-docker-directory-mount-po.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/luci/0007-luci-base-correct-textarea-wrap.patch | patch -p1
    curl -s https://$mirror/openwrt/patch/luci/0008-luci-base-cbifileupload-support-file-browser-mode.patch | patch -p1
    curl -s https://$github/openwrt/luci/commit/089903105f4f01135008b8a22557ae998b9303e9.patch | patch -p1
popd

# Luci diagnostics.js
sed -i "s/openwrt.org/www.qq.com/g" feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/diagnostics.js

# luci - drop ethernet port status
rm -f feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/29_ports.js

# luci - rollback dhcp.js
curl -s https://$mirror/openwrt/patch/luci/dhcp/dhcp.js > feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/dhcp.js

# luci - fix compat translation
sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm

# ppp - bump version
rm -rf package/network/services/ppp ../master/base-23.05/ppp
git clone https://$github/pmkol/package_network_services_ppp package/network/services/ppp

# odhcpd RFC-9096
mkdir -p package/network/services/odhcpd/patches
curl -s https://$mirror/openwrt/patch/odhcpd/001-odhcpd-RFC-9096-compliance.patch > package/network/services/odhcpd/patches/001-odhcpd-RFC-9096-compliance.patch
pushd feeds/luci
    curl -s https://$mirror/openwrt/patch/odhcpd/0001-luci-mod-network-add-option-for-ipv6-max-plt-vlt.patch | patch -p1
popd

# zlib - bump version
rm -rf package/libs/zlib
mv ../master/base-23.05/zlib package/libs/zlib

# autocore
git clone https://$github/pmkol/autocore package/system/autocore --depth 1

# profile
sed -i 's#\\u@\\h:\\w\\\$#\\[\\e[32;1m\\][\\u@\\h\\[\\e[0m\\] \\[\\033[01;34m\\]\\W\\[\\033[00m\\]\\[\\e[32;1m\\]]\\[\\e[0m\\]\\\$#g' package/base-files/files/etc/profile
sed -ri 's/(export PATH=")[^"]*/\1%PATH%:\/opt\/bin:\/opt\/sbin:\/opt\/usr\/bin:\/opt\/usr\/sbin/' package/base-files/files/etc/profile
sed -i '/PS1/a\export TERM=xterm-color' package/base-files/files/etc/profile

# bash
sed -i 's#ash#bash#g' package/base-files/files/etc/passwd
sed -i '\#export ENV=/etc/shinit#a export HISTCONTROL=ignoredups' package/base-files/files/etc/profile
mkdir -p files/root
curl -so files/root/.bash_profile https://$mirror/openwrt/files/root/.bash_profile
curl -so files/root/.bashrc https://$mirror/openwrt/files/root/.bashrc

# rootfs files
mkdir -p files/etc/sysctl.d
curl -so files/etc/sysctl.d/15-vm-swappiness.conf https://$mirror/openwrt/files/etc/sysctl.d/15-vm-swappiness.conf
curl -so files/etc/sysctl.d/16-udp-buffer-size.conf https://$mirror/openwrt/files/etc/sysctl.d/16-udp-buffer-size.conf

# NTP
sed -i 's/0.openwrt.pool.ntp.org/ntp.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp.tencent.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/cn.pool.ntp.org/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/ntp.ntsc.ac.cn/g' package/base-files/files/bin/config_generate

# base-23.05
mv ../master/base-23.05 package/new/base

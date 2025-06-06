#!/bin/bash -e

# libsodium - fix build with lto (GNU BUG - 89147)
sed -i "/CONFIGURE_ARGS/i\TARGET_CFLAGS += -ffat-lto-objects\n" feeds/packages/libs/libsodium/Makefile

# fix gcc14
if [ "$USE_GCC14" = y ]; then
    # libwebsockets
    mkdir feeds/packages/libs/libwebsockets/patches
    pushd feeds/packages/libs/libwebsockets/patches
        curl -sLO https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/libwebsockets/010-fix-enum-int-mismatch-openssl.patch
        curl -sLO https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/libwebsockets/011-fix-enum-int-mismatch-mbedtls.patch
        curl -sLO https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/libwebsockets/100-fix-uninitialized-variable-usage.patch
    popd
    # nginx-util
    pushd feeds/packages
        curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/nginx-util/0001-nginx-util-fix-compilation-with-GCC13.patch | patch -p1
        curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/nginx-util/0002-nginx-util-move-to-pcre2.patch | patch -p1
    popd
    # wsdd2
    mkdir -p feeds/packages/net/wsdd2/patches
    curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/wsdd2/100-wsdd2-cast-from-pointer-to-integer-of-different-size.patch > feeds/packages/net/wsdd2/patches/100-wsdd2-cast-from-pointer-to-integer-of-different-size.patch
    # mbedtls
    curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/mbedtls/900-tests-fix-calloc-argument-list-gcc-14-fix.patch > package/libs/mbedtls/patches/900-tests-fix-calloc-argument-list-gcc-14-fix.patch
    # perl
    curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/perl/1000-fix-implicit-declaration-error.patch > feeds/packages/lang/perl/patches/1000-fix-implicit-declaration-error.patch
fi

# grub2 -  disable `gc-sections` flag
sed -i '/PKG_BUILD_FLAGS/ s/$/ no-gc-sections/' package/boot/grub2/Makefile
[ "$USE_GCC14" = y ] && curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/grub2/900-fix-incompatible-pointer-type.patch > package/boot/grub2/patches/900-fix-incompatible-pointer-type.patch

# xdp-tools
[ "$platform" != "x86_64" ] && sed -i '/TARGET_LDFLAGS +=/iTARGET_CFLAGS += -Wno-error=maybe-uninitialized -ffat-lto-objects\n' package/network/utils/xdp-tools/Makefile
[ "$platform" = "x86_64" ] && sed -i '/TARGET_LDFLAGS +=/iTARGET_CFLAGS += -ffat-lto-objects\n' package/network/utils/xdp-tools/Makefile
[ "$USE_GCC14" = y ] && curl -s https://$mirror/openwrt/patch/openwrt-6.x/gcc-14/xdp-tools/900-Fix-transposed-calloc-arguments.patch > package/network/utils/xdp-tools/patches/900-Fix-transposed-calloc-arguments.patch

# linux-atm
rm -rf package/network/utils/linux-atm/patches/*
pushd package/network/utils/linux-atm/patches
        curl -sLO https://$mirror/openwrt/patch/linux-atm/000-debian_2.5.1-5.1.patch
        curl -sLO https://$mirror/openwrt/patch/linux-atm/200-no_libfl.patch
        curl -sLO https://$mirror/openwrt/patch/linux-atm/300-objcopy_path.patch
        curl -sLO https://$mirror/openwrt/patch/linux-atm/400-portability_fixes.patch
        curl -sLO https://$mirror/openwrt/patch/linux-atm/500-br2684ctl_script.patch
        curl -sLO https://$mirror/openwrt/patch/linux-atm/501-br2684ctl_itfname.patch
        curl -sLO https://$mirror/openwrt/patch/linux-atm/510-remove-LINUX_NETDEVICE-hack.patch
        curl -sLO https://$mirror/openwrt/patch/linux-atm/600-musl-include.patch
        [ "$USE_GCC14" = y ] && curl -sLO https://$mirror/openwrt/patch/linux-atm/700-fix-gcc14-build.patch
popd
[ "$KERNEL_CLANG_LTO" = "y" ] && curl -s https://$mirror/openwrt/patch/linux-atm/Makefile > package/network/utils/linux-atm/Makefile

# bpf - add host clang-15/17/18/19 support
sed -i 's/command -v clang/command -v clang clang-19 clang-18 clang-17 clang-15/g' include/bpf.mk

# perf
curl -s https://$mirror/openwrt/patch/openwrt-6.x/musl/990-add-typedefs-for-Elf64_Relr-and-Elf32_Relr.patch > toolchain/musl/patches/990-add-typedefs-for-Elf64_Relr-and-Elf32_Relr.patch
if [ "$KERNEL_CLANG_LTO" = "y" ]; then
    curl -s https://$mirror/openwrt/patch/openwrt-6.x/perf/Makefile > package/devel/perf/Makefile
else
    sed -i 's/no-lto/& no-mold/' package/devel/perf/Makefile
    sed -i 's/+librt/& +libstdcpp/' package/devel/perf/Makefile
    sed -i '/^TARGET_LDFLAGS/a\\nTARGET_CFLAGS += -Wno-maybe-uninitialized' package/devel/perf/Makefile
    sed -i '/NO_LIBCAP=1/a\\tNO_LIBTRACEEVENT=1 \\' package/devel/perf/Makefile
fi
[ "$ENABLE_MOLD" != y ] && sed -i 's/no-mold//g' package/devel/perf/Makefile

# kselftests-bpf
curl -s https://$mirror/openwrt/patch/packages-patches/kselftests-bpf/Makefile > package/devel/kselftests-bpf/Makefile

# sms-tools
mkdir -p feeds/packages/utils/sms-tool/patches
curl -s https://$mirror/openwrt/patch/packages-patches/sms-tools/900-fix-incompatible-pointer-type-error-for-signal-function.patch > feeds/packages/utils/sms-tool/patches/900-fix-incompatible-pointer-type-error-for-signal-function.patch

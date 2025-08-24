#!/bin/bash -e
export RED_COLOR='\e[1;31m'
export GREEN_COLOR='\e[1;32m'
export YELLOW_COLOR='\e[1;33m'
export BLUE_COLOR='\e[1;34m'
export PINK_COLOR='\e[1;35m'
export SHAN='\e[1;33;5m'
export RES='\e[0m'

GROUP=
group() {
    endgroup
    echo "::group::  $1"
    GROUP=1
}
endgroup() {
    if [ -n "$GROUP" ]; then
        echo "::endgroup::"
    fi
    GROUP=
}

###############################
#  OpenWrt Lite Build Script  #
###############################

# openwrt repo
OPENWRT_REPO=pmkol/openwrt-lite

# github proxy
[ "$CN_PROXY" = "y" ] && [ -z "$GITHUB_REPO" ] && github_proxy="git.apad.pro/https://" || github_proxy=""

# github mirror
export github="$github_proxy"github.com

# github actions - automatically retrieve `github raw` links
[ "$(whoami)" = "runner" ] && [ -n "$GITHUB_REPO" ] && OPENWRT_REPO=$GITHUB_REPO
export mirror="$github_proxy"raw.githubusercontent.com/$OPENWRT_REPO/main

# check root
if [ "$(id -u)" = "0" ]; then
    echo -e "${RED_COLOR}Building with root user is not supported.${RES}"
    exit 1
fi

# cpus
cores=`expr $(nproc --all) + 1`

# $CURL_BAR
if curl --help | grep progress-bar >/dev/null 2>&1; then
    CURL_BAR="--progress-bar";
fi

if [ -z "$1" ] || [ "$2" != "nanopi-r4s" -a "$2" != "nanopi-r5s" -a "$2" != "x86_64" ]; then
    echo -e "\n${RED_COLOR}Building type not specified.${RES}\n"
    echo -e "Usage:\n"
    echo -e "${GREEN_COLOR}bash build.sh lite nanopi-r4s${RES}"
    echo -e "${GREEN_COLOR}bash build.sh server nanopi-r4s${RES}"
    echo -e "${GREEN_COLOR}bash build.sh lite nanopi-r5s${RES}"
    echo -e "${GREEN_COLOR}bash build.sh server nanopi-r5s${RES}"
    echo -e "${GREEN_COLOR}bash build.sh lite x86_64${RES}"
    echo -e "${GREEN_COLOR}bash build.sh server x86_64${RES}\n"
    exit 1
fi

# source branch
get_branch_version=$(curl -s "https://api.github.com/repos/pmkol/openwrt-source/branches" | jq -r '.[].name | select(startswith("v"))' | sort -V | tail -n 1)
get_branch_timestamp=$(curl -s "https://api.github.com/repos/pmkol/openwrt-source/commits?sha=$get_branch_version" | jq -r '.[0].commit.committer.date' | xargs -I {} date -d "{}" +%s)

export toolchain_version=openwrt-23.05

if [ "$1" = "dev" ]; then
    export branch=${get_branch_version:-"v23.05-dev"}
    export DEV_BUILD=y
elif [ "$1" = "lite" ]; then
    export branch=${get_branch_version:-"v23.05-dev"}
	export MINIMAL_BUILD=y
elif [ "$1" = "server" ]; then
    export branch=${get_branch_version:-"v23.05-dev"}
fi

# platform
[ "$2" = "nanopi-r4s" ] && export platform="rk3399" toolchain_arch="aarch64_generic"
[ "$2" = "nanopi-r5s" ] && export platform="rk3568" toolchain_arch="aarch64_generic"
[ "$2" = "x86_64" ] && export platform="x86_64" toolchain_arch="x86_64"

# lan
[ -n "$LAN" ] && export LAN=$LAN || export LAN=10.0.0.1

# build flags
if [ "$(whoami)" = "runner" ] && [ -n "$GITHUB_REPO" ] && [ "$BUILD_TOOLCHAIN" != "y" ]; then
    export KERNEL_CLANG_LTO=y ENABLE_LTO=y ENABLE_LRNG=y ENABLE_BPF=y USE_GCC14=y ENABLE_MOLD=y ENABLE_DPDK=$ENABLE_DPDK BUILD_FAST=y
elif [ "$BUILD_TOOLCHAIN" = "y" ]; then
    export ENABLE_LTO=y ENABLE_BPF=y USE_GCC14=y ENABLE_MOLD=y
else
    export KERNEL_CLANG_LTO=y ENABLE_LTO=y ENABLE_LRNG=y ENABLE_BPF=y USE_GCC14=y ENABLE_MOLD=y ENABLE_DPDK=$ENABLE_DPDK
    [ $(grep MemTotal /proc/meminfo | awk '{print $2}') -lt $((15 * 1024 * 1024)) ] && export CLANG_LTO_THIN=y
fi

# gcc version
if [ "$USE_GCC14" = y ]; then
    export gcc_version=14
else
    export gcc_version=11
    # disable mold for gcc11
    [ "$ENABLE_MOLD" = y ] && export ENABLE_MOLD=n
fi

# start time
starttime=`date +'%Y-%m-%d %H:%M:%S'`
[ "$DEV_BUILD" = "y" ] && CURRENT_DATE=$(date +%s) || CURRENT_DATE=${get_branch_timestamp:-"$(date +%s)"}

# print version
echo -e "\r\n${GREEN_COLOR}Building $branch${RES}\r\n"
if [ "$platform" = "x86_64" ]; then
    echo -e "${GREEN_COLOR}Model: x86_64${RES}"
elif [ "$platform" = "rk3568" ]; then
    echo -e "${GREEN_COLOR}Model: nanopi-r5s/r5c${RES}"
else
    echo -e "${GREEN_COLOR}Model: nanopi-r4s${RES}"
fi
get_kernel_version=$(curl -s https://"$github_proxy"raw.githubusercontent.com/pmkol/openwrt-source/"$branch"/include/kernel-6.11)
kmod_hash=$(echo -e "$get_kernel_version" | awk -F'HASH-' '{print $2}' | awk '{print $1}' | tail -1 | md5sum | awk '{print $1}')
kmodpkg_name=$(echo $(echo -e "$get_kernel_version" | awk -F'HASH-' '{print $2}' | awk '{print $1}')-1-$(echo $kmod_hash))
echo -e "${GREEN_COLOR}Kernel: $kmodpkg_name ${RES}"
echo -e "${GREEN_COLOR}Date: $CURRENT_DATE${RES}\r\n"
echo -e "${GREEN_COLOR}GCC VERSION: $gcc_version${RES}"
[ -n "$LAN" ] && echo -e "${GREEN_COLOR}LAN: $LAN${RES}" || echo -e "${GREEN_COLOR}LAN: 10.0.0.1${RES}"
[ "$ENABLE_DPDK" = "y" ] && echo -e "${GREEN_COLOR}ENABLE_DPDK: true${RES}" || echo -e "${GREEN_COLOR}ENABLE_DPDK:${RES} ${YELLOW_COLOR}false${RES}"
[ "$ENABLE_MOLD" = "y" ] && echo -e "${GREEN_COLOR}ENABLE_MOLD: true${RES}" || echo -e "${GREEN_COLOR}ENABLE_MOLD:${RES} ${YELLOW_COLOR}false${RES}"
[ "$ENABLE_BPF" = "y" ] && echo -e "${GREEN_COLOR}ENABLE_BPF: true${RES}" || echo -e "${GREEN_COLOR}ENABLE_BPF:${RES} ${RED_COLOR}false${RES}"
[ "$ENABLE_LTO" = "y" ] && echo -e "${GREEN_COLOR}ENABLE_LTO: true${RES}" || echo -e "${GREEN_COLOR}ENABLE_LTO:${RES} ${RED_COLOR}false${RES}"
[ "$ENABLE_LRNG" = "y" ] && echo -e "${GREEN_COLOR}ENABLE_LRNG: true${RES}" || echo -e "${GREEN_COLOR}ENABLE_LRNG:${RES} ${RED_COLOR}false${RES}"
[ "$ENABLE_LOCAL_KMOD" = "y" ] && echo -e "${GREEN_COLOR}ENABLE_LOCAL_KMOD: true${RES}" || echo -e "${GREEN_COLOR}ENABLE_LOCAL_KMOD:${RES} ${YELLOW_COLOR}false${RES}"
[ "$BUILD_FAST" = "y" ] && echo -e "${GREEN_COLOR}BUILD_FAST: true${RES}" || echo -e "${GREEN_COLOR}BUILD_FAST:${RES} ${YELLOW_COLOR}false${RES}"
[ "$CN_PROXY" = "y" ] && [ -z "$GITHUB_REPO" ] && echo -e "${GREEN_COLOR}CN_PROXY: true${RES}" || echo -e "${GREEN_COLOR}CN_PROXY:${RES} ${YELLOW_COLOR}false${RES}"
[ "$MINIMAL_BUILD" = "y" ] && echo -e "${GREEN_COLOR}MINIMAL_BUILD: true${RES}" || echo -e "${GREEN_COLOR}MINIMAL_BUILD:${RES} ${YELLOW_COLOR}false${RES}"
if [ "$KERNEL_CLANG_LTO" = "y" ]; then
    [ "$CLANG_LTO_THIN" = "y" ] && echo -e "${GREEN_COLOR}KERNEL_CLANG_LTO(THIN): true${RES}\r\n" || echo -e "${GREEN_COLOR}KERNEL_CLANG_LTO: true${RES}\r\n"
else
    echo -e "${GREEN_COLOR}KERNEL_CLANG_LTO:${RES} ${YELLOW_COLOR}false${RES}\r\n"
fi

# clean old files
rm -rf openwrt master && mkdir master

# openwrt 23.05
[ "$(whoami)" = "runner" ] && group "source code"
git clone https://$github/pmkol/openwrt-source openwrt -b $branch --depth=1

# openwrt master
git clone https://$github/openwrt/openwrt master/openwrt --depth=1
git clone https://$github/openwrt/packages master/packages --depth=1
git clone https://$github/openwrt/luci master/luci --depth=1
git clone https://$github/openwrt/routing master/routing --depth=1
[ "$ARCHIVE_BUILD" = "y" ] && git clone https://$github/pmkol/openwrt-feeds -b archive-23.05 master/archive-23.05 --depth=1

# openwrt toolchain
git clone https://$github/pmkol/openwrt-llvm-toolchain master/toolchain -b gcc14 --depth=1

# openwrt feeds
git clone https://$github/pmkol/openwrt-feeds master/base-23.05 -b base-23.05 --depth=1
git clone https://$github/pmkol/openwrt-feeds master/extd-23.05 -b extd-23.05 --depth=1
git clone https://$github/pmkol/openwrt-feeds master/lite-23.05 -b lite-23.05 --depth=1
[ "$(whoami)" = "runner" ] && endgroup

# openwrt lite
if [ -d openwrt ]; then
    cd openwrt
    echo "$CURRENT_DATE" > version.date
    [ "$GITHUB_REPO" = "pmkol/openwrt-lite" ] && curl -Os $OPENWRT_KEY && tar zxf key.tar.gz && rm -f key.tar.gz && cat key-build.pub
else
    echo -e "${RED_COLOR}Failed to download source code${RES}"
    exit 1
fi

# branch version
if [ "$DEV_BUILD" != "y" ]; then
    git branch | awk '{print $2}' > version.txt
else
    echo 'openwrt-23.05' > version.txt
fi

# feeds mirror
cat > feeds.conf <<EOF
src-git packages https://$github/openwrt/packages.git;openwrt-23.05
src-git luci https://$github/openwrt/luci.git;openwrt-23.05
src-git routing https://$github/openwrt/routing.git;openwrt-23.05
src-git telephony https://$github/openwrt/telephony.git;openwrt-23.05
EOF

# Init feeds
[ "$(whoami)" = "runner" ] && group "feeds update -a"
./scripts/feeds update -a
[ "$(whoami)" = "runner" ] && endgroup

[ "$(whoami)" = "runner" ] && group "feeds install -a"
./scripts/feeds install -a
[ "$(whoami)" = "runner" ] && endgroup

# loader dl
if [ -f ../dl.gz ]; then
    tar xf ../dl.gz -C .
fi

# config version
([ "$GITHUB_REPO" != "pmkol/openwrt-lite" ] || [ "$DEV_BUILD" = "y" ]) && export CONFIG_CUSTOM=y
if [ "$CONFIG_CUSTOM" = "y" ]; then
    export cfg_ver=custom
    export cfg_cmd="eval awk '/### APPS/{exit} {print}'"
else
    [ "$MINIMAL_BUILD" = "y" ] && export cfg_ver=lite || export cfg_ver=server
    [ "$NO_APPS" = "y" ] && export cfg_cmd="eval awk '/### APPS/{exit} {print}'" || export cfg_cmd="cat"
fi

###############################################
echo -e "\n${GREEN_COLOR}Patching ...${RES}\n"

# scripts
curl -sO https://$mirror/openwrt/scripts/00-prepare_base.sh
curl -sO https://$mirror/openwrt/scripts/01-prepare_base-mainline.sh
curl -sO https://$mirror/openwrt/scripts/02-prepare_package.sh
curl -sO https://$mirror/openwrt/scripts/03-convert_translation.sh
curl -sO https://$mirror/openwrt/scripts/04-fix_kmod.sh
curl -sO https://$mirror/openwrt/scripts/05-fix-source.sh
curl -sO https://$mirror/openwrt/scripts/06-custom.sh
curl -sO https://$mirror/openwrt/scripts/99_clean_build_cache.sh
chmod 0755 *sh
[ "$(whoami)" = "runner" ] && group "patching openwrt"
bash 00-prepare_base.sh
bash 01-prepare_base-mainline.sh
bash 02-prepare_package.sh
bash 03-convert_translation.sh
bash 04-fix_kmod.sh
bash 05-fix-source.sh
bash 06-custom.sh
[ "$ARCHIVE_BUILD" = "y" ] && bash ../master/archive-23.05/10-archive.sh
[ "$(whoami)" = "runner" ] && endgroup

# toolchain
[ "$(whoami)" = "runner" ] && group "patching toolchain"
if [ "$USE_GCC14" = "y" ]; then
    rm -rf toolchain/{binutils,gcc}
    cp -a ../master/toolchain/binutils toolchain/binutils
    cp -a ../master/toolchain/gcc toolchain/gcc
    curl -s https://$mirror/openwrt/generic/config-gcc14 > .config
else
    curl -s https://$mirror/openwrt/generic/config-gcc11 > .config
fi
[ "$(whoami)" = "runner" ] && endgroup

rm -f 0*-*.sh
rm -rf ../master

# config-devices
if [ "$platform" = "x86_64" ]; then
    curl -s https://$mirror/openwrt/23-config-musl-x86$([ "$DEV_BUILD" = "y" ] && echo "-dev") >> .config
elif [ "$platform" = "rk3568" ]; then
    curl -s https://$mirror/openwrt/23-config-musl-r5s >> .config
else
    curl -s https://$mirror/openwrt/23-config-musl-r4s >> .config
fi

# config-common
[ "$CONFIG_CUSTOM" = "y" ] && [ "$NO_APPS" != "y" ] && curl -s https://$mirror/openwrt/23-config-common-custom >> .config
if [ "$MINIMAL_BUILD" = "y" ]; then
    curl -s https://$mirror/openwrt/23-config-common-lite | $cfg_cmd >> .config
    sed -i '/DOCKER/Id' .config
    echo 'VERSION_TYPE="lite"' >> package/base-files/files/usr/lib/os-release
else
    curl -s https://$mirror/openwrt/23-config-common-server | $cfg_cmd >> .config
    [ "$NO_DOCKER" = "y" ] && sed -i '/DOCKER/Id' .config
    echo 'VERSION_TYPE="server"' >> package/base-files/files/usr/lib/os-release
fi

# config-firmware
[ "$NO_KMOD" != "y" ] && [ "$platform" != "rk3399" ] && curl -s https://$mirror/openwrt/generic/config-firmware >> .config

# bpf
[ "$ENABLE_BPF" = "y" ] && curl -s https://$mirror/openwrt/generic/config-bpf >> .config

# LTO
[ "$ENABLE_LTO" = "y" ] && curl -s https://$mirror/openwrt/generic/config-lto >> .config

# DPDK
[ "$ENABLE_DPDK" = "y" ] && {
    echo 'CONFIG_PACKAGE_dpdk-tools=y' >> .config
    echo 'CONFIG_PACKAGE_numactl=y' >> .config
}

# mold
[ "$ENABLE_MOLD" = "y" ] && echo 'CONFIG_USE_MOLD=y' >> .config

# kernel - CLANG + LTO; Allow CONFIG_KERNEL_CC=clang / clang-19 / clang-xx
if [ "$KERNEL_CLANG_LTO" = "y" ]; then
    echo '# Kernel - CLANG LTO' >> .config
    echo 'CONFIG_KERNEL_CC="clang"' >> .config
    echo 'CONFIG_EXTRA_OPTIMIZATION=""' >> .config
    echo '# CONFIG_PACKAGE_kselftests-bpf is not set' >> .config
fi

# kernel - enable LRNG
if [ "$ENABLE_LRNG" = "y" ]; then
    echo -e "\n# Kernel - LRNG" >> .config
    echo "CONFIG_KERNEL_LRNG=y" >> .config
    echo "# CONFIG_PACKAGE_urandom-seed is not set" >> .config
    echo "# CONFIG_PACKAGE_urngd is not set" >> .config
fi

# local kmod
if [ "$ENABLE_LOCAL_KMOD" = "y" ]; then
    echo -e "\n# local kmod" >> .config
    echo "CONFIG_TARGET_ROOTFS_LOCAL_PACKAGES=y" >> .config
fi

# upx
[ "$MINIMAL_BUILD" = "y" ] && [ "$CONFIG_CUSTOM" != "y" ] && [ "$NO_APPS" != "y" ] && curl -s https://$mirror/openwrt/generic/upx_list.txt > upx_list.txt

# not all kmod
[ "$NO_KMOD" = "y" ] && sed -i '/CONFIG_ALL_KMODS=y/d; /CONFIG_ALL_NONSHARED=y/d' .config

# toolchain cache
if [ "$BUILD_FAST" = "y" ]; then
    echo -e "\n${GREEN_COLOR}Download Toolchain ...${RES}"
    TOOLCHAIN_URL="$github_proxy"https://github.com/pmkol/openwrt-lite/releases/download/openwrt-23.05
    curl -L "$TOOLCHAIN_URL"/toolchain_musl_"$toolchain_arch"_gcc-"$gcc_version".tar.zst -o toolchain.tar.zst $CURL_BAR
    echo -e "\n${GREEN_COLOR}Process Toolchain ...${RES}"
    tar -I "zstd" -xf toolchain.tar.zst
    rm -f toolchain.tar.zst
    mkdir bin
    find ./staging_dir/ -name '*' -exec touch {} \; >/dev/null 2>&1
    find ./tmp/ -name '*' -exec touch {} \; >/dev/null 2>&1
fi

# init openwrt config
rm -rf tmp/*
if [ "$BUILD" = "n" ]; then
    exit 0
else
    make defconfig
fi

# compile
if [ "$BUILD_TOOLCHAIN" = "y" ]; then
    echo -e "\r\n${GREEN_COLOR}Building Toolchain ...${RES}\r\n"
    make -j$cores toolchain/compile || make -j$cores toolchain/compile V=s || exit 1
    make tools/clang/clean
    rm -f dl/clang-*
    mkdir -p toolchain-cache
    tar -I "zstd -19 -T$(nproc --all)" -cf toolchain-cache/toolchain_musl_"$toolchain_arch"_gcc-"$gcc_version".tar.zst ./{build_dir,dl,staging_dir,tmp}
    echo -e "\n${GREEN_COLOR} Build success! ${RES}"
    exit 0
elif [ "$CLANG_LTO_THIN" = "y" ] && [ "$BUILD_TOOLCHAIN" != "y" ] && [ "$BUILD_FAST" != "y" ]; then
    echo -e "\r\n${GREEN_COLOR}Building OpenWrt ...${RES}\r\n"
    sed -i "/BUILD_DATE/d" package/base-files/files/usr/lib/os-release
    sed -i "/BUILD_ID/aBUILD_DATE=\"$CURRENT_DATE\"" package/base-files/files/usr/lib/os-release
    make toolchain/compile
    make -j$cores IGNORE_ERRORS="n m"
else
    if [ "$BUILD_FAST" = "y" ]; then
        echo -e "\r\n${GREEN_COLOR}Building tools/clang ...${RES}\r\n"
        make tools/clang/compile -j$cores
    fi
    echo -e "\r\n${GREEN_COLOR}Building OpenWrt ...${RES}\r\n"
    sed -i "/BUILD_DATE/d" package/base-files/files/usr/lib/os-release
    sed -i "/BUILD_ID/aBUILD_DATE=\"$CURRENT_DATE\"" package/base-files/files/usr/lib/os-release
    make -j$cores IGNORE_ERRORS="n m"
fi

# compile time
endtime=`date +'%Y-%m-%d %H:%M:%S'`
start_seconds=$(date --date="$starttime" +%s);
end_seconds=$(date --date="$endtime" +%s);
SEC=$((end_seconds-start_seconds));

if [ -f bin/targets/*/*/sha256sums ]; then
    echo -e "${GREEN_COLOR} Build success! ${RES}"
    echo -e " Build time: $(( SEC / 3600 ))h,$(( (SEC % 3600) / 60 ))m,$(( (SEC % 3600) % 60 ))s"
else
    echo -e "\n${RED_COLOR} Build error... ${RES}"
    echo -e " Build time: $(( SEC / 3600 ))h,$(( (SEC % 3600) / 60 ))m,$(( (SEC % 3600) % 60 ))s"
    echo
    exit 1
fi

if [ "$platform" = "x86_64" ]; then
    if [ "$NO_KMOD" != "y" ]; then
        cp -a bin/targets/x86/*/packages $kmodpkg_name
        rm -f $kmodpkg_name/Packages*
        # driver firmware
        rm -f bin/packages/x86_64/base/{amdgpu-firmware*.ipk,radeon-firmware*.ipk}
        cp -a bin/packages/x86_64/base/*firmware*.ipk $kmodpkg_name/
        [ "$GITHUB_REPO" = "pmkol/openwrt-lite" ] && bash kmod-sign $kmodpkg_name || echo "skip kmod-sign"
        tar zcf x86_64-$kmodpkg_name.tar.gz $kmodpkg_name
        rm -rf $kmodpkg_name
    fi
    # backup download cache
    if [ "$CN_PROXY" = "y" ]; then
        rm -rf dl/geo* dl/go-mod-cache
        tar cf ../dl.gz dl
    fi
    exit 0
else
    if [ "$NO_KMOD" != "y" ] && [ "$platform" != "rk3399" ]; then
        cp -a bin/targets/rockchip/armv8*/packages $kmodpkg_name
        rm -f $kmodpkg_name/Packages*
        # driver firmware
        cp -a bin/packages/aarch64_generic/base/*firmware*.ipk $kmodpkg_name/
        [ "$GITHUB_REPO" = "pmkol/openwrt-lite" ] && bash kmod-sign $kmodpkg_name || echo "skip kmod-sign"
        tar zcf aarch64-$kmodpkg_name.tar.gz $kmodpkg_name
        rm -rf $kmodpkg_name
    fi
    # backup download cache
    if [ "$CN_PROXY" = "y" ]; then
        rm -rf dl/geo* dl/go-mod-cache
        tar -cf ../dl.gz dl
    fi
    exit 0
fi

# OpenWrt Lite 23.05

### End of Life ：
- 由于 OpenWRT 25.12 内核已高于6.11版本，该项目已停止维护
- 软件源将在2026年4月20日后停止维护，届时将无法通过软件源在线升级部分插件
- 用户可以继续使用本项目编译 OpenWRT 23.05 及支持该版本的最新插件

### 基于原生 OpenWrt 优化的固件，提供高效、稳定的使用体验
该项目使用自动构建的扩展软件源，优化、修复官方插件，补充官方源中未包含的常用插件

仅需安装、配置一次，后续升级无需重新刷写、配置固件

欢迎加入交流群：[Infinity Nikki](https://t.me/+xqUr1lp9FD0xZDM1)

#### 固件下载：
https://github.com/pmkol/openwrt-lite/releases

#### 固件下载：
https://github.com/pmkol/openwrt-lite/releases

#### 支持硬件：
- [x] X86_64
- [x] NanoPi R4S/R5S/R5C

```
【首次登陆】
地址：10.0.0.1（默认）
用户：root
密码：空

【分区挂载】
系统 -> 磁盘管理 将系统盘剩余空间创建新分区
系统 -> 挂载点   启用新分区并挂载至/opt目录

【性能测试】
在控制台执行命令 /etc/coremark.sh
状态 -> 概览     查看CPU的CoreMark分数
```

---------------

### 固件说明：
- 优化与升级 Linux Kernel 6.11.11 
  - [x] Full cone NAT
  - [x] TCP BBRv3
  - [x] TCP Brutal
  - [x] LLVM-BPF
  - [x] Shortcut-FE
  - [x] Multipath TCP
- 固定内核、驱动至已在生产环境中验证的较高版本，兼顾系统优化与稳定性
- 优化编译工具链与参数，提升系统性能
- 内置 OpenWrt 扩展软件源，支持常用插件的在线安装与升级
- 系统默认使用支持指令补全功能的Bash
- 轻量集成常用插件，优化、修复上游插件BUG

```
固件分为 SquashFS 和 Ext4 两个文件系统

SquashFS：固件文件名带有 “squashfs”，SquashFS 为只读文件系统，支持系统重置，适合绝大部分用户使用

Ext4：固件文件名带有 “ext4”，Ext4 文件系统具备整个分区可读写性质，适合熟悉 Linux 系统的用户使用
```

---------------

### 版本说明：
- **Lite**

  适合绝大部分用户使用，压缩部分预装插件

  预装少量插件：

  Mihomo, Sing-box, DDNS, Tailscale, SMB, UPnP, EQoS, Socat

- **Thin**

  基于 Lite 版本，无任何插件，仅包含内核级功能与模板

- **Server**

  增加了 Docker 与 Iptables 的支持，插件无压缩，适合有 Linux 运维能力的高级用户使用

  预装以下插件：

  | ⚓ 服务 | 🗳️ Docker  | 🩺 网络  |
  |  :----  |  :----  |  :----  |
  | Xray | Dockerman | SpeedTest |
  | Sing-Box | Docker | UPnP |
  | Mihomo | Dockerd | Bandwidth Monitor |
  | MosDNS | Docker-compose | EQoS |
  | DDNS | | Socat |
  | Frp | | L2TP |
  | Tailscale | | WireGuard |
  | ZeroTier | | |
  | Watchcat | | |
  | Aira2 | | |
  | NATMap | | |
  | SMB | | |
  | WOL | | |

---------------

### 升级说明：
- 软件升级（推荐）

  绝大部分情况下，通过软件包仓库在线升级插件即可
  ``` 
  注意不要升级以下系统插件：
  luci-base | luci-mod-network | luci-mod-status | luci-mod-system
  ```

  系统已内置软件包定时升级功能，执行升级时将自动排除系统插件，默认为关闭状态

  系统 -> 计划任务

  删除下方命令前的注释 `#` 即可开启 *每日5点* 更新非系统插件的软件包

  ```
  0 5 * * * opkg update && opkg list-upgradable | grep -vE "(luci-base|luci-mod-)" | awk '{print $1}' | xargs opkg upgrade
  ```

- 固件升级

  系统 -> 备份与升级 -> 刷写新固件

---------------

### 附加功能：
- RTC 硬件时钟（HYM8563）

  NanoPi 支持 RTC 硬件时钟读取/同步，当设备断电时，重新通电启动系统时间不会错乱 （注意：设备需要安装 RTC 电池后使用）

  首次安装 RTC 电池写入时间命令
  ```
  hwclock -w -f /dev/rtc1
  ```

  测试时间读取（返回当前时间表示正常）
  ```
  hwclock -f /dev/rtc1
  ```

- R5S eMMC

  固件写入（SD to eMMC）
  ```
  # 1、下载最新 Releases 固件并通过 SD 卡启动
  # 2、使用 FileZilla 等工具上传一份固件到 /tmp 目录，或通过终端 wget 在线下载固件到 /tmp 目录
  # 3、使用内建命令写入固件到 eMMC 存储（请根据实际文件名称与路径）
  emmc-install /tmp/openwrt-23.05.6-rockchip-armv8-friendlyarm_nanopi-r5s-ext4-sysupgrade.img.gz
  ```

---------------

### 自定义构建固件：
提供云构建与本地编译两种方式

```
Toolchain Description: Clang19(LLVM-LTO) GCC14(MOLD+LTO)

默认开启的工具链优化可能会导致部分插件编译出错，请自行添加修复补丁
普通用户请前往 Issues 提交插件需求，兼容v23.05的插件会被加入软件源
```

#### 使用 Github Actions 云构建（推荐）

#### 一、Fork 本仓库到自己 GitHub 存储库

#### 二、配置插件

- 修改 `openwrt/23-config-common-custom` 配置，注释或删除掉不需要的插件，该配置会自动覆盖lite与server配置中的luci插件

- 按照 .config 格式添加需要的插件，例如 `CONFIG_PACKAGE_luci-app-mihomo=y`

- 如果添加了 Feed 中不存在的插件，请在 `openwrt/scripts/06-custom.sh` 加入插件引用代码

#### 三、构建固件

- 在存储库名称下，单击（<img src="https://github.com/user-attachments/assets/f1db14da-2dd9-4f10-8e37-d92ef9651912" alt="Actions"> Actions）
  
- 在左侧边栏中，单击要运行的工作流的名称“**Build OpenWrt 23.05 Custom**”
  
- 在工作流运行的列表右上方，单击“**Run workflow**”按钮，选择要构建的版本与设备固件并运行工作流
```
Select the build version: lite | server
Select device to build: x86_64 | nanopi-r4s | nanopi-r5s(r5c)
Build options: 默认无需填写，用于写入高级构建参数，参数之间用空格分开
例如 LAN=192.168.99.1 ENABLE_LOCAL_KMOD=y
```

---------------

#### 本地编译构建（内存16G+ / 硬盘80G+）

#### Linux 环境安装（debian 12+ / ubuntu 24+）
```shell
sudo apt-get update
sudo apt-get install -y build-essential flex bison cmake g++ gawk gcc-multilib g++-multilib gettext git gnutls-dev libfuse-dev libncurses5-dev libssl-dev python3 python3-pip python3-ply python3-pyelftools rsync unzip zlib1g-dev file wget subversion patch upx-ucl autoconf automake curl asciidoc binutils bzip2 lib32gcc-s1 libc6-dev-i386 uglifyjs msmtp texinfo libreadline-dev libglib2.0-dev xmlto libelf-dev libtool autopoint antlr3 gperf ccache swig coreutils haveged scons libpython3-dev rename qemu-utils jq
```

#### 一、Fork 本仓库到自己 GitHub 存储库

#### 二、修改构建脚本文件：`openwrt/build.sh`（使用 Github Actions 构建时无需更改）

将脚本默认 `pmkol/openwrt-lite` 替换为 `你的用户名/仓库名`

```diff
# openwrt repo
- OPENWRT_REPO=pmkol/openwrt-lite
+ OPENWRT_REPO=你的用户名/仓库名
```

#### 三、配置插件

- 修改 `openwrt/23-config-common-custom` 配置，注释或删除掉不需要的插件

- 按照 .config 格式添加需要的插件，例如 `CONFIG_PACKAGE_luci-app-mihomo=y`

- 如果添加了 Feed 中不存在的插件，请在 `openwrt/scripts/06-custom.sh` 加入插件引用代码

#### 四、在本地 Linux 执行基于你自己仓库的构建脚本，即可编译所需固件

- x86_64 openwrt-23.05
```shell
# lite version
bash <(curl -sS https://raw.githubusercontent.com/你的用户名/仓库名/main/openwrt/build.sh) lite x86_64

# server version
bash <(curl -sS https://raw.githubusercontent.com/你的用户名/仓库名/main/openwrt/build.sh) server x86_64
```

- nanopi-r4s openwrt-23.05
```shell
# lite version
bash <(curl -sS https://raw.githubusercontent.com/你的用户名/仓库名/main/openwrt/build.sh) lite nanopi-r4s

# server version
bash <(curl -sS https://raw.githubusercontent.com/你的用户名/仓库名/main/openwrt/build.sh) server nanopi-r4s
```

- nanopi-r5s/r5c openwrt-23.05
```shell
# lite version
bash <(curl -sS https://raw.githubusercontent.com/你的用户名/仓库名/main/openwrt/build.sh) lite nanopi-r5s

# server version
bash <(curl -sS https://raw.githubusercontent.com/你的用户名/仓库名/main/openwrt/build.sh) server nanopi-r5s
```

---------------

#### 高级构建参数说明

#### 更改 LAN IP 地址
自定义默认 LAN IP 地址

只需在构建固件前执行以下命令即可覆盖默认 LAN 地址（默认：10.0.0.1）

```
export LAN=10.0.0.1
```

#### 更改 LAN 端口数量（For X86_64）
自定义默认 LAN 端口数量，仅适配4或6个网口的 X86_64 非虚拟化设备

只需在构建固件前执行以下命令即可适配 LAN 端口数量

- 适配4个网口设备（WAN=eth0 | LAN=eth1~eth3）
```
export LAN_PORTS=3
```
- 适配6个网口设备（WAN=eth0 | LAN=eth1~eth5）
```
export LAN_PORTS=5
```

#### 启用本地 Kernel Modules 安装源（For developers）
启用该标志时，将会拷贝全部 target packages 到 rootfs 并替换 openwrt_core 源为本地方式，以供离线 `opkg install kmod-xxx` 安装操作

这会增加固件文件大小（大约 70MB），对项目内核版本、模块、补丁 有修改的需求时，该功能可能会有用

只需在构建固件前执行以下命令即可启用本地 Kernel Modules 安装源

```
export ENABLE_LOCAL_KMOD=y
```

#### 启用 DPDK 支持
DPDK（[Data Plane Development Kit](https://www.dpdk.org/) ）是一个开源工具集，专为加速数据包处理而设计，通过优化的数据平面技术，实现高性能、低延迟的网络应用

只需在构建固件前执行以下命令即可启用 DPDK 工具集支持

```
export ENABLE_DPDK=y
```

#### 启用 NoDocker 模式
Server版默认会构建 Docker 服务，使用该参数会跳过安装 Docker 仅支持 Iptables

只需在构建固件前执行以下命令即可跳过Server版的 Docker 安装

```
export NO_DOCKER=y
```

#### 启用 OPKG 代理
仅建议在无法正常访问软件源或下载速度过慢时使用

只需在构建固件前执行以下命令即可启用 OPKG 代理

```
export OPKG_PROXY=y
```

如需使用中国大陆的CDN线路请执行以下命令

```
export OPKG_PROXY=cn
```

#### 启用 GitHub 代理（仅限本地编译）
仅建议在无法正常访问 GitHub 或下载速度过慢时使用

只需在构建固件前执行以下命令即可启用 GitHub 代理

```
export CN_PROXY=y
```

-----------------

### 特别致谢：

#### 开源项目
- [OpenWrt](https://github.com/openwrt/openwrt)
- [r4s_build_script](https://github.com/sbwml/r4s_build_script/tree/openwrt-23.05)

#### 社区成员
- [@Joseph Mory](https://github.com/morytyann)
- [@Apois](https://github.com/apoiston)

[<img src="https://edgeone.ai/media/34fe3a45-492d-4ea4-ae5d-ea1087ca7b4b.png" height="22" alt="Tencent EdgeOne">](https://edgeone.ai/?from=github)
- CDN acceleration and security protection for this project are sponsored by [Tencent EdgeOne](https://edgeone.ai/?from=github)

#!/bin/bash -e

#################################################################

# kenrel vermagic
sed -ie 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
grep HASH include/kernel-6.11 | awk -F'HASH-' '{print $2}' | awk '{print $1}' | md5sum | awk '{print $1}' > .vermagic

# kernel modules
rm -rf package/kernel/linux
git checkout package/kernel/linux
pushd package/kernel/linux/modules
    rm -f [a-z]*.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/block.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/can.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/crypto.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/firewire.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/fs.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/gpio-cascade.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/hwmon.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/i2c.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/iio.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/input.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/leds.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/lib.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/multiplexer.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/netdevices.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/netfilter.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/netsupport.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/nls.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/other.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/pcmcia.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/sound.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/spi.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/usb.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/video.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/virt.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/w1.mk
    curl -Os https://$mirror/openwrt/patch/openwrt-6.x/modules/wpan.mk
popd

# BBRv3 - linux-6.11
pushd target/linux/generic/backport-6.11
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0001-net-tcp_bbr-broaden-app-limited-rate-sample-detectio.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0002-net-tcp_bbr-v2-shrink-delivered_mstamp-first_tx_msta.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0003-net-tcp_bbr-v2-snapshot-packets-in-flight-at-transmi.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0004-net-tcp_bbr-v2-count-packets-lost-over-TCP-rate-samp.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0005-net-tcp_bbr-v2-export-FLAG_ECE-in-rate_sample.is_ece.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0006-net-tcp_bbr-v2-introduce-ca_ops-skb_marked_lost-CC-m.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0007-net-tcp_bbr-v2-adjust-skb-tx.in_flight-upon-merge-in.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0008-net-tcp_bbr-v2-adjust-skb-tx.in_flight-upon-split-in.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0009-net-tcp-add-new-ca-opts-flag-TCP_CONG_WANTS_CE_EVENT.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0010-net-tcp-re-generalize-TSO-sizing-in-TCP-CC-module-AP.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0011-net-tcp-add-fast_ack_mode-1-skip-rwin-check-in-tcp_f.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0012-net-tcp_bbr-v2-record-app-limited-status-of-TLP-repa.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0013-net-tcp_bbr-v2-inform-CC-module-of-losses-repaired-b.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0014-net-tcp_bbr-v2-introduce-is_acking_tlp_retrans_seq-i.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0015-tcp-introduce-per-route-feature-RTAX_FEATURE_ECN_LOW.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0016-net-tcp_bbr-v3-update-TCP-bbr-congestion-control-mod.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0017-net-tcp_bbr-v3-ensure-ECN-enabled-BBR-flows-set-ECT-.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0018-tcp-export-TCPI_OPT_ECN_LOW-in-tcp_info-tcpi_options.patch
    [ "$TESTING_KERNEL" = "y" ] && curl -Os https://$mirror/openwrt/patch/kernel-6.11/bbr3/010-bbr3-0019-x86-cfi-bpf-Add-tso_segs-and-skb_marked_lost-to-bpf_.patch
popd

# LRNG v54/56 - linux-6.11
pushd target/linux/generic/hack-6.11
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0001-LRNG-Entropy-Source-and-DRNG-Manager.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0002-LRNG-allocate-one-DRNG-instance-per-NUMA-node.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0003-LRNG-proc-interface.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0004-LRNG-add-switchable-DRNG-support.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0005-LRNG-add-common-generic-hash-support.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0006-crypto-DRBG-externalize-DRBG-functions-for-LRNG.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0007-LRNG-add-SP800-90A-DRBG-extension.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0008-LRNG-add-kernel-crypto-API-PRNG-extension.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0009-LRNG-add-atomic-DRNG-implementation.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0010-LRNG-add-common-timer-based-entropy-source-code.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0011-LRNG-add-interrupt-entropy-source.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0012-scheduler-add-entropy-sampling-hook.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0013-LRNG-add-scheduler-based-entropy-source.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0014-LRNG-add-SP800-90B-compliant-health-tests.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0015-LRNG-add-random.c-entropy-source-support.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0016-LRNG-CPU-entropy-source.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0017-LRNG-add-Jitter-RNG-fast-noise-source.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0018-LRNG-add-option-to-enable-runtime-entropy-rate-confi.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0019-LRNG-add-interface-for-gathering-of-raw-entropy.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0020-LRNG-add-power-on-and-runtime-self-tests.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0021-LRNG-sysctls-and-proc-interface.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0022-LRMG-add-drop-in-replacement-random-4-API.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0023-LRNG-add-kernel-crypto-API-interface.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0024-LRNG-add-dev-lrng-device-file-support.patch
    curl -Os https://$mirror/openwrt/patch/kernel-6.11/lrng/011-LRNG-0025-LRNG-add-hwrand-framework-interface.patch
popd

# kernel patch
# btf: silence btf module warning messages
curl -s https://$mirror/openwrt/patch/kernel-6.11/btf/990-btf-silence-btf-module-warning-messages.patch > target/linux/generic/hack-6.11/990-btf-silence-btf-module-warning-messages.patch
# cpu model
curl -s https://$mirror/openwrt/patch/kernel-6.11/arm64/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch > target/linux/generic/pending-6.11/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch

# RTC
if [ "$platform" = "rk3399" ] || [ "$platform" = "rk3568" ]; then
    curl -s https://$mirror/openwrt/patch/rtc/sysfixtime > package/base-files/files/etc/init.d/sysfixtime
    chmod 755 package/base-files/files/etc/init.d/sysfixtime
fi

# emmc-install
if [ "$platform" = "rk3568" ]; then
    mkdir -p files/sbin
    curl -so files/sbin/emmc-install https://$mirror/openwrt/files/sbin/emmc-install
    chmod 755 files/sbin/emmc-install
fi

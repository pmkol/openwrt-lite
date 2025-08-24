#!/bin/bash -e

### Add new packages or patches below
### For example, download openlist from a third-party repository to package/new/openlist
### Then, add CONFIG_PACKAGE_luci-app-openlist2=y to the end of openwrt/23-config-common-custom

# openlist - add new package
git clone https://$github/sbwml/luci-app-openlist2 package/new/openlist

# lrzsz - add patched package
rm -rf feeds/packages/utils/lrzsz
git clone https://$github/sbwml/packages_utils_lrzsz package/new/lrzsz

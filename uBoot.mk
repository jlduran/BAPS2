#########################################################################
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# The Free Software Foundation; version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# Copyright @ 2008 Astfin <mark@astfin.org>
# Primary Authors: mark@astfin.org, pawel@astfin.org
#########################################################################

include rules.mk

SOURCES_DIR=$(TOP_DIR)/src
PRODUCT=ip08
CPU_FLAGS=CPU_400
MEM_FLAGS=SDRAM_64MB_SLOW
UCONFIG=$(PRODUCT)

UBOOT_DIRNAME=u-boot-1.1.5-bf1
UBOOT_DIR=$(BUILD_DIR)/$(UBOOT_DIRNAME)
UBOOT_SOURCE=u-boot-1.1.5-bf1-061210.tar.bz2
UBOOT_SITE=http://blackfin.uclinux.org/gf/download/frsrelease/330/2208/
UBOOT_UNZIP=bzcat
PATCHNAME=uBoot-$(PRODUCT)

TARGET_DIR=$(UBOOT_DIR)/images

$(DL_DIR)/$(UBOOT_SOURCE):
	mkdir -p $(DL_DIR)
	$(WGET) -P $(DL_DIR) $(UBOOT_SITE)/$(UBOOT_SOURCE)

uBoot-source: $(DL_DIR)/$(UBOOT_SOURCE)

$(UBOOT_DIR)/.unpacked: $(DL_DIR)/$(UBOOT_SOURCE)
	mkdir -p $(BUILD_DIR)
	$(UBOOT_UNZIP) $(DL_DIR)/$(UBOOT_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(PATCH_KERNEL) $(UBOOT_DIR) patch $(PATCHNAME).patch
	touch $(UBOOT_DIR)/.unpacked

$(UBOOT_DIR)/.configured: $(UBOOT_DIR)/.unpacked

	$(MAKE) -C $(UBOOT_DIR) UBOOT_FLAGS="$(MEM_FLAGS)" UBOOT_FLAGS2="$(CPU_FLAGS)" $(UCONFIG)_config
	touch $(UBOOT_DIR)/.configured

uBoot: $(UBOOT_DIR)/.configured
	$(MAKE) -C $(UBOOT_DIR)
	cd $(UBOOT_DIR)/tools/bin2ldr; ./runme.sh

uBoot-configure: $(UBOOT_DIR)/.configured

uBoot-clean:
	rm -f $(UBOOT_DIR)/.configured
	$(MAKE) -C $(UBOOT_DIR) clean

uBoot-config: $(UBOOT_DIR)/.configured
	$(MAKE) -C $(UBOOT_DIR) menuconfig

uBoot-dirclean:
	rm -rf $(UBOOT_DIR)

all: uBoot


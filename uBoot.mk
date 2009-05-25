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

UBOOT_DIRNAME=u-boot-1.1.6-2008R1.5
UBOOT_DIR=$(BUILD_DIR)/$(UBOOT_DIRNAME)
UBOOT_SOURCE=u-boot-1.1.6-2008R1.5.tar.bz2
UBOOT_SITE=http://download.analog.com/27516/frsrelease/4/8/7/4876
UBOOT_UNZIP=bzcat
UCONFIG=ip04

ifeq ($(strip $(ASTFIN_SDRAM_128)),y)
MEM_FLAGS=SDRAM_128MB
endif
ifeq ($(strip $(ASTFIN_SDRAM_64)),y)
ifeq ($(strip $(ASTFIN_CAS_3)),y)
MEM_FLAGS=SDRAM_64MB_SLOW
endif
ifeq ($(strip $(ASTFIN_CAS_2)),y)
MEM_FLAGS=SDRAM_64MB_FAST
endif
endif

ifeq ($(strip $(ASTFIN_CPU_300)),y)
CPU_FLAGS=CPU_300
endif
ifeq ($(strip $(ASTFIN_CPU_500)),y)
CPU_FLAGS=CPU_500
endif
ifeq ($(strip $(ASTFIN_CPU_600)),y)
CPU_FLAGS=CPU_600
endif

$(DL_DIR)/$(UBOOT_SOURCE):
	mkdir -p $(DL_DIR)
	$(WGET) -P $(DL_DIR) $(UBOOT_SITE)/$(UBOOT_SOURCE)

uBoot-source: $(DL_DIR)/$(UBOOT_SOURCE)

$(UBOOT_DIR)/.unpacked: $(DL_DIR)/$(UBOOT_SOURCE)
	mkdir -p $(BUILD_DIR)
	$(UBOOT_UNZIP) $(DL_DIR)/$(UBOOT_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(PATCH_KERNEL) $(UBOOT_DIR) patch uBoot.patch
	touch $(UBOOT_DIR)/.unpacked

$(UBOOT_DIR)/.configured: $(UBOOT_DIR)/.unpacked

	-$(MAKE) -C $(UBOOT_DIR) UBOOT_FLAGS="$(MEM_FLAGS)" UBOOT_FLAGS2="$(CPU_FLAGS)" $(UCONFIG)_config
	touch $(UBOOT_DIR)/.configured

uBoot: $(UBOOT_DIR)/.configured
	mkdir -p $(IMAGE_DIR)
	$(MAKE)  -C $(UBOOT_DIR)
	cd $(UBOOT_DIR)/tools/bin2ldr; ./runme.sh
	cp -v $(UBOOT_DIR)/u-boot.ldr $(IMAGE_DIR)

uBoot-configure: $(UBOOT_DIR)/.configured

uBoot-clean:
	rm -f $(UBOOT_DIR)/.configured
	$(MAKE) -C $(UBOOT_DIR) clean

uBoot-config: $(UBOOT_DIR)/.configured
	$(MAKE) -C $(UBOOT_DIR) menuconfig

uBoot-dirclean:
	rm -rf $(UBOOT_DIR)

all: uBoot

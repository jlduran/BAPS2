#  Ming C (Vincent) Li - Jan 29 2008 
#  mchun.li at gmail dot com 
#
#  See files/crontab for some usage hints and uClinux-dist/usr/cron/README
#  for more information.

include rules.mk

CRON_VERSION=1.0
CRON_NAME=cron
CRON_DIR=$(UCLINUX_DIST)/user/$(CRON_NAME)
CRON_BUILD_DIR=$(UCLINUX_DIST)/user/$(CRON_NAME)
TARGET_DIR=$(TOPDIR)/tmp/cron/ipkg/cron

PKG_NAME:=cron
PKG_VERSION:=$(CRON_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/cron

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib
CRON_CFLAGS=-O2 -Wall -D__uClinux__ -DEMBED -fno-builtin -mfdpic \
 -I$(UCLINUX_DIST) -isystem  $(STAGING_INC) -isystem  $(STAGING_INC)

cron: $(CRON_BUILD_DIR)/cron.o $(CRON_BUILD_DIR)/cron-parent.o
	bfin-linux-uclibc-gcc -mfdpic -B$(STAGING_LIB) -L$(STAGING_LIB)  -o $(CRON_BUILD_DIR)/cron $^

	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	cp -v $(CRON_BUILD_DIR)/cron $(TARGET_DIR)/bin/
	mkdir -p $(TARGET_DIR)/etc/init.d/
	cp files/cron.init $(TARGET_DIR)/etc/init.d/cron
	chmod a+x $(TARGET_DIR)/etc/init.d/cron
	mkdir -p $(TARGET_DIR)/etc/config/
	cp files/crontab $(TARGET_DIR)/etc/config/crontab

	touch $(PKG_BUILD_DIR)/.built

all: cron


$(CRON_BUILD_DIR)/cron.o: $(CRON_BUILD_DIR)/cron.c $(CRON_BUILD_DIR)/bitstring.h
	bfin-linux-uclibc-gcc $(CRON_CFLAGS) -c -o $@ $<

$(CRON_BUILD_DIR)/cron-parent.o: $(CRON_BUILD_DIR)/cron-parent.c
	bfin-linux-uclibc-gcc $(CRON_CFLAGS) -c -o $@ $<

distclean:
	-rm -f $(CRON_BUILD_DIR)/cron $(CRON_BUILD_DIR)/*.o

.PHONY: all distclean


#---------------------------------------------------------------------------
#                              CREATING PACKAGE
#---------------------------------------------------------------------------

define Package/cron
  SECTION:=core
  CATEGORY:=Applications
  TITLE:=CRON
  DESCRIPTION:=\
        CRON is a small version of the cron daemon.
  URL:=http://www.gnu.org/software/gcron/main.html
  ARCHITECTURE:=bfin-uclinux
endef

# post installation - add the sym link for auto start

define Package/cron/postinst
#!/bin/sh
/etc/init.d/cron enable
endef

# pre-remove - remove sym link

define Package/cron/prerm
#!/bin/sh
/etc/init.d/cron disable
endef

$(eval $(call BuildPackage,cron))

cron-package: cron $(PACKAGE_DIR)/cron_$(VERSION)_$(PKGARCH).ipk

# procps for the Blackfin 
# David Rowe March 2008
#
# Useful utils like slabtop, a complete top etc.
#
# usage: make -f procps.mk procps-package

include rules.mk
PROCPS_MAJOR=3
PROCPS_SUBVERSION=2
PROCPS_MINOR=7
PROCPS_VERSION=$(PROCPS_MAJOR).$(PROCPS_SUBVERSION).$(PROCPS_MINOR)
PROCPS_DIRNAME=procps-$(PROCPS_VERSION)
PROCPS_DIR=$(BUILD_DIR)/$(PROCPS_DIRNAME)
PROCPS_SITE=http://procps.sourceforge.net/
PROCPS_SOURCE=procps-$(PROCPS_VERSION).tar.gz
PROCPS_UNZIP=zcat

CFLAGS = -I$(STAGING_DIR)/usr/include -I. -D_GNU_SOURCE \
	 -DVERSION=\"$(PROCPS_MAJOR)\" \
	 -DSUBVERSION=\"$(PROCPS_SUBVERSION)\" 
LDFLAGS = -L$(STAGING_DIR)/usr/lib -lncurses

TARGET_DIR=$(BUILD_DIR)/tmp/procps/ipkg/procps
PKG_NAME:=procps
PKG_VERSION:=$(PROCPS_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/procps

$(DL_DIR)/$(PROCPS_SOURCE):
	$(WGET) -P $(DL_DIR) $(PROCPS_SITE)/$(PROCPS_SOURCE)

$(PROCPS_DIR)/.unpacked: $(DL_DIR)/$(PROCPS_SOURCE)
	$(PROCPS_UNZIP) $(DL_DIR)/$(PROCPS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(PROCPS_DIR)/.unpacked

procps: $(PROCPS_DIR)/.unpacked
	cd $(PROCPS_DIR); \
	bfin-linux-uclibc-gcc $(CFLAGS)	$(LDFLAGS) \
	slabtop.c proc/slab.c proc/version.c -o slabtop; \
	bfin-linux-uclibc-gcc $(CFLAGS)	$(LDFLAGS) \
	top.c proc/devname.c proc/readproc.c \
	proc/sig.c proc/sysinfo.c proc/version.c \
	proc/whattime.c proc/pwcache.c proc/alloc.c \
	proc/ksym.c proc/escape.c -o top

	mkdir -p $(TARGET_DIR)/bin
	cd $(PROCPS_DIR); cp -f slabtop top $(TARGET_DIR)/bin
	$(STRIP) $(TARGET_DIR)/bin/slabtop

	mkdir -p $(TARGET_DIR)/usr/doc
	cp doc/procps.txt $(TARGET_DIR)/usr/doc

	touch $(PKG_BUILD_DIR)/.built

all: procps

define Package/$(PKG_NAME)
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=proc utils like slabtop, top...
  DESCRIPTION:=\
        procps is the package that has a bunch of small useful		\\\
        utilities that give information about processes using the	\\\
        /proc filesystem. The package includes the programs ps, top,	\\\
        vmstat, w, kill, free, slabtop, and skill.

  URL:=http://procps.sourceforge.net
endef

# post installation

$(eval $(call BuildPackage,$(PKG_NAME)))

procps-package: procps $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk



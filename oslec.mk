# oslec.mk

include rules.mk

OSLEC_NAME=oslec
export OSLEC_DIR=$(BUILD_DIR)/$(OSLEC_NAME)
OSLEC_SITE=http://svn.astfin.org/software/oslec/trunk
TARGET_DIR=$(TOPDIR)/tmp/oslec/ipkg/oslec

PKG_NAME:=oslec
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/oslec

MOD_PATH:=$(UCLINUX_DIST)/root/lib/modules
MOD_DIR:=$(shell ls $(UCLINUX_DIST)/root/lib/modules)

$(OSLEC_DIR):
	mkdir -p $(TOPDIR)
	svn co $(OSLEC_SITE) $(OSLEC_NAME)
	patch -p0 < patch/oslec.patch

oslec: $(OSLEC_DIR)
	make -C $(UCLINUX_DIST) SUBDIRS=$(OSLEC_DIR)/kernel modules
	make -C $(OSLEC_DIR)/user

	mkdir -p $(TARGET_DIR)/lib/modules/$(MOD_DIR)/misc
	cp -f $(OSLEC_DIR)/kernel/oslec.ko \
        $(TARGET_DIR)/lib/modules/$(MOD_DIR)/misc

	mkdir -p $(TARGET_DIR)/bin
	cp -f $(OSLEC_DIR)/user/sample $(TARGET_DIR)/bin

	touch $(PKG_BUILD_DIR)/.built

all: oslec

oslec-dirclean:
	rm -Rf $(OSLEC_DIR)

define Package/oslec
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Oslec echo canceller
  DESCRIPTION:=\
        Open Source Line Echo Canceller, a high quality free echo \\\
	canceller for Asterisk.
  URL:=http://www.rowetel.com/ucasterisk/oslec.html
endef

# post installation - add the modules.dep entry

define Package/oslec/postinst
#!/bin/sh
cd /lib/modules/$(MOD_DIR)/misc
cat modules.dep | sed '/.*oslec.ko:/ d' > modules.tmp
cp -f modules.tmp modules.dep
rm -r modules.tmp
echo /lib/modules/$(MOD_DIR)/misc/oslec.ko: >> modules.dep

# device node for sample util
mknod -m 666 /dev/sample c 33 0

endef

# pre-remove - remove the modules.dep entry

define Package/oslec/prerm
#!/bin/sh
cd /lib/modules/$(MOD_DIR)
cat modules.dep | sed '/.*oslec.ko:/ d' > modules.tmp
cp -f modules.tmp modules.dep
rm -r modules.tmp
endef

$(eval $(call BuildPackage,oslec))

oslec-package: oslec $(PACKAGE_DIR)/oslec_$(VERSION)_$(PKGARCH).ipk

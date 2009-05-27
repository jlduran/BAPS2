# g729.mk

include rules.mk

G729_NAME=g729
export G729_DIR=$(BUILD_DIR)/$(G729_NAME)
G729_SITE=svn://sources.blackfin.uclinux.org/uclinux-dist/trunk/lib/libbfgdots
TARGET_DIR=$(TOPDIR)/tmp/g729/ipkg/g729

PKG_NAME:=g729
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/g729

$(G729_DIR):
	mkdir -p $(TOPDIR)
	svn co $(G729_SITE) $(G729_NAME)
	patch -p0 < patch/g729.patch

g729: $(G729_DIR)
	make -C $(G729_DIR)

	mkdir -p $(TARGET_DIR)/lib
	cp -f $(G729_DIR)/g729/src.fdpic/libg729ab.so \
        $(TARGET_DIR)/lib

	touch $(PKG_BUILD_DIR)/.built

all: g729

g729-dirclean:
	rm -Rf $(G729_DIR)

define Package/g729
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=G.729
  DESCRIPTION:=\
        G.729 Codec
  URL:=http://www.sipro.com
endef

# post installation

define Package/g729/postinst
endef

# pre-remove

define Package/g729/prerm
endef

$(eval $(call BuildPackage,g729))

g729-package: g729 $(PACKAGE_DIR)/g729_$(VERSION)_$(PKGARCH).ipk

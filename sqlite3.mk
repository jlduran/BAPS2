# sqlite3 for the Blackfin 
# David Rowe March 2008
#
# usage: make -f sqlite3.mk sqlite3-package
#
# Thanks OpenWRT for build options

include rules.mk

SQLITE3_VERSION=3.5.6
SQLITE3_DIRNAME=sqlite-$(SQLITE3_VERSION)
SQLITE3_DIR=$(BUILD_DIR)/$(SQLITE3_DIRNAME)
SQLITE3_SITE=http://www.sqlite.org
SQLITE3_SOURCE=sqlite-$(SQLITE3_VERSION).tar.gz
SQLITE3_CONFIGURE_OPTS = --host=bfin-linux-uclibc \
		--prefix=$(TARGET_DIR) \
                --enable-shared \
		--disable-static \
                --disable-tcl \
		--libdir=$(STAGING_LIB)

TARGET_DIR=$(BUILD_DIR)/tmp/sqlite3/ipkg/sqlite3
PKG_NAME:=sqlite3
PKG_VERSION:=$(SQLITE3_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/sqlite3

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib
export CFLAGS=-mfdpic -Os -I$(STAGING_INC)
export LDFLAGS=-L$(STAGING_LIB)

$(DL_DIR)/$(SQLITE3_SOURCE):
	mkdir -p dl
	wget -P $(DL_DIR) $(SQLITE3_SITE)/$(SQLITE3_SOURCE)

$(SQLITE3_DIR)/.unpacked: $(DL_DIR)/$(SQLITE3_SOURCE)
	zcat $(DL_DIR)/$(SQLITE3_SOURCE) | tar -C $(BUILD_DIR) -xf -
	touch $(SQLITE3_DIR)/.unpacked

$(SQLITE3_DIR)/.configured: $(SQLITE3_DIR)/.unpacked
	cd $(SQLITE3_DIR); ./configure $(SQLITE3_CONFIGURE_OPTS)
	touch $(SQLITE3_DIR)/.configured

sqlite3: $(SQLITE3_DIR)/.configured
	cd $(SQLITE3_DIR); make install

	mkdir -p $(TARGET_DIR)/bin
	mkdir -p $(TARGET_DIR)/lib
	cp $(STAGING_LIB)/libsqlite3.so.0.8.6 $(TARGET_DIR)/lib
	ln -sf libsqlite3.so.0.8.6 $(TARGET_DIR)/lib/libsqlite3.so 
	ln -sf libsqlite3.so.0.8.6 $(TARGET_DIR)/lib/libsqlite3.so.0
	$(STRIP) $(TARGET_DIR)/lib/libsqlite3.so.0.8.6

	# mv include files to staging

	cp $(TARGET_DIR)/include/* $(STAGING_INC)
	rm -Rf $(TARGET_DIR)/include

	# doc

	mkdir -p $(TARGET_DIR)/usr/doc
	cp doc/sqlite3.txt $(TARGET_DIR)/usr/doc

	touch $(PKG_BUILD_DIR)/.built

all: sqlite3

dirclean:
	rm -rf $(SQLITE3_DIR)

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=SQLite (v3.x) database engine
  DESCRIPTION:=\
        SQLite is a small C library that implements a self-contained, \\\
	embeddable, zero-configuration SQL database engine.
  URL:=http://www.sqlite.org/
endef

# post installation

define Package/$(PKG_NAME)/postinst
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

sqlite3-package: sqlite3 $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk


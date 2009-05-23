##################################################################
# gettext.mk
# David Rowe March 2008
#
# usage: make -f gettext.mk gettext-package 
# 
# Used for building and running PHP, mainly for the bindtext domain
# function.
#
###################################################################

include rules.mk

GETTEXT_SITE=http://ftp.gnu.org/pub/gnu/gettext/
GETTEXT_VERSION=0.16.1
GETTEXT_SOURCE=gettext-$(GETTEXT_VERSION).tar.gz
GETTEXT_UNZIP=zcat
GETTEXT_DIR=$(BUILD_DIR)/gettext-$(GETTEXT_VERSION)
GETTEXT_CONFIGURE_OPTS=--host=bfin-linux-uclibc \
                --enable-shared \
                --disable-rpath \
                --enable-nls \
                --disable-java \
                --disable-native-java \
                --disable-openmp \
                --with-included-gettext \
                --prefix=$(TARGET_DIR)

TARGET_DIR=$(BUILD_DIR)/tmp/gettext/ipkg/gettext
PKG_NAME:=gettext
PKG_VERSION:=$(GETTEXT_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/gettext

$(DL_DIR)/$(GETTEXT_SOURCE):
	$(WGET) -P $(DL_DIR) $(GETTEXT_SITE)/$(GETTEXT_SOURCE)

gettext-source: $(DL_DIR)/$(GETTEXT_SOURCE)

$(GETTEXT_DIR)/.unpacked: $(DL_DIR)/$(GETTEXT_SOURCE)
	tar -xzvf $(DL_DIR)/$(GETTEXT_SOURCE)
	touch $(GETTEXT_DIR)/.unpacked

$(GETTEXT_DIR)/.configured: $(GETTEXT_DIR)/.unpacked
	cd $(GETTEXT_DIR); ./configure $(GETTEXT_CONFIGURE_OPTS)

	# For some strange reason this variable needed to be commented
	# out for the (unused) test programs to build.  Alternative
	# is to work out how to disable build of test programs

	cd $(GETTEXT_DIR)/gettext-tools/src/; \
	sed -i "s|error_print_progname|//error_print_progname|" *.c

	touch $(GETTEXT_DIR)/.configured

gettext: $(GETTEXT_DIR)/.configured
	make -C $(GETTEXT_DIR)
	make -C $(GETTEXT_DIR) install

	cp $(TARGET_DIR)/include/* $(STAGING_DIR)/usr/include
	cp $(TARGET_DIR)/lib/libintl.a $(STAGING_DIR)/usr/lib
	cp $(TARGET_DIR)/lib/libintl.so.8.0.1 $(STAGING_DIR)/usr/lib
	ln -sf libintl.so.8.0.1 libintl.so
	ln -sf libintl.so.8.0.1 libintl.so.2

	# setup directories for package

	rm -Rf $(TARGET_DIR)/bin
	rm -Rf $(TARGET_DIR)/include
	rm -Rf $(TARGET_DIR)/share
	cd $(TARGET_DIR)/lib; rm -Rf gettext libasprintf* libgettextlib* \
	libgettextpo* libgettextsrc* libintl.a libintl.la

	# strip is very effective, .so shrinks from 109k to 18k
	$(STRIP) $(TARGET_DIR)/lib/libintl.so.8.0.1

	touch $(PKG_BUILD_DIR)/.built

all: gettext

dirclean:
	rm -rf $(GETTEXT_DIR)


define Package/gettext
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=GNU Internationalization library
  URL:=http://www.gnu.org/software/gettext/
  DESCRIPTION:=\
	This is the GNU gettext package.  It is interesting for authors or \\\
	maintainers of other packages or programs which they want to see \\\
	internationalized.  As one step the handling of messages in different \\\
	languages should be implemented.  For this task GNU gettext provides \\\
	the needed tools and library functions.
endef

#post installation - do nothing
define Package/$(PKG_NAME)/postinst
endef

#pre-remove
define Package/$(PKG_NAME)/prerm
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

gettext-package: gettext $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk


# hello world demo package
# David Rowe 19 October 2007

include rules.mk

export TARGET_DIR=$(TOPDIR)/tmp/hello/ipkg/hello

PKG_NAME:=hello
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/hello

hello:
	mkdir -p $(TARGET_DIR)/bin
	bfin-linux-uclibc-gcc src/hello.c -o $(TARGET_DIR)/bin/hello -Wall
	mkdir -p $(TARGET_DIR)/etc/init.d 
	cp files/hello.init $(TARGET_DIR)/etc/init.d/hello
	chmod a+x $(TARGET_DIR)/etc/init.d/hello
	touch $(PKG_BUILD_DIR)/.built

#---------------------------------------------------------------------------
#                              CREATING PACKAGE    
#---------------------------------------------------------------------------

define Package/hello
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=hello world demo program
  DESCRIPTION:=\
        A trivial demo program to show how easy baps is to use.
  URL:=http://www.rowetel.com/ucasterisk/baps.html
endef

$(eval $(call BuildPackage,hello))

hello-package: hello $(PACKAGE_DIR)/hello_$(VERSION)_$(PKGARCH).ipk

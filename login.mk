# login.mk
# David Rowe May 2008
#
# Package to install /bin/login to make telnet prompt for
# username/password.

include rules.mk

LOGIN_VERSION=1.0
LOGIN_DIRNAME=login
LOGIN_DIR=$(UCLINUX_DIST)/user/$(LOGIN_DIRNAME)

export CC = $(TARGET_CROSS)gcc
export CFLAGS = -I$(UCLINUX_DIST)
export LDFLAGS = -L$(STAGING_DIR)/usr/lib -lcrypt

TARGET_DIR=$(BUILD_DIR)/tmp/login/ipkg/login
PKG_NAME:=login
PKG_VERSION:=$(LOGIN_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/login

login:
	make -C $(LOGIN_DIR)

	mkdir -p $(TARGET_DIR)/bin
	cp $(LOGIN_DIR)/login $(TARGET_DIR)/bin/login
	mkdir -p $(TARGET_DIR)/usr/doc
	cp doc/login.txt $(TARGET_DIR)/usr/doc
	touch $(PKG_BUILD_DIR)/.built

all: login

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=login utility
  DESCRIPTION:=\
        The default telnet in the BAPS uImage does not request a \
	username/password.  This package adds the login utility  \
	which forces telnet to prompt for a username/password.
endef

# post installation

$(eval $(call BuildPackage,$(PKG_NAME)))

login-package: login $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk



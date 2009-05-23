# asterisk-gui package
# David Rowe 27 November 2007
# Updated for Dec 2008 for latest AsteriskNow
#
# Makefile Astfin packages/asterisk-gui.mk, with some
# extra code to support building ipkg.  Thanks Mark and Li :-)
#
# Build Asterisk (make -f asterisk.mk) before building this.

include rules.mk

export TARGET_DIR=$(TOPDIR)/tmp/asterisk-gui/ipkg/asterisk-gui

PKG_NAME:=asterisk-gui
PKG_VERSION:=2.0
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/asterisk-gui

#########################################################################
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# The Free Software Foundation; version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# Copyright @ 2008 Astfin <mark@astfin.org> and <Li@astfin.org>
# Primary Authors: mark@astfin.org, li@astfin.org
#########################################################################

#ASTERISKGUI_REVISION=1771
ASTERISKGUI_REVISION=2.04
ASTERISKGUI_DIR=$(BUILD_DIR)/asterisk-gui-$(ASTERISKGUI_REVISION)
ASTERISKGUI_UNPACKED=asterisk-gui-$(ASTERISKGUI_REVISION)
ASTERISKGUI_SITE=http://svn.digium.com/svn/asterisk-gui/tags/
ASTERISKGUI_VERSION=2.0.4
STAGING_INC=$(STAGING_DIR)/usr/include

$(DL_DIR)/$(ASTERISKGUI_UNPACKED):
	$(SVN) $(ASTERISKGUI_SITE)/$(ASTERISKGUI_VERSION) $(DL_DIR)/$(ASTERISKGUI_UNPACKED)

asterisk-gui-source: $(DL_DIR)/asterisk-gui


$(ASTERISKGUI_DIR)/.unpacked: $(DL_DIR)/$(ASTERISKGUI_UNPACKED)
	cp -R $(DL_DIR)/$(ASTERISKGUI_UNPACKED) $(ASTERISKGUI_DIR)
	touch $(ASTERISKGUI_DIR)/.unpacked


$(ASTERISKGUI_DIR)/.configured: $(ASTERISKGUI_DIR)/.unpacked
	touch $(ASTERISKGUI_DIR)/.configured

asterisk-gui:  $(ASTERISKGUI_DIR)/.configured
	-find $(ASTERISKGUI_DIR) -type d -name .svn | xargs rm -rf

	# ztscan (comes with later Zaptel, we use a hacked up version
	# for now).  Fix this if we move to a later Zaptel version

	bfin-linux-uclibc-gcc -I$(STAGING_INC) src/ztscan.c \
	-o $(ASTERISKGUI_DIR)/ztscan -Wall

	mkdir -p $(TARGET_DIR)/var/lib/asterisk
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/scripts
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/static-http
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/static-http/config
	cp -Rv $(ASTERISKGUI_DIR)/config/* $(TARGET_DIR)/var/lib/asterisk/static-http/config/
	cp -v $(ASTERISKGUI_DIR)/scripts/* $(TARGET_DIR)/var/lib/asterisk/scripts/
	chmod +x  $(TARGET_DIR)/var/lib/asterisk/scripts/*

	mkdir -p $(TARGET_DIR)/bin
	cp -f $(ASTERISKGUI_DIR)/ztscan $(TARGET_DIR)/bin

all: asterisk-gui

#---------------------------------------------------------------------------
#                              CREATING PACKAGE    
#---------------------------------------------------------------------------

define Package/asterisk-gui
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=asterisk-gui
  DESCRIPTION:=\
        Asterisk Now GUI.
  URL:=http://www.rowetel.com/ucasterisk/baps.html
endef

$(eval $(call BuildPackage,asterisk-gui))

asterisk-gui-package: asterisk-gui $(PACKAGE_DIR)/asterisk-gui_$(VERSION)_$(PKGARCH).ipk

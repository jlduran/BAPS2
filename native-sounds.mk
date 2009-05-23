# native sounds package
# David Rowe 23 November 2007

include rules.mk

export TARGET_DIR=$(TOPDIR)/tmp/native-sounds/ipkg/native-sounds

PKG_NAME:=hello
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/native-sounds

native-sounds:
	mkdir -p $(TARGET_DIR)/var/lib/asterisk
	cd tmp; \
	wget http://www.rowetel.com/ucasterisk/downloads/ip04/asterisk-native-sounds-20060209-01-ulaw.tar.bz2; \
	tar xjf asterisk-native-sounds-20060209-01-ulaw.tar.bz2 -C $(TARGET_DIR)/var/lib/asterisk
	touch $(PKG_BUILD_DIR)/.built

#---------------------------------------------------------------------------
#                              CREATING PACKAGE    
#---------------------------------------------------------------------------

define Package/native-sounds
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=Asterisk native sounds
  DESCRIPTION:=\
        Asterisk prompts in native mulaw format.
  URL:=http://www.rowetel.com/ucasterisk/baps.html
endef

$(eval $(call BuildPackage,native-sounds))

native-sounds-package: native-sounds $(PACKAGE_DIR)/native-sounds_$(VERSION)_$(PKGARCH).ipk

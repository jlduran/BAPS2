#########################################################
# rsync for uClinux  
# Mark Hindess Feb 2008
#
# usage: make -f rsync.mk rsync-package 
#
#########################################################

include rules.mk

RSYNC_SITE=http://downloads.openwrt.org/sources
RSYNC_VERSION=2.6.5
RSYNC_SOURCE=rsync-2.6.5.tar.gz
RSYNC_UNZIP=zcat
RSYNC_DIR=$(BUILD_DIR)/rsync-$(RSYNC_VERSION)
RSYNC_CONFIGURE_OPTS=--host=bfin-linux-uclibc --disable-locale --disable-ipv6

TARGET_DIR=$(BUILD_DIR)/tmp/rsync/ipkg/rsync
PKG_NAME:=rsync
PKG_VERSION:=$(RSYNC_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/rsync


$(DL_DIR)/$(RSYNC_SOURCE):
	$(WGET) -P $(DL_DIR) $(RSYNC_SITE)/$(RSYNC_SOURCE)

rsync-source: $(DL_DIR)/$(RSYNC_SOURCE)

$(RSYNC_DIR)/.unpacked: $(DL_DIR)/$(RSYNC_SOURCE)
	tar -xzvf $(DL_DIR)/$(RSYNC_SOURCE)
	touch $(RSYNC_DIR)/.unpacked

$(RSYNC_DIR)/.configured: $(RSYNC_DIR)/.unpacked
	chmod a+x $(RSYNC_DIR)/configure
	$(PATCH_KERNEL) $(RSYNC_DIR) patch rsync.patch
	cd $(RSYNC_DIR); ./configure $(RSYNC_CONFIGURE_OPTS)
	touch $(RSYNC_DIR)/.configured

	# setup directories for package
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin


rsync: $(RSYNC_DIR)/.configured
	make -C $(RSYNC_DIR)/ STAGEDIR=$(STAGING_DIR)
	#copy to the package location
	cp -f $(RSYNC_DIR)/rsync $(TARGET_DIR)/bin/rsync
	touch $(PKG_BUILD_DIR)/.built

all: rsync

dirclean:
	rm -rf $(RSYNC_DIR)

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=rsync
  DESCRIPTION:=\
	fast remote file copy program
  URL:=http://rsync.samba.org/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

rsync-package: rsync $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk


#---------------------------------------------------------------------------
#                              CREATING PATCHES     
#---------------------------------------------------------------------------

# Generate patches between vanilla tar ball and our 
# version.  Run this target after you have made any changes to
# to capture.

AO = rsync-$(RSYNC_VERSION)-orig
A = rsync-$(RSYNC_VERSION)

rsync-make-patch:

        # untar original, to save time we check if the orig is already there

	if [ ! -d $(RSYNC_DIR)-orig ] ; then \
		cd $(DL_DIR); tar xzf $(RSYNC_SOURCE); \
		mv $(A) $(RSYNC_DIR)-orig; \
	fi

	# fix configure to include bfin
	diff -uN \
	$(AO)/config.sub \
	$(A)/config.sub \
	> $(PWD)/patch/rsync.patch

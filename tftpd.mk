#########################################################
# tftpd-hpa for uClinux and Asterisk, 
# Jeff Knighton Feb 2008
#
# usage: make -f tftpd-hpa.mk tftpd-package 
#
#########################################################

include rules.mk

TFTPD_SITE=http://freshmeat.net/redir/tftp-hpa/14040/url_tgz
TFTPD_VERSION=0.48
TFTPD_SOURCE=tftp-hpa-0.48.tar.gz
TFTPD_UNZIP=zcat
TFTPD_DIR=$(BUILD_DIR)/tftp-hpa-$(TFTPD_VERSION)
TFTPD_CONFIGURE_OPTS=--host=bfin-linux-uclibc 

TARGET_DIR=$(BUILD_DIR)/tmp/tftpd/ipkg/tftpd
PKG_NAME:=tftpd
PKG_VERSION:=$(TFTPD_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/tftpd


$(DL_DIR)/$(TFTPD_SOURCE):
	$(WGET) -P $(DL_DIR) $(TFTPD_SITE)/$(TFTPD_SOURCE)

tftpd-source: $(DL_DIR)/$(TFTPD_SOURCE)

$(TFTPD_DIR)/.unpacked: $(DL_DIR)/$(TFTPD_SOURCE)
	tar -xzvf $(DL_DIR)/$(TFTPD_SOURCE)
	touch $(TFTPD_DIR)/.unpacked

$(TFTPD_DIR)/.configured: $(TFTPD_DIR)/.unpacked
	chmod a+x $(TFTPD_DIR)/configure
	$(PATCH_KERNEL) $(TFTPD_DIR) patch tftpd.patch
	cd $(TFTPD_DIR); CFLAGS=-D__BLACKFIN__ ./configure $(TFTPD_CONFIGURE_OPTS)
	touch $(TFTPD_DIR)/.configured

	# setup directories for package
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	mkdir -p $(TARGET_DIR)/tftpboot


tftpd: $(TFTPD_DIR)/.configured
	make -C $(TFTPD_DIR)/ STAGEDIR=$(STAGING_DIR)
	#copy to the package location
	cp -f $(TFTPD_DIR)/tftpd/tftpd $(TARGET_DIR)/bin/in.tftpd
	touch $(PKG_BUILD_DIR)/.built

all: tftpd

dirclean:
	rm -rf $(TFTPD_DIR)

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=tftpd
  DESCRIPTION:=\
	tftp (trivial file transfer protocol) server	
  URL:=http://www.kernel.org/pub/software/network/tftp/
endef

#post installation - 
define Package/$(PKG_NAME)/postinst
#!/bin/sh
cp -f /etc/inetd.conf /etc/inetd.conf.pre-tftpd
echo "tftp    dgram  udp wait   root /bin/in.tftpd -s /tftpboot" >> /etc/inetd.conf
kill -HUP `pidof inetd`
endef

#pre-remove 
define Package/$(PKG_NAME)/prerm
#!/bin/sh
cat /etc/inetd.conf | sed '/tftp/ d' > /etc/inetd.conf.tmp
cp -f /etc/inetd.conf.tmp /etc/inetd.conf
rm /etc/inetd.conf.pre-tftpd /etc/inetd.conf.tmp
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

tftpd-package: tftpd $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk


#---------------------------------------------------------------------------
#                              CREATING PATCHES     
#---------------------------------------------------------------------------

# Generate patches between vanilla tar ball and our 
# version.  Run this target after you have made any changes to
# to capture.

AO = tftp-hpa-$(TFTPD_VERSION)-orig
A = tftp-hpa-$(TFTPD_VERSION)

tftpd-make-patch:

        # untar original, to save time we check if the orig is already there

	if [ ! -d $(TFTPD_DIR)-orig ] ; then \
		cd $(DL_DIR); tar xzf $(TFTPD_SOURCE); \
		mv $(A) $(TFTPD_DIR)-orig; \
	fi

        # switch fork to vfork

	-cd $(BUILD_DIR); diff -uN \
	$(AO)/tftpd/tftpd.c \
	$(A)/tftpd/tftpd.c \
	> $(PWD)/patch/tftpd.patch



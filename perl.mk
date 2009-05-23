# 
# perl.mk
#
# Based on OpenWRT perl, attempt at working Perl for the Blackfin.

include rules.mk

PERL_VERSION=5.8.6
PERL_DIRNAME=perl-$(PERL_VERSION)
PERL_DIR=$(BUILD_DIR)/$(PERL_DIRNAME)
PERL_SITE=ftp://ftp.cpan.org/pub/CPAN/src/5.0 \
	        ftp://ftp.mpi-sb.mpg.de/pub/perl/CPAN/src/5.0 \
	   	ftp://ftp.gmd.de/mirrors/CPAN/src/5.0 \
		ftp://ftp.funet.fi/pub/languages/perl/CPAN/src/5.0
PERL_SOURCE=perl-$(PERL_VERSION).tar.gz

PERL_CONFIGURE_OPTS=

TARGET_DIR=$(BUILD_DIR)/tmp/perl/ipkg/perl
PKG_NAME:=perl
PKG_VERSION:=$(PERL_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/perl

TARGET_CC=bfin-linux-uclibc-gcc
TARGET_CFLAGS=-Os

$(DL_DIR)/$(PERL_SOURCE):
	mkdir -p dl
	wget -P $(DL_DIR) $(PERL_SITE)/$(PERL_SOURCE)

$(PERL_DIR)/.unpacked: $(DL_DIR)/$(PERL_SOURCE)
	zcat $(DL_DIR)/$(PERL_SOURCE) | tar -C $(BUILD_DIR) -xf -
	touch $(PERL_DIR)/.unpacked

$(PERL_DIR)/.configured: $(PERL_DIR)/.unpacked
	cd $(PERL_DIR); \
	rm -f config.sh Policy.sh; \
	sh Configure -de
	touch $(PERL_DIR)/.configured

perl: $(PERL_DIR)/.configured
	$(MAKE) -C $(PERL_DIR) -f Makefile.micro \
		CC="$(TARGET_CC)" OPTIMIZE="$(TARGET_CFLAGS)"
	mkdir -p $(TARGET_DIR)/usr/bin
	cp $(PERL_DIR)/microperl $(TARGET_DIR)/usr/bin
	$(STRIP) $(TARGET_DIR)/usr/bin/microperl

	touch $(PKG_BUILD_DIR)/.built

all: perl

dirclean:
	rm -rf $(PERL_DIR)

define Package/perl
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=A really minimal perl
  DESCRIPTION:=\
	A perl package without operating-specific functions such as readdir.
  URL:=http://www.perl.com/
endef

# post installation
define Package/$(PKG_NAME)/postinst
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

perl-package: perl $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

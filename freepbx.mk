# freepbx.mk
# 
# FreePBX port for the Blackfin
# David Rowe March 2008
#
# Note that the files files/sqlite3.php, files/freeepbx.patch were
# developed on an x86 version of FreePBX/sqlite3 using:
#   https://freetel.svn.sourceforge.net/svnroot/freetel/freepbx-sandbox

# TODO: 
# 1/ Reduce 6M of stuff in file/freepbx-php-libs

include rules.mk

FREEPBX_VERSION=2.4.0
FREEPBX_DIRNAME=freepbx-$(FREEPBX_VERSION)
FREEPBX_DIR=$(BUILD_DIR)/$(FREEPBX_DIRNAME)
FREEPBX_SITE= http://mirror.freepbx.org
FREEPBX_SOURCE=freepbx-$(FREEPBX_VERSION).tar.gz
FREEPBX_CONFIGURE_OPTS=

SANDBOX_SITE=https://freetel.svn.sourceforge.net/svnroot/freetel/freepbx-sandbox
SANDBOX_DIR=$(BUILD_DIR)/freepbx-sandbox

TARGET_DIR=$(BUILD_DIR)/tmp/freepbx/ipkg/freepbx
PKG_NAME:=freepbx
PKG_VERSION:=$(FREEPBX_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/freepbx

$(DL_DIR)/$(FREEPBX_SOURCE):
	mkdir -p dl
	wget -P $(DL_DIR) $(FREEPBX_SITE)/$(FREEPBX_SOURCE)

# make sure we always check for new patch, so we unpack and patch every time

.PHONY : freepbx-patch
freepbx-patch:
	mkdir -p $(SANDBOX_DIR)/patch
	rm -f $(SANDBOX_DIR)/patch/freepbx.patch
	wget -P $(SANDBOX_DIR)/patch $(SANDBOX_SITE)/patch/freepbx.patch
	wget -P $(SANDBOX_DIR)/files $(SANDBOX_SITE)/files/retrieve_conf.inc.php
	wget -P $(SANDBOX_DIR)/files $(SANDBOX_SITE)/files/do_reload.php

$(FREEPBX_DIR)/.unpacked: $(DL_DIR)/$(FREEPBX_SOURCE) freepbx-patch
	zcat $(DL_DIR)/$(FREEPBX_SOURCE) | tar -C $(BUILD_DIR) -xf -
	patch -d $(FREEPBX_DIR) -p1 < $(SANDBOX_DIR)/patch/freepbx.patch

	# additional files to implement retrieve_conf as include

	cd $(SANDBOX_DIR)/files; cp retrieve_conf.inc.php do_reload.php \
	$(FREEPBX_DIR)/amp_conf/htdocs/admin

	touch $(FREEPBX_DIR)/.unpacked

freepbx: $(FREEPBX_DIR)/.unpacked

	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)

	# PEAR/DB stuff, just cp-ed from an x86 install, this could probably
	# be edited to save a little room.  Files DB/common.php and 
	# DB/sqlite3.php are the only files that have been edited to bring 
	# PEAR/DB sqlite3 support up to date for PHP5.

	mkdir -p $(TARGET_DIR)/lib/php
	cp -af files/freepbx-php-libs/* $(TARGET_DIR)/lib/php
	find $(TARGET_DIR)/lib/php -name '.svn' | xargs rm -Rf

	# edit amportal.conf ------------------------------------------------

        #     out with the old......

	cat $(FREEPBX_DIR)/amportal.conf | \
	sed -e '/AMPDBENGINE=/ d' -e '/AMPDBFILE=/ d' \
	-e '/AMPWEBROOT=/ d' -e '/FOPWEBROOT=/ d' \
	-e '/AMPDBHOST=/ d' -e '/AMPDBUSER=/ d' -e '/AMPDBPASS=/ d' \
	> $(FREEPBX_DIR)/amportal.conf.tmp

	mv $(FREEPBX_DIR)/amportal.conf.tmp $(FREEPBX_DIR)/amportal.conf

        #    in with the new........

	echo "AMPDBENGINE=sqlite3" >> $(FREEPBX_DIR)/amportal.conf
	echo "AMPDBFILE=/var/freepbx.db" >> $(FREEPBX_DIR)/amportal.conf
	echo "AMPWEBROOT=/www" >> $(FREEPBX_DIR)/amportal.conf
	echo "FOPWEBROOT=/www/panel" >> $(FREEPBX_DIR)/amportal.conf

	sed -i "s|/var/www/html|/www|" $(FREEPBX_DIR)/amportal.conf

	# edit other files with hard coded paths -----------------------------

	# change recordings/includes/main.conf.php DBENGINE and DBFILE 
	# settings which are hard coded for mysql

	sed -i "s|ASTERISKCDR_DBENGINE.*|ASTERISKCDR_DBENGINE=\"sqlite3\";|" \
	$(FREEPBX_DIR)/amp_conf/htdocs/recordings/includes/main.conf.php
	sed -i "s|ASTERISKCDR_DBFILE.*|ASTERISKCDR_DBFILE=\"/var/asteriskcdr.db\";|" \
	$(FREEPBX_DIR)/amp_conf/htdocs/recordings/includes/main.conf.php

	# change admin/cdr/lib/defines DB_TYPE and DBNAME settings

	sed -i "s|\"DBNAME\".*|\"DBNAME\",\"/var/asteriskcdr.db\");|" \
	$(FREEPBX_DIR)/amp_conf/htdocs/admin/cdr/lib/defines.php
	sed -i "s|\"DB_TYPE\".*|\"DB_TYPE\",\"sqlite3\");|" \
	$(FREEPBX_DIR)/amp_conf/htdocs/admin/cdr/lib/defines.php

	# switch off mp3 support as I dont have asterisk-addons and Asterisk
	# keeps crashing when I start it

	sed -i "s|load => format_mp3.so|;load => format_mp3.so|" \
	$(FREEPBX_DIR)/amp_conf/astetc/modules.conf

	# just grab entire distro, as we will install on target

	cp -af $(FREEPBX_DIR) $(TARGET_DIR)/$(FREEPBX_DIRNAME)

	touch $(PKG_BUILD_DIR)/.built

all: freepbx

dirclean:
	rm -rf $(FREEPBX_DIR)

define Package/$(PKG_NAME)/postinst
#!/bin/sh -x
# configure php.ini for FreePBX
sed -i -e "/include_path/ d" /etc/php.ini
echo include_path=\".:/lib/php\" >> /etc/php.ini
cp -af /etc/asterisk /etc/asterisk.orig
endef

# pre-remove
#!/bin/sh -x
define Package/$(PKG_NAME)/prerm
# replace asterisk conf files
rm -f /etc/asterisk
mv /etc/asterisk.orig /etc/asterisk
endef

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:= php
  TITLE:=FreePBX is a full-featured PBX web application
  DESCRIPTION:=\
        FreePBX is a standardized implementation of Asterisk and is \\\
	based around a web-based configuration interface and other tools.
  URL:=http://www.freepbx.org/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

freepbx-package: freepbx $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk


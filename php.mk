# php5 for the Blackfin 
# David Rowe March 2008
#
# usage: make -f php.mk php-package
#
# Thanks Mike Taht for working out initial Blackfin config, and Astfin
# guys for helping me with sqlite3 support.
#
# Build options have been selected for running FreePBX on the
# Blackfin.
#
# You need to build a bunch of other stuff first, e.g. from a scratch BAPS
# check out:
#
#   [baps]$ make -f uClinux.mk && make -f libssl.mk && make -f libiconv.mk
#   [baps]$ make -f gettext.mk gettext-package
#   [baps]$ make -f sqlite3.mk sqlite3-package
#   [baps]$ make -f libxml.mk libxml-package
#   [baps]$ make -f php.mk php-package

# Notes:
#
# 1/ Run time memory is still around 6.6M for dynamic linked (e.g. just
# ./php).  Would be nice to reduce this....
# 2/ Strip reduced exe size from 8.3M to 2.4M
# 3/ Idea: further weight loss might be possible by looking at
#    all the options reported in php_info() and working out
#    which ones we can disable at ./configure time.
# 4/ Can php and php-cgi be combined in some way, e.g. via exporting
#    some of their functionality to .so's?  

include rules.mk

###################################################
# PHP setting for uCLinux
####################################################

PHP_VERSION=5.2.5
PHP_DIRNAME=php-$(PHP_VERSION)
PHP_DIR=$(BUILD_DIR)/$(PHP_DIRNAME)
PHP_SITE=http://www.php.net/distributions
PHP_SOURCE=php-$(PHP_VERSION).tar.bz2
PHP_UNZIP=bzcat

# NOTE: --enable-pdo --with-pdo-sqlite were found to be essential for
# reliable operation of php with sqlite3 on the Blackfin, even though
# PDO is not used for FreePBX.  Without these options php hangs or
# core dumps.

#PHP_CONFIGURE_OPTS=--host=bfin-linux-uclibc --target=bfin-linux-uclibc --disable-all --disable-ipv6 --enable-session --with-sqlite  --with-pcre-regex --with-pear=$(PHP_DIR)/pear --enable-pdo --with-pdo-sqlite --with-sqlite3=$(DL_DIR)/ext/pdo_sqlite/sqlite/src --enable-fastcgi --enable-xml --enable-libxml --with-libxml-dir=$(STAGING_DIR) --enable-memory-limit --prefix=/etc --with-config-file-path=/etc --with-gettext

# test small PHP.  Can we make this smaller?
PHP_CONFIGURE_OPTS=--host=bfin-linux-uclibc --target=bfin-linux-uclibc --disable-all --disable-ipv6  --prefix=/etc --with-config-file-path=/etc

export CFLAGS = -Os -g -Wall -I$(STAGING_DIR)/usr/include -I$(STAGING_DIR)/include/libxml2
export LDFLAGS = -L$(STAGING_DIR)/usr/lib -lpthread -ldl -lintl

export CROSS_COMPILE=bfin-linux-uclibc-

TARGET_DIR=$(BUILD_DIR)/tmp/php/ipkg/php
PKG_NAME:=php
PKG_VERSION:=$(PHP_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/php

$(DL_DIR)/$(PHP_SOURCE):
	$(WGET) -P $(DL_DIR) $(PHP_SITE)/$(PHP_SOURCE)

php-source: $(DL_DIR)/$(PHP_SOURCE)

$(PHP_DIR)/.unpacked: $(DL_DIR)/$(PHP_SOURCE)
	$(PHP_UNZIP) $(DL_DIR)/$(PHP_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	cp -rf files/sqlite3/ $(PHP_DIR)/ext/
	touch $(PHP_DIR)/.unpacked

$(PHP_DIR)/.configured: $(PHP_DIR)/.unpacked
	cd $(PHP_DIR); ./buildconf --force ; ./configure $(PHP_CONFIGURE_OPTS)
	touch $(PHP_DIR)/.configured

php: $(PHP_DIR)/.configured
	$(MAKE)	CROSS="$(TARGET_CROSS)" \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		-C "$(PHP_DIR)"

	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	find $(PHP_DIR) -name php-cgi -exec cp -v "{}" $(TARGET_DIR)/bin \;	

	# php needed to run am_conf/bin/retrieve_conf on FreePBX
	find $(PHP_DIR) -name php -exec cp -v "{}" $(TARGET_DIR)/bin \;

	# this saves a few 100k
	$(STRIP) $(TARGET_DIR)/bin/php-cgi
	$(STRIP) $(TARGET_DIR)/bin/php

	mkdir -p $(TARGET_DIR)/etc
	cp $(PHP_DIR)/php.ini-recommended $(TARGET_DIR)/etc/php.ini-recommended

	# optional fast-cgi startup script and lighttpd.conf for php-cgi
	mkdir -p $(TARGET_DIR)/etc/init.d
	cp files/fastphp $(TARGET_DIR)/etc/init.d
	cp files/lighttpd-fastphp.conf $(TARGET_DIR)/etc

	mkdir -p $(TARGET_DIR)/www
	cp files/test.php files/testdb.php $(TARGET_DIR)/www
	cp files/test.php files/test_.php $(TARGET_DIR)/www

	mkdir -p $(TARGET_DIR)/usr/doc
	cp doc/php.txt $(TARGET_DIR)/usr/doc

	touch $(PKG_BUILD_DIR)/.built

all: php

define Package/$(PKG_NAME)
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=PHP5 Hypertext preprocessor
  DEPENDS:= pagecache lighttpd gettext sqlite3 libxml
  DESCRIPTION:=\
        PHP is a widely-used general-purpose scripting language that \\\
	is especially suited for Web development and can be embedded \\\
	into HTML.
  URL:=http://www.php.net/
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
#
# configure lighttpd
# remove any existing cgi.assign lines and add cgi-assign for php-cgi
mkdir -p /usr/bin
ln -sf /bin/php /usr/bin/php
ln -sf /bin/php-cgi /usr/bin/php-cgi
sed -i -e "/cgi.assign.*php/ d" /etc/lighttpd.conf
echo 'cgi.assign = (".php" => "/bin/php-cgi")' >> /etc/lighttpd.conf
/etc/init.d/lighttpd stop
/etc/init.d/lighttpd start
#
# preserve existing php.ini
if  [ ! -f /etc/php.ini ] ; then \
  cp /etc/php.ini-recommended /etc/php.ini; \
fi
exit 0
endef

# pre-remove

define Package/$(PKG_NAME)/prerm
#!/bin/sh
# remove cgi.assign line
sed -i -e "/cgi.assign.*php/ d" /etc/lighttpd.conf
/etc/init.d/lighttpd stop
/etc/init.d/lighttpd start
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

php-package: php $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk



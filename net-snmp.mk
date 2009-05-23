#####################################################
# net-snmp setting for uCLinux and asterisk
# created by Kelvin Chua
# nextIX-INF
# kelvin@nextixsystems.com
#####################################################

include rules.mk

CROSS_COMPILE=bfin-linux-uclibc
NETSNMP_SITE=http://downloads.sourceforge.net/net-snmp
NETSNMP_VERSION=5.4.1
NETSNMP_SOURCE=net-snmp-$(NETSNMP_VERSION).tar.gz
NETSNMP_DIR=$(BUILD_DIR)/net-snmp-$(NETSNMP_VERSION)
NETSNMP_CFLAGS=-g -mfdpic -mfast-fp -ffast-math -D__FIXED_PT__ -D__BLACKFIN__
NETSNMP_LDFLAGS=-mfdpic
NETSNMP_CONFIGURE_OPTS=--host=$(CROSS_COMPILE) --with-endianness=little --disable-perl-cc-checks --disable-embedded-perl --without-perl-modules
NETSNMP_CONFIGURE_OPTS_TEMP=--host=$(CROSS_COMPILE) --with-endianness=little --prefix=$(STAGING_DIR) \
                       --exec-prefix=$(STAGING_DIR) --enable-mini-agent --with-defaults --disable-manuals \
                       --disable-snmptrapd-subagent --disable-debugging --enable-static --disable-shared \
                       --with-out-mib-modules="default_modules" \
                       --with-mibdirs=/etc/asterisk/mibs --with-mib-modules="host utilities/execute agentx mibII/vacm_vars snmpv3/usmConf" \
                       --disable-perl-cc-checks --disable-embedded-perl --without-perl-modules --disable-applications \
                       --disable-snmptrapd-subagent --disable-scripts --disable-md5 \
                       --without-rpm --without-openssl --without-dmalloc --without-efence --without-rsaref --without-krb5 
                       CFLAGS="$(NETSNMP_CFLAGS)" LDFLAGS="$(NETSNMP_LDFLAGS)"

TARGET_DIR=$(BUILD_DIR)/tmp/net-snmp/ipkg/net-snmp
PKG_NAME:=net-snmp
PKG_VERSION:=$(TFTPD_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/net-snmp

$(DL_DIR)/$(NETSNMP_SOURCE):
	$(WGET) -P $(DL_DIR) $(NETSNMP_SITE)/$(NETSNMP_SOURCE)

net-snmp-source: $(DL_DIR)/$(NETSNMP_SOURCE)

$(NETSNMP_DIR)/.unpacked: $(DL_DIR)/$(NETSNMP_SOURCE)
	tar -xvzf $(DL_DIR)/$(NETSNMP_SOURCE)
	touch $(NETSNMP_DIR)/.unpacked

$(NETSNMP_DIR)/.configured: $(NETSNMP_DIR)/.unpacked
	cd $(NETSNMP_DIR); ./configure $(NETSNMP_CONFIGURE_OPTS)
	$(PATCH_KERNEL) $(NETSNMP_DIR) patch net-snmp.patch
	ln -sf $(NETSNMP_DIR)/net-snmp-config opt/uClinux/bfin-linux-uclibc/bin/bfin-linux-uclibc-net-snmp-config
	touch $(NETSNMP_DIR)/.configured
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	mkdir -p $(TARGET_DIR)/etc
	mkdir -p $(TARGET_DIR)/lib

net-snmp: $(NETSNMP_DIR)/.configured
	make -C $(NETSNMP_DIR)/ STAGEDIR=$(STAGING_DIR)
	cp -f $(NETSNMP_DIR)/agent/.libs/snmpd $(TARGET_DIR)/bin/
	cp -fd $(NETSNMP_DIR)/agent/.libs/lib*so* $(STAGING_DIR)/usr/lib/
	cp -fd $(NETSNMP_DIR)/agent/helpers/.libs/lib*so* $(STAGING_DIR)/usr/lib/
	cp -fd $(NETSNMP_DIR)/snmplib/.libs/lib*so* $(STAGING_DIR)/usr/lib/
	cp -fd $(NETSNMP_DIR)/agent/.libs/lib*so* $(TARGET_DIR)/lib/
	cp -fd $(NETSNMP_DIR)/agent/helpers/.libs/lib*so* $(TARGET_DIR)/lib/
	cp -fd $(NETSNMP_DIR)/snmplib/.libs/lib*so* $(TARGET_DIR)/lib/
	cp -fr $(NETSNMP_DIR)/include/net-snmp $(STAGING_DIR)/usr/include/
	mkdir -p $(TARGET_DIR)/etc/default
	cp -f files/sample.snmpd.conf $(TARGET_DIR)/etc/default/snmpd.conf
	mkdir -p $(TARGET_DIR)/etc/init.d
	cp -f files/snmpd.init $(TARGET_DIR)/etc/init.d/snmpd
	chmod +x $(TARGET_DIR)/etc/init.d/snmpd
	touch $(PKG_BUILD_DIR)/.built

all: net-snmp

net-snmp-clean:
	cd $(NETSNMP_DIR); make clean;

net-snmp-dirclean:
	rm -rf $(NETSNMP_DIR)

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=net-snmp
  VERSION:=5.4.1
  DESCRIPTION:=\
        net-snmp server (with agentx support)
  URL:=http://net-snmp.sourceforge.net/
endef

#post installation -
define Package/$(PKG_NAME)/postinst
#!/bin/sh
mkdir -p /var/agentx
/etc/init.d/snmpd enable
/etc/init.d/snmpd start
endef

#pre-remove
define Package/$(PKG_NAME)/prerm
#!/bin/sh
/etc/init.d/snmpd stop
/etc/init.d/snmpd disable
rm -rf /var/agentx
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

net-snmp-package: net-snmp $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

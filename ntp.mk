#  Ming C (Vincent) Li - Jan 29 2008 
#  mchun.li at gmail dot com 
#  Originated from $(UCLINUX_DIST)/user/ntp/makefile

include rules.mk

NTP_VERSION=4.2.4p4
NTP_NAME=ntp
NTP_DIR=$(UCLINUX_DIST)/user/ntp/$(NTP_NAME)-$(NTP_VERSION)
NTP_BUILD_DIR=$(UCLINUX_DIST)/user/ntp/$(NTP_NAME)-$(NTP_VERSION)/builddir
TARGET_DIR=$(TOPDIR)/tmp/ntp/ipkg/ntp

PKG_NAME:=ntp
PKG_VERSION:=$(NTP_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/ntp

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib
NTP_CFLAGS=-O2 -Wall -D__uClinux__ -DEMBED -fno-builtin -mfdpic \
 -I$(UCLINUX_DIST) -isystem  $(STAGING_INC)
NTP_LDFLAGS=-mfdpic -B$(STAGING_INC) -L$(STAGING_INC)
NTP_CONFIGURE_OPTS=--host=bfin-linux-uclibc \
                   --build=i686-pc-linux-gnu \
                   --target=bfin-linux-uclibc --prefix=/usr --sysconfdir=/etc \
                   --datadir=/usr/share --mandir=/usr/share/man --infodir=/usr/share/info \
                   --localstatedir=/var/lib

NTPDATE := with

ifdef CONFIG_USER_NTPD_NTPDC
NTPDC := with
else
NTPDC := without
endif

ifdef CONFIG_USER_NTPD_NTPQ
NTPQ := with
else
NTPQ := without
endif

CONFOPTIONS=                                                               \
        --disable-debugging     \
        --disable-HOPFSERIAL --disable-HOPFPCI --disable-BANCOMM           \
        --disable-GPSVME --disable-SHM --disable-all-clocks                \
        --disable-ACTS --disable-ARBITER --disable-ARCRON-MSF              \
        --disable-ATOM --disable-AS2201 --disable-CHU --disable-AUDIO-CHU  \
        --disable-DATUM --disable-FG --disable-HEATH --disable-HPGPS       \
        --disable-IRIG --disable-JJY --disable-LEITCH                      \
        --disable-LOCAL-CLOCK --disable-MSFEES --disable-MX4200            \
        --disable-NMEA --disable-ONCORE --disable-PALISADE --disable-PST   \
        --disable-JUPITER --disable-PTBACTS --disable-TPRO --disable-TRAK  \
        --disable-CHRONOLOG --disable-DUMBCLOCK --disable-PCF              \
        --disable-SPECTRACOM --disable-TRUETIME --disable-ULINK            \
        --disable-WWV --disable-USNO --disable-parse-clocks                \
        --disable-COMPUTIME --disable-DCF7000 --disable-HOPF6021           \
        --disable-MEINBERG --disable-RAWDCF --disable-RCC8000              \
        --disable-SCHMID --disable-TRIMTAIP --disable-TRIMTSIP             \
        --disable-WHARTON --disable-VARITEXT --disable-kmem                \
        --without-openssl-libdir --without-openssl-incdir --without-crypto \
        --without-electricfence --without-sntp --$(NTPDATE)-ntpdate \
        --$(NTPDC)-ntpdc --$(NTPQ)-ntpq

$(NTP_BUILD_DIR)/Makefile: $(NTP_DIR)/makefile
	cd $(NTP_DIR)
	find $(NTP_DIR) -type f -print0 | xargs -0 touch -r $(NTP_DIR)/configure
	rm -rf $(NTP_BUILD_DIR)
	mkdir $(NTP_BUILD_DIR)
	cd $(NTP_BUILD_DIR) && \
	CC="bfin-linux-uclibc-gcc $(NTP_CFLAGS)" LDFLAGS="$(NTP_LDFLAGS)" LIBS="" \
        MISSING="true" \
        ../configure \
                $(NTP_CONFIGURE_OPTS) $(CONFOPTIONS)

ntp: $(NTP_BUILD_DIR)/Makefile
	$(MAKE) -C $(NTP_BUILD_DIR) CFLAGS='$(NTP_CFLAGS) -DCONFIG_FILE=\"/etc/config/ntp.conf\"'

	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	cp -v $(NTP_BUILD_DIR)/ntpd/ntpd $(TARGET_DIR)/bin/
	cp -v $(NTP_BUILD_DIR)/ntpdate/ntpdate $(TARGET_DIR)/bin/
	mkdir -p $(TARGET_DIR)/etc/init.d/
	cp files/ntp.init $(TARGET_DIR)/etc/init.d/ntp
	chmod a+x $(TARGET_DIR)/etc/init.d/ntp
	touch $(PKG_BUILD_DIR)/.built
	mkdir -p $(TARGET_DIR)/usr/doc
	cp -v doc/ntp.txt $(TARGET_DIR)/usr/doc

distclean:
	rm -rf $(NTP_BUILD_DIR)

.PHONY: ntp distclean


#---------------------------------------------------------------------------
#                              CREATING PACKAGE
#---------------------------------------------------------------------------

define Package/ntp
  SECTION:=net
  CATEGORY:=Network
  TITLE:=NTP
  DESCRIPTION:=\
        NTP is a protocol designed to synchronize the clocks of computers over a network. \\\
        only ntpd is packaged in for now.
  URL:=http://www.ntp.org/
  ARCHITECTURE:=bfin-uclinux

endef

# post installation - add the sym link for auto start

define Package/ntp/postinst
#!/bin/sh
echo "ntp             123/tcp"  >> /etc/services
echo "ntp             123/udp"  >> /etc/services
echo EST5 > /etc/TZ
echo "export TZ=`cat /etc/TZ`" > /etc/profile
/etc/init.d/ntp enable
endef

# pre-remove - remove sym link

define Package/ntpd/prerm
#!/bin/sh
cd /etc
cat services | sed '/ntp/ d' > services.tmp
mv services.tmp services
rm -rf /bin/ntpd
rm -rf /bin/ntpdate
/etc/init.d/ntp disable
rm -rf /etc/init.d/ntp
endef

$(eval $(call BuildPackage,ntp))

ntp-package: ntp $(PACKAGE_DIR)/ntp_$(VERSION)_$(PKGARCH).ipk

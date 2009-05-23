# voiptel-gui package, pre-release version
# VoIPtel 18 March 2008
#
# based on the asterisk-gui package, for use on IP04/IP08
#
# Build Asterisk (make -f asterisk.mk) before building this.

include rules.mk

TARGET_DIR=$(TOPDIR)/tmp/voiptel-gui-pre/ipkg/voiptel-gui-pre
VOIPTELGUI_DIR=$(BUILD_DIR)/voiptel-gui

PKG_NAME:=voiptel-gui-pre
PKG_VERSION:=1.1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/voiptel-gui-pre

.PHONY: voiptel-gui-pre

voiptel-gui-pre:
	rm -Rf $(TARGET_DIR)

	# install asterisk-now files

	mkdir -p $(TARGET_DIR)/var/lib/asterisk
	mkdir -p $(TARGET_DIR)/etc/asterisk/scripts
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/static-http
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/static-http/config
	mkdir -p $(TARGET_DIR)/etc/init.d
	cp files/network-voiptel.init $(TARGET_DIR)/etc/init.d/network-voiptel
	chmod u+x $(TARGET_DIR)/etc/init.d/network-voiptel
	cp -Rv $(VOIPTELGUI_DIR)/asterisk-gui/config/* $(TARGET_DIR)/var/lib/asterisk/static-http/config/
	rm -f $(TARGET_DIR)/var/lib/asterisk/static-http/gui_sysinfo
	mkdir -p $(TARGET_DIR)/bin
	cp -a $(VOIPTELGUI_DIR)/asterisk-gui/scripts/gui_sysinfo $(TARGET_DIR)/bin/
	cp -v $(VOIPTELGUI_DIR)/asterisk-gui/gui_configs/gui_custommenus.conf $(TARGET_DIR)/bin/
	cp -a $(VOIPTELGUI_DIR)/asterisk-gui/scripts/* $(TARGET_DIR)/etc/asterisk/scripts
	chmod +x $(TARGET_DIR)/bin/gui_sysinfo

	# Install Voiptel /etc/asterisk conf files 
	# Note we install to /etc/asterisk.voiptel to avoid clash with exisiting /etc/asterisk
	# The postinst script renames /etc/asterisk.voiptel to /etc/asterisk

	mkdir -p $(TARGET_DIR)/etc/asterisk.voiptel
	cp -a $(VOIPTELGUI_DIR)/etc-asterisk/* $(TARGET_DIR)/etc/asterisk.voiptel

	# install Voiptel shell scipts in /etc/voiptel-gui

	mkdir -p $(TARGET_DIR)/etc/voiptel-gui
	cp -a $(VOIPTELGUI_DIR)/scripts/* $(TARGET_DIR)/etc/voiptel-gui

	# make sure we don't include any SVN or temp files in the ipkg

	-find $(TARGET_DIR) -type d -name .svn | xargs rm -rf
	-find $(TARGET_DIR) -name '*~' | xargs rm -rf

	touch $(PKG_BUILD_DIR)/.built

all: voiptel-gui-pre

#---------------------------------------------------------------------------
#                              CREATING PACKAGE    
#---------------------------------------------------------------------------

# The busybox dependency is for a missing utility (tr) that the GUI requires

define Package/voiptel-gui-pre
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=voiptel-gui-pre
  DEPENDS:=busybox
  MAINTAINER:=Voiptel
  DESCRIPTION:=\
        VoIPtel GUI, pre-release version.  An upgraded and debugged	\
        version of the AsteriskNow GUI for Blackfin Asterisk.
  URL:=http://www.voiptel.no
endef

# NOTE: the $$var type variables are escapes so Make doesn't interpret
#       the $var.  They end up being $var in the postinst/prerm scripts

define Package/voiptel-gui-pre/postinst
#!/bin/sh -x

# replace conf files without ipkg installer complaining

mv /etc/asterisk /etc/asterisk.backup
mv /etc/asterisk.voiptel /etc/asterisk

# set up a bunch of directories needed for voiptel-gui

[ ! -d /var/log/cdr-csv ] && mkdir /var/log/cdr-csv
[ ! -d /var/log/cdr-custom ] && mkdir /var/log/cdr-custom
[ ! -d /var/lib/asterisk/gui_configbackups ] && mkdir /var/lib/asterisk/gui_configbackups
if [ ! -d /default/etc/asterisk ]; then
     mkdir -p /default/etc
     cp -r /etc/asterisk /default/etc
fi
ln -sfn /var/lib/asterisk/sounds /sounds

# detect current network settings and copy to voiptel-gui compatible
# network script in /etc/asterisk/rc.conf

if [ -f /etc/rc.d/S10network ]
then

  # dhcp network

  /etc/init.d/network disable

  # check if dhcpcd is running and enable it in new config if yes

  ps | grep -v grep | grep dhcpcd
  if [ $$? -eq 0 ]
  then
    sed -i 's/DHCPD=.*/DHCPD=yes/g' /etc/asterisk/rc.conf
  fi
fi

if [ -f /etc/rc.d/S10network-static ]
then

  # static network

  /etc/init.d/network-static disable

  tmpipaddr=`sed -n 's/IPADDRESS="\(.*\)"/\1/p' /etc/init.d/network-static`
  tmpnetmask=`sed -n 's/NETMASK="\(.*\)"/\1/p' /etc/init.d/network-static`
  tmpgateway=`sed -n 's/GATEWAY="\(.*\)"/\1/p' /etc/init.d/network-static`
  tmpdns=`sed -n 's/DNS="\(.*\)"/\1/p' /etc/init.d/network-static`
  sed -i "s/DHCPD=.*/DHCPD=no/g" /etc/asterisk/rc.conf
  sed -i "s/IPADDRESS=.*/IPADDRESS=\"$$tmpipaddr\"/g" /etc/asterisk/rc.conf
  sed -i "s/NETMASK=.*/NETMASK=\"$$tmpnetmask\"/g" /etc/asterisk/rc.conf
  sed -i "s/GATEWAY=.*/GATEWAY=\"$$tmpgateway\"/g" /etc/asterisk/rc.conf
  sed -i "s/DNS=.*/DNS=\"$$tmpdns\"/g" /etc/asterisk/rc.conf
fi

# finally enable voiptel network start up script

/etc/init.d/network-voiptel enable

endef

define Package/voiptel-gui-pre/prerm
#!/bin/sh -x

# restore backup conf files

mv /etc/asterisk.backup /etc/asterisk

# cp network parameters back

/etc/init.d/network-voiptel disable

tmpdhcpd=`sed -n 's/DHCPD=\(.*\)/\1/p' /etc/asterisk/rc.conf`

if [ "$$tmpdhcpd" == "yes" ]
then
  /etc/init.d/network enable
else
  # static network, copy params back

  tmpipaddr=`sed -n 's/IPADDRESS="\(.*\)"/\1/p' /etc/asterisk/rc.conf`
  tmpnetmask=`sed -n 's/NETMASK="\(.*\)"/\1/p' /etc/asterisk/rc.conf`
  tmpgateway=`sed -n 's/GATEWAY="\(.*\)"/\1/p' /etc/asterisk/rc.conf`
  tmpdns=`sed -n 's/DNS="\(.*\)"/\1/p' /etc/asterisk/rc.conf`

  sed -i "s/IPADDRESS=.*/IPADDRESS=\"$$tmpipaddr\"/g" /etc/init.d/network-static
  sed -i "s/NETMASK=.*/NETMASK=\"$$tmpnetmask\"/g" /etc/init.d/network-static
  sed -i "s/GATEWAY=.*/GATEWAY=\"$$tmpgateway\"/g" /etc/init.d/network-static
  sed -i "s/DNS=.*/DNS=\"$$tmpdns\"/g" /etc/init.d/network-static
  /etc/init.d/network-static enable
fi

endef

$(eval $(call BuildPackage,voiptel-gui-pre))

voiptel-gui-pre-package: voiptel-gui-pre $(PACKAGE_DIR)/voiptel-gui-pre_$(VERSION)_$(PKGARCH).ipk

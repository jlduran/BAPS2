#  Ming C (Vincent) Li - Jan 14 2008 
#  mchun.li at gmail dot com 


include rules.mk

IPTABLES_VERSION=1.3.6
IPTABLES_NAME=iptables
IPTABLES_DIR=$(UCLINUX_DIST)/user/$(IPTABLES_NAME)
IPTABLES_EXT_DIR=$(UCLINUX_DIST)/user/$(IPTABLES_NAME)/extensions
TARGET_DIR=$(TOPDIR)/tmp/iptables/ipkg/iptables

PKG_NAME:=iptables
PKG_VERSION:=$(IPTABLES_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/iptables

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib
IPTABLES_CFLAGS=-Wall -Wunused -I$(IPTABLES_DIR)/include/ -DIPTABLES_VERSION=\"1.3.6\" -O2 -Wall -D__uClinux__ -DEMBED \
-fno-builtin -mfdpic -I$(UCLINUX_DIST) -isystem  $(STAGING_INC) -DNO_SHARED_LIBS=1


#all: iptables.o libipt_tcp.o libipt_udp.o libipt_icmp.o libipt_standard.o initext.c initext.o libext.a libip4tc.o libiptc.a iptables

iptables: $(IPTABLES_DIR)/iptables-multi.c $(IPTABLES_DIR)/iptables-save.c $(IPTABLES_DIR)/iptables-restore.c \
          $(IPTABLES_DIR)/iptables-standalone.c $(IPTABLES_DIR)/iptables.o $(IPTABLES_EXT_DIR)/libext.a $(IPTABLES_DIR)/libiptc/libiptc.a

	cd $(IPTABLES_DIR)
	bfin-linux-uclibc-gcc $(IPTABLES_CFLAGS) -DIPTABLES_MULTI -DIPT_LIB_DIR=\"/usr/local/lib/iptables\" -B$(STAGING_LIB) -L$(STAGING_LIB) \
        -o $(IPTABLES_DIR)/iptables $^
	
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	cp -v $(IPTABLES_DIR)/iptables $(TARGET_DIR)/bin/

	touch $(PKG_BUILD_DIR)/.built

all: iptables

$(IPTABLES_DIR)/iptables.o: $(IPTABLES_DIR)/iptables.c
	bfin-linux-uclibc-gcc $(IPTABLES_CFLAGS) -DIPT_LIB_DIR=\"/usr/local/lib/iptables\" -c -o $@ $<
$(IPTABLES_EXT_DIR)/libipt_tcp.o: $(IPTABLES_EXT_DIR)/libipt_tcp.c
	bfin-linux-uclibc-gcc $(IPTABLES_CFLAGS) -D_INIT=ipt_tcp_init -c -o $@ $< 
$(IPTABLES_EXT_DIR)/libipt_udp.o: $(IPTABLES_EXT_DIR)/libipt_udp.c
	bfin-linux-uclibc-gcc $(IPTABLES_CFLAGS) -D_INIT=ipt_udp_init -c -o $@ $< 
$(IPTABLES_EXT_DIR)/libipt_icmp.o: $(IPTABLES_EXT_DIR)/libipt_icmp.c
	bfin-linux-uclibc-gcc $(IPTABLES_CFLAGS) -D_INIT=ipt_icmp_init -c -o $@ $< 
$(IPTABLES_EXT_DIR)/libipt_standard.o: $(IPTABLES_EXT_DIR)/libipt_standard.c
	bfin-linux-uclibc-gcc $(IPTABLES_CFLAGS) -D_INIT=ipt_standard_init -c -o $@ $< 

$(IPTABLES_EXT_DIR)/initext.c: 
	echo "" > $(IPTABLES_EXT_DIR)/initext.c
	for i in ipt_tcp ipt_udp ipt_icmp ipt_standard ; do \
		echo "extern void ${i}_init(void);" >> $(IPTABLES_EXT_DIR)/initext.c; \
        done
	echo "void init_extensions(void) {" >> $(IPTABLES_EXT_DIR)/initext.c
	for i in ipt_tcp ipt_udp ipt_icmp ipt_standard ; do \
		echo "  ${i}_init();" >> $(IPTABLES_EXT_DIR)/initext.c; \
        done
	echo "}" >> $(IPTABLES_EXT_DIR)/initext.c

$(IPTABLES_EXT_DIR)/initext.o: $(IPTABLES_EXT_DIR)/initext.c
	bfin-linux-uclibc-gcc $(IPTABLES_CFLAGS) -c -o $@ $<
$(IPTABLES_EXT_DIR)/libext.a: $(IPTABLES_EXT_DIR)/libipt_tcp.o $(IPTABLES_EXT_DIR)/libipt_udp.o \
          $(IPTABLES_EXT_DIR)/libipt_icmp.o $(IPTABLES_EXT_DIR)/libipt_standard.o \
          $(IPTABLES_EXT_DIR)/initext.o
	rm -f $(IPTABLES_EXT_DIR)/libext.a
	bfin-linux-uclibc-ar cr $@ $^
	bfin-linux-uclibc-ranlib $@ 

$(IPTABLES_DIR)/libiptc/libip4tc.o: $(IPTABLES_DIR)/libiptc/libip4tc.c
	bfin-linux-uclibc-gcc $(IPTABLES_CFLAGS) -c -o $@ $<
$(IPTABLES_DIR)/libiptc/libiptc.a: $(IPTABLES_DIR)/libiptc/libip4tc.o
	bfin-linux-uclibc-ar rv $@ $<

.PHONY: distclean

distclean:
	-rm -f $(IPTABLES_EXT_DIR)/initext.c
	-rm -f $(IPTABLES_DIR)/iptables
	@-find $(IPTABLES_DIR) -name '*.[ao]' -o -name '*.so' | xargs rm -f
	@-find $(IPTABLES_DIR) -name '*.gdb' -print | xargs rm -f
	

#---------------------------------------------------------------------------
#                              CREATING PACKAGE
#---------------------------------------------------------------------------

define Package/iptables
  SECTION:=net
  CATEGORY:=Network
  TITLE:=IPTABLES
  DESCRIPTION:=\
        iptables is the userspace command line program used to configure the Linux 2.4.x and 2.6.x IPv4 packet filtering ruleset. \\\
        It is targeted towards system administrators.
  URL:=http://www.netfilter.org/projects/iptables/index.html
  ARCHITECTURE:=bfin-uclinux

endef

# post installation - add the sym link for auto start

define Package/iptables/postinst
#!/bin/sh
ln -sf /bin/iptables /bin/iptables-save
ln -sf /bin/iptables /bin/iptables-restore
endef

# pre-remove - remove sym link

define Package/iptables/prerm
#!/bin/sh
rm -rf /bin/iptables
rm -rf /bin/iptables-save
rm -rf /bin/iptables-restore
endef

$(eval $(call BuildPackage,iptables))

iptables-package: iptables $(PACKAGE_DIR)/iptables_$(VERSION)_$(PKGARCH).ipk


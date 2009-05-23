#########################################################
# libpcap for uClinux and Asterisk, 
# Ming C. Li April 2008
#
# usage: make -f libpcap.mk libpcap
#
# Run after building uClinux-dist, copies shared libs to
# uClinux-dist/staging, ready for use in Asterisk if 
# required.
#########################################################

include rules.mk

LIBPCAP_SITE=http://www.tcpdump.org/release
LIBPCAP_VERSION=0.9.8
LIBPCAP_SOURCE=libpcap-0.9.8.tar.gz
LIBPCAP_UNZIP=zcat
LIBPCAP_DIR=$(BUILD_DIR)/libpcap-$(LIBPCAP_VERSION)
LIBPCAP_CONFIGURE_OPTS=--host=bfin-linux-uclibc \
	--prefix=$(TARGET_DIR) \
	--sysconfdir=/etc \
	--datadir=/usr/share \
	--localstatedir=/var/lib \
	--with-pcap=linux \

$(DL_DIR)/$(LIBPCAP_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBPCAP_SITE)/$(LIBPCAP_SOURCE)

libpcap-source: $(DL_DIR)/$(LIBPCAP_SOURCE)

$(LIBPCAP_DIR)/.unpacked: $(DL_DIR)/$(LIBPCAP_SOURCE)
	$(LIBPCAP_UNZIP) $(DL_DIR)/$(LIBPCAP_SOURCE) | \
	tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	find $(LIBPCAP_DIR) '(' -name '*.orig' -o -name '*.rej' ')' -exec rm -f {} \;
	$(PATCH_KERNEL) $(LIBPCAP_DIR) patch libpcap.patch

	touch $(LIBPCAP_DIR)/.unpacked

$(LIBPCAP_DIR)/.configured: $(LIBPCAP_DIR)/.unpacked
	cd $(LIBPCAP_DIR); ./configure $(LIBPCAP_CONFIGURE_OPTS)
	touch $(LIBPCAP_DIR)/.configured

libpcap: $(LIBPCAP_DIR)/.configured
	make -C $(LIBPCAP_DIR)/ STAGEDIR=$(STAGING_DIR)
	cp -f $(LIBPCAP_DIR)/libpcap.a $(STAGING_DIR)/usr/lib


all: libpcap

dirclean:
	rm -rf $(LIBPCAP_DIR)


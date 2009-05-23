#########################################################
# vim  for uClinux  
# Mark Hindess Feb 2008
#
# usage: make -f vim.mk vim-package 
#
#########################################################

include rules.mk

VIM_SITE=http://downloads.openwrt.org/sources
VIM_VERSION=7.1
VIM_SOURCE=vim-7.1.tar.bz2
VIM_CROSS_COMPILE_SITE=\
  http://svn.cross-lfs.org/svn/repos/cross-lfs/branches/clfs-sysroot/patches
VIM_CROSS_COMPILE_PATCH=vim-7.1-cross_compile-1.patch
VIM_UNZIP=bzcat
VIM_DIR_BASENAME=vim71
VIM_DIR=$(BUILD_DIR)/$(VIM_DIR_BASENAME)
VIM_CONFIGURE_OPTS=--host=bfin-linux-uclibc --prefix=/usr \
  --with-tlib=ncurses --with-features=small --without-x --disable-netbeans

TARGET_DIR=$(BUILD_DIR)/tmp/vim/ipkg/vim
PKG_NAME:=vim
PKG_VERSION:=$(VIM_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/vim


$(DL_DIR)/$(VIM_SOURCE):
	$(WGET) -P $(DL_DIR) $(VIM_SITE)/$(VIM_SOURCE)

$(DL_DIR)/$(VIM_CROSS_COMPILE_PATCH):
	$(WGET) -P $(DL_DIR) \
		$(VIM_CROSS_COMPILE_SITE)/$(VIM_CROSS_COMPILE_PATCH)

vim-source: $(DL_DIR)/$(VIM_SOURCE) $(DL_DIR)/$(VIM_CROSS_COMPILE_PATCH)

$(VIM_DIR)/.unpacked: $(DL_DIR)/$(VIM_SOURCE) $(DL_DIR)/$(VIM_CROSS_COMPILE_PATCH)
	tar -xjvf $(DL_DIR)/$(VIM_SOURCE)
	touch $(VIM_DIR)/.unpacked

$(VIM_DIR)/.configured: $(VIM_DIR)/.unpacked
	chmod a+x $(VIM_DIR)/configure
	cd $(VIM_DIR); patch -p1 <$(DL_DIR)/$(VIM_CROSS_COMPILE_PATCH)
	$(PATCH_KERNEL) $(VIM_DIR) patch vim.patch
	cd $(VIM_DIR); LDFLAGS="-L$(STAGING_DIR)/usr/lib" \
	  ./configure $(VIM_CONFIGURE_OPTS)
	touch $(VIM_DIR)/.configured

vim: $(VIM_DIR)/.configured
	make -C $(VIM_DIR)/ STAGEDIR=$(STAGING_DIR)
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	mkdir -p $(TARGET_DIR)/usr/share/vim
	cp -f $(VIM_DIR)/src/vim $(TARGET_DIR)/bin/vim
	echo set nocompatible > $(TARGET_DIR)/usr/share/vim/vimrc
	touch $(PKG_BUILD_DIR)/.built

all: vim

dirclean:
	rm -rf $(VIM_DIR)

define Package/$(PKG_NAME)
  SECTION:=editor
  CATEGORY:=Editor
  TITLE:=vim
  DESCRIPTION:=\
	Vim is an almost compatible version of the UNIX editor Vi
  URL:=http://www.vim.org/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

vim-package: vim $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk


#---------------------------------------------------------------------------
#                              CREATING PATCHES     
#---------------------------------------------------------------------------

# Generate patches between vanilla tar ball and our 
# version.  Run this target after you have made any changes to
# to capture.

AO = $(VIM_DIR_BASENAME)-orig
A = $(VIM_DIR_BASENAME)

vim-make-patch:

        # untar original, to save time we check if the orig is already there

	if [ ! -d $(VIM_DIR)-orig ] ; then \
		cd $(DL_DIR); tar xjf $(VIM_SOURCE); \
		mv $(A) $(VIM_DIR)-orig; \
	fi

	# change default terminal type to one that ip04 has defined
	-cd $(BUILD_DIR);  diff -uN \
        $(AO)/src/term.c \
        $(A)/src/term.c \
        > $(PWD)/patch/vim.patch
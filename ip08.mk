# ip08.mk
# Creates alll the packages needed for the baseline IP08

all:
	make -f uClinux.mk
	make -f oslec.mk oslec-package
	make -f zaptel.mk zaptel-package
	make -f asterisk.mk asterisk-package
	make -f asterisk-gui.mk asterisk-gui-package

#
# Asterisk -- A telephony toolkit for Linux.
#
# Tools makefile
#
# Copyright (C) 1999-2006, Digium, Inc.
#
# Mark Spencer <markster@digium.com>
#
# This program is free software, distributed under the terms of
# the GNU General Public License

ifeq ($(PBX_ZAPTEL),1)
TOOLS:=zapscan.bin
endif

all: $(TOOLS)

zapscan.bin: zapscan.o
	$(CC) -o $@ $^

zapscan.o: CFLAGS+=$(ZAPTEL_INCLUDE) $(ASTCFLAGS)

install:
ifeq ($(PBX_ZAPTEL),1)
	mkdir -p $(ASTSBINDIR)
	$(INSTALL) -m 755 zapscan.bin $(ASTSBINDIR)
	$(INSTALL) -m 755 zapscan.bin /sbin
	$(INSTALL) -m 755 zapscan $(ASTSBINDIR)
	$(INSTALL) -m 755 zapscan /sbin	
endif

clean: 
	rm -f zapscan.o
	rm -f zapscan.bin

.PHONY: all install clean

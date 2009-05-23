/*
 * Detect Zaptel interfaces.
 *
 * Written by Mark Spencer <markster@digium.com>
 *
 * Copyright (C) 2006 Digium, Inc.
 *
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under thet erms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */  
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <zaptel/zaptel.h>

int main(int argc, char *argv[])
{
	int x;
	int oldsig=-1;
	int fd = open("/dev/zap/ctl", O_RDWR);
	struct zt_params ztp;
	FILE *zdc = fopen("/etc/zaptel.conf", "a");
	FILE *zsc = fopen("/etc/asterisk/zapscan.conf", "w");
	FILE *zap = fopen("/etc/asterisk/zapata.conf", "a");
	if (fd < 0) {
		fprintf(stderr, "Failed to open /dev/zap/ctl: %s\n", strerror(errno));
		exit(1);
	}
	if (!zdc||!zsc||!zap) {
		fprintf(stderr, "Failed to open zaptel.conf or zapscan.conf or zapata.conf");
		exit(1);
	}
	for (x=1;;x++) {
		memset(&ztp, 0, sizeof(ztp));
		ztp.channo = x;
		if (ioctl(fd, ZT_GET_PARAMS, &ztp))
			break;
		switch (ztp.sigcap & (__ZT_SIG_FXO|__ZT_SIG_FXS)) {
		case __ZT_SIG_FXO:
			if (oldsig != 1) {
				fprintf(zdc, "\nfxoks=%d", x);
				fprintf(zap, "\nsignalling = fxo_ks\nchannel => %d",x);
			} else {
				fprintf(zdc, ",%d",x);
				fprintf(zap, ",%d",x);
			}
			fprintf(zsc, "[%d]\nport=fxo\n", x);
			oldsig = 1;
			break;
		case __ZT_SIG_FXS:
			if (oldsig != 2) {
				fprintf(zdc, "\nfxsks=%d", x);
				fprintf(zap, "\nsignalling = fxs_ks\nchannel => %d",x);
			} else {
				fprintf(zdc, ",%d",x);
				fprintf(zap, ",%d",x);
			}
			fprintf(zsc, "[%d]\nport=fxs\n", x);
			oldsig = 2;
			break;
		}
	}
	fprintf(zdc, "\n");
	fprintf(zsc, "\n");
	fprintf(zap, "\n");
	fclose(zdc);
	fclose(zsc);
	fclose(zap);
	exit(0);
}

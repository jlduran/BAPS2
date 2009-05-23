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

void strip_lines(const char* filename, const char* text1, const char* text2);

int main(int argc, char *argv[])
{
	int x;
	int oldsig=-1;
	int fd = open("/dev/zap/ctl", O_RDWR);
	struct zt_params ztp;
	FILE *zdc,*zsc,*zap;

	strip_lines("/etc/zaptel.conf","fxoks=","fxsks=");
	strip_lines("/etc/asterisk/zapata.conf","signalling =","channel =>");

	zdc = fopen("/etc/zaptel.conf", "a");
	zsc = fopen("/etc/asterisk/zapscan.conf", "w");
	zap = fopen("/etc/asterisk/zapata.conf", "a");
	if (fd < 0) {
		fprintf(stderr, "Failed to open /dev/zap/ctl: %s\n", strerror(errno));
		exit(1);
	}
/*	if (!zdc||!zsc||!zap) {
		fprintf(stderr, "Failed to open zaptel.conf or zapscan.conf or zapata.conf");
		exit(1);
	}
*/
	for (x=1;;x++) {
		memset(&ztp, 0, sizeof(ztp));
		ztp.channo = x;
		if (ioctl(fd, ZT_GET_PARAMS, &ztp))
			break;
		switch (ztp.sigcap & (__ZT_SIG_FXO|__ZT_SIG_FXS)) {
		case __ZT_SIG_FXO:
			if (oldsig != 1) {
				if (zdc) fprintf(zdc, "\nfxoks=%d", x);
				if (zap) fprintf(zap, "\nsignalling = fxo_ks\nchannel => %d",x);
			} else {
				if (zdc) fprintf(zdc, ",%d",x);
				if (zap) fprintf(zap, ",%d",x);
			}
			if (zsc) fprintf(zsc, "[%d]\nport=fxo\n", x);
			oldsig = 1;
			break;
		case __ZT_SIG_FXS:
			if (oldsig != 2) {
				if (zdc) fprintf(zdc, "\nfxsks=%d", x);
				if (zap) fprintf(zap, "\nsignalling = fxs_ks\nchannel => %d",x);
			} else {
				if (zdc) fprintf(zdc, ",%d",x);
				if (zap) fprintf(zap, ",%d",x);
			}
			if (zsc) fprintf(zsc, "[%d]\nport=fxs\n", x);
			oldsig = 2;
			break;
		}
	}
	if (zdc) fprintf(zdc, "\n");
	if (zsc) fprintf(zsc, "\n");
	if (zap) fprintf(zap, "\n");
	if (zdc) fclose(zdc);
	if (zsc) fclose(zsc);
	if (zap) fclose(zap);
	exit(0);
}

void strip_lines(const char* filename, const char* text1, const char* text2)
{
	FILE *fp, *fptemp;
	char curr_line[255];
	char prev_line[255];
	char* tempfile = tmpnam(0);
	fp = fopen(filename,"r");
	fptemp = fopen(tempfile,"w");
	if (fp && fptemp)
	{
	  prev_line[0] = '\0';
	  /*loop though each line and write out lines that don't
	   *begin with text1 or text2 */
	   while (fgets(curr_line,sizeof(curr_line),fp))
	   {
	      if ((!memcmp(curr_line,text1,strlen(text1)) ||
	           (!memcmp(curr_line,text2,strlen(text2)))))
	      {
		if (prev_line[0] == '\n')
		{
		    prev_line[0] = '\0';
		}
		curr_line[0] = '\0';
	      }
	      fputs(prev_line,fptemp);
	      memcpy(prev_line,curr_line,sizeof(prev_line));
	   }
 	   fputs(prev_line,fptemp);
	   fclose(fp);
	   fclose(fptemp);
	   /*remove the old file*/
	   remove(filename);
	   /*move the new file into place*/
	   rename(tempfile,filename);
	}
	else
	{
	  if (fp) fclose(fp);
	  if (fptemp) fclose(fptemp);
	}
}


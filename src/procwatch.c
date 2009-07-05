/*
 * procwatch - Process monitor using Standard Linux Watchdog API
 *
 * Copyright (C) 2006-2008, Digium, Inc.
 *
 * Doug Bailey <dbailey@digium.com>
 *
 * See http://www.asterisk.org for more information about
 * the Asterisk project. Please do not directly contact
 * any of the maintainers of this project for assistance;
 * the project provides a web site, mailing lists and IRC
 * channels for your use.
 *
 * This program is free software, distributed under the terms of
 * the GNU General Public License Version 2. 
 */

#include <dirent.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <time.h>
#include <unistd.h>
#include <fcntl.h>
#include <asm/page.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/sysinfo.h>
#include <sys/types.h>
#include <linux/version.h>
#include <linux/watchdog.h>
#include <syslog.h>

#define MAX_PROC_NAME_SIZE	256
#define MAX_PROCESS			32
#define DEFAULT_SLEEP_VAL 	(2000)
#define DEFAULT_CACHE_MEMORY_TRIGGER 	(12000)

#define STATUS_LINE_ARG		"Name:"

#define CACHED_MEMORY_ARG		"Cached:"

struct app_monitor {
		char * name;
		int valid;
		int online;
};

/*** Local Prototypes ***/
static void show_usage(void);
static void try_to_free_cache(int val);
/*static int memory_in_cache(void);*/
static int log_status(int class, char * fmt,...);
static int find_processes(struct app_monitor *list, int list_len);

/*** Global Variable Declarations ***/
char * log_filename = NULL;

int main(int argc, char ** argv)
{
	struct app_monitor proc_monitor[MAX_PROCESS];
	int 			num_to_monitor = 0; 
	unsigned long 	sleep_val = DEFAULT_SLEEP_VAL; 
	unsigned long 	new_sleep;
	int 			watchdog_time = 0;
	int 			fd_watchdog;
	char 			* dummy;
	int				opt;
	int 			daemon = 0;
	pid_t 			pid, sid;
	long			memory_cache_trigger = DEFAULT_CACHE_MEMORY_TRIGGER;
	int 			last_dog_skipped = 0;
	unsigned		cache_flush_count = 0;
	struct sysinfo 	sys_info;

	opterr = 0;
	while ((opt = getopt(argc, argv, "?dc:l:p:t:w:")) > 0) {
		switch (opt) {
			case 'p':
				proc_monitor[num_to_monitor].name 	= optarg;
				proc_monitor[num_to_monitor].valid 	= 0;
				proc_monitor[num_to_monitor].online = 0;
				num_to_monitor++;
				break;
			case 't':
				new_sleep = strtoul(optarg, &dummy, 10);
				if (0 < new_sleep) {
					sleep_val = new_sleep;
				}
				break;
			case 'w':
				watchdog_time = atoi(optarg);
				break;
			case 'd':
				daemon = 1;
				break;
			case 'c':
				memory_cache_trigger = strtoul(optarg, &dummy, 10);
				break;
			case 'l':
				log_filename = optarg; 
				break;
			default:
				show_usage();
				exit(EXIT_SUCCESS);
		}
	}

    if (daemon){	/*NOTE uClinux does not support fork - Save it for later*/
		/* Fork off process */
		pid = fork();
		if (pid < 0) {
			perror("Cannot Fork child process\n");
			exit(EXIT_FAILURE);
		}
        /* If we got a good PID, then
			we can exit the parent process. */
		else if (pid > 0) {
			exit(EXIT_SUCCESS);
		}

		/* Change the file mode mask */
		umask(0);

		/* new SID for the child process */
		sid = setsid();
		if (sid < 0) {
			perror("Cannot set the Watchdog Monitor child SID \n");
			_exit(EXIT_FAILURE);
		}
	}
	
	fd_watchdog = open("/dev/watchdog", O_RDWR);

	if (fd_watchdog == -1) {
		fprintf(stderr, "Cannot open the watchdog timer\n");
		_exit(1);
	}

	if (0 < watchdog_time) {
		ioctl(fd_watchdog, WDIOC_SETTIMEOUT, &watchdog_time);
		fprintf(stdout, "The watchdog timeout has been set to %d seconds\n", watchdog_time);
		log_status(LOG_INFO, "The watchdog timeout has been set to %d seconds\n", watchdog_time);
	}

	while (1) {
		if (0 == find_processes(proc_monitor, num_to_monitor)) {
			write(fd_watchdog, "\0", 1);
			if (last_dog_skipped) {
				log_status(LOG_INFO, "%s\n", "Restart hitting Watchdog");
				last_dog_skipped = 0;
			}
		} else {
			if (!last_dog_skipped) {
				log_status(LOG_INFO, "%s\n", "Skipping Watchdog");
				last_dog_skipped = 1;
			}
		}
		/* Sleep between checking for processes */
		usleep(1000 * sleep_val);
		/* check to see if the free memory is below what we want.  if so, clean it out. */
		if (!sysinfo(&sys_info)) {
			if (memory_cache_trigger > (sys_info.freeram / (1024 * sys_info.mem_unit))) {
				if (0 == (cache_flush_count % 32)) {
					log_status(LOG_INFO, "Cache flush, Memory at %dKB (desired %d)\n", sys_info.freeram / (1024 * sys_info.mem_unit), memory_cache_trigger );
				}
				cache_flush_count++;
				try_to_free_cache(3);
			} else {
				if (1 < cache_flush_count) {	/* If multiple attempts to flush cache, indicate so */
					log_status(LOG_INFO, "Memory OK @ %dKB, Cache flush attempts = %d\n", sys_info.freeram / (1024 * sys_info.mem_unit), cache_flush_count );
				}
				cache_flush_count = 0;
			}
		} else {
			/* Can't get sys info spec, assume I need to free up memory */
			log_status(LOG_INFO, "Cache flush, Cannot read memory status\n", sys_info.freeram );
			try_to_free_cache(3);
		}
	}
	return 0;
}

/* Display command line usage */
static void show_usage(void)
{
	fprintf(stdout, "procwatch - Watchdog monitor for one or more processes (and disk cache monitor)\n");
	fprintf(stdout, "Usage: \n");
	fprintf(stdout, "procwatch [-t <time in mS>] [-w <watchdog timer value in seconds>] [-p <process name>] [-l <log file>] [-d] \n");
	fprintf(stdout, "\t\t-t - specified time to sleep between checks (in milliseconds)\n");
	fprintf(stdout, "\t\t-w - specified time for the watchdog to timeout (in seconds)\n");
	fprintf(stdout, "\t\t-p - specific process name to monitor.  Program waits for the process to become active.\n");
	fprintf(stdout, "\t\t     After the program is active, it must stay alive for the watchdog to be refreshed.\n");
	fprintf(stdout, "\t\t     There can be multiple processes monitored by the program.\n");
	fprintf(stdout, "\t\t-c - Number of kilobytes under which free memory must go that triggers a cleanup the system disk cache.\n");
	fprintf(stdout, "\t\t     (The disk cache eats up free memory which causes the free memory sysinfo to be \n");
	fprintf(stdout, "\t\t      non-indicative of the actual memory available) \n");
	fprintf(stdout, "\t\t-l - specify a log file into which event information can be written\n");
	fprintf(stdout, "\t\t-d - run the program as a daemon. (Not supported under uClinux.)\n");
	fprintf(stdout, "\t\t-? - See this usage.\n");
	
}

/* 
 * Finds whether the list of processes passed to the function are currently active. 
 * The function uses the proc file system to find the active processes. 
 * 
 * The it looks at the Name field in the /proc/<id>/status file for the 
 * desired process name.  
 */

static int find_processes(struct app_monitor *list, int list_len)
{
	int unfound_process;
	int offline_process;

	DIR    			*dir;
	int 			pid;
	int 			valid_line;
	int				x, y, n;
	struct dirent 	*entry;
	FILE 			*fp;
	char 			*proc_id_name;
	char 			*cmd_line = NULL;
	char 			status[128];
	char 			buf[128];

	if (0 == list_len)
		return 0;
	else if ( 0 > list_len)
		return -1;
	
	dir = opendir("/proc");
	if (!dir)
		return -1; 
	
	/* Initialize the list to all invalid processes */
	for (n = 0, unfound_process = 0, offline_process = 0; n < list_len; n++){
		list[n].valid = 0; 	
		if (0 != list[n].online)	/* This process is online, we must find it in proc */
			unfound_process++;
		else 
			offline_process++;
		
	}
		
/* while I have not accounted for all the processes I need to check */
	while (0 < unfound_process || 0 < offline_process) {
		if ((entry = readdir(dir)) == NULL)
			break; 			/* cannot read more entries, time to get out */
		proc_id_name = entry->d_name;
		if (!(*proc_id_name >= '0' && *proc_id_name <= '9')) /* look for decimal numeric name */
			continue;

		pid = atoi(proc_id_name);
		if (0 >= pid)
			continue;
		
		buf[0] = '\0';	/* Insure termination of string */
		sprintf(status, "/proc/%d/status", pid);
		if ((fp = fopen(status, "r")) == NULL)
			continue;
		
		/* Find the Name line in the status file */
		n = 0;
		valid_line = 0;
		while (0 != valid_line || !feof(fp)) {
			/* Append data from the file into the raw buffer */
			if ((x=fread(&buf[n], 1, sizeof(buf)-1-n, fp)) > 0)
				n = x+n;
			
			/* extract a terminated line from the buffer */
			for (valid_line = 0, x = 0; x < n && x < 128; x++) {
				if (buf[x] == '\n' || buf[x] == '\r' ) {
					status[x] = '\0';
					valid_line = 1;
					x++;
					for (y = 0; x < n; y++, x++) {
						buf[y] = buf[x];
					} 
					n = y;
					buf[n] = '\0';
					break;
				} else if ( ' ' > buf[x])
					status[x] = ' '; 
				else 
					status[x] = buf[x]; 
			}
			/* see if this line starts with the desired line header*/
			if (valid_line) {
				/* set cmd_line to point to string after header name, must be first item on the line */
				if (NULL != (cmd_line= strstr( status, STATUS_LINE_ARG))) {
					cmd_line += strlen(STATUS_LINE_ARG);
					break;
				} 
			} else 
				cmd_line = NULL;
		}
		fclose(fp);
		
		/* Is the name in the list of processes to look for */ 
		if (cmd_line != NULL) {
			for (n = 0; n < list_len; n++) {
				/* If we have found this process */
				if (NULL != strstr( cmd_line, list[n].name)){
					/* first test if the process has come online, if so markit as such */
					if (0 == list[n].online){
						list[n].online = 1;
						list[n].valid = 1;	/* Mark that I checked this one */
						offline_process--;
						log_status(LOG_INFO, "Process %s is now online\n", list[n].name);
						/* If it is already online and has not been marked, then mark it */
					} else if (0 == list[n].valid){
						unfound_process--;
						list[n].valid = 1;
					}
				}
			}
		}
	}
	closedir(dir);
	dir = NULL;
	return unfound_process;
}	

#if 0  /* Using more direct sysinfo  */
/* 
 *	This function determine the number of KB allocated to page frame cache 
 * 	The value is extracted from the /proc/meminfo proc file. 
 */
static int memory_in_cache(void)
{
	char 	status[128];
	char 	buf[256];
	int 	valid_line;
	FILE  	* fp;
	int		x, y, n;
	char 	*cmd_line;
	long 	memory_amount = -1;
	
	if ((fp = fopen("/proc/meminfo", "r")) == NULL){
		return -1; 
	}
	valid_line = 0;
	n = 0;
	while (0 != valid_line || !feof(fp)) {
		/* Append data from the file into the raw buffer */
		if ((x=fread(&buf[n], 1, sizeof(buf)-1-n, fp)) > 0) {
			n = x+n;
		}
		/* extract a terminated line from the buffer */
		for (valid_line = 0, x = 0; x < n && x < 256; x++) {
			if (buf[x] == '\n' || buf[x] == '\r' ) {
				status[x] = '\0';
				valid_line = 1;
				x++;
				for (y = 0; x < n; y++, x++) {
					buf[y] = buf[x];
				} 
				n = y;
				buf[n] = '\0';
				break;
			} else if ( ' ' > buf[x]) {
				status[x] = ' '; 
			} else {
				status[x] = buf[x]; 
			}
		}
		/* see if this line starts with the desired line header*/
		if (valid_line) {
			/* set cmd_line to point to string after header name */
			if (NULL != (cmd_line= strstr( status, CACHED_MEMORY_ARG)) && cmd_line == status) {
				cmd_line += strlen(CACHED_MEMORY_ARG);
				while (' ' == *cmd_line)
					cmd_line++;
				memory_amount = strtoul(cmd_line, NULL, 10);
				break;
			} 
		} else {
			cmd_line = NULL;
		}
	}
	fclose(fp);
	return memory_amount;
}
#endif

/* 
 *	This function tries to force the system to clean out page frame cache.  
 *	It uses teh /proc/sys/vm/drop_caches tuanble to indicate to the OS to clean up the 
 * 	page frame cache. 
 */
static void try_to_free_cache(int val)
{
	FILE 	*fp;
	char	type[4];
	if ((fp = fopen("/proc/sys/vm/drop_caches", "w")) == NULL)
		return;
	
	type[1] = '\n';
	type[2] = '\0';
	if (val == 1)
		type[0] = '1';	
	else if (val == 2)
		type[0] = '2';
	else 
		type[0] = '3';
	fwrite(type, 1, 3, fp);
	fclose(fp);
}

/* 
 *	This function logs events to disk storage.  The information is
 * tagged with date and time
 */

#ifdef USE_SYSLOG
static int log_status(int class, char * fmt,...)
{
	openlog("PROCWATCH", LOG_CONS, LOG_SYSLOG);
	va_list ap;
	va_start( ap, fmt );

	vsyslog(class, fmt, ap);
	closelog();
	return 0;
}

#else

static int log_status(int class, char * fmt,...)
{
	time_t now;
	struct tm *ts;
	FILE * flog;
	char buf[80];
	int result = -1;
	char * msg_class = NULL;

	if (NULL != log_filename) {
		va_list ap;
		va_start( ap, fmt );

		switch (class) {
			case LOG_EMERG:
				msg_class = "Emergency";
				break;
			case LOG_ALERT:
				msg_class = "Alert";
				break;
			case LOG_CRIT:
				msg_class = "Critical";
				break;
			case LOG_ERR:
				msg_class = "Error";
				break;
			case LOG_WARNING:
				msg_class = "Warning";
				break;
			case LOG_NOTICE:
				msg_class = "Notice";
				break;
			case LOG_INFO:
				msg_class = "Info";
				break;
			case LOG_DEBUG:
				msg_class = "Debug";
				break;
		}
		
		if (NULL != (flog = fopen(log_filename, "a"))) {
			now = time(NULL);
			ts = localtime(&now);
			strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", ts);
			fprintf(flog, "%s: ", buf);
			if (NULL != msg_class) {
				fprintf(flog, "%s: ", msg_class);
			}
			vfprintf(flog, fmt, ap);
			fclose(flog);
			result = 0;
		} else {
			fprintf(stderr, "PROCWATCH: Unable to update log %s:\n", log_filename);
			vfprintf(stderr, fmt, ap);
		}
	}
	return result;
}

#endif

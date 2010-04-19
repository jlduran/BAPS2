/* include/autoconf.h.  Generated from autoconf.h.in by configure.  */
/* include/autoconf.h.in.  Generated from configure.in by autoheader.  */

/* Defines how many threads aufs uses for I/O */
/* #undef AUFS_IO_THREADS */

/* If you are upset that the cachemgr.cgi form comes up with the hostname
   field blank, then define this to getfullhostname() */
/* #undef CACHEMGR_HOSTNAME */

/* What default TCP port to use for HTTP listening? */
#define CACHE_HTTP_PORT 3128

/* What default UDP port to use for ICP listening? */
#define CACHE_ICP_PORT 3130

/* Host type from configure */
#define CONFIG_HOST_TYPE "i686-pc-linux-gnu"

/* Define if you want to set the COSS membuf size */
/* #undef COSS_MEMBUF_SZ */

/* Define to one of `_getb67', `GETB67', `getb67' for Cray-2 and Cray-YMP
   systems. This function is required for `alloca.c' support on those systems.
   */
/* #undef CRAY_STACKSEG_END */

/* Define to 1 if using `alloca.c'. */
/* #undef C_ALLOCA */

/* MemPool debug verifications */
/* #undef DEBUG_MEMPOOL */

/* Default FD_SETSIZE value */
#define DEFAULT_FD_SETSIZE 1024

/* Traffic management via "delay pools". */
/* #undef DELAY_POOLS */

/* Enable following X-Forwarded-For headers */
/* #undef FOLLOW_X_FORWARDED_FOR */

/* Enable Forw/Via database */
/* #undef FORW_VIA_DB */

/* If gettimeofday is known to take only one argument */
/* #undef GETTIMEOFDAY_NO_TZP */

/* Define to 1 if you have the <aio.h> header file. */
#define HAVE_AIO_H 1

/* Define to 1 if you have `alloca', as a function or macro. */
#define HAVE_ALLOCA 1

/* Define to 1 if you have <alloca.h> and it should be used (not on Ultrix).
   */
#define HAVE_ALLOCA_H 1

/* Define if your compiler supports prototyping */
#define HAVE_ANSI_PROTOTYPES 1

/* Define to 1 if you have the <arpa/inet.h> header file. */
#define HAVE_ARPA_INET_H 1

/* Define to 1 if you have the <arpa/nameser.h> header file. */
#define HAVE_ARPA_NAMESER_H 1

/* Define to 1 if you have the <assert.h> header file. */
#define HAVE_ASSERT_H 1

/* Define to 1 if you have the `backtrace_symbols_fd' function. */
#define HAVE_BACKTRACE_SYMBOLS_FD 1

/* Define to 1 if you have the `bcopy' function. */
#define HAVE_BCOPY 1

/* Define to 1 if you have the <bstring.h> header file. */
/* #undef HAVE_BSTRING_H */

/* Define to 1 if you have the <byteswap.h> header file. */
#define HAVE_BYTESWAP_H 1

/* Define to 1 if you have the `cap_clear_flag' function. */
/* #undef HAVE_CAP_CLEAR_FLAG */

/* Define to 1 if you have the `crypt' function. */
#define HAVE_CRYPT 1

/* Define to 1 if you have the <crypt.h> header file. */
#define HAVE_CRYPT_H 1

/* Define to 1 if you have the <ctype.h> header file. */
#define HAVE_CTYPE_H 1

/* Define to 1 if you have the <db_185.h> header file. */
#define HAVE_DB_185_H 1

/* Define to 1 if you have the <db.h> header file. */
#define HAVE_DB_H 1

/* Define to 1 if you have the <dirent.h> header file, and it defines `DIR'.
   */
#define HAVE_DIRENT_H 1

/* Define to 1 if you have the `drand48' function. */
#define HAVE_DRAND48 1

/* Define to 1 if you have the `epoll_ctl' function. */
#define HAVE_EPOLL_CTL 1

/* Define to 1 if you have the <errno.h> header file. */
#define HAVE_ERRNO_H 1

/* Define to 1 if you have the <execinfo.h> header file. */
#define HAVE_EXECINFO_H 1

/* Define if struct mallinfo has mxfast member */
/* #undef HAVE_EXT_MALLINFO */

/* Define to 1 if you have the `fchmod' function. */
#define HAVE_FCHMOD 1

/* Define to 1 if you have the <fcntl.h> header file. */
#define HAVE_FCNTL_H 1

/* Define to 1 if you have the <fnmatch.h> header file. */
#define HAVE_FNMATCH_H 1

/* Define to 1 if you have the `getdtablesize' function. */
#define HAVE_GETDTABLESIZE 1

/* Define to 1 if you have the <getopt.h> header file. */
#define HAVE_GETOPT_H 1

/* Define to 1 if you have the `getpagesize' function. */
#define HAVE_GETPAGESIZE 1

/* Define to 1 if you have the `getpass' function. */
#define HAVE_GETPASS 1

/* Define to 1 if you have the `getrlimit' function. */
#define HAVE_GETRLIMIT 1

/* Define to 1 if you have the `getrusage' function. */
#define HAVE_GETRUSAGE 1

/* Define to 1 if you have the `getspnam' function. */
#define HAVE_GETSPNAM 1

/* Define to 1 if you have the `gettimeofday' function. */
#define HAVE_GETTIMEOFDAY 1

/* Define to 1 if you have the <glib.h> header file. */
/* #undef HAVE_GLIB_H */

/* Define to 1 if you have the `glob' function. */
#define HAVE_GLOB 1

/* Define to 1 if you have the <glob.h> header file. */
#define HAVE_GLOB_H 1

/* Define to 1 if you have the <gnumalloc.h> header file. */
/* #undef HAVE_GNUMALLOC_H */

/* Define to 1 if you have the <grp.h> header file. */
#define HAVE_GRP_H 1

/* Define to 1 if you have the `initgroups' function. */
#define HAVE_INITGROUPS 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the <ipl.h> header file. */
/* #undef HAVE_IPL_H */

/* Define to 1 if you have the <ip_compat.h> header file. */
/* #undef HAVE_IP_COMPAT_H */

/* Define to 1 if you have the <ip_fil_compat.h> header file. */
/* #undef HAVE_IP_FIL_COMPAT_H */

/* Define to 1 if you have the <ip_fil.h> header file. */
/* #undef HAVE_IP_FIL_H */

/* Define if struct ip has ip_hl member */
#define HAVE_IP_HL 1

/* Define to 1 if you have the <ip_nat.h> header file. */
/* #undef HAVE_IP_NAT_H */

/* Define to 1 if you have the `kqueue' function. */
/* #undef HAVE_KQUEUE */

/* Define to 1 if you have the <libc.h> header file. */
/* #undef HAVE_LIBC_H */

/* Define to 1 if you have the `gnumalloc' library (-lgnumalloc). */
/* #undef HAVE_LIBGNUMALLOC */

/* Define to 1 if you have the `m' library (-lm). */
#define HAVE_LIBM 1

/* Define to 1 if you have the `malloc' library (-lmalloc). */
/* #undef HAVE_LIBMALLOC */

/* Define to 1 if you have the `pthread' library (-lpthread). */
/* #undef HAVE_LIBPTHREAD */

/* Define to 1 if you have the <limits.h> header file. */
#define HAVE_LIMITS_H 1

/* Define to 1 if you have the <linux/netfilter_ipv4.h> header file. */
#define HAVE_LINUX_NETFILTER_IPV4_H 1

/* Define to 1 if you have the <linux/netfilter_ipv4/ip_tproxy.h> header file.
   */
/* #undef HAVE_LINUX_NETFILTER_IPV4_IP_TPROXY_H */

/* Define to 1 if you have the `lrand48' function. */
#define HAVE_LRAND48 1

/* Define to 1 if you have the `mallinfo' function. */
#define HAVE_MALLINFO 1

/* Define to 1 if you have the `mallocblksize' function. */
/* #undef HAVE_MALLOCBLKSIZE */

/* Define to 1 if you have the <malloc.h> header file. */
#define HAVE_MALLOC_H 1

/* Define to 1 if you have the `mallopt' function. */
#define HAVE_MALLOPT 1

/* Define to 1 if you have the <math.h> header file. */
#define HAVE_MATH_H 1

/* Define to 1 if you have the `MD5Init' function. */
/* #undef HAVE_MD5INIT */

/* Define to 1 if you have the <md5.h> header file. */
/* #undef HAVE_MD5_H */

/* Define to 1 if you have the `memcpy' function. */
#define HAVE_MEMCPY 1

/* Define to 1 if you have the `memmove' function. */
#define HAVE_MEMMOVE 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `memset' function. */
#define HAVE_MEMSET 1

/* Define to 1 if you have the `mkstemp' function. */
#define HAVE_MKSTEMP 1

/* Define to 1 if you have the `mktime' function. */
#define HAVE_MKTIME 1

/* Define to 1 if you have the <mount.h> header file. */
/* #undef HAVE_MOUNT_H */

/* Define to 1 if you have the `mstats' function. */
/* #undef HAVE_MSTATS */

/* Define to 1 if you have the <ndir.h> header file, and it defines `DIR'. */
/* #undef HAVE_NDIR_H */

/* Define to 1 if you have the <netdb.h> header file. */
#define HAVE_NETDB_H 1

/* Define to 1 if you have the <netinet/if_ether.h> header file. */
#define HAVE_NETINET_IF_ETHER_H 1

/* Define to 1 if you have the <netinet/in.h> header file. */
#define HAVE_NETINET_IN_H 1

/* Define to 1 if you have the <netinet/ipl.h> header file. */
/* #undef HAVE_NETINET_IPL_H */

/* Define to 1 if you have the <netinet/ip_compat.h> header file. */
/* #undef HAVE_NETINET_IP_COMPAT_H */

/* Define to 1 if you have the <netinet/ip_fil_compat.h> header file. */
/* #undef HAVE_NETINET_IP_FIL_COMPAT_H */

/* Define to 1 if you have the <netinet/ip_fil.h> header file. */
/* #undef HAVE_NETINET_IP_FIL_H */

/* Define to 1 if you have the <netinet/ip_nat.h> header file. */
/* #undef HAVE_NETINET_IP_NAT_H */

/* Define to 1 if you have the <netinet/tcp.h> header file. */
#define HAVE_NETINET_TCP_H 1

/* Define to 1 if you have the <net/if.h> header file. */
#define HAVE_NET_IF_H 1

/* Define to 1 if you have the <net/pfvar.h> header file. */
/* #undef HAVE_NET_PFVAR_H */

/* Define to 1 if you have the <nss_common.h> header file. */
/* #undef HAVE_NSS_COMMON_H */

/* Define to 1 if you have the <nss.h> header file. */
#define HAVE_NSS_H 1

/* Define to 1 if you have the <openssl/engine.h> header file. */
#define HAVE_OPENSSL_ENGINE_H 1

/* Define to 1 if you have the <openssl/err.h> header file. */
#define HAVE_OPENSSL_ERR_H 1

/* Define to 1 if you have the <openssl/md5.h> header file. */
#define HAVE_OPENSSL_MD5_H 1

/* Define to 1 if you have the <openssl/ssl.h> header file. */
#define HAVE_OPENSSL_SSL_H 1

/* Define to 1 if you have the <paths.h> header file. */
#define HAVE_PATHS_H 1

/* Define to 1 if you have the `poll' function. */
#define HAVE_POLL 1

/* Define to 1 if you have the <poll.h> header file. */
#define HAVE_POLL_H 1

/* Define to 1 if you have the `prctl' function. */
#define HAVE_PRCTL 1

/* Define to 1 if you have the `pthread_attr_setschedparam' function. */
#define HAVE_PTHREAD_ATTR_SETSCHEDPARAM 1

/* Define to 1 if you have the `pthread_attr_setscope' function. */
#define HAVE_PTHREAD_ATTR_SETSCOPE 1

/* Define to 1 if you have the `pthread_setschedparam' function. */
#define HAVE_PTHREAD_SETSCHEDPARAM 1

/* Define to 1 if you have the `pthread_sigmask' function. */
/* #undef HAVE_PTHREAD_SIGMASK */

/* Define to 1 if you have the `putenv' function. */
#define HAVE_PUTENV 1

/* Define to 1 if you have the <pwd.h> header file. */
#define HAVE_PWD_H 1

/* Define to 1 if you have the `random' function. */
#define HAVE_RANDOM 1

/* Define to 1 if you have the `regcomp' function. */
#define HAVE_REGCOMP 1

/* Define to 1 if you have the `regexec' function. */
#define HAVE_REGEXEC 1

/* Define to 1 if you have the <regex.h> header file. */
#define HAVE_REGEX_H 1

/* Define to 1 if you have the `regfree' function. */
#define HAVE_REGFREE 1

/* Define to 1 if you have the <resolv.h> header file. */
#define HAVE_RESOLV_H 1

/* Define to 1 if you have the `res_init' function. */
/* #undef HAVE_RES_INIT */

/* If _res structure has nsaddr_list member */
#define HAVE_RES_NSADDR_LIST 1

/* If _res structure has ns_list member */
/* #undef HAVE_RES_NS_LIST */

/* Define to 1 if you have the `rint' function. */
#define HAVE_RINT 1

/* Define to 1 if you have the <sasl.h> header file. */
/* #undef HAVE_SASL_H */

/* Define to 1 if you have the <sasl/sasl.h> header file. */
/* #undef HAVE_SASL_SASL_H */

/* Define to 1 if you have the `sbrk' function. */
#define HAVE_SBRK 1

/* Define to 1 if you have the <sched.h> header file. */
#define HAVE_SCHED_H 1

/* Define to 1 if you have the `select' function. */
#define HAVE_SELECT 1

/* Define to 1 if you have the `seteuid' function. */
#define HAVE_SETEUID 1

/* Define to 1 if you have the `setgroups' function. */
#define HAVE_SETGROUPS 1

/* Define to 1 if you have the `setpgrp' function. */
#define HAVE_SETPGRP 1

/* Yay! Another Linux brokenness. Its not good enough to know that setresuid()
   exists, because RedHat 5.0 declare setresuid() but doesn't implement it. */
#define HAVE_SETRESUID 1

/* Define to 1 if you have the `setrlimit' function. */
#define HAVE_SETRLIMIT 1

/* Define to 1 if you have the `setsid' function. */
#define HAVE_SETSID 1

/* Define to 1 if you have the `sigaction' function. */
#define HAVE_SIGACTION 1

/* Define to 1 if you have the <signal.h> header file. */
#define HAVE_SIGNAL_H 1

/* Define to 1 if you have the `snprintf' function. */
#define HAVE_SNPRINTF 1

/* Define to 1 if you have the `socketpair' function. */
#define HAVE_SOCKETPAIR 1

/* Define to 1 if you have the `srand48' function. */
#define HAVE_SRAND48 1

/* Define to 1 if you have the `srandom' function. */
#define HAVE_SRANDOM 1

/* Define to 1 if you have the `statfs' function. */
#define HAVE_STATFS 1

/* If your system has statvfs(), and if it actually works! */
#define HAVE_STATVFS 1

/* Define to 1 if you have the <stdarg.h> header file. */
#define HAVE_STDARG_H 1

/* Define to 1 if you have the <stddef.h> header file. */
#define HAVE_STDDEF_H 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdio.h> header file. */
#define HAVE_STDIO_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the `strerror' function. */
#define HAVE_STRERROR 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the `strsep' function. */
#define HAVE_STRSEP 1

/* Define to 1 if you have the `strtoll' function. */
#define HAVE_STRTOLL 1

/* we check for the existance of struct mallinfo */
#define HAVE_STRUCT_MALLINFO 1

/* Define if you have struct rusage */
#define HAVE_STRUCT_RUSAGE 1

/* Define to 1 if you have the <syscall.h> header file. */
#define HAVE_SYSCALL_H 1

/* Define to 1 if you have the `sysconf' function. */
#define HAVE_SYSCONF 1

/* Define to 1 if you have the `syslog' function. */
#define HAVE_SYSLOG 1

/* Define to 1 if you have the <syslog.h> header file. */
#define HAVE_SYSLOG_H 1

/* Define to 1 if you have the <sys/bitypes.h> header file. */
#define HAVE_SYS_BITYPES_H 1

/* Define to 1 if you have the <sys/capability.h> header file. */
/* #undef HAVE_SYS_CAPABILITY_H */

/* Define to 1 if you have the <sys/dir.h> header file, and it defines `DIR'.
   */
/* #undef HAVE_SYS_DIR_H */

/* Define to 1 if you have the <sys/event.h> header file. */
/* #undef HAVE_SYS_EVENT_H */

/* Define to 1 if you have the <sys/file.h> header file. */
#define HAVE_SYS_FILE_H 1

/* Define to 1 if you have the <sys/ioctl.h> header file. */
#define HAVE_SYS_IOCTL_H 1

/* Define to 1 if you have the <sys/md5.h> header file. */
/* #undef HAVE_SYS_MD5_H */

/* Define to 1 if you have the <sys/mount.h> header file. */
#define HAVE_SYS_MOUNT_H 1

/* Define to 1 if you have the <sys/msg.h> header file. */
#define HAVE_SYS_MSG_H 1

/* Define to 1 if you have the <sys/ndir.h> header file, and it defines `DIR'.
   */
/* #undef HAVE_SYS_NDIR_H */

/* Define to 1 if you have the <sys/param.h> header file. */
#define HAVE_SYS_PARAM_H 1

/* Define to 1 if you have the <sys/poll.h> header file. */
#define HAVE_SYS_POLL_H 1

/* Define to 1 if you have the <sys/prctl.h> header file. */
#define HAVE_SYS_PRCTL_H 1

/* Define to 1 if you have the <sys/resource.h> header file. */
#define HAVE_SYS_RESOURCE_H 1

/* Define to 1 if you have the <sys/select.h> header file. */
#define HAVE_SYS_SELECT_H 1

/* Define to 1 if you have the <sys/socket.h> header file. */
#define HAVE_SYS_SOCKET_H 1

/* Define to 1 if you have the <sys/statfs.h> header file. */
#define HAVE_SYS_STATFS_H 1

/* Define to 1 if you have the <sys/statvfs.h> header file. */
#define HAVE_SYS_STATVFS_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/syscall.h> header file. */
#define HAVE_SYS_SYSCALL_H 1

/* Define to 1 if you have the <sys/time.h> header file. */
#define HAVE_SYS_TIME_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <sys/un.h> header file. */
#define HAVE_SYS_UN_H 1

/* Define to 1 if you have the <sys/vfs.h> header file. */
#define HAVE_SYS_VFS_H 1

/* Define to 1 if you have the <sys/wait.h> header file. */
#define HAVE_SYS_WAIT_H 1

/* Define to 1 if you have the `tempnam' function. */
#define HAVE_TEMPNAM 1

/* Define to 1 if you have the `timegm' function. */
#define HAVE_TIMEGM 1

/* Define to 1 if you have the <time.h> header file. */
#define HAVE_TIME_H 1

/* Define if struct tm has tm_gmtoff member */
#define HAVE_TM_GMTOFF 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Do we have unix sockets? (required for the winbind ntlm helper */
#define HAVE_UNIXSOCKET 1

/* Define to 1 if you have the <utime.h> header file. */
#define HAVE_UTIME_H 1

/* Define to 1 if you have the <varargs.h> header file. */
/* #undef HAVE_VARARGS_H */

/* Some systems dont have va_copy */
#define HAVE_VA_COPY 1

/* Define to 1 if you have the `vsnprintf' function. */
#define HAVE_VSNPRINTF 1

/* Define if you have PSAPI.DLL on Windows systems */
/* #undef HAVE_WIN32_PSAPI */

/* Define to 1 if you have the <winsock2.h> header file. */
/* #undef HAVE_WINSOCK2_H */

/* Define to 1 if you have the <winsock.h> header file. */
/* #undef HAVE_WINSOCK_H */

/* Define to 1 if you have the `__res_init' function. */
#define HAVE___RES_INIT 1

/* Some systems support __va_copy */
#define HAVE___VA_COPY 1

/* By default (for now anyway) Squid includes options which allows the cache
   administrator to violate the HTTP protocol specification in terms of cache
   behaviour. Setting this to '0' will disable such code. */
#define HTTP_VIOLATIONS 1

/* Enable support for Transparent Proxy on systems using IP-Filter address
   redirection. This provides "masquerading" support for non Linux system. */
/* #undef IPF_TRANSPARENT */

/* A dangerous feature which causes Squid to kill its parent process
   (presumably the RunCache script) upon receipt of SIGTERM or SIGINT. Use
   with caution. */
/* #undef KILL_PARENT_OPT */

/* Support large cache files > 2GB */
/* #undef LARGE_CACHE_FILES */

/* if libcap2 headers are broken and clashing with glibc */
/* #undef LIBCAP_BROKEN */

/* Enable support for Transparent Proxy on Linux (Netfilter) systems */
/* #undef LINUX_NETFILTER */

/* Enable real Transparent Proxy support for Netfilter TPROXY. */
/* #undef LINUX_TPROXY */

/* Define to enable experimental multicast of cache miss URLs */
/* #undef MULTICAST_MISS_STREAM */

/* If we need to declare sys_errlist[] as external */
/* #undef NEED_SYS_ERRLIST */

/* Define to 1 if your C compiler doesn't accept -c and -o together. */
/* #undef NO_MINUS_C_MINUS_O */

/* Define if NTLM is allowed to fail gracefully when a helper has problems */
/* #undef NTLM_FAIL_OPEN */

/* Name of package */
#define PACKAGE "squid"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "http://bugs.squid-cache.org/"

/* Define to the full name of this package. */
#define PACKAGE_NAME "Squid Web Proxy"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "Squid Web Proxy 2.7.STABLE9"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "squid"

/* Define to the version of this package. */
#define PACKAGE_VERSION "2.7.STABLE9"

/* Enable support for Transparent Proxy on systems using PF address
   redirection. This provides "masquerading" support for OpenBSD. */
/* #undef PF_TRANSPARENT */

/* Print stacktraces on fatal errors */
/* #undef PRINT_STACK_TRACE */

/* The size of `char', as computed by sizeof. */
#define SIZEOF_CHAR 1

/* The size of `int', as computed by sizeof. */
#define SIZEOF_INT 4

/* The size of `int16_t', as computed by sizeof. */
#define SIZEOF_INT16_T 2

/* The size of `int32_t', as computed by sizeof. */
#define SIZEOF_INT32_T 4

/* The size of `int64_t', as computed by sizeof. */
#define SIZEOF_INT64_T 8

/* The size of `int8_t', as computed by sizeof. */
#define SIZEOF_INT8_T 1

/* The size of `long', as computed by sizeof. */
#define SIZEOF_LONG 4

/* The size of `long long', as computed by sizeof. */
#define SIZEOF_LONG_LONG 8

/* The size of `off_t', as computed by sizeof. */
#define SIZEOF_OFF_T 4

/* The size of `short', as computed by sizeof. */
#define SIZEOF_SHORT 2

/* The size of `size_t', as computed by sizeof. */
#define SIZEOF_SIZE_T 4

/* The size of `uint16_t', as computed by sizeof. */
#define SIZEOF_UINT16_T 2

/* The size of `uint32_t', as computed by sizeof. */
#define SIZEOF_UINT32_T 4

/* The size of `uint64_t', as computed by sizeof. */
#define SIZEOF_UINT64_T 8

/* The size of `uint8_t', as computed by sizeof. */
#define SIZEOF_UINT8_T 1

/* The size of `u_int16_t', as computed by sizeof. */
#define SIZEOF_U_INT16_T 2

/* The size of `u_int32_t', as computed by sizeof. */
#define SIZEOF_U_INT32_T 4

/* The size of `u_int64_t', as computed by sizeof. */
#define SIZEOF_U_INT64_T 8

/* The size of `u_int8_t', as computed by sizeof. */
#define SIZEOF_U_INT8_T 1

/* The size of `void *', as computed by sizeof. */
#define SIZEOF_VOID_P 4

/* The size of `__int64', as computed by sizeof. */
#define SIZEOF___INT64 0

/* configure command line used to configure Squid */
#define SQUID_CONFIGURE_OPTIONS ""

/* Maximum number of open filedescriptors */
#define SQUID_MAXFD 1024

/* Define to enable SNMP monitoring of Squid */
/* #undef SQUID_SNMP */

/* TCP receive buffer size */
#define SQUID_TCP_SO_RCVBUF 65535

/* TCP send buffer size */
#define SQUID_TCP_SO_SNDBUF 16384

/* UDP receive buffer size */
#define SQUID_UDP_SO_RCVBUF 109568

/* UDP send buffer size */
#define SQUID_UDP_SO_SNDBUF 109568

/* If using the C implementation of alloca, define if you know the
   direction of stack growth for your system; otherwise it will be
   automatically deduced at runtime.
	STACK_DIRECTION > 0 => grows toward higher addresses
	STACK_DIRECTION < 0 => grows toward lower addresses
	STACK_DIRECTION = 0 => direction of growth unknown */
/* #undef STACK_DIRECTION */

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Supports large dgram sockets over AF_UNIX sockets */
#define SUPPORTS_LARGE_AF_UNIX_DGRAM 1

/* Define this to include code which lets you specify access control elements
   based on ethernet hardware addresses. This code uses functions found in 4.4
   BSD derviations (e.g. FreeBSD, ?). */
/* #undef USE_ARP_ACL */

/* Define this if you would like to use the aufs I/O method for disk I/O
   instead of the POSIX AIO method. */
#define USE_AUFSOPS 1

/* Use Cache Digests for locating objects in neighbor caches. This code is
   still semi-experimental. */
/* #undef USE_CACHE_DIGESTS */

/* Cache Array Routing Protocol */
#define USE_CARP 1

/* If --disable-internal-dns was given to configure, then we'll use the
   dnsserver processes instead. */
/* #undef USE_DNSSERVERS */

/* Define if we should use GNU regex */
/* #undef USE_GNUREGEX */

/* Define this to include code for the Hypertext Cache Protocol (HTCP) */
/* #undef USE_HTCP */

/* If you want to use Squid's ICMP features (highly recommended!) then define
   this. When USE_ICMP is defined, Squid will send ICMP pings to origin server
   sites. This information is used in numerous ways: - Sent in ICP replies so
   neighbor caches know how close you are to the source. - For finding the
   closest instance of a URN. - With the 'test_reachability' option. Squid
   will return ICP_OP_MISS_NOFETCH for sites which it cannot ping. */
/* #undef USE_ICMP */

/* Compile in support for Ident (RFC 931) lookups? Enabled by default. */
#define USE_IDENT 1

/* Enable code for assiting in finding memory leaks. Hacker stuff only. */
/* #undef USE_LEAKFINDER */

/* use libcap to set capabilities required for TPROXY */
/* #undef USE_LIBCAP */

/* Define this to make use of the OpenSSL libraries for MD5 calculation rather
   than Squid's own MD5 implementation or if building with SSL encryption
   (USE_SSL) */
/* #undef USE_OPENSSL */

/* If you want to log Referer request header values, define this. By default,
   they are written to referer.log in the Squid log directory. */
/* #undef USE_REFERER_LOG */

/* Define this to force use of the internal MD5 implementation */
/* #undef USE_SQUID_MD5 */

/* Define this to include code for SSL encryption. */
/* #undef USE_SSL */

/* Do we want to use truncate(2) or unlink(2)? */
/* #undef USE_TRUNCATE */

/* Define this if unlinkd is required (strongly recommended for ufs storage
   type) */
#define USE_UNLINKD 1

/* If you want to log User-Agent request header values, define this. By
   default, they are written to useragent.log in the Squid log directory. */
/* #undef USE_USERAGENT_LOG */

/* Define to enable WCCP */
#define USE_WCCP 1

/* Define to enable WCCP V2 */
#define USE_WCCPv2 1

/* Define Windows NT & Windows 2000 run service mode */
/* #undef USE_WIN32_SERVICE */

/* Version number of package */
#define VERSION "2.7.STABLE9"

/* Define to enable experimental forward_log directive */
/* #undef WIP_FWD_LOG */

/* Valgrind memory debugger support */
/* #undef WITH_VALGRIND */

/* Define WORDS_BIGENDIAN to 1 if your processor stores words with the most
   significant byte first (like Motorola and SPARC, unlike Intel and VAX). */
#if defined __BIG_ENDIAN__
# define WORDS_BIGENDIAN 1
#elif ! defined __LITTLE_ENDIAN__
/* # undef WORDS_BIGENDIAN */
#endif

/* Define to have malloc statistics */
/* #undef XMALLOC_STATISTICS */

/* Enable support for the X-Accelerator-Vary HTTP header */
/* #undef X_ACCELERATOR_VARY */

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* Define to 'int' if not defined */
/* #undef fd_mask */

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
/* #undef inline */
#endif

/* Define to 'int' if not defined */
/* #undef int16_t */

/* Define to 'long' if not defined */
/* #undef int32_t */

/* Define to '__int64' if not defined */
/* #undef int64_t */

/* Define to 'char' if not defined */
/* #undef int8_t */

/* Define to 'unsigned short' if not defined */
/* #undef mode_t */

/* message type for message queues */
#define mtyp_t long

/* Define to 'int' if not defined */
/* #undef off_t */

/* Define to 'int' if not defined */
/* #undef pid_t */

/* Define to 'unsigned int' if not defined */
/* #undef size_t */

/* This makes warnings go away. If you have socklen_t defined in your
   /usr/include files, then this should remain undef'd. Otherwise it should be
   defined to int. */
/* #undef socklen_t */

/* Define to 'int' if not defined */
/* #undef ssize_t */

/* Define to 'unsigned int' if not defined */
/* #undef u_int16_t */

/* Define to 'unsigned long' if not defined */
/* #undef u_int32_t */

/* Define to 'unsigned __int64' if not defined */
/* #undef u_int64_t */

/* Define to 'unsigned char' if not defined */
/* #undef u_int8_t */

/* Define to 'unsigned int' if not defined */
/* #undef uint16_t */

/* Define to 'unsigned long' if not defined */
/* #undef uint32_t */

/* Define to 'unsigned __int64' if not defined */
/* #undef uint64_t */

/* Define to 'unsigned char' if not defined */
/* #undef uint8_t */

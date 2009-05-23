/*
  leds.c
  David Rowe 15 April 2008

  Simple device driver to support control of IP04 LEDs via /proc
  interface.

  Usage:

    $ modprobe leds
    $ echo 1 > /proc/sd_led
    $ echo 1 > /proc/sys_led

  Turning the LEDs off is left as an exercise for the reader :-)
*/

/*
  Copyright (C) 2006 David Rowe
 
  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. 
*/

#include <linux/module.h>
#include <linux/errno.h>
#include <linux/sched.h>
#include <asm/uaccess.h>
#include <asm/io.h>
#include <linux/proc_fs.h>
#include <linux/platform_device.h>

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Simple driver for IP04 LEDs");
MODULE_AUTHOR("David Rowe");

#define SD_LED     6 /* SD LED on PF6  */
#define SYS_LED    7 /* SYS LED on PF6 */
#define CFGRESET  13 /* SD LED on PF6  */

static int proc_write_sd_led(struct file *file, const char *buffer,
                             unsigned long count, void *data)
{
  int   on;
  char *endbuffer;

  on = simple_strtol (buffer, &endbuffer, 10);
  if (on)
  	bfin_write_FIO_FLAG_S((1<<SD_LED)); 
  else
  	bfin_write_FIO_FLAG_C((1<<SD_LED)); 

  return count;
}

static int proc_write_sys_led(struct file *file, const char *buffer,
                              unsigned long count, void *data)
{
  int   on;
  char *endbuffer;

  on = simple_strtol (buffer, &endbuffer, 10);
  if (on)
  	bfin_write_FIO_FLAG_S((1<<SYS_LED)); 
  else
  	bfin_write_FIO_FLAG_C((1<<SYS_LED)); 

  return count;
}

static int proc_read_cfgreset(char *buf, char **start, off_t offset,
                       int count, int *eof, void *data)
{
    int len;

    if (bfin_read_FIO_FLAG_D() & (1<<CFGRESET))
	len = sprintf(buf, "1\n");
    else
	len = sprintf(buf, "0\n");
    
    //len = sprintf(buf, "0x%x 0x%x\n", bfin_read_FIO_FLAG_D(), bfin_read_FIO_DIR());

    *eof=1;

    return len;
}


static int __init leds_init(void)
{
    struct proc_dir_entry *sd_led, *sys_led;

    sd_led = create_proc_read_entry("sd_led", 0, NULL, NULL, NULL);
    sd_led->write_proc = proc_write_sd_led;
    sys_led = create_proc_read_entry("sys_led", 0, NULL, NULL, NULL);
    sys_led->write_proc = proc_write_sys_led;

    create_proc_read_entry("cfgreset", 0, NULL, proc_read_cfgreset, NULL);

    bfin_write_FIO_DIR(bfin_read_FIO_DIR() | (1<<SD_LED) | (1<<SYS_LED)); 
    bfin_write_FIO_INEN(bfin_read_FIO_INEN() | (1<<CFGRESET)); 

    return 0;
}

static void __exit leds_cleanup(void)
{
    remove_proc_entry("sd_led", NULL);
    remove_proc_entry("sys_led", NULL);
}

module_init(leds_init);
module_exit(leds_cleanup);


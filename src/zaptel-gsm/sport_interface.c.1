/*
 * File:	sport_interface.c
 *
 * Author:	Alex Tao <wosttq@gmail.com>
 * Mods:	Added partial support for BF536/Bf537 mark@astfin.org
 *
 * Based on:	bfsi.c    by David Rowe 
 *                  bfin_sport.c   by Roy Huang (roy.huang@analog.com)
 * 
 * Created:	Jun 3, 2007
 * Description: This device driver enables SPORT1 on Blackfin532 interfacing 
 *              to Silicon Labs chips.
 */

/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see the file COPYING, or write
 * to the Free Software Foundation, Inc.,
 * 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */


#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/types.h>
#include <linux/proc_fs.h>
#include <linux/fcntl.h>
#include <linux/delay.h>
#include <asm/blackfin.h>
#include <asm/system.h>
#include <asm/uaccess.h>

#include "sport_interface.h"
#include "GSM_module_SPI.h"//yn


int sport_configure(int baud);

/* When FX_MODE, we need not fill the struct of sport_config */
int sport_configure(int baud)
{
	sport1_write_TCR1( sport1_read_TCR1() & ~(TSPEN) ); 
	sport1_write_RCR1( sport1_read_RCR1() & ~(RSPEN) ); 
	__builtin_bfin_ssync();
	/* Register SPORTx_TCR1 ( relative details pls refer 12-12 of hardware reference ) 
	        TCKFE ( Clock Falling Edge Select )   ( Bit14 ) 
          	LTFS ( Bit11) :  0 - Active high TFS; 1 - Active low TFS
		ITFS ( Bit9 ) :  0 - External TFS used; 1 - Internal TFS used 
		TFSR: 0 - Dose not require TFS for every data word;  1 - Requires TFS for every data word
		TLSBIT: 0 - Transmit MSB first ;  1 - Transmit LSB first
		ITCLK: 0 - External transmit clock selected; 1 - Internal transmit clock selected
	*/
	sport1_write_TCR1(TCKFE | LATFS | LTFS | TFSR | ITFS | ITCLK);
	__builtin_bfin_ssync();
	
	/* 8 bit word length  */
	sport1_write_TCR2(0x7);
    
	/* SPORTx_TCLK frequency = ( System Clock frequency ) / ( 2 * ( SPORTx_TCLKDIV + 1 ) )   */
	sport1_write_TCLKDIV(baud);
	sport1_write_TFSDIV(0x7);
	
	/* Initialization of SPORT1_RCR1 and SPORT1_RCR2, similar to the Register SPORTx_TCR1  and SPORTx_TCR2 */
	sport1_write_RCR1(RCKFE | LARFS | LRFS | RFSR);  
	sport1_write_RCR2(0x7);      /* 8 bit word length      */
	
	sport1_write_RCLKDIV(baud);
	sport1_write_RFSDIV(0x7);

	//Enable SPORT1 interface
	//sport1_write_TCR1( sport1_read_TCR1() | TSPEN );//YN
	
	__builtin_bfin_ssync();

	PRINTK("tcr1:0x%x, tcr2:0x%x, rcr1:0x%x, rcr2:0x%x\n",
		sport1_read_TCR1(), sport1_read_TCR2(),
		sport1_read_RCR1(), sport1_read_RCR2());
//	printk("tcr1:0x%x, rcr1:0x%x \n",
//		sport1_read_TCR1(),sport1_read_RCR1());


	return 0;
}


void sport_tx_byte(u16 chip_select, u8 bits)
{
	u16 tmp;
	//printk("TX byte chip_select=%d\n",chip_select);
	
	/* Enable the transmit operation *///YN
	sport1_write_TCR1( sport1_read_TCR1() | TSPEN ); 
	while (!(sport1_read_TCR1() & TSPEN));

	/* drop chip select */
	if ( chip_select >7 )
	{
		/* Clear PFx used for chip_select */
#if (defined(CONFIG_BF533) || defined(CONFIG_BF532))
        bfin_write_FIO_FLAG_C((1<<chip_select));
#endif
#if (defined(CONFIG_BF536) || defined(CONFIG_BF537))
        bfin_write_PORTFIO_CLEAR((1<<chip_select));
#endif
		__builtin_bfin_ssync();
		udelay(2);	//tsu1 - Setup Time, /CS to SCLK fall
	}
	
	tmp = bits & 0x0ff;
	bfin_write_SPORT1_TX16(tmp);

	while (!(sport1_read_STAT() & TXHRE));

	/*  Wait for the last byte sent out  */
	udelay(10);//Was 2 YN

	/* Raise chip select */
	if ( chip_select >7 )
	{
		/* Raise PFx High*/
#if (defined(CONFIG_BF533) || defined(CONFIG_BF532))
    bfin_write_FIO_FLAG_S((1<<chip_select));
#endif
#if (defined(CONFIG_BF536) || defined(CONFIG_BF537))
        bfin_write_PORTFIO_SET((1<<chip_select));
#endif
		__builtin_bfin_ssync();
		udelay(20);
	}

#ifdef SPORT_INTERFACE_DEBUG
	txCnt++;
	PRINTK("Send the %d byte OK!\n", txCnt);
#endif
	return;
}


u8 sport_rx_byte(u16 chip_select)
{
	u8 ret = 0;
	PRINTK("Come into %s\n",__FUNCTION__);

	/* Enable the receive operation */
	sport1_write_RCR1( sport1_read_RCR1() | RSPEN ); 
	while (!(sport1_read_RCR1() & RSPEN));
	
	/* drop chip select */
	if ( chip_select >7 )
	{
		/* Clear PFx used for chip_select */
#if (defined(CONFIG_BF533) || defined(CONFIG_BF532))
    bfin_write_FIO_FLAG_C((1<<chip_select));
#endif
#if (defined(CONFIG_BF536) || defined(CONFIG_BF537))
        bfin_write_PORTFIO_CLEAR((1<<chip_select));
#endif
		__builtin_bfin_ssync();
	}

	/* Write a dummy byte to generate a FSYNC */
	bfin_write_SPORT1_TX16(0x00ff);

	while (!(sport1_read_STAT() & RXNE))
	{
		PRINTK("%s Line%d:status:%x  %d \n", __FUNCTION__, __LINE__, sport1_read_STAT(), txCnt);
	}
	ret = (u8)bfin_read_SPORT1_RX16();
	PRINTK("%s Line%d: tcr1:0x%x, tcr2:0x%x, rcr1:0x%x, rcr2:0x%x\n",
		__FUNCTION__, __LINE__,
		sport1_read_TCR1(), sport1_read_TCR2(),
		sport1_read_RCR1(), sport1_read_RCR2());

	/* Raise chip select */
	if ( chip_select >7 )
	{
		/* Raise High of PFx */
#if (defined(CONFIG_BF533) || defined(CONFIG_BF532))
    	bfin_write_FIO_FLAG_S((1<<chip_select));
#endif
#if (defined(CONFIG_BF536) || defined(CONFIG_BF537))
        bfin_write_PORTFIO_SET((1<<chip_select));
#endif
		__builtin_bfin_ssync();
	}

	sport1_write_RCR1( sport1_read_RCR1() & ~(RSPEN) ); 
	ndelay(200);
	__builtin_bfin_ssync();

	PRINTK("%s Line%d receive byte OK!\n",__FUNCTION__, __LINE__ );

	return ret;
}


 void sport_interface_cleanup(void)
{
	sport1_write_TCR1( sport1_read_TCR1() & ~(TSPEN) ); 
	sport1_write_RCR1( sport1_read_RCR1() & ~(RSPEN) ); 
	__builtin_bfin_ssync();
}


int sport_interface_init(int baud, u16 new_chip_select_mask)
{
	sport_configure(baud); /* Default should be 0x1 */

//Raise chip selects PF8 and PF9; ADDEd by YN
#if (defined(CONFIG_BF533) || defined(CONFIG_BF532))
	bfin_write_FIO_FLAG_S(1<<8);
	bfin_write_FIO_FLAG_S(1<<9);
#endif
#if (defined(CONFIG_BF536) || defined(CONFIG_BF537))
	bfin_write_PORTFIO_SET(1<<8);
	bfin_write_PORTFIO_SET(1<<9);
#endif
#if (defined(CONFIG_BF533) || defined(CONFIG_BF532))
	bfin_write_FIO_FLAG_S( 1 << SPORT_nPWR );
#endif
#if (defined(CONFIG_BF536) || defined(CONFIG_BF537))
	bfin_write_PORTFIO_SET( 1 << SPORT_nPWR );
#endif
__builtin_bfin_ssync();//YN

	PRINTK("Before setting, FIOD_DIR = 0x%04x\n", bfin_read_FIO_DIR());
	PRINTK("Before setting, new_chip_select_mask = 0x%04x\n", new_chip_select_mask);
	if (new_chip_select_mask & 0xff00) 
	{
#if (defined(CONFIG_BF533) || defined(CONFIG_BF532))
		bfin_write_FIO_DIR(bfin_read_FIO_DIR() | 
#endif
#if (defined(CONFIG_BF536) || defined(CONFIG_BF537))
		bfin_write_PORTFIO_DIR(bfin_read_PORTFIO_DIR() |
#endif
				   (new_chip_select_mask & 0xff00) |
				   (1<<SPORT_nPWR)
				   ); 
		__builtin_bfin_ssync(); 
	}
	PRINTK("After setting, FIOD_DIR = 0x%04x\n", bfin_read_FIO_DIR());

#if (defined(CONFIG_BF533) || defined(CONFIG_BF532))
	bfin_write_FIO_FLAG_S( 1 << SPORT_nPWR );
#endif
#if (defined(CONFIG_BF536) || defined(CONFIG_BF537))
	bfin_write_PORTFIO_SET( 1 << SPORT_nPWR );
#endif

	return 0; /* succeed */
}

void sport_interface_reset(int reset_bit)
{
	/* Port from David! Thanks, David!*/
#if (defined(CONFIG_BF533) || defined(CONFIG_BF532))
  	PRINTK("set reset to PF%d\n",reset_bit);
  	bfin_write_FIO_DIR(bfin_read_FIO_DIR() | (1<<reset_bit)); 
  	__builtin_bfin_ssync();

  	bfin_write_FIO_FLAG_C((1<<reset_bit)); 
  	__builtin_bfin_ssync();
  	udelay(100);

  	bfin_write_FIO_FLAG_S((1<<reset_bit));
  	__builtin_bfin_ssync();
#endif
#if (defined(CONFIG_BF536) || defined(CONFIG_BF537))
	PRINTK("set reset to PF%d\n",reset_bit); 
        bfin_write_PORTFIO_DIR(bfin_read_PORTFIO_DIR() | (1<<reset_bit));
        __builtin_bfin_ssync();

        bfin_write_PORTFIO_CLEAR((1<<reset_bit));
        __builtin_bfin_ssync();
        udelay(100);

        bfin_write_PORTFIO_SET((1<<reset_bit));
        __builtin_bfin_ssync();
#endif
	
  	/*
  	p24 3050 data sheet, allow 1ms for PLL lock, with
  	less than 1ms (1000us) register 2 would have
  	a value of 0 rather than 3, indicating a bad reset.
  	*/
  	udelay(1000); 
}
EXPORT_SYMBOL(sport_configure);
EXPORT_SYMBOL( sport_tx_byte );
EXPORT_SYMBOL( sport_rx_byte );
EXPORT_SYMBOL( sport_interface_init );
EXPORT_SYMBOL( sport_interface_reset );
EXPORT_SYMBOL( sport_interface_cleanup );

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Alex Tao <wosttq@gmail.com>");



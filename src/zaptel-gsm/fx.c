/*
  fx.c
  David Rowe 21 Sep 2006
  
  Modified by Alex Tao  Jun 3, 2007
 
  Functions supporting the 4fx card for Linux device drivers on the
  Blackfin that support interfacing the Blackfin.

  These functions are in a separate file from the target wcfxs driver
  so they can be re-used with different drivers, for example unit
  test software. 
 
  Include this file after including bfsi.c

  See also unittest spi/tspi_4fx_det.c

  TODO: work out a way to make this a seperately compiled module,
  include files are messy, perhaps make this a stand-alone module, wor
  work out how to link it with other .ko's
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

#define FX_MAX_DBS     4  // max number of 4fx daughter boards
#define FX_LED_OFF     0
#define FX_LED_GREEN   2

#include "GSM_module_SPI.h"//yn

char  port_type[FX_MAX_PORTS];//YN

static int led[FX_MAX_DBS];

/*

  From hardware-x.y tar ball, cpld dir, README.txt:

  D1 D0 | LED1
  ------|---
  0   0 | off
  0   1 | red
  1   0 | green
  1   1 | off

  An similarly for the other LEDs:

  D[3:2] LED2
  D[5:4] LED3
  D[7:6] LED4

 */

void fx_set_led(int port, int state) {
  int card;

  if (port > 4) {
    
#ifdef CONFIG_4FX_SPI_INTERFACE
    bfsi_spi_write_8_bits(SPI_NCSB, 0x45);
#else
    sport_tx_byte(SPI_NCSB, 0x45);
#endif

    port -= 4;
    card = 1;
  }
  else {
    
#ifdef CONFIG_4FX_SPI_INTERFACE
    bfsi_spi_write_8_bits(SPI_NCSB, 0x05);
#else
    sport_tx_byte(SPI_NCSB, 0x05);
#endif
    
    card = 0;
  }

  led[card] &= ~(0x3 << ((port-1)*2));
  led[card] |= state << ((port-1)*2);
	

#ifdef CONFIG_4FX_SPI_INTERFACE
  bfsi_spi_write_8_bits(SPI_NCSA, led[card]); 
#else
  sport_tx_byte(SPI_NCSA, led[card]); 
#endif
}

/*----------------- PORT READ FUNCTIONS --------------------------*/

// read register 0x2 of 3050 FXO

char fx_read_fxo(int port) {
    u8  reg;

    if (port > 4)
      port += 0x40 - 4;
#ifdef CONFIG_4FX_SPI_INTERFACE
    bfsi_spi_write_8_bits(SPI_NCSB, port); 
    bfsi_spi_write_8_bits(SPI_NCSA, 0x60);
    bfsi_spi_write_8_bits(SPI_NCSA, 0x02);
    reg =  bfsi_spi_read_8_bits(SPI_NCSA);
#else
    sport_tx_byte(SPI_NCSB, port); 
    sport_tx_byte(SPI_NCSA, 0x60);
    sport_tx_byte(SPI_NCSA, 0x02);
    reg =  sport_rx_byte(SPI_NCSA);
#endif

    return reg;
}

// read register 0x0 of 3210 FXS
/* According to the 3215 datasheet, we need to read the direct register 0x1, the Bit7 is identification of part number
     when 0 is Si3210 family or 1 is Si3215 family  */
char fx_read_fxs(int port, u8 bits) {
    u8  reg;

    if (port > 4)
      port += 0x40 - 4;
#ifdef CONFIG_4FX_SPI_INTERFACE
    bfsi_spi_write_8_bits(SPI_NCSB, port); 
    bfsi_spi_write_8_bits(SPI_NCSA, bits | 0x80);
    reg =  bfsi_spi_read_8_bits(SPI_NCSA);
#else
    sport_tx_byte(SPI_NCSB, port); 
    sport_tx_byte(SPI_NCSA, bits | 0x80);
    reg =  sport_rx_byte(SPI_NCSA);
#endif
    
    return reg;
}

void fx_auto_detect(char port_type[], int bit_reset) {
  int i;
  u8  reg;

  for(i=0; i<FX_MAX_PORTS; i++) {
    port_type[i] = '-';

    bfsi_reset(bit_reset);
    reg = fx_read_fxo(i+1);
    if (reg == 0x3) {
      port_type[i] = 'O';
      fx_set_led(i+1, FX_LED_RED);
    }
    else {
      bfsi_reset(bit_reset);
      reg = fx_read_fxs(i+1, 0);
      if (reg == 0x5 ) {
		port_type[i] = 'S';
        fx_set_led(i+1, FX_LED_GREEN);
      }
      else
      {
         /* Check whether Si3215 */
         bfsi_reset(bit_reset);
         reg = fx_read_fxs(i+1, 0x1);
         /* As mentioned in datasheet of Si3215, the register 0x1 
         Bit7 is identification 2, and Bit6 is Reserved which is read 
         as zero */
         if ( ( reg & 0xC0) == 0x80 )
         {
            port_type[i] = 'S';
            fx_set_led(i+1, FX_LED_GREEN);
         }
      }
    }
  }
}


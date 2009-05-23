/*
 * GSM Interface Driver for Zapata Telephony interface
 *
 * Written by Youliy Ninov <yni@ucpbx.com>
 *         
 *
 * Copyright (C) 2008, uCPBX Ltd.
 *
 * All rights reserved.
 *
 *
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
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. 
 *
 */
//#include <linux/delay.h>

#include "GSM_module_SPI.h"

extern int sport_configure(int baud);

extern int outgoing_call_state;
extern int incomming_call_state;
extern char  port_type[FX_MAX_PORTS];


//SPORT1 emulates SPI communication through the CPLD.
//Each time we address the SPI device on the GSM module (SC16IS750) we
//need to reconfigure the SPORT1 interface, since the SPI2UART (SC16IS750) accepts
//16-bit SPI words only
static int sport_configure_gsm(int baud)
{

	//It is important to stop SPORT1 before we reconfigure it. Otherwise
	//some registers do not always get initialiazed
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
	sport1_write_TCR1( LATFS | LTFS | TFSR | ITFS | ITCLK);
	__builtin_bfin_ssync();
		
	/* 16 bit word length  */
	sport1_write_TCR2(0xf);
    
	/* SPORTx_TCLK frequency = ( System Clock frequency ) / ( 2 * ( SPORTx_TCLKDIV + 1 ) )   */
	sport1_write_TCLKDIV(baud);
	sport1_write_TFSDIV(0xf);
	
	/* Initialization of SPORT1_RCR1 and SPORT1_RCR2, similar to the Register SPORTx_TCR1  and SPORTx_TCR2 */
	sport1_write_RCR1(LARFS | LRFS | RFSR);  
	sport1_write_RCR2(0xf);      /* 16 bit word length      */
	
	sport1_write_RCLKDIV(baud);
	sport1_write_RFSDIV(0xf);
	
	__builtin_bfin_ssync();

	PRINTK("tcr1:0x%x, tcr2:0x%x, rcr1:0x%x, rcr2:0x%x\n",
		sport1_read_TCR1(), sport1_read_TCR2(),
		sport1_read_RCR1(), sport1_read_RCR2());

	return 0;
}

//This is the function that transmits 16-bit data to the SPI2UART
//It has been verified for 1.33MHz SPI clock. If lower clocks
//are necessary some of the delays in the function must be 
//increased. It works also for 13.3 MHz.
static void sport_tx_word(u16 chip_select, u16 bits)
{
	/* Enable the transmit operation */
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
	//Transmit 16 bits
	bfin_write_SPORT1_TX16(bits);

	while (!(sport1_read_STAT() & TXHRE));

	/*  Wait for the last byte sent out (clocked out!) */
	udelay(30);//!

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
	PRINTK("Send the %d word OK!\n", txCnt);
#endif
	return;
} 

//This is the function that reads data from the SPI2UART chip on 
//on the GSM module. The first 8 bits are sent to the SPI2UART (
//padded by 8 trailing zeros). The second 8 bits are the data from
// the SPI2UART chip (padded by 8 front zeros).
//It has been verified for 1.33MHz SPI clock. If lower clocks
//are necessary some of the delays in the function must be 
//increased. It works also for 13.3 MHz.
static u16 sport_rx_word(u16 chip_select,u16 regdata)
{
	u16 ret = 0;
	PRINTK("Come into %s\n",__FUNCTION__);

	/* Enable the transmit operation */
	sport1_write_TCR1( sport1_read_TCR1() | TSPEN ); 
	while (!(sport1_read_TCR1() & TSPEN));

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
		udelay(2);	//tsu1 - Setup Time, /CS to SCLK fall
	}

	/* Tx data and  generate a FSYNC */
	bfin_write_SPORT1_TX16(regdata);

	//Wait for the SPI2UART to answer
	while (!(sport1_read_STAT() & RXNE))
	{
		PRINTK("%s Line%d:status:%x  %d \n", __FUNCTION__, __LINE__, sport1_read_STAT(), txCnt);
	}

	/*  Wait for the last byte sent out  */
	udelay(13);

	ret = (u16)bfin_read_SPORT1_RX16();
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
		udelay(20);
	}
	PRINTK("%s Line%d receive word OK!\n",__FUNCTION__, __LINE__ );

	return ret;
}

//This is the complete reading function of the SPI2UART
//Internal workings:
//1.Select the card to program
//2.Configure the sport1 interface for the GSM module access
//3.Read data fromt the SPI2UART chip
//4.Reconfigure sport1 interface for FXS/FXO access
static u16 fx_read_SPI2UART(struct wcfxs *wc,int port,int value) 
{
    u16  reg;

 if (port > 4)
      port += 0x40 - 4;
#ifdef CONFIG_4FX_SPI_INTERFACE
    bfsi_spi_write_8_bits(SPI_NCSB, port); 
#else// added YN

	__wcfxs_setcard(wc, port);//We wish to progarmm module 'port'

 	sport_configure_gsm(SPI_BAUDS_GSM); //Configure the SPI (sport) to 1.33MHz/16bits (GSM access)
	reg=sport_rx_word(SPI_NCSA,value);//Read register
 	sport_configure(SPI_BAUDS);//Reconfigure the SPI (sport) to 1.33MHz/8bits

#endif

    return reg;
}
//This function is used when we need to send data without any Chip Select active.
//This is used for addressing the Codec (WM8510), since the clock is gated by an
//AND gate (see schematics).
//Internal workings:
//1.Configure the sport1 interface for the GSM module access
//2.Transmit data to the CODEC
//3.Reconfigure sport1 interface for FXS/FXO access
static void fx_write_SPI2UART_wo_CS(int value) 
{
 sport_configure_gsm(SPI_BAUDS_GSM); //Configure the SPI (sport) to 1.33MHz/16bits
 sport_tx_word(0,value);//Tx data
 sport_configure(SPI_BAUDS);//Reconfigure the SPI (sport) to 1.33MHz/8bits
}

//This is the complete reading function of the SPI2UART
//Internal workings:
//1.Select the card to program
//2.Configure the sport1 interface for the GSM module access
//3.Transmit data to the SPI2UART chip
//4.Reconfigure sport1 interface for FXS/FXO access
static void fx_write_SPI2UART(struct wcfxs *wc,int port,int value) 
{

 if (port > 4)
      port += 0x40 - 4;
#ifdef CONFIG_4FX_SPI_INTERFACE
    bfsi_spi_write_8_bits(SPI_NCSB, port); 
#else//adde YN

	__wcfxs_setcard(wc, port);//We wish to progarmm module 'port'
	
 	sport_configure_gsm(SPI_BAUDS_GSM); //Configure the SPI (sport) to 1.33MHz/16bits
 	sport_tx_word(SPI_NCSA,value);//Tx to register
 	sport_configure(SPI_BAUDS);//Reconfigure the SPI (sport) to 1.33MHz/8bits

#endif

}

//This function implements writing followed by reading from the same
//register of SPI2UART and compares the results.
//Internal workings:
//1.Select the card to program
//2.Configure the sport1 interface for the GSM module access
//3.Transmit data to the SPI2UART chip
//4.Read data from the SPI2UART chip
//5.Compare Tx and Rx data
//4.Reconfigure sport1 interface for FXS/FXO access
static int fx_program_register_SPI2UART(struct wcfxs *wc,int port,int value) 
{
    u16  reg,temp;

 if (port > 4)
      port += 0x40 - 4;
#ifdef CONFIG_4FX_SPI_INTERFACE
    bfsi_spi_write_8_bits(SPI_NCSB, port); 

#else//adde YN

	__wcfxs_setcard(wc, port);//We wish to progarmm module 'port'

 	sport_configure_gsm(SPI_BAUDS_GSM); //Configure the SPI (sport) to 1.33MHz/16bits
 	sport_tx_word(SPI_NCSA,value);//Write register
 	value=value | 0x8000;//change writing to reading!
 	reg=sport_rx_word(SPI_NCSA,value);//Read register
	temp=value |0xff00;
 	sport_configure(SPI_BAUDS);//Reconfigure the SPI (sport) to 1.33MHz/8bits
	if(temp!=reg){
		 printk("Register not programmed! T=%x R=%x Rm=%x\n",value,reg,temp);
		 return 1;
	}
	return 0;
#endif

}

//This function is used for detection of the GSM module (on which port
//it is placed,if any). A register of the SPI2UAR is read. After reset
//the register value is 0x001D. When this value is found, the GSM module
//place is fixed and a the respective diode is set to RED (same as for a FXO module)
void gsm_auto_detect(struct wcfxs *wc,char port_type[], int bit_reset) 
{
  int i;
  u16  reg;
	
  //Traverse all the available ports
  for(i=0; i<FX_MAX_PORTS; i++) {
    if(port_type[i] == '-'){//if there is an unassigned port check it!
	reg = fx_read_SPI2UART(wc,i,0x9800);
	//printk("GAD:i=%d reg=%x\n",i,reg);
  	 if (reg == 0xff1D) {// When GSM module is found
	 // printk("GAD1:%x\n",reg);
   	  port_type[i] = 'G';
	  fx_set_led(i+1, FX_LED_RED);//Set let to RED
	  wc->curcard=-1;// setting led messes with the current card settings
  	  break;//only one GSM module per system!
	 }
    }//end if(port_type[i]..
  }//end for
}//end gsm_auto_detect

//This function implements sending data to the GSM module through the 
//SPI2UART.Data is sent to the UARTs FIFO character by charachter.
//CR and LF are added after every command/data
void GSM_send(struct wcfxs *wc,int port,const char * info)
{
	int count;
	count=0;
	if (debug)
		printk("Sent: %s\n",info);
	while(info[count]!=0x00)
	{
		//Send data to THR
		//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
		//==>   0    0  0  0  0  0   0  0 ==0x00
		//THR address and command bits default to 0, so we neglect the command word entirely
		fx_write_SPI2UART(wc,port,info[count]);
		count++;
	}
	fx_write_SPI2UART(wc,port,0x000d);//send CR
	fx_write_SPI2UART(wc,port,0x000a);//send LF
}

//This function receives data from the GSM module through the 
//SPI2UART.Data is received from the UARTs FIFO character by charachter.
//It checks if there is data to read and if yes ->reads it, if no 
// an 'x' character is output.
char * GSM_receive(struct wcfxs *wc,int port)
{
	static char GSM_string[60];
	u16 reg,i,temp;
	int keep_s;
	
	//Get the number of characters in the Rx FIFO
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   1    1  0  0  1  0   0  0 ==0xC8. RXLVL register
	reg=fx_read_SPI2UART(wc,port,0xC800); 
	reg=reg & 0x00ff;
	//Check if data to read is available
	if(reg==0) {//if no data to read -> output 'x' string
		GSM_string[0]='x';
		GSM_string[1]=0x00;//string terminating character
		return GSM_string;
	}

	//Get all the characters and put them in a char array
	keep_s=0;
	for(i=0;i<reg;i++){
		temp=fx_read_SPI2UART(wc,port,0x8000); 
		temp=temp & 0x00ff;
		if((temp==0x000d)||(temp==0x000a)){
			if(debug>=2)
				printk("\n");
			//Add the terminating character when at least one char has been received
			if(keep_s>0){
				GSM_string[keep_s]=0x00;
				keep_s+=1;
			}
		}
		else{		
			if(debug>=2)
				printk("%c",(char)temp);
			GSM_string[keep_s]=(char)temp;
			keep_s+=1;
		}		
	}

	return GSM_string;
}

//The function is placed in the main SPORT interrupt
// It implements a state mashine for control of the Dialed/Received
//calls. When necessary it passed signals to Zaptel.
void wcfxs_gsm_control(struct wcfxs *wc, int card)
{
	static int interrupt_count=0;
	char * p2char;

//Dialing part

	//Once we have dialed the number we expect an OK received from
	//the modem. When OK is received, we switch to the next state
	if(outgoing_call_state==1){
		p2char=GSM_receive(wc,card);
		if(strcmp(p2char,"x")==0) return;
		if(strcmp(p2char,"0")==0){
			outgoing_call_state=2;
			//zt_hooksig(&wc->chans[card], ZT_RXSIG_OFFHOOK);
			if (debug>=2)
				printk("OK recevied!\n");
			return;
		}
		else{
			if (debug>=2)
				printk("ocs=%d str_rec=%s\n",outgoing_call_state,p2char);
			outgoing_call_state=0;
			zt_hooksig(&wc->chans[card], ZT_RXSIG_ONHOOK);
			if (debug>=2)
				printk("OK not received!\n");
			return;	
		}
			
	}
	
	//During converstaion
	//We continue looking for "NO CARRIER" "BUSY" or other signals.
	if(outgoing_call_state==2){
		p2char=GSM_receive(wc,card);
		if(strcmp(p2char,"x")==0) return;
		//If NO CARRIER received, initialize the state machine
		//Inform zaptel for call disconnect
		if(strcmp(p2char,"3")==0){
			outgoing_call_state=0;
			zt_hooksig(&wc->chans[card], ZT_RXSIG_ONHOOK);
			if (debug>=2)
				printk("NO CARRIER %s\n",p2char);
			return;
		}
		//If BUSY received, initialize the state machine
		//Inform zaptel for call disconnect
		if(strcmp(p2char,"7")==0){
			outgoing_call_state=0;
			zt_hooksig(&wc->chans[card], ZT_RXSIG_ONHOOK);
			if (debug>=2)
				printk("BUSY %s\n",p2char);
			return;
		}
		//If NO ANSWER received, initialize the state machine
		//Inform zaptel for call disconnect
		if(strcmp(p2char,"8")==0){
			outgoing_call_state=0;
			zt_hooksig(&wc->chans[card], ZT_RXSIG_ONHOOK);
			if (debug>=2)
				printk("NO ANSWER %s\n",p2char);
			return;
		}
		if (debug>=2)
			printk("ocs=%d str_rec=%s\n",outgoing_call_state,p2char);	
		return;		
	}

//Receiving a call
	//Waiting for RING signal from the GSM
	if(incomming_call_state==0){
		
			p2char=GSM_receive(wc,card);
			//When RING is received
			if(strcmp(p2char,"2")==0){
				 interrupt_count=2;
				 if (debug>=2)
					 printk("Ring: %s\n",p2char);
			}
			else{
				if(strcmp(p2char,"x")!=0){
					if (debug>=2)
						printk("ics=%d str_rec=%s\n",incomming_call_state,p2char);
				}
			}
			if(interrupt_count==2){
				zt_hooksig(&wc->chans[card], ZT_RXSIG_RING);
				if (debug>=2)
					printk("zt_hooksig ZT_RXSIG_RING sent!\n");
				interrupt_count=1;
				return;
			}	
			if(interrupt_count==1) {
				zt_hooksig(&wc->chans[card], ZT_RXSIG_OFFHOOK);
				if (debug>=2)
					printk("zt_hooksig ZT_RXSIG_OFFHOOK sent!\n");
				interrupt_count=0;
				incomming_call_state=1;
				return;
			}
			return;

	}
		
	//Ringing and checking for call disconnect
	if(incomming_call_state==1){
			p2char=GSM_receive(wc,card);

			//It is necessary to set the state to ZT_TXSTATE_OFFHOOK, otherwise
			//there is a problem when call is disconnected before it is answered
			wc->chans[card].txstate=1;//!! YN
			//When call is disconnected before it is answered
			if(strcmp(p2char,"3")==0){
				incomming_call_state=0;
				interrupt_count=0;
				
				zt_hooksig(&wc->chans[card],ZT_RXSIG_ONHOOK);
				if (debug>=2)
					printk("NO CARRIER %s\n",p2char);
				return;
			}
			//When RING is received
			if(strcmp(p2char,"2")==0){
				 interrupt_count=2;
				 if (debug>=2)
					 printk("Ring: %s\n",p2char);
			}
			else{
				if(strcmp(p2char,"x")!=0) {
					if (debug>=2)
						printk("ics=%d str_rec=%s\n",incomming_call_state,p2char);
				}
			}
			if(interrupt_count==2){
				zt_hooksig(&wc->chans[card], ZT_RXSIG_RING);
				if (debug>=2)
					printk("zt_hooksig ZT_RXSIG_RING sent!\n");
				interrupt_count=1;
				return;
			}	
			if(interrupt_count==1) {
				zt_hooksig(&wc->chans[card], ZT_RXSIG_OFFHOOK);
				if (debug>=2)
					printk("zt_hooksig ZT_RXSIG_OFFHOOK sent!\n");
				interrupt_count=0;
				return;
			}
			return;
	}		

	//Connected state (during conversation)
	if(incomming_call_state==2){
		p2char=GSM_receive(wc,card);
		if(strcmp(p2char,"x")==0) return;
		//Looking for NO CARRIER. If received, inform zaptel
		//that the other party has ended the conversation
		if(strcmp(p2char,"3")==0){
			incomming_call_state=0;
			zt_hooksig(&wc->chans[card], ZT_RXSIG_ONHOOK);
			if (debug>=2){
				printk("NO CARRIER %s\n",p2char);
				printk("zt_hooksig ZT_RXSIG_ONHOOK sent!\n");
			}
			return;
		}
		if (debug>=2)
			printk("ics=%d str_rec=%s\n",incomming_call_state,p2char);	
		return;
	}
		
}//end wcfxs_gsm_control



//This function implements the initialization of the 
//SPI2UART chip
static int init_SC16IS750(struct wcfxs *wc,int port)
{
	int ret;

	//Program LCR 
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    0  0  1  1  0   0  0 ==0x18
	ret=fx_program_register_SPI2UART(wc,port,0x1880); //0x80 allows special register set programming
	if(ret)
		return 1;
	//program DLL
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    0  0  0  0  0   0  0 ==0x00
	//according to the formula on pp.17 for 3.6864 MHz oscillator we need  divisor=24=18HEX
	//in order to get 9600 bauds
	//for 38400 bauds we need divisor=6
	ret=fx_program_register_SPI2UART(wc,port,0x0006);//program oscillator
	if(ret)
		return 1;

	//program DLM
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    0  0  0  1  0   0  0 ==0x08
	ret=fx_program_register_SPI2UART(wc,port,0x0800);//program oscillator
	if(ret)
		return 1;

	//Program LCR to access EFR register
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    0  0  1  1  0   0  0 ==0x18
	ret=fx_program_register_SPI2UART(wc,port,0x18BF);//0xBF allows EFR register programming
	if(ret)
		return 1;

	//Program EFR register
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    0  0  1  0  0   0  0 ==0x10
	ret=fx_program_register_SPI2UART(wc,port,0x10D0);//auto CTS,auto RTS,enable enhanced functions
	if(ret)
		return 1;
	
	//Program LCR 
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    0  0  1  1  0   0  0 ==0x18
	ret=fx_program_register_SPI2UART(wc,port,0x1803);//8n1, no parity
	if(ret)
		return 1;

	//Program MCR
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    0  1  0  0  0   0  0 ==0x20
	ret=fx_program_register_SPI2UART(wc,port,0x2004);//TCR and TLR enable
	if(ret)
		return 1;

	//Program TCR
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    0  1  1  0  0   0  0 ==0x60
	ret=fx_program_register_SPI2UART(wc,port,0x301E);//resume at 4 halt at 60 charachters
	if(ret)
		return 1;

	//Program FCR 
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    0  0  1  0  0   0  0 ==0x10
	fx_write_SPI2UART(wc,port,0x10c6); //NOTE: Write only register!
	//reset TXFIFO, reset RXFIFO,RX trigger=60 characters, non FIFO mode
	
	//Program IER
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    0  0  0  1  0   0  0 ==0x08
	ret=fx_program_register_SPI2UART(wc,port,0x0801);//enable Rx interrupt
	if(ret)
		return 1;

	//Program FCR 
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    0  0  1  0  0   0  0 ==0x10;//enable FIFO
	fx_write_SPI2UART(wc,port,0x1007); //NOTE: Write only register!


	//Set GPIO_CS at High,PWRKEY high. IOState register  0x0B.DTR high
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    1  0  1  1  0   0  0 ==0x58
	fx_write_SPI2UART(wc,port,0x5825);//gives bad results when read (inputs)
	//fx_program_register_SPI2UART(wc,port,0x5801);

	//Program GPIO_CS as output,GPIO0 (PWRKEY)as output,DTR output IODir register 0x0A
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    1  0  1  0  0   0  0 ==0x50
//	fx_write_SPI2UART(wc,port,0x5000);
	ret=fx_program_register_SPI2UART(wc,port,0x5025);
	if(ret)
		return 1;
	
	return 0;

}

//Implements the GSM module initialization
//through the SPI2UART chip.
static int init_GSM(struct wcfxs *wc,int port)
{
	u16 reg;
	char * p2char;
	int cntr;

//GSM management part
	//Check if VDD_EXT is in high state
	//(if GSM modem if ON).
	reg=fx_read_SPI2UART(wc,port,0xd800); 
	if (debug)
		printk("VDD_EXT=%x\n",reg);

	//Reset the GSM modem if it has already been started!
	if((reg & 0x0002)!=0){
		printk("Resetting the GSM modem!\n");	

		//Power down GSM modem
		cntr=3;
		do {
		GSM_send(wc,port,"at+cpowd=1");
		printk("Logging off the network........!\n");
		wait_just_a_bit(7*HZ);
		p2char=GSM_receive(wc,port);
		if (debug)
			printk("Received: %s\n",p2char);
		} while(strcmp(p2char,"NORMAL POWER DOWN")!=0 && (--cntr>0));


		//Check if VDD_EXT is in high state
		//(make sure the modem in in OFF state)
		reg=fx_read_SPI2UART(wc,port,0xd800); 
		if (debug)
			printk("VDD_EXT=%x\n",reg);
		if((reg & 0x0002)!=0) {
			printk("Unable to reset the GSM modem!!\n");
			return 1;
		}

		//Wait for more than 0.5 seconds
		wait_just_a_bit(1*HZ);
		
	}

	//Start the GSM if has not been started already
	else{
		printk("Starting the GSM modem!\n");
	}
	
	//Whether after RESET of after complete disconnet
	//of the main board from the main supply, we need to start
	// the GSM modem

	//Lower PWRKEY for more than two seconds
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    1  0  1  1  0   0  0 ==0x58
	fx_write_SPI2UART(wc,port,0x5824);

	printk("Wait for GSM module start!\n");
	//Keep PWRKEY low for more than two seconds (three in this case)
	wait_just_a_bit(3*HZ);

	//Raise PWRKEY again 
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    1  0  1  1  0   0  0 ==0x58
	fx_write_SPI2UART(wc,port,0x5825);
	wait_just_a_bit(1*HZ);//DPN

	//Check if VDD_EXT is in high state
	//(if modem is ON)
	reg=fx_read_SPI2UART(wc,port,0xd800); 
	if (debug)
		printk("VDD_EXT=%x\n",reg);
	if((reg & 0x0002)==0){
		 printk("Unable to start the GSM modem!!\n");
		return 1; 
	}

	//Ensure autobauding and modem answer
	GSM_send(wc,port,"at");
	// Wait 
	wait_just_a_bit(HZ);
	p2char=GSM_receive(wc,port);
	if (debug)
		printk("Received: %s\n",p2char);

	//Make sure there that there is no echo to the terminal
	cntr=3;
	do {
	GSM_send(wc,port,"ate0");
	wait_just_a_bit(HZ/10);
	p2char=GSM_receive(wc,port);
	if (debug)
		printk("Received: %s\n",p2char);
	} while(strcmp(p2char,"OK")!=0 && (--cntr>0));
		

	//Change the modem answer type, i.e.
	//switch from "OK" to '0",etc.
	cntr=3;
	do {
		GSM_send(wc,port,"atv0");
		wait_just_a_bit(HZ/10);
		p2char=GSM_receive(wc,port);
		if (debug)
			printk("Received: %s\n",p2char);
	} while(strcmp(p2char,"0")!=0 && (--cntr>0));
	
	//Error message verbose string
	cntr=3;
	do {
		GSM_send(wc,port,"at+cmee=2");
		wait_just_a_bit(HZ/10);
		p2char=GSM_receive(wc,port);
		if (debug)
			printk("Received: %s\n",p2char);
	} while(strcmp(p2char,"0")!=0 && (--cntr>0));
	


	//SIM PIN check
	GSM_send(wc,port,"at+cpin?");
	wait_just_a_bit(HZ/2);
	p2char=GSM_receive(wc,port);
	if (debug)
		printk("Received: %s\n",p2char);
	

	//If SIM pin has not been entered, enter it
	if(strcmp(p2char,"+CPIN: SIM PIN")==0)
	{
		//Enter PIN and wait for OK
		do{
			GSM_send(wc,port,SIM_Enter_string);//"at+cpin=\"3700\"");
			wait_just_a_bit(3*HZ);
			p2char=GSM_receive(wc,port);
			if (debug)
				printk("Received: %s\n",p2char);
			//PIN entered but wrong -> exit
			if(strcmp(p2char,"+CME ERROR: incorrect password")==0)
			{
				printk("WRONG SIM PIN!\n");
				return 1;
			}
		} while(strcmp(p2char,"0")!=0);
	}
	//if No SIM PIN required
	else
	{
		//Card not inserted
		if(strcmp(p2char,"+CME ERROR: SIM not inserted")==0)
		{
			printk("SIM NOT INSERTED! PLEASE INSERT SIM!\n");
			return 1;

		}
		else
		{
			//Card unlocked
			if(strcmp(p2char,"+CPIN: READY")==0)
			{
				printk("SIM CARD UNLOCKED!\n");
			}
			//Other problems!
			else{
				printk("SIM ERROR!\n");
				return 1;
			}


		}
			
		
	}
	
	// Wait until the modem is initialized properly
	if(debug)
		printk("Wait some time for GSM PIN init!\n");
	wait_just_a_bit(10*HZ);

	//text result code ,dial and busy enabled
	do {
	GSM_send(wc,port,"atx4");
	wait_just_a_bit(HZ/10);
	p2char=GSM_receive(wc,port);
	if (debug)
		printk("Received: %s\n",p2char);
	} while(strcmp(p2char,"0")!=0);

	//Adjust mic volume
	do {
	GSM_send(wc,port,"at+cmic=0,0");
	wait_just_a_bit(HZ/10);
	p2char=GSM_receive(wc,port);
	if (debug)
		printk("Received: %s\n",p2char);
	} while(strcmp(p2char,"0")!=0);


        //Adjust the side-tone level to 0dB
        do {
        GSM_send(wc,port,"at+sidet=0");
        wait_just_a_bit(HZ/10);
        p2char=GSM_receive(wc,port);
        if (debug)
                printk("Received: %s\n",p2char);
        } while(strcmp(p2char,"0")!=0);


        //Set the built in echo canceler
	//AT+ECHO=<voxGain>,<minMicEnergy>,<sampSlncePrd>,<channel>
	//
	// < voxGain >      : the parameter models the acoustic path between ear-piece and microphone.
	// < minMicEnergy > : the parameter sets the minimum microphone energy level to beattained 
	//                    before suppression is allowed. A typical value of this parameter is 20.
	// < sampSlncePrd > : the parameter control the minimum number of speech frames that will be 
	//                    replace with SID frames when an echo is detected. Atypical value of 
	//		      this parameter is 4.
	// <channel>        : channel, can be 0 or 1
    	//		      1     AUX_AUDIO
    	//		      0     NORMAL_AUDIO
        do {
        GSM_send(wc,port,"at+echo=5000,5,4,0");
        wait_just_a_bit(HZ/10);
        p2char=GSM_receive(wc,port);
        if (debug)
                printk("Received: %s\n",p2char);
        } while(strcmp(p2char,"0")!=0);


	//Adjust loudspeaker volume
	do {
	GSM_send(wc,port,"at+clvl=90");
	wait_just_a_bit(HZ/10);
	p2char=GSM_receive(wc,port);
	if (debug)
		printk("Received: %s\n",p2char);
	} while(strcmp(p2char,"0")!=0);

	if(debug)
		printk("\n");
	
	return 0;
}

//Implements latching of the data in the SPI input register of 
//the codec. Acts as a chip select. Only the rising edge of
//the signal matters.
static void Codec_reg_data_latch(struct wcfxs *wc,int port)
{
	//Latch data into the codec by raising and lowering the SPI2UART's GPIO
	
	//Lower GPIO_CS
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    1  0  1  1  0   0  0 ==0x58
	fx_write_SPI2UART(wc,port,0x5821);

	
	//Raise GPIO_CS
	//==>  R/~W A3 A2 A1 A0 CH1 CH0 X
	//==>   0    1  0  1  1  0   0  0 ==0x58
	fx_write_SPI2UART(wc,port,0x5825);

}

//Initializaion of the codec
static void init_WM8510(struct wcfxs *wc,int port)
{	

	//Resetting the chip ;Register 0x0;Write any value
	fx_write_SPI2UART_wo_CS(0x000F); 
	Codec_reg_data_latch(wc,port);

	//Powering up and enables ;Register 0x1
	//7bit address + 9bit data= 8bits +8bits
	// 8bits= 0x02 + 8bits = 0x0B (set BIASEN=1,BUFIOEN=1,VMIDSEL=11)
	fx_write_SPI2UART_wo_CS(0x020F); 
	Codec_reg_data_latch(wc,port);

	//Starting the ALC function;Register 0x20; ALCSEL;max gain
	fx_write_SPI2UART_wo_CS(0x4138); 
	Codec_reg_data_latch(wc,port);

	//DAC volume. Register 0x0B; 
	fx_write_SPI2UART_wo_CS(0x16D0); //was 0x16F0
	Codec_reg_data_latch(wc,port);

	//OSR enable=128 OSR;Register 0x0E;set ADCOSR, High pass filter enabled
	fx_write_SPI2UART_wo_CS(0x1D08); 
	Codec_reg_data_latch(wc,port);

        //Register 0x21;
        fx_write_SPI2UART_wo_CS(0x420B); //ALCLVL -> -7.5dB relative to Full Scale
					 //ALC hold time 0 ms
					 //zero crossing disable		
        Codec_reg_data_latch(wc,port);


	//Noise gate enable;Register 0x22;set ALCMODE->limiter!
	fx_write_SPI2UART_wo_CS(0x4532); //ALCMODE->limiter!
	//fx_write_SPI2UART_wo_CS(0x4432);   //ALCMODE->Normal
					   //26.2ms/6db gain ramp up
					   //3.33ms/6db gain ramp down 
	Codec_reg_data_latch(wc,port);
	
   	//Noise gate enable;Register 0x23;set NGATEN
	fx_write_SPI2UART_wo_CS(0x4608); 
	Codec_reg_data_latch(wc,port);

	//Output limiter enable;Register 0x18;disable LIMEN
	fx_write_SPI2UART_wo_CS(0x3032); 
	Codec_reg_data_latch(wc,port);
	
	//Output limiter gain adjust;Register 0x19;set LIMLVL
	fx_write_SPI2UART_wo_CS(0x3270); 
	Codec_reg_data_latch(wc,port);

	//Audio interface register;Register 0x04;
	//Setting DSP/PCM mode TDM, 16 bit samples
	fx_write_SPI2UART_wo_CS(0x0818); 
	Codec_reg_data_latch(wc,port);
	
	//Clock generation register;Register 0x06;
	//Setting CLKSEL to 1; MCLKDIV=1
	fx_write_SPI2UART_wo_CS(0x0C00); 
	Codec_reg_data_latch(wc,port);
	
	//Companding register;Register 0x05;
	//Setting ADC_COMP and DAC_COMP to u-law;Loopback disabled
	fx_write_SPI2UART_wo_CS(0x0A14); 
	Codec_reg_data_latch(wc,port);

	//Sampling rate register;Register 0x07;
	//Setting sampling rate to 8kHz
	fx_write_SPI2UART_wo_CS(0x0E0A); 
	Codec_reg_data_latch(wc,port);

	//OSR enable=128 OSR;Register 0x0A;set DACOSR=128
	fx_write_SPI2UART_wo_CS(0x1408); 
	Codec_reg_data_latch(wc,port);

	//Input PGA enable;Register 0x2;set INPGAEN, set ADCEN:BOOSTENABLE
	fx_write_SPI2UART_wo_CS(0x0415); 
	Codec_reg_data_latch(wc,port);

	//Input PGA boost stage: Reg 0x2f;PGABOOST= 0
	fx_write_SPI2UART_wo_CS(0x5F00); 
	Codec_reg_data_latch(wc,port);

	//output of DAC switching; Register 0x32
	//fx_write_SPI2UART_wo_CS(0x6400);//Output of DAC to MONOOUT 
	fx_write_SPI2UART_wo_CS(0x6401);  //Output of DAC to spkoutP/spkoutN outputs
	Codec_reg_data_latch(wc,port);

	//MONOOUTPUT mute;reg=0x38; MONOMUTE=1
	//fx_write_SPI2UART_wo_CS(0x7001);     //the case we have used MONOOUTPUT, MONOOUTPUT not mute
	fx_write_SPI2UART_wo_CS(0x7040); //for  spkoutP/spkoutN outputs, MONOOUTPUT is mute
	Codec_reg_data_latch(wc,port);


	//DAC startup;Register 0x3; Set DACEN bit
	//enable MONOOUT 
	//fx_write_SPI2UART_wo_CS(0x0689); //enable MONOOUT
	fx_write_SPI2UART_wo_CS(0x0665); //enable spkoutP/spkoutN outputs
	Codec_reg_data_latch(wc,port);

}

//All the functions for GSM module init
int Initialize_GSM_module(struct wcfxs *wc,int port)
{
	int ret;
	//Init SPI2UART
	ret=init_SC16IS750(wc,port);
	if(ret)
		return 1;
	//Init CODEC
	init_WM8510(wc,port);
	//Init GSM 
	ret=init_GSM(wc,port);
	if(ret)
		return 1;
	
	return 0;
}






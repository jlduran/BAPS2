
#ifndef GSM_MODULE_SPI



/* Modified by Alex Tao */
#ifdef CONFIG_4FX_SPI_INTERFACE
#define SPI_BAUDS   5  /* 12.5 MHz for 100MHz system clock    */
#define SPI_NCSA    3  /* nCS bit for SPI data                */
#define SPI_NCSB    12 /* nCS bit for SPI mux                 */
#else
#ifdef CONFIG_4FX_SPORT_INTERFACE
#define SPI_BAUDS   49  /* 13.4 MHz for 133MHz system clock    */
#define SPI_BAUDS_GSM 49 //1.33MHz for 133Mhz system clock; 4 MHz allowed //YN
/* Use other PF signals */
#define SPI_NCSA    8    /* Simulate SPORT interface as SPI */
#define SPI_NCSB    9
#endif
#endif

#define RESET_BIT   4  /* GPIO bit tied to nRESET on Si chips */
#define NUM_CARDS 8
#define NUM_CAL_REGS 12

#define FX_MAX_PORTS   8  // max number of ports in system

#define FX_LED_RED     1

//penev
#define GSM_MODULE_SPI


//#define SPORT_INTERFACE_DEBUG
#ifdef SPORT_INTERFACE_DEBUG
#define PRINTK(args...) printk(args)
#else
#define PRINTK(args...)
#endif

#ifdef SPORT_INTERFACE_DEBUG
static int txCnt = 0, rxCnt = 0;
#endif

#ifndef SPI_NCSB
/* Use other PF signals */
#define SPI_NCSA    8    /* Simulate SPORT interface as SPI */
#define SPI_NCSB    9
#endif
#define SPORT_nPWR	12

#ifndef SPORT1_REGBASE
#define SPORT1_REGBASE 0xFFC00900
#endif

#define DEFINE_SPORT1_REG(reg, off) \
static inline u16 sport1_read_##reg(void) \
            { return *(volatile unsigned short*)(SPORT1_REGBASE + off); } \
static inline void sport1_write_##reg(u16 v) \
            {*(volatile unsigned short*)(SPORT1_REGBASE + off) = v;\
             __builtin_bfin_ssync();}


DEFINE_SPORT1_REG(TCR1,0x00)
DEFINE_SPORT1_REG(TCR2,0x04)
DEFINE_SPORT1_REG(TCLKDIV,0x08)
DEFINE_SPORT1_REG(TFSDIV,0x0C)

DEFINE_SPORT1_REG(RCR1, 0x20)
DEFINE_SPORT1_REG(RCR2, 0x24)
DEFINE_SPORT1_REG(RCLKDIV,0x28)
DEFINE_SPORT1_REG(RFSDIV,0x2C)
DEFINE_SPORT1_REG(STAT,0x30)

#endif


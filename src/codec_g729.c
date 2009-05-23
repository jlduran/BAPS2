/*
 * FILE..: codec_g729.c
 * AUTHOR: David Rowe 
 *
 * This program is free software, distributed under the terms of
 * the GNU General Public License Version 2. See the LICENSE file
 * at the top of the source tree.
 */

/*! \file
 *
 * \brief codec_g729.c - translate between signed linear and g729
 * 
 * \ingroup codecs
 */

#include "asterisk.h"

ASTERISK_FILE_VERSION(__FILE__, "$Revision: 40722 $")

#include <fcntl.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dlfcn.h>

#include "asterisk/lock.h"
#include "asterisk/logger.h"
#include "asterisk/module.h"
#include "asterisk/config.h"
#include "asterisk/options.h"
#include "asterisk/translate.h"
#include "asterisk/channel.h"
#include "asterisk/alaw.h"
#include "asterisk/utils.h"

#include "g729ab_codec.h"

/* mode flags for G729 encoder */

#define MODE_G729A  0
#define MODE_G729AB 1

/* bit packing format flags G729 encoder and decoder */

#define BIT_PACKED    0
#define BIT_UNPACKED  1

AST_MUTEX_DEFINE_STATIC(localuser_lock);

static int localusecnt=0;

struct ast_translator_pvt {

	struct ast_frame f;

	G729_enc_h  inst_g729_enc_h;
	G729_dec_h  inst_g729_dec_h;

	short          *pcmStream;	/* Signed linear data */
	unsigned char  *bitStream;	/* G.729 bits */

	int nbanks;
	int maxbitsize;
  	int inFrameSize;
   	int outFrameSize;

	short pcm_buf[8000];
	unsigned char bitstream_buf[1000];

	int tail;
};

/* variables used to measure MIPs at run time */

static unsigned int total_enc_cycles;
static unsigned int total_dec_cycles;
static unsigned int enc_calls;
static unsigned int dec_calls;
static unsigned int start_dec_cycles;
static unsigned int start_enc_cycles;

#define g729_coder_pvt ast_translator_pvt

/*
 * Signed 16 bit audio data - used by Asterisk to test codec
 *
 */

static signed short __attribute__ ((aligned (4))) slin_g729_ex[] = {
0x0873, 0x06d9, 0x038c, 0x0588, 0x0409, 0x033d, 0x0311, 0xff6c, 
0xfeef, 0xfd3e, 0xfdff, 0xff7a, 0xff6d, 0xffec, 0xff36, 0xfd62, 
0xfda7, 0xfc6c, 0xfe67, 0xffe1, 0x003d, 0x01cc, 0x0065, 0x002a, 
0xff83, 0xfed9, 0xffba, 0xfece, 0xff42, 0xff16, 0xfe85, 0xff31, 
0xff02, 0xfdff, 0xfe32, 0xfe3f, 0xfed5, 0xff65, 0xffd4, 0x005b, 
0xff88, 0xff01, 0xfebd, 0xfe95, 0xff46, 0xffe1, 0x00e2, 0x0165, 
0x017e, 0x01c9, 0x0182, 0x0146, 0x00f9, 0x00ab, 0x006f, 0xffe8, 
0xffd8, 0xffc4, 0xffb2, 0xfff9, 0xfffe, 0x0023, 0x0018, 0x000b, 
0x001a, 0xfff7, 0x0014, 0x000b, 0x0004, 0x000b, 0xfff1, 0xff4f, 
0xff3f, 0xff42, 0xff5e, 0xffd4, 0x0014, 0x0067, 0x0051, 0x003b, 
0x0034, 0xfff9, 0x000d, 0xff54, 0xff54, 0xff52, 0xff3f, 0xffcc, 
0xffe6, 0x00fc, 0x00fa, 0x00e4, 0x00f3, 0x0021, 0x0011, 0xffa1, 
0xffab, 0xffdb, 0xffa5, 0x0009, 0xffd2, 0xffe6, 0x0007, 0x0096, 
0x00e4, 0x00bf, 0x00ce, 0x0048, 0xffe8, 0xffab, 0xff8f, 0xffc3, 
0xffc1, 0xfffc, 0x0002, 0xfff1, 0x000b, 0x00a7, 0x00c5, 0x00cc, 
0x015e, 0x00e4, 0x0094, 0x0029, 0xffc7, 0xffc3, 0xff86, 0xffe4, 
0xffe6, 0xffec, 0x000f, 0xffe3, 0x0028, 0x004b, 0xffaf, 0xffcb, 
0xfedd, 0xfef8, 0xfe83, 0xfeba, 0xff94, 0xff94, 0xffbe, 0xffa8, 
0xff0d, 0xff32, 0xff58, 0x0021, 0x0087, 0x00be, 0x0115, 0x007e, 
0x0052, 0xfff0, 0xffc9, 0xffe8, 0xffc4, 0x0014, 0xfff0, 0xfff5, 
0xfffe, 0xffda, 0x000b, 0x0010, 0x006f, 0x006f, 0x0052, 0x0045, 
0xffee, 0xffea, 0xffcb, 0xffdf, 0xfffc, 0xfff0, 0x0012, 0xfff7, 
0xfffe, 0x0018, 0x0050, 0x0066, 0x0047, 0x0028, 0xfff7, 0xffe8, 
0xffec, 0x0007, 0x001d, 0x0016, 0x00c4, 0x0093, 0x007d, 0x0052, 
0x00a5, 0x0091, 0x003c, 0x0041, 0xffd1, 0xffda, 0xffc6, 0xfff0, 
0x001d, 0xfffe, 0x0024, 0xffee, 0xfff3, 0xfff0, 0xffea, 0x0012, 
0xfff3, 0xfff7, 0xffda, 0xffca, 0xffda, 0xffdf, 0xfff3, 0xfff7, 
0xff54, 0xff7c, 0xff8c, 0xffb9, 0x0012, 0x0012, 0x004c, 0x0007, 
0xff50, 0xff66, 0xff54, 0xffa9, 0xffdc, 0xfff9, 0x0038, 0xfff9, 
0x00d2, 0x0096, 0x008a, 0x0079, 0xfff5, 0x0019, 0xffad, 0xfffc
};

/*
 * One frame of raw G729 data - used by Asterisk to test codec
 */

static unsigned char __attribute__ ((aligned (4))) g729_slin_ex[] = {
  0xf9, 0xa3, 0xc9, 0xe0, 0x0, 0xfa, 0xdd, 0xa9, 0x97, 0x7d };

/* C-callable function to return value of CYCLES register */

static unsigned int cycles(void) {
  int ret;

   __asm__ __volatile__
   (
   "%0 = CYCLES;\n\t"
   : "=&d" (ret)
   :
   : "R1"
   );

   return ret;
}

/* Create a new linear to g729 translator (g729 encoder) */

static int lintog729_new(struct ast_trans_pvt *pvt) {
	struct  g729_coder_pvt *tmp = pvt->pvt;

	if (option_verbose > 2)
		ast_verbose(VERBOSE_PREFIX_3 "lintog729_new\n");

	if(tmp) {

		/* init encoder */

		tmp->inst_g729_enc_h = (G729_enc_h)malloc(sizeof(G729_EncObj));
		if (tmp->inst_g729_enc_h == NULL) {
			ast_log(LOG_ERROR, "Couldn't malloc inst_g729_enc_h");
			return 1;
		}
		if ((unsigned int)tmp->inst_g729_enc_h % 4) {
			/* g729 codec will blow up if states not 32-bit aligned */
			ast_log(LOG_ERROR, "inst_g729_enc_h not aligned");
			return 1;
		}
		(*g729ab_enc_reset) (tmp->inst_g729_enc_h);
		G729AB_ENC_CONFIG(tmp->inst_g729_enc_h, G729_ENC_OUTPUTFORMAT, 
				  BIT_UNPACKED);
		G729AB_ENC_CONFIG(tmp->inst_g729_enc_h, G729_ENC_VAD, MODE_G729A);

		tmp->tail = 0;
		localusecnt++;
		ast_update_use_count();
		if (option_verbose > 2)
			ast_verbose(VERBOSE_PREFIX_3 "use count: %d\n", localusecnt);
	}
	
	return 0;
}

/* Create a new g729 to linear translator (g729 decoder) */

static int g729tolin_new(struct ast_trans_pvt *pvt) {
	struct g729_coder_pvt *tmp = pvt->pvt;

	if (option_verbose > 2)
		ast_verbose(VERBOSE_PREFIX_3 "g729tolin_new\n");
	if(tmp) {

		/* init decoder */

		tmp->inst_g729_dec_h = (G729_dec_h)malloc(sizeof(G729_DecObj));
		if (tmp->inst_g729_dec_h == NULL) {
			ast_log(LOG_ERROR, "Couldn't malloc inst_g729_dec_h");
			return 1;
		}
		if ((unsigned int)tmp->inst_g729_dec_h % 4) {
			/* g729 codec will blow up if states not 32-bit aligned */
			ast_log(LOG_ERROR, "inst_g729_dec_h not aligned");
			return 1;
		}
		(*g729ab_dec_reset) (tmp->inst_g729_dec_h);
		G729AB_DEC_CONFIG(tmp->inst_g729_dec_h, G729_DEC_INPUTFORMAT, 
				  BIT_UNPACKED);

		tmp->tail = 0;
		localusecnt++;
		ast_update_use_count();
		if (option_verbose > 2)
			ast_verbose(VERBOSE_PREFIX_3 "use count: %d\n", localusecnt);
	}

	return 0;
}

/* These stuctures set up test data that Asterisk uses to test codec */

static struct ast_frame *lintog729_sample(void) {
	static struct ast_frame f;
	f.frametype = AST_FRAME_VOICE;
	f.subclass = AST_FORMAT_SLINEAR;
	f.datalen = sizeof(slin_g729_ex);
	f.samples = sizeof(slin_g729_ex) / 2;
	f.mallocd = 0;
	f.offset = 0;
	f.src = __PRETTY_FUNCTION__;
	f.data = slin_g729_ex;
	return &f;
}

static struct ast_frame *g729tolin_sample(void) {
	static struct ast_frame f;
	f.frametype = AST_FRAME_VOICE;
	f.subclass = AST_FORMAT_G729A;
	f.datalen = sizeof(g729_slin_ex);
	f.samples = 240;
	f.mallocd = 0;
	f.offset = 0;
	f.src = __PRETTY_FUNCTION__;
	f.data = g729_slin_ex;
	return &f;
}

/**
 * Retrieve a frame that has already been decompressed
 */
static struct ast_frame *g729tolin_frameout(struct ast_trans_pvt *pvt) {
	struct g729_coder_pvt *tmp = pvt->pvt;
	if(!tmp->tail)
		return NULL;
	tmp->f.frametype = AST_FRAME_VOICE;
	tmp->f.subclass = AST_FORMAT_SLINEAR;
	tmp->f.datalen = tmp->tail * 2;
	tmp->f.samples = tmp->tail;
	tmp->f.mallocd = 0;
	tmp->f.offset = AST_FRIENDLY_OFFSET;
	tmp->f.src = __PRETTY_FUNCTION__;
	tmp->f.data = tmp->pcm_buf;
	tmp->tail = 0;
	return &tmp->f;
}

/**
 * Accept a g729 compressed frame and decode it at the end of the
 * current buffer.
 */
static int g729tolin_framein(struct ast_trans_pvt *pvt, struct ast_frame *f) {
	struct g729_coder_pvt *tmp = pvt->pvt;
	int x,i,byte,bit;
	int frameSize = 0;
	short  __attribute__ ((aligned (4))) tmp_bits[82];
	short __attribute__ ((aligned (4))) tmp_pcm[80];
	unsigned int t;
	
	for(x = 0; x < f->datalen; x += frameSize) {
		if((f->datalen - x) == 2)
			frameSize = 2;   /* VAD frame */
		else
			frameSize = 10;  /* Regular frame */
		if(tmp->tail + 80 < sizeof(tmp->pcm_buf) / 2) {

			/* decode the frame */

			tmp->bitStream = f->data + x;
			tmp->pcmStream = tmp->pcm_buf + tmp->tail;

			/* convert into unpacked format to suit ADI g729 library */

			tmp_bits[0] = 0x6b21; tmp_bits[1] = 0x0050;
			for(i=0; i<80; i++) {
				byte = i>>3;
				bit = i & 0x7;
				if ((tmp->bitStream[byte] >> (7-bit)) & 0x1) 
					tmp_bits[i+2] = 0x81;
				else
					tmp_bits[i+2] = 0x7f;
			}

			t = cycles();
			G729AB_DEC(tmp->inst_g729_dec_h, tmp_bits, tmp_pcm);
			total_dec_cycles += cycles() - t;
			if (dec_calls++ == 500) {
				unsigned int total_cycles = cycles() - start_dec_cycles;
				start_dec_cycles = cycles();
				if (option_verbose > 2)
					ast_verbose(VERBOSE_PREFIX_3 "g729 dec_calls  %d  total_cycles: %d  "
					"total_dec_cycles: %d dec CPU load: %6.3f%%\n", 
					dec_calls, total_cycles, total_dec_cycles, 
					100.0*(float)total_dec_cycles/total_cycles);
				total_dec_cycles = 0;
				dec_calls = 0;
			}
			memcpy(tmp->pcmStream, tmp_pcm, 80*sizeof(short));
			pvt->samples += 80;

			tmp->tail += 80;
		} else {
			ast_log(LOG_WARNING, "Out of G.729 buffer space\n");
			return -1;
		}
	}
	return 0;
}

/**
 * Accept a signed linear frame for encoding.
 */
static int lintog729_framein(struct ast_trans_pvt *pvt, struct ast_frame *f) {
	struct g729_coder_pvt *tmp = pvt->pvt;
	if(tmp->tail + f->datalen/2 < sizeof(tmp->pcm_buf) / 2) {
		memcpy((tmp->pcm_buf + tmp->tail), f->data, f->datalen);
		tmp->tail += f->datalen/2;
		pvt->samples += f->samples;
	} else {
		ast_log(LOG_WARNING, "Out of buffer space\n");
		return -1;
	}
	return 0;
}

/**
 * Encode a linear frame to compressed g729 frame.
 */
static struct ast_frame *lintog729_frameout(struct ast_trans_pvt *pvt) {
	struct g729_coder_pvt *tmp = pvt->pvt;
	int x = 0;
	int i, bit, byte;
	unsigned int t;

	/* ADI g729 library requires 4 byte aligned I/O arrays.  Also
	   note the bit array is 82 long rather than the 80 required,
	   this is due to some extra bytes required by the g729
	   library that are not part of the g729 payload data. */

	short  __attribute__ ((aligned (4))) tmp_bits[82];
	short __attribute__ ((aligned (4))) tmp_pcm[80];

	if(tmp->tail < 80)
		return NULL;
	tmp->f.frametype = AST_FRAME_VOICE;
	tmp->f.subclass = AST_FORMAT_G729A;
	tmp->f.mallocd = 0;
	tmp->f.offset = AST_FRIENDLY_OFFSET;
	tmp->f.src = __PRETTY_FUNCTION__;
	tmp->f.data = tmp->bitstream_buf;
	while(tmp->tail >= 80) {
		if((x+1) * 10 >= sizeof(tmp->bitstream_buf)) {
			ast_log(LOG_WARNING, "Out of buffer space\n");
			break;
		}
		/* Copy the frame to workspace, then encode it */
		tmp->pcmStream = tmp->pcm_buf;
		tmp->bitStream = tmp->bitstream_buf + (x * 10);
		memcpy(tmp_pcm, tmp->pcmStream, 80*sizeof(short));
		t = cycles();
		G729AB_ENC(tmp->inst_g729_enc_h, tmp_pcm, tmp_bits);
		total_enc_cycles += cycles() - t;
		if (enc_calls++ >= 500) {
			unsigned int total_cycles = cycles() - start_enc_cycles;
			start_enc_cycles = cycles();
			if (option_verbose > 2)
				ast_verbose(VERBOSE_PREFIX_3 "g729 enc_calls  %d  total_cycles: %d  "
			        "total_enc_cycles: %d enc CPU load: %6.3f%%\n", 
				enc_calls, total_cycles, total_enc_cycles, 
				100.0*(float)total_enc_cycles/total_cycles);
			total_enc_cycles = 0;
			enc_calls = 0;
		}
		/* convert into unpacked format to suit ADI g729 library */

		memset(tmp->bitStream, 0, 10);
		for(i=0; i<80; i++) {
			byte = i>>3;
			bit = i & 0x7;
			if (tmp_bits[i+2] == 0x81)
				tmp->bitStream[byte] |= 1 << (7-bit);
		}

		tmp->tail -= 80;
		if(tmp->tail)
			memmove(tmp->pcm_buf, tmp->pcm_buf + 80, tmp->tail * 2);
		x++;
	}
	tmp->f.datalen = x * 10;
	tmp->f.samples = x * 80;


	return &(tmp->f);
}

static void lintog729_release(struct ast_trans_pvt *pvt) {
	struct g729_coder_pvt *tmp = pvt->pvt;

	free(tmp->inst_g729_enc_h);
	localusecnt--;
	ast_update_use_count();
}

static void g729tolin_release(struct ast_trans_pvt *pvt) {
	struct g729_coder_pvt *tmp = pvt->pvt;

	free(tmp->inst_g729_dec_h);
	localusecnt--;
	ast_update_use_count();
}

static struct ast_translator g729tolin = {
        .name = "g729tolin",
        .srcfmt = AST_FORMAT_G729A,
        .dstfmt = AST_FORMAT_SLINEAR,
        .newpvt = g729tolin_new,
        .framein = g729tolin_framein,
        .frameout = g729tolin_frameout,
        .destroy = g729tolin_release,
        .sample = g729tolin_sample,
        .desc_size = sizeof(struct g729_coder_pvt),
        .buf_size = 8000 * 2};

static struct ast_translator lintog729 = {
        .name = "lintog729",
        .srcfmt = AST_FORMAT_SLINEAR,
        .dstfmt = AST_FORMAT_G729A,
        .newpvt = lintog729_new,
        .framein = lintog729_framein,
        .frameout = lintog729_frameout,
        .destroy = lintog729_release,
        .sample = lintog729_sample,
        .desc_size = sizeof(struct g729_coder_pvt),
        .buf_size = 1000 };

static int load_module(void) {
	int   res;
	void *handle;
	char *error;

	total_enc_cycles = total_dec_cycles = 0;
	enc_calls = dec_calls = 0;

	/* Set up function ptrs to g729 .so library functions */

	handle = dlopen ("libg729ab.so", RTLD_LAZY);
	if (!handle) {
		ast_log(LOG_ERROR, "Error opening libg729ab.so : %s\n", dlerror());
		return 1;
	}  
	dlerror();
	g729ab_enc_reset = dlsym(handle, "G729AB_ENC_RESET");
	error = (char*)dlerror();
	if (error != NULL)  {
		ast_log(LOG_ERROR, "%s\n", error);
		return 1;
	}

	g729ab_enc_process = dlsym(handle, "G729AB_ENC_PROCESS");
	error = (char*)dlerror();
	if (error != NULL)  {
		ast_log(LOG_ERROR, "%s\n", error);
		return 1;
	}
	g729ab_dec_reset   = dlsym(handle, "G729AB_DEC_RESET");
	error = (char*)dlerror();
	if (error != NULL)  {
		ast_log(LOG_ERROR, "%s\n", error);
		return 1;
	}
	g729ab_dec_process = dlsym(handle, "G729AB_DEC_PROCESS");
	error = (char*)dlerror();
	if (error != NULL)  {
		ast_log(LOG_ERROR, "%s\n", error);
		return 1;
	}

	res = ast_register_translator(&g729tolin);
	if(!res)
		res = ast_register_translator(&lintog729);
	else
		ast_unregister_translator(&g729tolin);
	return res;
}

static int unload_module(void) {
	int res;
	ast_mutex_lock(&localuser_lock);
	res = ast_unregister_translator(&lintog729);
	  if(!res)
		res = ast_unregister_translator(&g729tolin);
	if(localusecnt)
		res = -1;
	ast_mutex_unlock(&localuser_lock);
	return res;
}


AST_MODULE_INFO(ASTERISK_GPL_KEY, AST_MODFLAG_DEFAULT, "G.729 Coder/Decoder",
		.load = load_module,
		.unload = unload_module,
	       );

/*
   strchrnul - find a character or nul in a string

   Copyright (c) 2014-2022, ARM Limited
   All rights Reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:
       * Redistributions of source code must retain the above copyright
         notice, this list of conditions and the following disclaimer.
       * Redistributions in binary form must reproduce the above copyright
         notice, this list of conditions and the following disclaimer in the
         documentation and/or other materials provided with the distribution.
       * Neither the name of the company nor the names of its contributors
         may be used to endorse or promote products derived from this
         software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  */
#include <picolibc.h>

#if (defined (__OPTIMIZE_SIZE__) || defined (__PREFER_SIZE_OVER_SPEED)) || !defined(__LP64__) || !defined(__ARM_NEON)
/* See strchrnul-stub.c  */
#else

/* Assumptions:
 *
 * ARMv8-a, AArch64
 * Neon Available.
 */

#include "asmdefs.h"

/* Arguments and results.  */
#define srcin		x0
#define chrin		w1

#define result		x0

#define src		x2
#define	tmp1		x3
#define wtmp2		w4
#define tmp3		x5

#define vrepchr		v0
#define vdata1		v1
#define vdata2		v2
#define vhas_nul1	v3
#define vhas_nul2	v4
#define vhas_chr1	v5
#define vhas_chr2	v6
#define vrepmask	v7
#define vend1		v16

/* Core algorithm.

   For each 32-byte hunk we calculate a 64-bit syndrome value, with
   two bits per byte (LSB is always in bits 0 and 1, for both big
   and little-endian systems).  For each tuple, bit 0 is set iff
   the relevant byte matched the requested character or nul.  Since the
   bits in the syndrome reflect exactly the order in which things occur
   in the original string a count_trailing_zeros() operation will
   identify exactly which byte is causing the termination.  */

/* Locals and temporaries.  */

ENTRY (strchrnul)
	PTR_ARG (0)
	/* Magic constant 0x40100401 to allow us to identify which lane
	   matches the termination condition.  */
	mov	wtmp2, #0x0401
	movk	wtmp2, #0x4010, lsl #16
	dup	vrepchr.16b, chrin
	bic	src, srcin, #31		/* Work with aligned 32-byte hunks.  */
	dup	vrepmask.4s, wtmp2
	ands	tmp1, srcin, #31
	b.eq	L(loop)

	/* Input string is not 32-byte aligned.  Rather than forcing
	   the padding bytes to a safe value, we calculate the syndrome
	   for all the bytes, but then mask off those bits of the
	   syndrome that are related to the padding.  */
	ld1	{vdata1.16b, vdata2.16b}, [src], #32
	neg	tmp1, tmp1
	cmeq	vhas_chr1.16b, vdata1.16b, vrepchr.16b
	cmeq	vhas_chr2.16b, vdata2.16b, vrepchr.16b
	cmhs	vhas_nul1.16b, vhas_chr1.16b, vdata1.16b
	cmhs	vhas_nul2.16b, vhas_chr2.16b, vdata2.16b
	and	vhas_chr1.16b, vhas_nul1.16b, vrepmask.16b
	and	vhas_chr2.16b, vhas_nul2.16b, vrepmask.16b
	lsl	tmp1, tmp1, #1
	addp	vend1.16b, vhas_chr1.16b, vhas_chr2.16b	// 256->128
	mov	tmp3, #~0
	addp	vend1.16b, vend1.16b, vend1.16b		// 128->64
	lsr	tmp1, tmp3, tmp1

	mov	tmp3, vend1.d[0]
	bic	tmp1, tmp3, tmp1	// Mask padding bits.
	cbnz	tmp1, L(tail)

	.p2align 4
L(loop):
	ld1	{vdata1.16b, vdata2.16b}, [src], #32
	cmeq	vhas_chr1.16b, vdata1.16b, vrepchr.16b
	cmeq	vhas_chr2.16b, vdata2.16b, vrepchr.16b
	cmhs	vhas_nul1.16b, vhas_chr1.16b, vdata1.16b
	cmhs	vhas_nul2.16b, vhas_chr2.16b, vdata2.16b
	orr	vend1.16b, vhas_nul1.16b, vhas_nul2.16b
	umaxp	vend1.16b, vend1.16b, vend1.16b
	mov	tmp1, vend1.d[0]
	cbz	tmp1, L(loop)

	/* Termination condition found.  Now need to establish exactly why
	   we terminated.  */
	and	vhas_chr1.16b, vhas_nul1.16b, vrepmask.16b
	and	vhas_chr2.16b, vhas_nul2.16b, vrepmask.16b
	addp	vend1.16b, vhas_chr1.16b, vhas_chr2.16b		// 256->128
	addp	vend1.16b, vend1.16b, vend1.16b		// 128->64

	mov	tmp1, vend1.d[0]
L(tail):
	/* Count the trailing zeros, by bit reversing...  */
	rbit	tmp1, tmp1
	/* Re-bias source.  */
	sub	src, src, #32
	clz	tmp1, tmp1	/* ... and counting the leading zeros.  */
	/* tmp1 is twice the offset into the fragment.  */
	add	result, src, tmp1, lsr #1
	ret

END (strchrnul)
#endif

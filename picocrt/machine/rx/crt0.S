/* Copyright (c) 2008, 2009, 2011 Red Hat Incorporated.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met: 

     Redistributions of source code must retain the above copyright 
     notice, this list of conditions and the following disclaimer.

     Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.

     The name of Red Hat Incorporated may not be used to endorse 
     or promote products derived from this software without specific 
     prior written permission.

   This software is provided by the copyright holders and contributors
   "AS IS" and any express or implied warranties, including, but not
   limited to, the implied warranties of merchantability and fitness for
   a particular purpose are disclaimed.  In no event shall Red Hat
   incorporated be liable for any direct, indirect, incidental, special,
   exemplary, or consequential damages (including, but not limited to,
   procurement of substitute goods or services; loss of use, data, or
   profits; or business interruption) however caused and on any theory of
   liability, whether in contract, strict liability, or tort (including
   negligence or otherwise) arising in any way out of the use of this
   software, even if advised of the possibility of such damage.  */

	.text

	.global __start
__start:
.LFB2:
	mvtc	#0, psw
	/* Enable the DN bit - this should have been done for us by
           the CPU reset, but it is best to make sure for ourselves.  */	
	mvtc    #0x100, fpsw
	mov	#___stack, r0

	/* Copy the .data section from ROM into RAM.  */
	mov	#___data_start, r1
	mov	#___data_source, r2
	mov	#___data_size, r3
#ifdef __RX_DISALLOW_STRING_INSNS__
	cmp	#0, r3
	beq	2f

1:	mov.b	[r2+], r5
	mov.b	r5, [r1+]
	sub	#1, r3
	bne	1b
2:	
#else
	smovf
#endif

	/* Initialise the contents of the .bss section.  */
	mov	#___bss_start, r1
	mov	#0, r2
	mov	#___bss_size, r3
	sstr.l	

	mov	#0, r1 /* argc */
	mov	#0, r2 /* argv */
	mov	#0, r3 /* envv */
	bsr.a	_main

	nop


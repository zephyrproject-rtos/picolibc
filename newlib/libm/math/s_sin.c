
/* @(#)s_sin.c 5.1 93/09/24 */
/*
 * ====================================================
 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 *
 * Developed at SunPro, a Sun Microsystems, Inc. business.
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 * ====================================================
 */

/*
FUNCTION
        <<sin>>, <<sinf>>, <<cos>>, <<cosf>>---sine or cosine
INDEX
sin
INDEX
sinf
INDEX
cos
INDEX
cosf
SYNOPSIS
        #include <math.h>
        double sin(double <[x]>);
        float  sinf(float <[x]>);
        double cos(double <[x]>);
        float cosf(float <[x]>);

DESCRIPTION
        <<sin>> and <<cos>> compute (respectively) the sine and cosine
        of the argument <[x]>.  Angles are specified in radians.

        <<sinf>> and <<cosf>> are identical, save that they take and
        return <<float>> values.


RETURNS
        The sine or cosine of <[x]> is returned.

PORTABILITY
        <<sin>> and <<cos>> are ANSI C.
        <<sinf>> and <<cosf>> are extensions.

QUICKREF
        sin ansi pure
        sinf - pure
*/

/* sin(x)
 * Return sine function of x.
 *
 * kernel function:
 *	__kernel_sin		... sine function on [-pi/4,pi/4]
 *	__kernel_cos		... cose function on [-pi/4,pi/4]
 *	__rem_pio2	... argument reduction routine
 *
 * Method.
 *      Let S,C and T denote the sin, cos and tan respectively on
 *	[-PI/4, +PI/4]. Reduce the argument x to y1+y2 = x-k*pi/2
 *	in [-pi/4 , +pi/4], and let n = k mod 4.
 *	We have
 *
 *          n        sin(x)      cos(x)        tan(x)
 *     ----------------------------------------------------------
 *	    0	       S	   C		 T
 *	    1	       C	  -S		-1/T
 *	    2	      -S	  -C		 T
 *	    3	      -C	   S		-1/T
 *     ----------------------------------------------------------
 *
 * Special cases:
 *      Let trig be any of sin, cos, or tan.
 *      trig(+-INF)  is NaN, with signals;
 *      trig(NaN)    is that NaN;
 *
 * Accuracy:
 *	TRIG(x) returns trig(x) nearly rounded
 */

#include "fdlibm.h"

#ifdef _NEED_FLOAT64

__float64
sin64(__float64 x)
{
    __float64 y[2], z = _F_64(0.0);
    __int32_t n, ix;

    /* High word of x. */
    GET_HIGH_WORD(ix, x);

    /* |x| ~< pi/4 */
    ix &= 0x7fffffff;
    if (ix <= 0x3fe921fb)
        return __kernel_sin(x, z, 0);

    /* sin(Inf or NaN) is NaN */
    else if (ix >= 0x7ff00000)
        return __math_invalid(x);

    /* argument reduction needed */
    else {
        n = __rem_pio2(x, y);
        switch (n & 3) {
        case 0:
            return __kernel_sin(y[0], y[1], 1);
        case 1:
            return __kernel_cos(y[0], y[1]);
        case 2:
            return -__kernel_sin(y[0], y[1], 1);
        default:
            return -__kernel_cos(y[0], y[1]);
        }
    }
}

#ifdef __strong_reference
#if defined(__GNUCLIKE_PRAGMA_DIAGNOSTIC) && !defined(__clang__)
#pragma GCC diagnostic ignored "-Wmissing-attributes"
#endif
__strong_reference(_NAME_64(sin), _NAME_64(_sin));
#endif

_MATH_ALIAS_d_d(sin)

#endif /* _NEED_FLOAT64 */

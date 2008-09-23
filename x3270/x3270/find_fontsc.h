/*
 * Copyright 2001 by Paul Mattes.
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose and without fee is hereby granted,
 *  provided that the above copyright notice appear in all copies and that
 *  both that copyright notice and this permission notice appear in
 *  supporting documentation.
 *
 * x3270 is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the file LICENSE for more details.
 */

/*
 *	find_fontsc.h
 *		Global declarations for find_fonts.c.
 */

extern Boolean find_fonts(char *charset, FILE *outfile,
    void (*progress)(int percent), void (*done)(int n_found));
extern const char *name2cs_3270(const char *name);

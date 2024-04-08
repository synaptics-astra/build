/*******************************************************************************
*                Copyright 2016, MARVELL SEMICONDUCTOR, LTD.                   *
* THIS CODE CONTAINS CONFIDENTIAL INFORMATION OF MARVELL.                      *
* NO RIGHTS ARE GRANTED HEREIN UNDER ANY PATENT, MASK WORK RIGHT OR COPYRIGHT  *
* OF MARVELL OR ANY THIRD PARTY. MARVELL RESERVES THE RIGHT AT ITS SOLE        *
* DISCRETION TO REQUEST THAT THIS CODE BE IMMEDIATELY RETURNED TO MARVELL.     *
* THIS CODE IS PROVIDED "AS IS". MARVELL MAKES NO WARRANTIES, EXPRESSED,       *
* IMPLIED OR OTHERWISE, REGARDING ITS ACCURACY, COMPLETENESS OR PERFORMANCE.   *
*                                                                              *
* MARVELL COMPRISES MARVELL TECHNOLOGY GROUP LTD. (MTGL) AND ITS SUBSIDIARIES, *
* MARVELL INTERNATIONAL LTD. (MIL), MARVELL TECHNOLOGY, INC. (MTI), MARVELL    *
* SEMICONDUCTOR, INC. (MSI), MARVELL ASIA PTE LTD. (MAPL), MARVELL JAPAN K.K.  *
* (MJKK), MARVELL ISRAEL LTD. (MSIL).                                          *
*******************************************************************************/
#ifndef _GENIMG_H
#define _GENIMG_H

struct image_header {
	unsigned int header_magic_num;	/* 'IM*H' */
	unsigned int header_size;
	unsigned int header_version;
	unsigned int header_reserved;
	char image_name[32];
	unsigned int image_version;
	unsigned int reserved[2];
	unsigned int chunk_num;
	struct chunk_param{
		unsigned int id;
		unsigned int offset;	 /* start from image header, 16 bytes aligned */
		unsigned int size;
		unsigned int attr0;		/* reserved */
		/* data can be in (dest_start, dest_start + dest_size)	
		 * if dest_size == 0, then chunk data must always place at
		 * dest_start.
		 */
		unsigned long long dest_start;       /* destination address if it gets */
		//unsigned int reserved_dest_start;
		unsigned int dest_size;        /* destination address region */
		unsigned int attr1;
	} chunk[0];
};

#endif //_GENIMG_H

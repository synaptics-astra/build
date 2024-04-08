/*
 * NDA AND NEED-TO-KNOW REQUIRED
 *
 * Copyright © 2013-2018 Synaptics Incorporated. All rights reserved.
 *
 * This file contains information that is proprietary to Synaptics
 * Incorporated ("Synaptics"). The holder of this file shall treat all
 * information contained herein as confidential, shall use the
 * information only for its intended purpose, and shall not duplicate,
 * disclose, or disseminate any of this information in any manner
 * unless Synaptics has otherwise provided express, written
 * permission.
 *
 * Use of the materials may require a license of intellectual property
 * from a third party or from Synaptics. This file conveys no express
 * or implied licenses to any intellectual property rights belonging
 * to Synaptics.
 *
 * INFORMATION CONTAINED IN THIS DOCUMENT IS PROVIDED "AS-IS," AND
 * SYNAPTICS EXPRESSLY DISCLAIMS ALL EXPRESS AND IMPLIED WARRANTIES,
 * INCLUDING ANY IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE, AND ANY WARRANTIES OF NON-INFRINGEMENT OF ANY
 * INTELLECTUAL PROPERTY RIGHTS. IN NO EVENT SHALL SYNAPTICS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE, OR
 * CONSEQUENTIAL DAMAGES ARISING OUT OF OR IN CONNECTION WITH THE USE
 * OF THE INFORMATION CONTAINED IN THIS DOCUMENT, HOWEVER CAUSED AND
 * BASED ON ANY THEORY OF LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * NEGLIGENCE OR OTHER TORTIOUS ACTION, AND EVEN IF SYNAPTICS WAS
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. IF A TRIBUNAL OF
 * COMPETENT JURISDICTION DOES NOT PERMIT THE DISCLAIMER OF DIRECT
 * DAMAGES OR ANY OTHER DAMAGES, SYNAPTICS' TOTAL CUMULATIVE LIABILITY
 * TO ANY PARTY SHALL NOT EXCEED ONE HUNDRED U.S. DOLLARS.
 */
#ifndef _VERSION_TABLE_H_
#define _VERSION_TABLE_H_

#define PART_NAME_MAX_LEN	15
#define IMG2_NAME	"bootloader"
#define IMG3_NAME	"bootimgs"
#define SYSCONF_NAME	"sysconf"
#define FLASHLESS_NAME	"flashless_data"
#define UBOOT_ENV_NAME	"u-boot.env"

#define NORMAL_WP_MASK	(1)
#define RECOVERY_WP_MASK	(1<<1)

//DDR type
#define DDR_TYPE_DDR2	2
#define DDR_TYPE_DDR3	3

//DDR channel
#define DDR_CHANNEL_DUAL	2
#define DDR_CHANNEL_SINGLE	1

//CPU type
#define CPU_TYPE_B		0xb
#define CPU_TYPE_C		0xc

typedef struct _version_t_ {
	union {
		struct {
			unsigned minor_version;
			unsigned major_version;
		};
		unsigned long long version;
	};
} version_t __attribute__ ((aligned (4)));

typedef enum data_type_t_ {
	DATA_TYPE_NORMAL,
	DATA_TYPE_OOB,
	DATA_TYPE_RAW
}data_type_t;

typedef enum partition_type_t_ {
	PARTITION_TYPE_MLC,
	PARTITION_TYPE_SLC,
	PARTITION_TYPE_ESLC
}partition_type_t;
typedef struct _sub_img_info_t_ {
	char name[PART_NAME_MAX_LEN+1];
	unsigned long long size;
	unsigned crc;
	version_t version;

	unsigned reserved_blocks; // refer to Notes*
	unsigned chip_start_blkind;
	unsigned chip_num_blocks;
	unsigned data_type;
	unsigned partition_type;
	unsigned char reserved[8]; //64 bytes aligned
} sub_img_info_t;

typedef struct _img_hdr_t_ {
	unsigned magic;
	version_t version;

	unsigned page_size;
	unsigned oob_size;
	unsigned pages_per_block;
	unsigned blks_per_chip;

	unsigned num_sub_images;
	unsigned char ddr_type		: 4;
	unsigned char ddr_channel	: 4;
	unsigned char cpu_type[2];
	unsigned char reserved[29]; //64 bytes aligned
	sub_img_info_t sub_image[];
} img_hdr_t;

typedef struct _ver_table_entry_t_ {
	char name[PART_NAME_MAX_LEN+1];
	version_t part1_version;
	unsigned part1_start_blkind;
	unsigned part1_blks;
#ifdef CONFIG_EMMC_WRITE_PROTECT
	unsigned write_protect_flag;
	unsigned char reserved[12];
#else
	version_t part2_version;
	unsigned part2_start_blkind;
	unsigned part2_blks;
	unsigned write_protect_flag;
	char part_type[PART_NAME_MAX_LEN+1];
#endif
} ver_table_entry_t;

typedef struct _version_table_t_ {
	unsigned int magic;
	unsigned int ou_status;
	unsigned int num_entries;
	ver_table_entry_t table[];
} version_table_t;

#endif

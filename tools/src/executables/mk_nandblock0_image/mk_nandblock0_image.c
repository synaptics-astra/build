/*******************************************************************************
 *                 2017 Synaptics Incorporated. All Rights Reserved            *
 * THIS CODE CONTAINS CONFIDENTIAL INFORMATION OF Synaptics.                   *
 * NO RIGHTS ARE GRANTED HEREIN UNDER ANY PATENT, MASK WORK RIGHT OR COPYRIGHT *
 * OF Synaptics OR ANY THIRD PARTY. Synaptics RESERVES THE RIGHT AT ITS SOLE   *
 * DISCRETION TO REQUEST THAT THIS CODE BE IMMEDIATELY RETURNED TO Synaptics.  *
 * THIS CODE IS PROVIDED "AS IS". Synaptics MAKES NO WARRANTIES, EXPRESSED,    *
 * IMPLIED OR OTHERWISE, REGARDING ITS ACCURACY, COMPLETENESS OR PERFORMANCE.  *
 *                                                                             *
 *******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <getopt.h>

#define	MAGIC_NUMBER 0xD2ADA3F1
#define NAND_PAGE_SIZE 2048
#define NAND_BLOCK_SIZE 131072
#define NAND_ADDRESS_CYCLE 5
#define NAND_SPARE_EN 1
#define NAND_ECC_EN 1
#define NAND_QUAD_EN 0
#define NAND_SCRAMBLER_EN 0
#define NAND_ECC_STRENGTH 48
#define BOOT_PARTITION_SIZE (0x40000)
#define NAND_BLOCKS_PER_PARTITION (BOOT_PARTITION_SIZE/NAND_BLOCK_SIZE)

typedef struct _bootparam_t_{
	uint32_t magic;
	union{
		uint32_t nand_param;
		uint32_t u32;
		struct{
			uint32_t page_size       : 2; // @0
			uint32_t address_cycle   : 1; // @1
			uint32_t scrambler_en    : 1; // @2
			uint32_t block_size      : 4; // @4
			uint32_t ecc_en          : 1; // @8
			uint32_t quad_en         : 1; // @9
			uint32_t spare_en        : 1; // @10
			uint32_t chunk_size      : 2; // @11
			uint32_t ecc_strength    : 5; // @13
			uint32_t slc_en          : 1; // @18
			uint32_t slc_page_table_offset : 8; // @19
			uint32_t blk_num         : 4; // @27
			uint32_t page_size_hi    : 1; // @31
		};
	} ;
} bootparam_t;

typedef struct _block0_t_ {
	union{
		bootparam_t bootparam[129];
		char pad[2048];
	} ;
} block0_t;

static void print_help(void)
{
	printf("--page-size -p nand page size\n");
	printf("--block-size -b nand block size\n");
	printf("--ecc-strength -s nand ecc strength\n");
	printf("--nand-scrambler-en -c is nand scrambler enabled\n");
	printf("--nand-blk-num -n how many blocks composed of a boot partition\n");
	printf("--nand-quad-en -q is nand xspi 4bit enabled\n");
	printf("output file name\n");
}

int main(int argc, char * argv[])
{
	int i, c;
	block0_t block0 = {0};
	bootparam_t bootp = {0};
	FILE *file, *frand;
	char *buf, *image_name = "block0.img";
	unsigned int *block0_buff = NULL;
	int page_size = NAND_PAGE_SIZE;
	int block_size = NAND_BLOCK_SIZE;
	int address_cycles = NAND_ADDRESS_CYCLE;
	int nand_spare_enable = NAND_SPARE_EN;
	int nand_ecc_enable = NAND_ECC_EN;
	int nand_quad_enable = NAND_QUAD_EN;
	int nand_ecc_strength = NAND_ECC_STRENGTH;

	if (argc == 1) {
		printf("Usage: %s [OPTIONS]\n", argv[0]);
		print_help();
		exit(1);
	}

	opterr = 0;
	while (1) {
		static struct option long_options[] = {
			{"help", no_argument, NULL, 'h'},
			{"output", required_argument, 0, 'o'},
			{"block-size", required_argument, 0, 'b'},
			{"page-size", required_argument, 0, 'p'},
			{"nand-blk-num", required_argument, 0, 'n'},
			{"ecc-strength", required_argument, 0, 's'},
			{"nand-scrambler-en", required_argument, 0, 'c'},
			{"nand-quad-en", required_argument, 0, 'q'},
			{0, 0, 0, 0}
		};

		int option_index = 0;
		c = getopt_long (argc, argv, "ho:p:b:s:c:n",
				long_options,
				&option_index);
		if (c == -1)
			break;
		switch (c) {
		case 0:
			if (long_options[option_index].flag != 0)
				break;
			break;
		case 'h':
			printf("Usage: %s [OPTIONS]\n", argv[0]);
			print_help();
			break;
		case 'p':
			page_size = strtol(optarg, NULL, 10);
			break;
		case 'b':
			block_size = strtol(optarg, NULL, 10);
			break;
		case 's':
			nand_ecc_strength = strtol(optarg, NULL, 10);
			break;
		case 'c':
			bootp.scrambler_en = strtol(optarg, NULL, 10);
			break;
		case 'q':
			nand_quad_enable = strtol(optarg, NULL, 10);
			break;
		case 'n':
			bootp.blk_num = strtol(optarg, NULL, 10);
			break;
		case '?':
			break;
		default:
			abort();
		}
	}

	image_name = (char *)argv[optind];
	optind++;

	if (optind < argc) {
		printf ("non-option ARGV-elements: ");
		while (optind < argc)
			printf ("%s ", argv[optind++]);
		printf ("\n");
		exit(1);
	}

	if (bootp.blk_num == 0)
		bootp.blk_num = BOOT_PARTITION_SIZE / block_size;

	memset(&block0, 0, sizeof(block0));
	block0_buff = (unsigned int *)malloc(block_size*sizeof(unsigned char));
	if(NULL == block0_buff){
		printf("malloc block0_buff error\n");
		exit(1);
	}

	bootp.magic = MAGIC_NUMBER;
	if(page_size == 512){
		bootp.page_size = 0;
	}else if(page_size == 2048){
		bootp.page_size = 1;
	}else if(page_size == 4096){
		bootp.page_size = 2;
	}else if(page_size == 8192){
		bootp.page_size = 3;
	}else{
		printf("Invalid page size\n") ;
		exit(1);
	}
	printf("bootparam_t.page_size=0x%x\n", bootp.page_size);

	bootp.address_cycle = address_cycles -4;
	printf("bootparam_t.address_cycle=0x%x\n", bootp.address_cycle);

	if(block_size % (1024 * 16)){
		printf("Invalid block size\n") ;
		exit(1);
	}
	bootp.block_size = ffs(block_size / (1024 * 16)) - 1;
	printf("bootparam_t.block_size=0x%x\n", bootp.block_size);
	bootp.ecc_en = nand_ecc_enable;
	printf("bootparam_t.ecc_en=0x%x\n", bootp.ecc_en);
	bootp.quad_en = nand_quad_enable;
	printf("bootparam_t.quad_en=0x%x\n", bootp.quad_en);
	bootp.spare_en = nand_spare_enable;
	printf("bootparam_t.spare_en=0x%x\n", bootp.spare_en);
	bootp.chunk_size = 0;
	printf("bootparam_t.chunk_size=0x%x\n", bootp.chunk_size );
	bootp.ecc_strength = nand_ecc_strength / 4 - 1;
	printf("bootparam_t.ecc_strength=0x%x\n", bootp.ecc_strength);
	printf("bootparam_t.blk_num=0x%x\n", bootp.blk_num);
	if (bootp.scrambler_en == 0)
		bootp.scrambler_en = NAND_SCRAMBLER_EN;
	printf("bootparam_t.scrambler_en=0x%x\n", bootp.scrambler_en);
	printf("bootparam_t.nand_param=0x%08x\n", bootp.nand_param);

	memset(block0_buff, 0, block_size) ;
	for(i = 0; i < 256; i++){
		memcpy(&block0.bootparam[i], &bootp, sizeof(bootp));
	}
	printf("sizeof bootp= %ld, magic = 0x%08x, flash attribute= 0x%08x\n", \
			sizeof(bootp), *(uint32_t *)&bootp, bootp.nand_param);

	file = fopen((const char *)image_name, "w");
	if(file == NULL){
		printf("open file %s error\n", argv[1]) ;
		exit(1);
	}
	fwrite(&block0, sizeof(block0) , 1, file) ;

	frand = fopen("/dev/urandom", "r") ;
	if(file == NULL){
		printf("open file /dev/urandom error\n") ;
		fclose(file) ;
		exit(1);
	}

	buf = malloc(block_size - sizeof(block0));
	if(buf == NULL) {
		printf("Malloc failed.\n");
		fclose(file);
		fclose(frand);
		exit(1);
	}

	if(fread(buf, block_size-sizeof(block0), 1, frand) !=1 ) {
		fprintf(stderr, "read /dev/urandom failed.\n");
		fclose(file);
		fclose(frand);
		free(buf);
		exit(1);
	}

	if(fwrite(buf, block_size-sizeof(block0), 1, file) !=1 ) {
		fprintf(stderr, "write %s failed.\n",argv[1] );
		fclose(file);
		fclose(frand);
		free(buf);
		exit(1);
	}

	fclose(file) ;
	fclose(frand);
	free(buf);

	exit(0);
}

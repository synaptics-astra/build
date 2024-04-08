#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <getopt.h>
#include <errno.h>
#include <stdint.h>

#include <version_table.h>

void display_help()
{
printf(
"Usage: gen_subimg_info [OPTION] INPUTFILE(s)\n"
"Join input files into a single unified image.\n"
"\n"
"  --output outputFile      OUTPUT file Path\n"
"  --major \n"
"  --minor \n"
"  --data_type              normal, oob, raw\n"


"  -q                    don't display progress messages\n"
"  -h                    display help information and exit normally\n");
}

int quiet = 0;

char *name = NULL;
unsigned chip_start_blkind = -1;
unsigned chip_num_blocks = -1;
unsigned reserved_blocks = -1;
unsigned data_type = DATA_TYPE_NORMAL;
unsigned partition_type = PARTITION_TYPE_MLC;
char *out = NULL;
char *in = NULL;
FILE *fout = NULL;
FILE *fin = NULL;
version_t version = {-1, -1};

void process_options(int argc, char *argv[])
{
	int error = 0, option_index;
	static const struct option long_options[] = {
		{"output", required_argument, 0, 800},
		{"name", required_argument, 0, 1000},
		{"major", required_argument, 0, 2000},
		{"minor", required_argument, 0, 2500},
		{"reserved_blocks", required_argument, 0, 3000},
		{"start_blkind", required_argument, 0, 3500},
		{"num_blocks", required_argument, 0, 4000},
		{"data_type", required_argument, 0, 4500},
		{"partition_type", required_argument, 0, 5000},
		{0, 0, 0, 0},
	};

	for (;;) {
		int option_index = 0;

		int c = getopt_long(argc, argv, "", long_options, &option_index);
		if (c == -1)
			break;

		switch (c) {
			case 'q':
				quiet = 1;
				break;
			case 800:
				out = optarg;
				break;
			case 1000:
				name = optarg;
				break;
			case 2000:
				version.major_version = strtol(optarg, NULL, 0);
				break;
			case 2500:
				version.minor_version = strtol(optarg, NULL, 0);
				break;
			case 3000:
				reserved_blocks = strtol(optarg, NULL, 0);
				break;
			case 3500:
				chip_start_blkind = strtol(optarg, NULL, 0);
				break;
			case 4000:
				chip_num_blocks = strtol(optarg, NULL, 0);
				break;
			case 4500:
				if (!strncmp(optarg, "oob", 3))
					data_type = DATA_TYPE_OOB;
				else if (!strncmp(optarg, "raw", 3))
					data_type = DATA_TYPE_RAW;
				else if (!strncmp(optarg, "normal", 6))
					data_type = DATA_TYPE_NORMAL;
				else {
					printf("Not support data type. Using default normal\n");
					//return;
				}
				break;
			case 5000:
				if (!strncmp(optarg, "mlc", 3))
					partition_type = PARTITION_TYPE_MLC;
				else if (!strncmp(optarg, "slc", 3))
					partition_type = PARTITION_TYPE_SLC;
				else if (!strncmp(optarg, "eslc", 4))
					partition_type = PARTITION_TYPE_ESLC;
				else {
					printf("Not support partition type. Using default mlc \n");
					//return;
				}
				break;
			case 'h':
				display_help();
				exit(0);
				break;
			case '?':
				error = 1;
				break;
		}
	}

	if ( !name || !out || version.major_version==-1 || version.minor_version==-1 ||
			reserved_blocks==-1 || chip_start_blkind==-1 || chip_num_blocks==-1 ||
			(argc - optind) < 1 || error) {
		display_help();
		exit(1);
	}

	in = argv[optind];
}

uint32_t crc32(uint32_t crc, unsigned char *buf, unsigned int len);

uint32_t fcrc32(FILE *fp)
{
#define BUFSZ	(1024 * 1024)
	static char buf[BUFSZ];
	size_t readlen = 0;
	uint32_t crc = 0;

	if (!fp)
		return 0;

	while ((readlen = fread(buf, 1, BUFSZ, fp)) > 0) {
		crc = crc32(crc, buf, readlen);
		if (readlen < BUFSZ)
			break;
	}
	return crc;
}

int main(int argc, char **argv)
{
	sub_img_info_t sii;
	struct stat st;

	process_options(argc, argv);

	memset(&sii, 0, sizeof(sii));

	if (strlen(name) > PART_NAME_MAX_LEN) {
		fprintf(stderr, "Partition name length(%ld) exceeds MAX_LEN(%d)\n",
				strlen(name), PART_NAME_MAX_LEN);
		goto fail_out;
	}
	fin = fopen(in, "r");
	if (fin == NULL) {
		fprintf(stderr, "Open %s failed.\n", in);
		goto fail_out;
	}
	if (fstat(fileno(fin), &st)) {
		fprintf(stderr, "Can't stat %s.\n", in);
	}

	fout = fopen(out, "w+");
	if (fout == NULL) {
		fprintf(stderr, "Open %s failed.\n", out);
		goto fail_out;
	}

	sii.size = st.st_size;
	sii.crc = fcrc32(fin);
	strcpy(sii.name, name);
	sii.version = version;
	sii.reserved_blocks = reserved_blocks;
	sii.chip_start_blkind = chip_start_blkind;
	sii.chip_num_blocks = chip_num_blocks;
	sii.data_type = data_type;
	sii.partition_type = partition_type;
	if (fwrite(&sii, sizeof(sii), 1, fout) != 1) {
		fprintf(stderr, "Write %s failed.\n", out);
		goto fail_out;
	}

	return 0;

fail_out:
	return 1;
}

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <getopt.h>
#include <errno.h>

#include <version_table.h>

#ifndef MAGIC_NUMER
#define MAGIC_NUMER 	0xD2ADA3F1
#endif

char *out = NULL;
char *dir = NULL;
unsigned int page_size;
unsigned int oob_size;
unsigned int block_size;
long long chip_size;
char ddr_type = -1;
char ddr_channel = -1;
version_t version;
int num_sub_images = 0;
char **subimage_paths = NULL;
unsigned char cpu_type[2];

void display_help()
{
printf(
"Usage: gen_img [OPTION] INPUTFILE(s)\n"
"Join input files into a single unified image.\n"
"\n"
"  -o output		OUTPUT file Path\n"
"  -d dir		input file dir\n"
"  -p page_size		NAND page size in byte\n"
"  -b block_size	NAND block size in byte\n"
"  -c chip_size 	NAND chip size in byte\n"
"  --ddr_type		DDR2/DDR3\n"
"  --ddr_channel	DDR_DUAL_CHANNEL/DDR_SINGLE_CHANNEL\n"
"  --cpu_type       B/C\n"
"  -j major		major version number\n"
"  -n minor		minor version number\n"
"  -h                   display help information and exit normally\n");
}

void process_options (int argc, char *argv[])
{
	int error = 0;
	int option_index;

	for (;;) {
		static const struct option long_options[] = {
			{"dir", 1, 0, 'd'},
			{"output", 1, 0, 'o'},
			{"page_size", 1, 0, 'p'},
			{"block_size", 1, 0, 'b'},
			{"chip_size", 1, 0, 'c'},
			{"major", 1, 0, 'j'},
			{"minor", 1, 0, 'n'},
			{"ddr_type", 1, 0, 1000},
			{"ddr_channel", 1, 0, 2000},
			{"cpu_type", 1, 0, 3000},
			{0, 0, 0, 0},
		};

		int c = getopt_long(argc, argv, "d:o:p:b:c:j:n:", long_options, &option_index);
		if (c == -1) {
			break;
		}

		switch (c) {
			case 1000:
				if (strcmp(optarg, "DDR2") == 0) {
					ddr_type = DDR_TYPE_DDR2;
				} else if (strcmp(optarg, "DDR3") == 0) {
					ddr_type = DDR_TYPE_DDR3;
				}
				break;
			case 2000:
				if (strcmp(optarg, "DDR_DUAL_CHANNEL") == 0) {
					ddr_channel = DDR_CHANNEL_DUAL;
				} else if (strcmp(optarg, "DDR_SINGLE_CHANNEL") == 0) {
					ddr_channel = DDR_CHANNEL_SINGLE;
				}
				break;
			case 3000:
				cpu_type[0] = optarg[0];
				cpu_type[1] = optarg[1];
				break;
			case 'd':
				dir = optarg;
				break;
			case 'o':
				out = optarg;
				break;
			case 'p':
				page_size = atoi(optarg);
				break;
			case 'b':
				block_size = atoi(optarg);
				break;
			case 'c':
				chip_size = atoll(optarg);
				break;
			case 'j':
				version.major_version = atoi(optarg);
				break;
			case 'n':
				version.minor_version = atoi(optarg);
				break;
			case '?':
				error = 1;
				break;
		}
	}

	if ((argc - optind) < 1 || error) {
		display_help();
		exit(1);
	}

	num_sub_images = argc - optind;
	subimage_paths = argv + optind;
}

int main(int argc, char **argv)
{
	int i;
	unsigned int sum;
	img_hdr_t hdr;
	sub_img_info_t sub_hdr;
	FILE *fout=NULL, *fin=NULL;
	char in_info[1024];
	char in_image[1024];
	char temp[1024];
	struct stat image_stat;

	cpu_type[0] = 0;
	cpu_type[1] = 0;
	process_options(argc, argv);
	printf("dir path: %s \n", dir);

	printf("img_hdr_t size: %ld, sub_img_info_t size: %ld\n",
		sizeof(img_hdr_t), sizeof(sub_img_info_t));
	memset(&hdr, 0, sizeof(img_hdr_t));
	hdr.magic = MAGIC_NUMER;
	hdr.page_size = page_size;
	hdr.oob_size = oob_size;
	hdr.pages_per_block = block_size/page_size;
	if(chip_size%block_size)
	{
		fprintf(stderr, "chip size must be block aligned.\n");
		return -1;
	}
	hdr.blks_per_chip = chip_size/block_size;
	hdr.num_sub_images = num_sub_images;
	memcpy(&hdr.version, &version, sizeof(version_t));

	if (ddr_type == -1 || ddr_channel == -1) {
		fprintf(stderr, "ddr parameters are not properly set\n");
		return -1;
	}

	if((!cpu_type[0]) && (!cpu_type[1])) {
		fprintf(stderr, "cpu type %c%c is not properly set\n", cpu_type[0], cpu_type[1]);
		return -1;
	}
	hdr.ddr_type = ddr_type;
	hdr.ddr_channel = ddr_channel;
	hdr.cpu_type[0] = cpu_type[0];
	hdr.cpu_type[1] = cpu_type[1];

	fout = fopen(out, "w+");
	if (fout == NULL) {
		fprintf(stderr, "Fail to open %s.\n", out);
		goto fail_out;
	}
	if(fwrite(&hdr, sizeof(img_hdr_t), 1, fout) != 1) {
		fprintf(stderr, "Fail to write %s.\n", out);
		goto fail_out;
	}

	sum=0;
	for(i=0;i<num_sub_images;i++)
	{
		unsigned int pos;
		unsigned int count;

		pos = sizeof(img_hdr_t) + sizeof(sub_img_info_t) * i;
		fseek(fout, pos,SEEK_SET);

		sprintf(in_info, "%s/%s.subimg.info", dir, subimage_paths[i]);
		sprintf(in_image, "%s/%s.subimg", dir, subimage_paths[i]);
		fprintf(stdout, "handle subimg: %s\n", subimage_paths[i]);

		fin = fopen(in_info, "r");
		if(fin == NULL) {
			fprintf(stderr, "Fail to open %s.\n", in_info);
			goto fail_out;
		}
		if(fread(&sub_hdr, sizeof(sub_img_info_t), 1, fin) != 1) {
			fprintf(stderr, "Fail to read %s.\n", in_info);
			goto fail_out;
		}

		if (!stat(in_image, &image_stat) && (image_stat.st_size != sub_hdr.size))
		{
			fprintf(stdout, "adopt new subimg size: %ld, old size: %lld\n", image_stat.st_size, sub_hdr.size);
			sub_hdr.size = image_stat.st_size;
		}

		if(fwrite(&sub_hdr, sizeof(sub_img_info_t), 1, fout) != 1) {
			fprintf(stderr, "Fail to write %s.\n", out);
			goto fail_out;
		}
		fclose(fin);

		pos = sizeof(img_hdr_t) + sizeof(sub_img_info_t) * num_sub_images + sum;
		fseek(fout, pos ,SEEK_SET);


		fin = fopen(in_image, "r");
		if(fin == NULL) {
			fprintf(stderr, "Fail to open `%s'.\n", in_image);
			goto fail_out;
		}
		while((count = fread(temp, 1, sizeof(temp), fin)))
			fwrite(temp, 1, count, fout);

		fclose(fin);
		sum += sub_hdr.size;
	}

	if(fout!=NULL)
		fclose(fout);
	fprintf(stdout, "uniimg generation succeeded: %s\n", out);
	return 0;

fail_out:
	if(fout!=NULL)
		fclose(fout);
	if(fin!=NULL)
		fclose(fin);
	fprintf(stderr, "uniimg generation failed: %s\n", out);
	return 1;
}

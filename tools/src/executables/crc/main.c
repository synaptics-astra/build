#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <getopt.h>
#include <errno.h>
#include <stdint.h>


void display_help()
{
printf(
"Usage: crc [OPTION] infile\n"
"calculate the crc checksum.\n"
"\n"
"  -o outfile            output to a file, keep the original file unchanged.\n"
"  -a                    append the crc to end of file.\n"
"  -h                    display help information and exit normally\n");
}

int quiet = 0;
int append = 0;

char *out = NULL;
char *in = NULL;
FILE *fout = NULL;
FILE *fin = NULL;


void process_options(int argc, char *argv[])
{
	int error = 0, option_index;
	static const struct option long_options[] = {
		{"output", required_argument, 0, 800},
		{0, 0, 0, 0},
	};

	for (;;) {
		int option_index = 0;

		int c = getopt_long(argc, argv, "aqo:h", long_options, &option_index);
		if (c == -1)
			break;

		switch (c) {
			case 'a':
				append = 1;
				break;
			case 'q':
				quiet = 1;
				break;
			case 'o':
			case 800:
				out = optarg;
				break;
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
	uint32_t crc;
	process_options(argc, argv);

	fin = fopen(in, "r+");
	if (fin == NULL) {
		fin = stdin;
	}
	crc = fcrc32(fin);
	printf("%08x\n", crc);
	crc ^= 0xffffffff;
	if (append)
		fwrite(&crc, 1, sizeof(crc), fin);

	return 0;
}

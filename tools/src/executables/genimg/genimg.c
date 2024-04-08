#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <getopt.h>
#include <libgen.h>
#include <limits.h>
#include "genimg.h"

/*******************************************************
 *  image format:
 *  _____________________
 * |                     |
 * | encryption header   |
 * |_____________________|
 * |                     |
 * |   data chunk 0      |
 * |_____________________|
 * |                     |
 * |         ...         |
 * |_____________________|
 * |                     |
 * |   data chunk n      |
 * |_____________________|
 *
 *******************************************************/
#define DEFAULT_ALIGN_SIZE	(16)

unsigned int get_aligned(unsigned address, unsigned page_size) {
	return (address + page_size - 1) / page_size * page_size;
}


long get_file_size(const char *path)
{
	long filesize = -1;
	struct stat statbuff;
	if(stat(path, &statbuff) < 0){
		return filesize;
	}else{
		filesize = statbuff.st_size;
	}
	return filesize;
}

void display_help(void)
{
	printf(	"\nUsage:	genimg tool to generate image\n");
	printf( "eg: genimg -n image_name [-i <id0> -d <in_file0> ...] -o <out_file> \n");
	printf( "option:\n"
		"	-h or --help                         show this help message\n\n"
		"	-n or --name        <string>         image name,max size 32 bytes,\n"
		"					     this option is required \n\n"
		"	-d or --data        <string>         input file name,\n"
		"					     this option is required,there may be multiple input files, up to 60\n\n"
		"	-i or --id          <unsigned int/string>   Start a new chunk with ID. size 4 bytes.\n"
		"	                                     this option is required,the id number and the data number are consistent\n\n"
		"	-o or --output      <string>         output file name,\n"
		"					     this option is required\n\n"
		"	-A or --align       <unsigned int>   align size of header(if not seperated) and each data chunk\n\n"
		"	-a or --addr        <unsigned int>   start address of memory to run\n\n"
		"	-s or --size        <unsigned int>   address region\n\n"
		"	-t or --attr        <int> <unsigned int>\n"
		"               in bootloader layout information, the first 3 bits of attr0 are used to indicate the image type\n"
		"               in other image, attr0 indicates the compression method. attr1 indicates the size of original image\n\n"
		"	-V or --header_ver  <unsigned int>   header version\n\n"
		"	-v or --image_ver   <unsigned int>   image version\n\n"
		"	-S or --seperate    <string> <unsigned int> generate seperate image header with specified size and images\n"
		"                                               the size also should be aligned with align-size\n\n"
		);
}

struct _chunk_record{
	unsigned int id;
	char path_name[4096];
	unsigned long long dest_start;  /* destination address if it gets */
	unsigned int dest_size;   /* destination address region */
	unsigned int attr0;        /* reserved */
	unsigned int attr1;        /* reserved */
	unsigned int reserved[2];
}chunk_record[60];

const struct option long_options[] = {
	{"help",    0, NULL, 'h'},
	{"name",    1, NULL, 'n'},
	{"id",      1, NULL, 'i'},
	{"data",    1, NULL, 'd'},
	{"output",  1, NULL, 'o'},
	{"align",   1, NULL, 'A'},
	{"address", 1, NULL, 'a'},
	{"size",    1, NULL, 's'},
	{"attr",    2, NULL, 't'},
	{"h_ver",   1, NULL, 'V'},
	{"i_ver",   1, NULL, 'v'},
	{"seperate",2, NULL, 'S'},
	{ NULL,     1, NULL,  0},
};

int main(int argc, char *argv[])
{
	struct image_header *img_header;
	char out_path_name[PATH_MAX],curr_path_dir[PATH_MAX],system_cmd[3 * PATH_MAX], img_header_name[PATH_MAX];
	char *out_path_dir;
	char image_name[32], defalut_img_header_name[PATH_MAX];
	int opt = 0,i = 0,ret = 0, is_seperate_header = 0;
	int h_ver = 0,i_ver = 0;
	int img_header_fd = 0;
	off_t offset = 0;
	unsigned int image_header_size = 0,size = 0;
	static int id_num = 0,name_num = 0;
	unsigned align_size = DEFAULT_ALIGN_SIZE;
	unsigned header_size = 0;
	int arg_index = 1; //used to handle the multi value in one option

	if(argc < 5){
		display_help();
		return ret;
	}

	memset(chunk_record,0,sizeof(struct _chunk_record)*60);

	while((opt = getopt_long(argc,argv,"n:m:i:d:o:A:a:s:t:v:V:S:h",long_options,NULL)) != -1){
		switch(opt){
			case 'n':
				strncpy(image_name,optarg,strlen(optarg));
				image_name[strlen(optarg)] = '\0';
				arg_index += 2;
				break;
			case 'i':
				if(isalpha(optarg[0])){
					chunk_record[id_num].id = (unsigned int)((optarg[3]<<24)|(optarg[2]<<16)|(optarg[1]<<8)|optarg[0]);
				}else{
					chunk_record[id_num].id = strtol(optarg, NULL, 0);
				}
				id_num++;
				arg_index += 2;
				break;
			case 'd':
				printf("optarg = %s\n",optarg);
				strncpy(chunk_record[name_num].path_name,optarg,strlen(optarg));
				chunk_record[name_num].path_name[strlen(optarg)] = '\0';
				name_num++;
				arg_index += 2;
				break;
			case 'A':
				align_size = strtol(optarg, NULL, 0);
				arg_index += 2;
				break;
			case 'N':
				header_size = strtol(optarg, NULL, 0);
				arg_index += 2;
				break;
			case 'a':
				chunk_record[name_num - 1].dest_start = strtoll(optarg, NULL, 0);
				chunk_record[name_num - 1].dest_size = 0;
				arg_index += 2;
				break;
			case 's':
				chunk_record[name_num - 1].dest_size = strtol(optarg, NULL, 0);
				arg_index += 2;
				break;
			case 't':
				if(strcmp(argv[arg_index + 1], "attr0") == 0)
					chunk_record[name_num - 1].attr0 = strtol(argv[arg_index + 2], NULL, 0);
				if(strcmp(argv[arg_index + 1], "attr1") == 0)
					chunk_record[name_num - 1].attr1 = strtol(argv[arg_index + 2], NULL, 0);
				arg_index += 3;
				break;
			case 'o':
				strncpy(out_path_name,optarg,strlen(optarg));
				out_path_name[strlen(optarg)] = '\0';
				for(i = strlen(optarg); i > 0; i--) {
					if(optarg[i - 1] == '/')
						break;
				}
				strncpy(defalut_img_header_name, (&optarg[i]), strlen((&optarg[i])));
				strncpy(&defalut_img_header_name[strlen((&optarg[i]))], ".header", 7);
				defalut_img_header_name[strlen((&optarg[i])) + 7] = '\0';
				arg_index += 2;
				break;
			case 'V':
				h_ver = strtol(optarg, NULL, 0);
				arg_index += 2;
				break;
			case 'v':
				i_ver = strtol(optarg, NULL, 0);
				arg_index += 2;
				break;
			case 'S':
				strncpy(img_header_name, argv[arg_index + 1], strlen(argv[arg_index + 1]));
				img_header_name[strlen(optarg)] = '\0';
				is_seperate_header = 1;
				header_size = strtol(argv[arg_index + 2], NULL, 0);
				arg_index += 3;
				break;
			case 'h':
				display_help();
				arg_index += 1;
				break;
			default:
				printf("unknow option : -%c\n",opt);
				display_help();
				return ret;
		}
	}

	if(id_num != name_num)
		printf("error: chunk id number != chunk data number,pls check!\n");

	image_header_size = sizeof(struct image_header) + id_num*sizeof(struct chunk_param);
	img_header = ((struct image_header *)malloc(image_header_size));

	if(header_size == 0)
		header_size = image_header_size;

	//the case is that image header size also should be algiend with page size
	header_size = get_aligned(header_size, align_size);

	img_header->header_magic_num = 0x482a4d49; //IM*H
	img_header->header_size = image_header_size;
	img_header->header_version = h_ver;
	img_header->image_version = i_ver;
	img_header->chunk_num = id_num;
	strncpy(img_header->image_name,image_name,31);
	img_header->image_name[31] = '\0';
	for(i = 0;i < img_header->chunk_num;i++){
		img_header->chunk[i].id = chunk_record[i].id;
		img_header->chunk[i].dest_start = chunk_record[i].dest_start;
		img_header->chunk[i].dest_size = chunk_record[i].dest_size;
		img_header->chunk[i].attr0 = chunk_record[i].attr0;
		img_header->chunk[i].attr1 = chunk_record[i].attr1;
		img_header->chunk[i].size = get_file_size(chunk_record[i].path_name);
		if(i > 0){
			size = get_aligned((img_header->chunk[i - 1].size), align_size);
			img_header->chunk[i].offset = img_header->chunk[i - 1].offset + size;
		}else{
			if(is_seperate_header) {
				size = get_aligned((image_header_size), header_size);
			} else {
				size = get_aligned((image_header_size), align_size);
			}
			img_header->chunk[i].offset = size;
		}
		printf("%c%c%c%c: offset = 0x%08x, size = 0x%08x, dest_start = 0x%016llx, dest_size = 0x%08x, attr0 = 0x%08x, attr1 = 0x%08x\n",
			(char)img_header->chunk[i].id, (char)(img_header->chunk[i].id >> 8),
			(char)(img_header->chunk[i].id >> 16), (char)(img_header->chunk[i].id >> 24),
			img_header->chunk[i].offset, img_header->chunk[i].size,
			img_header->chunk[i].dest_start, img_header->chunk[i].dest_size,
			img_header->chunk[i].attr0, img_header->chunk[i].attr1);
	}

	if(!is_seperate_header) {
		strncpy(img_header_name, defalut_img_header_name, strlen(defalut_img_header_name));
		img_header_name[strlen(defalut_img_header_name)] = '\0';
	}

	img_header_fd = open(img_header_name, O_RDWR|O_CREAT|O_TRUNC, S_IRWXG|S_IRWXU);
	if(-1 == img_header_fd){
		printf("open %s error!\n",img_header_name);
		ret = -1;
		goto error;
	}

	size = write(img_header_fd, img_header, image_header_size) ;
	if(size != image_header_size){
		printf("write %s error!\n",img_header_name);
		ret = -1;
	}

	close(img_header_fd);
	if(!is_seperate_header) {
		size = get_aligned(image_header_size, align_size);
		if(image_header_size < size){
			sprintf(system_cmd,"dd if=/dev/urandom of=%s.filler bs=1 count=%d",
				img_header_name, (size - image_header_size));
			printf("system_cmd = %s\n",system_cmd);
			ret = system(system_cmd);
			if(ret < 0)
				goto error;
			sprintf(system_cmd,"cat %s %s.filler > %s",img_header_name,img_header_name,out_path_name);
		} else {
			sprintf(system_cmd,"cat %s > %s",img_header_name,out_path_name);
		}
		printf("system_cmd = %s\n",system_cmd);
		ret = system(system_cmd);
		if(ret < 0)
			goto error;
	}
	for(i = 0;i < img_header->chunk_num;i++){
		size = get_aligned((img_header->chunk[i].size), align_size);
		if(img_header->chunk[i].size < size){
			sprintf(system_cmd,"dd if=/dev/urandom of=%s.filler bs=1 count=%d",
				chunk_record[i].path_name, (size - img_header->chunk[i].size));
			printf("system_cmd = %s\n",system_cmd);
			ret = system(system_cmd);
			if(ret < 0)
				goto error;
			sprintf(system_cmd,"cat %s %s.filler >> %s",chunk_record[i].path_name, chunk_record[i].path_name,out_path_name);
		} else {
			sprintf(system_cmd,"cat %s >> %s", chunk_record[i].path_name,out_path_name);
		}

		printf("system_cmd = %s\n",system_cmd);
		ret = system(system_cmd);
		if(ret < 0)
			goto error;

	}

	// move imgage header file to output direct
	getcwd(curr_path_dir,PATH_MAX);
	out_path_dir = dirname(out_path_name);
	strcat(curr_path_dir,"/");
	strcat(curr_path_dir,img_header_name);
	sprintf(system_cmd,"mv %s %s",curr_path_dir,out_path_dir);
	printf("system_cmd = %s\n",system_cmd);
	ret = system(system_cmd);
	if(ret < 0)
		printf("warning: move imgage header file to output direct failed!\n");
	sprintf(system_cmd,"mv %s.filler %s",curr_path_dir,out_path_dir);
	printf("system_cmd = %s\n",system_cmd);
	ret = system(system_cmd);
	if(ret < 0)
		printf("warning: move imgage header filler to output direct failed!\n");

error:
	free(img_header);
	return ret;
}

/********************************************************************************
 * Marvell GPL License Option
 *
 * If you received this File from Marvell, you may opt to use, redistribute and/or
 * modify this File in accordance with the terms and conditions of the General
 * Public License Version 2, June 1991 (the "GPL License"), a copy of which is
 * available along with the File in the license.txt file or by writing to the Free
 * Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 or
 * on the worldwide web at http://www.gnu.org/licenses/gpl.txt.
 *
 * THE FILE IS DISTRIBUTED AS-IS, WITHOUT WARRANTY OF ANY KIND, AND THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE ARE EXPRESSLY
 * DISCLAIMED.  The GPL License provides additional details about this warranty
 * disclaimer.
 ******************************************************************************/

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <unistd.h>
#define _GNU_SOURCE
#include <string.h>

#include <version_table.h>

#define MAGIC_NUMER	0xD2ADA3F1
#define PART_NAME_MAX_LEN 15

#define OU_DONE		0x55504544
#define SECTOR_SIZE 512
#define ToM         2048
#define USE_ZERO_START
#ifdef CONFIG_GPT
#define GPT_PART_RESERVED_SIZE			(16ULL << 20)	/* GPT is 16MB */
#define BACKUP_GPT_PART_MIN_RESERVED_SIZE	( 1ULL << 20)	/* minimal reserve 1MB */
#endif
int block_size;
long long chip_size;
#define EMMC_RESERVED_SIZE (0)
int emmc_chip_reserved_size = EMMC_RESERVED_SIZE;
int half_size_entry = -1;

struct table_entry{
	char layout[PART_NAME_MAX_LEN+1];
	char name[PART_NAME_MAX_LEN+1];
	long long start;
	unsigned long long size;
	int invisible;
	int is_back_up;
	int has_back_up;
	int has_offset;
	struct table_entry *back_up_entry;
	unsigned char flash_plane;
	unsigned char flash_type;
	char partition_type[PART_NAME_MAX_LEN + 1];
	char emmc_operation[PART_NAME_MAX_LEN + 1];
	char emmc_burn_option[PART_NAME_MAX_LEN + 1];
	char emmc_write_protection[PART_NAME_MAX_LEN + 1];
};
struct table_entry cfg_table[256];
int entries;

struct part_record
{
	char reserved1[4];
	char flag;
	char reserved2[3];
	unsigned int start;
	unsigned int size;
};

void usage(int argc, char **argv)
{
	fprintf(stderr, "usage:\n");
	fprintf(stderr, "%s major_version minor_version block_size chip_size part_config_file "
		"kernel_parameter_file version_table_file layout_file [emmc_part_table emmc_part_list emmc_image_list]\n",
		argv[0]);
}

int parse_layout(struct table_entry * entry)
{
	int i,j;
	char layout[PART_NAME_MAX_LEN+1];
	char *str_pos;
	unsigned long long size, pos;

//	printf("%s\t%s\t%s\n", __FUNCTION__, entry->layout, entry->name);
	strcpy(layout, entry->layout);
	str_pos = strchr(layout, '@');
	if(str_pos)
	{
		entry->has_offset = 1;
		str_pos[0]='\0';
		str_pos++;
//		printf("str_size:%s, str_pos: %s\n", layout, str_pos);

		j = strlen(str_pos);
		if((str_pos[j-1] == 'B') || (str_pos[j-1] == 'b')) {
			str_pos[j-1] = '\0';
			pos = atoi(str_pos)*block_size;
		}
		else if((str_pos[j-1] == 'M') || (str_pos[j-1] == 'm')) {
			str_pos[j-1] = '\0';
			pos = (unsigned long long)(atoi(str_pos))*1024*1024;
		}
		else if((str_pos[j-1] == 'K') || (str_pos[j-1] == 'k')) {
			str_pos[j-1] = '\0';
			pos = atoi(str_pos)*1024;
		}
		else {
			pos = atoi(str_pos);
		}
		if(pos&(block_size-1)) {
			fprintf(stderr, "patition %s position must be block aligned.\n", entry->name);
			return -1;
		}
	}
	else
	{
		entry->has_offset = 0;
		pos = 0;
	}

	j = strlen(layout);
	if((layout[j-1] == 'B') || (layout[j-1] == 'b')) {
		layout[j-1] = '\0';
		size = atoi(layout)*block_size;
	}
	else if((layout[j-1] == 'M') || (layout[j-1] == 'm')) {
		layout[j-1] = '\0';
		size = (unsigned long long)(atoi(layout))*1024*1024;
	}
	else if((layout[j-1] == 'K') || (layout[j-1] == 'k')) {
		layout[j-1] = '\0';
		size = atoi(layout)*1024;
	}
	else {
		size = atoi(layout);
	}
	if(size&(block_size-1)) {
		fprintf(stderr, "patition %s size %s must be block aligned.\n", entry->name, layout);
		return -1;
	}


	entry->size = size;
	entry->start = pos;
//	printf("size=%d, start=%d\n", entry->size, entry->start);
	return 0;
}

int parse_name(struct table_entry * entry)
{
	int i,j;
	char str[PART_NAME_MAX_LEN+1];

//	printf("%s\t%s\t%s\n", __FUNCTION__, entry->layout, entry->name);
	i = strlen(entry->name);

	if(entry->name[0] != '@')
		return 0;
	entry->invisible = 1;
	strcpy(str, &entry->name[1]);
//	printf("%s\n", entry->name);
#if 0
	for(i=0;i<entries;i++)
	{
		if(entry == &cfg_table[i])
			continue;
		j=strlen(cfg_table[i].name);
		if(strncmp(str, cfg_table[i].name, j))
			continue;
		cfg_table[i].has_back_up = 1;
		cfg_table[i].back_up_entry = entry;
		entry->is_back_up = 1;
		printf("match partition name: %s\n", cfg_table[i].name);
		break;
	}
#endif
	strcpy(entry->name, str);
	return 0;
}

#ifdef CONFIG_GPT
int gen_emmc_part_table(char *part_table_path)
{
	FILE *ftable = NULL;
	int i, ret = -1;
	struct part_record record;

	ftable = fopen(part_table_path, "w");
	if(ftable == NULL) {
		fprintf(stderr, "Open %s failed.\n", part_table_path);
		return ret;
	}

	for (i = 0; i < entries; i++)
	{
		memset(&record, 0, sizeof(record));

		record.flag = 0x83;
		record.start = cfg_table[i].start/SECTOR_SIZE;
		record.size = cfg_table[i].size/SECTOR_SIZE;
		if(fwrite(&record, sizeof(record), 1, ftable) != 1)
		{
			fprintf(stderr, "write to %s error.\n", part_table_path);
			goto end;
		}
	}
	ret = 0;
end:
	fclose(ftable);
	return ret;
}
#else
int gen_emmc_part_table(char *part_table_path)
{
	FILE *ftable = NULL;
	char sector_buf[510] = {0};
	char partition_record[16] = {0};
	int i, ret = -1;
	char br_path[512];
	unsigned int extended_start, offset=1024*1024;
	struct part_record record;


	ftable = fopen(part_table_path, "w");
	if(ftable == NULL) {
		fprintf(stderr, "Open %s failed.\n", part_table_path);
		return ret;
	}

	for (i = 0; i < entries; i++)
	{
		memset(&record, 0, sizeof(record));

		if (i < 3)
		{
			if (i == 0)
			{
				if (cfg_table[i].start < (long long)offset)
				{
				cfg_table[i].start += offset;
					cfg_table[i].size -= offset;
				}
			}
			record.flag = 0x83;
			record.start = cfg_table[i].start/SECTOR_SIZE;
			record.size = cfg_table[i].size/SECTOR_SIZE;
			if(fwrite(&record, sizeof(record), 1, ftable) != 1)
			{
				fprintf(stderr, "write to %s error.\n", part_table_path);
				goto end;
			}
		}
		else
		{
			if (i == 3)
			{
				if (entries == 4)
				{
					record.flag = 0x83;
					record.start = cfg_table[i].start/SECTOR_SIZE;
					record.size = cfg_table[i].size/SECTOR_SIZE;
				}
				else
				{
					record.flag = 0x05; /* extended partition */
					record.start = cfg_table[i].start/SECTOR_SIZE;
					record.size = chip_size/SECTOR_SIZE - record.start;
					extended_start = record.start;

				}

				if(fwrite(&record, sizeof(record), 1, ftable) != 1)
				{
					fprintf(stderr, "write to %s error.\n", part_table_path);
					goto end;
				}

				if (entries == 4)
				{
					ret = 0;
					goto end;
				}
			}

			/* logical partition */
			/* first entry */
			cfg_table[i].start += offset;
			cfg_table[i].size -= offset;
			record.flag = 0x83;
			record.start = offset/512;
			record.size = cfg_table[i].size/SECTOR_SIZE;
			if(fwrite(&record, sizeof(record), 1, ftable) != 1)
			{
				fprintf(stderr, "write to %s error.\n", part_table_path);
				goto end;
			}

			/* second entry */
			if (i == entries - 1)
			{
				memset(&record, 0, sizeof(record));
			}
			else
			{
				record.flag = 0x5;
				record.start = cfg_table[i + 1].start/SECTOR_SIZE - extended_start;
				record.size = cfg_table[i + 1].size/SECTOR_SIZE;
			}
			if(fwrite(&record, sizeof(record), 1, ftable) != 1)
			{
				fprintf(stderr, "write to %s error.\n", part_table_path);
				goto end;
			}
		}
	}

	ret = 0;

end:
	fclose(ftable);
	return ret;
}
#endif

#ifdef CONFIG_GPT
int gen_emmc_part_list(const char *part_table_path, const char *part_list_path)
{
	int i, ret = -1;
	unsigned int start, size;
	FILE *f_part_out=NULL;
	char *name_start;
	char part_option[64] = "";
	unsigned int offset_from_prev = 0;

	f_part_out = fopen(part_list_path, "w");
	if (f_part_out == NULL)
	{
		fprintf(stderr, "Open %s failed.\n", part_list_path);
		goto END;
	}
	fprintf(f_part_out, "#GPT\n");
	for(i = 0; i < entries; i++)
	{
		strcpy(part_option, "");
		start = (unsigned int)(cfg_table[i].start/(ToM * SECTOR_SIZE));
		size = (unsigned int)(cfg_table[i].size/(ToM * SECTOR_SIZE));
		name_start = strchr(cfg_table[i].name, '@');
		if (name_start == NULL)
			name_start = cfg_table[i].name;
		else
			name_start++;
		if (half_size_entry == i)
		{
			strcpy(part_option, "enhanced");
		}
#ifndef USE_ZERO_START
	fprintf(f_part_out, "%-16s,%d\t,%d\t,%-16s\n", name_start, start, size,part_option);
#else
	if (offset_from_prev == start)
		fprintf(f_part_out, "%-16s,0\t,%d\t,%-16s\n", name_start,size,part_option);
	else
		fprintf(f_part_out, "%-16s,%d\t,%d\t,%-16s\n", name_start,start, size,part_option);
	offset_from_prev = start + size;
#endif

	}

	ret = 0;
END:
	if (f_part_out)
		fclose(f_part_out);
	return ret;
}

#else
int gen_emmc_part_list(const char *part_table_path, const char *part_list_path)
{
	int i, ret = -1;
 	struct stat file_stat;
	FILE *f_part_in=NULL, *f_part_out=NULL;
	char *buf;
	struct part_record *record;
	unsigned int extended_start, offset_from_prev = 0;

	ret = stat(part_table_path, &file_stat);
	if (ret)
	{
		fprintf(stderr, "fail to stat %s\n", part_table_path);
		ret = -1;
		goto END;
	}
	if (file_stat.st_size < 96)
	{
		fprintf(stderr, "too small partition table size: %d\n", file_stat.st_size);
		ret = -1;
		goto END;
	}

	f_part_in = fopen(part_table_path, "r");
	if (f_part_in == NULL)
	{
		fprintf(stderr, "Open %s failed.\n", part_table_path);
		ret = -1;
		goto END;
	}

	buf = malloc(file_stat.st_size);
	if (NULL == buf) {
		ret = -1;
		goto END;
	}

	ret = fread(buf, file_stat.st_size, 1, f_part_in);
	if (1 != ret) {
		fprintf(stderr, "fail to read %s\n", part_table_path);
		ret = -1;
		goto END;
	}

	f_part_out = fopen(part_list_path, "w");
	if (f_part_out == NULL)
	{
		fprintf(stderr, "Open %s failed.\n", part_list_path);
		goto END;
	}
	fprintf(f_part_out, "#DOS\n");
	for (i = 0; i < 3; i++)
	{

		record = (struct part_record*)(buf + i*sizeof(struct part_record));
#ifndef USE_ZERO_START
		fprintf(f_part_out, "p,%d,%d\n", record->start/ToM, record->size/ToM);
#else
		if (offset_from_prev == record->start)
			fprintf(f_part_out, "p,0,%d\n", record->size/ToM);
		else
			fprintf(f_part_out, "p,%d,%d\n", record->start/ToM, record->size/ToM);
		offset_from_prev = record->start + record->size;
#endif
	}

	record = (struct part_record*)(buf + 3*sizeof(struct part_record));
#ifndef USE_ZERO_START
	fprintf(f_part_out, "e,%d,%d\n", record->start/ToM, record->size/ToM);
#else
	if (offset_from_prev == record->start)
		fprintf(f_part_out, "e,0,%d\n", record->size/ToM);
	else
		fprintf(f_part_out, "e,%d,%d\n", record->start/ToM, record->size/ToM);
	offset_from_prev = record->start;
#endif

	extended_start = record->start;
	for(i = 0; i < (file_stat.st_size - 64)/32 - 1; i++)
	{
		if (i == 0) /* for first logical partition, start is extended partition start */
		{
			record = (struct part_record*)(buf + 64);
#ifndef USE_ZERO_START
			fprintf(f_part_out, "l,%d,%d\n", extended_start/ToM,
				(record->start + record->size)/ToM);
#else
			fprintf(f_part_out, "l,0,%d\n", (record->start + record->size)/ToM);
			offset_from_prev = record->start + record->size;
#endif
		}

		record = (struct part_record*)(buf + 64 + i*32 + 16);
		if (record->start == 0)
			break;
#ifndef USE_ZERO_START
		fprintf(f_part_out, "l,%d,%d\n", (record->start + extended_start)/ToM,
			record->size/ToM);
#else
		if (offset_from_prev == record->start)
			fprintf(f_part_out, "l,0,%d\n", record->size/ToM);
		else
			fprintf(f_part_out, "l,%d,%d\n", (record->start + extended_start)/ToM,
				record->size/ToM);
		offset_from_prev = record->start + record->size;
#endif
	}

	ret = 0;
END:
	if (f_part_in)
		fclose(f_part_in);
	if (f_part_out)
		fclose(f_part_out);
	return ret;
}
#endif

int human_format(unsigned long long size, char *buf, int buf_len)
{
	const char *unit[] = {"", "K", "M", "G"};
	int i = 0;

	if (size > 0) {
		for (i = 0; i < sizeof(unit)/sizeof(*unit); i++) {
			if (size & 1023)
				break;
			size >>= 10;
		}
	}

	sprintf(buf, "%Ld%s", size, unit[i]);
	return strlen(buf);
}
static int parse_arg(char* input, int len, int* argc, char* argv[])
{
    char* p = input;
    char* dot;
    int i=0;
    *argc = 0;
//    printf("parse_arg %s\n", input);

    while(p < (input+len))
    {
        argv[i++] = p;
        dot = strchr(p, ',');
        if (dot)
        {
            *dot = 0;
            p = dot + 1;
//            printf("parse arg got one %s\n", argv[i-1]);
        }
        else
        {
//            printf("parse arg got one %s\n", argv[i-1]);
            break;
        }
    }

    *argc = i;
    return i;
}
#define NAND_PARAM_COUNT		(9)
#define EMMC_PARAM_COUNT		(12)

int main(int argc, char **argv)
{
	int i, j;
	int kernel_param_len = 0, flash_plane_info_len = 0;
	int ret,tmp;
	long long pos1, pos2;
	int _entry=-1;
	int enhanced_partition = -1;
	int ver_major, ver_minor;
	char *part_cfg_file, *kernel_param_file, *version_table_file, *layout_file;
	char *part_table_path, *part_list_path, *image_list_path;
	FILE *fcfg=NULL, *fparam=NULL, *fvt=NULL, *flayout=NULL, *fimg=NULL;

	char line_buffer[1024];
	char flash_plane_info[1024] = "";
	char kernel_param[2048];
	version_table_t ver_t;
	ver_table_entry_t vt;

	if (argc != NAND_PARAM_COUNT && argc != EMMC_PARAM_COUNT) {
		usage(argc, argv);
		return 1;
	}

	ver_major = atoi(argv[1]);
	ver_minor = atoi(argv[2]);
	block_size = atoi(argv[3]);
	chip_size = atoll(argv[4]);
	part_cfg_file = argv[5];
	kernel_param_file = argv[6];
	version_table_file = argv[7];
	layout_file = argv[8];
	if (argc == EMMC_PARAM_COUNT)
	{
#ifdef CONFIG_GPT
		/* make the flash GPT_PART_RESERVED_SIZE (16MB) aligned */
		unsigned int tail_reserved_size = chip_size % GPT_PART_RESERVED_SIZE;
		/* if the rest memory space is not enough for backup GPT,
		 * then reserve another 16MB.
		 */
		if (tail_reserved_size < BACKUP_GPT_PART_MIN_RESERVED_SIZE)
			tail_reserved_size += GPT_PART_RESERVED_SIZE;
		chip_size -= tail_reserved_size;
		printf("tail reserved size: %dMB, avaliable size %lldMB\n",
				tail_reserved_size >> 20, chip_size >> 20);
#endif
		part_table_path = argv[9];
		part_list_path = argv[10];
		image_list_path = argv[11];
		fimg = fopen(image_list_path, "w");
		if(fimg == NULL)
		{
			fprintf(stderr, "Open %s failed.\n", image_list_path);
			return -1;
		}
	}

	if((block_size <= 0) || (chip_size <=0 ))
	{
		fprintf(stderr, "Block size or chip size error.\n");
		goto fail_out;
	}

	fcfg = fopen(part_cfg_file, "r");
	if(fcfg == NULL)
	{
		fprintf(stderr, "Open %s failed.\n", part_cfg_file);
		return -1;
	}

	//read entries and parse size
#ifdef CONFIG_GPT
	pos1 = GPT_PART_RESERVED_SIZE;	// for GPT, start from 16MB
#else
	pos1=0;
#endif
	i=0;
	while(fgets(line_buffer, 512, fcfg))
	{
		char str[PART_NAME_MAX_LEN + 1] = "";

		// cut the comments chars
		char *comment_pos = (char *)strchr(line_buffer, '#');
		if (comment_pos)
			*comment_pos = '\0';

		if((line_buffer[0] == '#')|| (strlen(line_buffer)<2))
			continue;

		if (argc == NAND_PARAM_COUNT) {
			ret = sscanf(line_buffer, "%s%s%hhd%s%s",
					cfg_table[i].layout, cfg_table[i].name, &cfg_table[i].flash_plane, cfg_table[i].partition_type, str);
			if (ret < 2) {
				fprintf(stderr, "parse entry %d error.\n", i+1);
				goto fail_out;
			}
			if (cfg_table[i].flash_plane != 2)
				cfg_table[i].flash_plane = 1;

			if (!strcmp(str, "yaffs"))
				cfg_table[i].flash_type = 1;
			else if (!strcmp(str, "raw"))
				cfg_table[i].flash_type = 2;
			else
				cfg_table[i].flash_type = 0;
		} else {
			char str1[PART_NAME_MAX_LEN + 1] = "";
#ifdef CONFIG_EMMC_WRITE_PROTECT
			ret = sscanf(line_buffer, "%s%s%s%s%s",
					cfg_table[i].layout, cfg_table[i].name, cfg_table[i].emmc_operation, cfg_table[i].emmc_burn_option,
					cfg_table[i].emmc_write_protection);
			if (ret < 5) {
				fprintf(stderr, "parse entry %d error.\n", i+1);
				goto fail_out;
			}
#else
			ret = sscanf(line_buffer, "%s%s%s%s",
					cfg_table[i].layout, cfg_table[i].name, cfg_table[i].emmc_operation, cfg_table[i].emmc_burn_option);
			if (ret < 3) {
				fprintf(stderr, "parse entry %d error.\n", i+1);
				goto fail_out;
			}
#endif
			int emmc_argc;
			char* emmc_argv[8];
			parse_arg(cfg_table[i].emmc_operation, strlen(cfg_table[i].emmc_operation),
						&emmc_argc, emmc_argv);
			for (j = 0; j < emmc_argc; j++)
			{
				if (strcmp(emmc_argv[j], "enhance") == 0)
				{
					if (enhanced_partition == 1){
							fprintf(stderr, "Only one partition can be set to enhanced... \n");
							goto	fail_out;
						}
					enhanced_partition = 1;
					half_size_entry = i;
					fprintf(stdout, "half_size_entry=%d\n", half_size_entry);
				}else
				{
					strcpy(cfg_table[i].emmc_operation,emmc_argv[j]);
				}
			}
		}

		if(strncmp(cfg_table[i].layout, "-", 2) == 0)
		{
			if(_entry >= 0)
			{
				fprintf(stderr, "parse entry %d error.\n", i+1);
				goto fail_out;
			}
			_entry = i;
			fprintf(stdout, "_entry=%d\n", _entry);
		}
		if(_entry >= 0)
		{
			i++;
			continue;
		}
		if(parse_layout(&cfg_table[i]))
			return -1;
		if (half_size_entry == i)
		{
			cfg_table[i].size = cfg_table[i].size >> 1;
			chip_size -= cfg_table[i].size;
			chip_size += emmc_chip_reserved_size;
		}
		if(cfg_table[i].start == 0)
		{//increase pos
			cfg_table[i].start = pos1;
			pos1 += cfg_table[i].size;
		}
		else//move pos
			pos1 = cfg_table[i].start+cfg_table[i].size;
		if(pos1>chip_size) {
			fprintf(stderr, "partition %s end %llu exceed chip size.\n", cfg_table[i].name, pos1);
			return -1;
		}

		printf("pos1=%lld\n", pos1);
		i++;
	}
	entries = i;
	fprintf(stdout, "read %d entries.\n", entries);
	if (_entry >= 0)
	{
		pos2 = chip_size;
		printf("pos2 = %lld\n",pos2);
		for(i=entries-1; i>_entry; i--)
		{
			if(parse_layout(&cfg_table[i]))
				return -1;
			if (i == half_size_entry)
			{
				cfg_table[half_size_entry].size = cfg_table[half_size_entry].size >> 1;
				chip_size -= cfg_table[half_size_entry].size;
				chip_size += emmc_chip_reserved_size;
				pos2 = chip_size;
			}
			printf("cfg_table[%d].size = %lld\n", i, cfg_table[i].size);
			pos2 -= cfg_table[i].size;
			if(cfg_table[i].start == 0)
				cfg_table[i].start = pos2;
			printf("pos2=%lld\n", pos2);
		}
		if(pos2<pos1)
		{
			fprintf(stderr, "sum of partition size exceed chip size.\n");
			return -1;
		}
		cfg_table[_entry].start = pos1;
		cfg_table[_entry].size = pos2 - pos1;
		if (_entry == half_size_entry)
		{
			cfg_table[half_size_entry].size = cfg_table[half_size_entry].size >> 1;
			chip_size -= cfg_table[half_size_entry].size;
			chip_size += emmc_chip_reserved_size;
			pos2 = chip_size;
			printf("pos2 = %lld\n",pos2);
			for(i=entries-1; i>_entry; i--)
			{
				if(parse_layout(&cfg_table[i]))
					return -1;
				printf("cfg_table[%d].size = %lld\n", i, cfg_table[i].size);
				pos2 -= cfg_table[i].size;
				printf("pos2=%lld\n", pos2);
			}
			if(pos2<pos1)
			{
				fprintf(stderr, "sum of partition size exceed chip size.\n");
				return -1;
			}
		}
	}

	if (argc == EMMC_PARAM_COUNT)
	{
		if (gen_emmc_part_table(part_table_path))
			return -1;
 		if (gen_emmc_part_list(part_table_path, part_list_path))
			return -1;
	}

	//pick out invisible and back up partitions
	for(i=0;i<entries;i++)
	{
		if(i&&(cfg_table[i].start < cfg_table[i-1].start+cfg_table[i-1].size))
		{
			printf("partition %d and %d overlaps.\n", i-1 ,i);
			goto fail_out;
		}
		parse_name(&cfg_table[i]);
#ifdef CONFIG_EMMC_WRITE_PROTECT
		printf("part name %s, off %Ld, size %lld, plane %d, type %d, operation %s, burn option %s, write protection %s\n",
			cfg_table[i].name, cfg_table[i].start, cfg_table[i].size,
			cfg_table[i].flash_plane, cfg_table[i].flash_type, cfg_table[i].emmc_operation,
			cfg_table[i].emmc_burn_option, cfg_table[i].emmc_write_protection);
#else
		printf("part name %s, off %Ld, size %lld, plane %d, type %d, operation %s, %s\n",
			cfg_table[i].name, cfg_table[i].start, cfg_table[i].size,
			cfg_table[i].flash_plane, cfg_table[i].flash_type, cfg_table[i].emmc_operation, cfg_table[i].emmc_burn_option);
#endif
	}
	//generate files
	fparam = fopen(kernel_param_file, "w+");
	if(fparam == NULL) {
		fprintf(stderr, "Open %s failed.\n", kernel_param_file);
		goto fail_out;
	}
	fvt= fopen(version_table_file, "w+");
	if(fvt== NULL) {
		fprintf(stderr, "Open %s failed.\n", version_table_file);
		goto fail_out;
	}
	flayout = fopen(layout_file, "w+");
	if(flayout == NULL) {
		fprintf(stderr, "Open %s failed.\n", layout_file);
		goto fail_out;
	}

	memset(&ver_t, 0, sizeof(ver_t));
	ver_t.magic=MAGIC_NUMER;
	ver_t.ou_status = OU_DONE;
	printf("ou_status: %08x\n", ver_t.ou_status);
	if(fwrite(&ver_t, sizeof(ver_t), 1, fvt) != 1) {
		fprintf(stderr, "write to %s error.\n", version_table_file);
		goto fail_out;
	}
	/* for emmc */
	if (argc == EMMC_PARAM_COUNT)
	{
		fprintf(flayout, "%s\t\t%d\t%d\n", "preboot", 0, 1);
		fprintf(fimg, "preboot.subimg,b1\npreboot.subimg,b2\n");

		strcpy(vt.name, "preboot");
		vt.part1_version.major_version = ver_major;
		vt.part1_version.minor_version = ver_minor;
		vt.part1_start_blkind = 0;
		vt.part1_blks = 1;
#ifdef CONFIG_EMMC_WRITE_PROTECT
		vt.write_protect_flag = 0;
#else
		vt.part2_version.major_version = 0;
		vt.part2_version.minor_version = 0;
		vt.part2_start_blkind = 0;
		vt.part2_blks = 1;
#endif
		if(fwrite(&vt, sizeof(vt), 1, fvt) != 1)
		{
			fprintf(stderr, "write to %s error.\n", version_table_file);
			goto fail_out;
		}
		ver_t.num_entries = 1;
	}

	kernel_param_len = sprintf(kernel_param, " mtdparts=mv_nand:");
	flash_plane_info_len = 0;
	for(i=0;i<entries;i++)
	{
		char size_buf[64];
		char start_buf[64];
		char img_name[PART_NAME_MAX_LEN + 10];
		memset(&vt, 0, sizeof(ver_table_entry_t));

		human_format(cfg_table[i].size, size_buf, sizeof(size_buf));
		human_format(cfg_table[i].start, start_buf, sizeof(start_buf));

		if (cfg_table[i].has_offset) {
			kernel_param_len += sprintf(&kernel_param[kernel_param_len], "%s@%s(%s),",
				size_buf, start_buf, cfg_table[i].name);
		} else {
			kernel_param_len += sprintf(&kernel_param[kernel_param_len], "%s(%s),",
				size_buf, cfg_table[i].name);
		}

		if (argc == NAND_PARAM_COUNT) {
			if (cfg_table[i].flash_plane == 2) {
				if (flash_plane_info_len == 0)
					flash_plane_info_len = sprintf(flash_plane_info, " pxa3xx_nand.use_dp=1 pxa3xx_nand.plane_cmdline=");
				flash_plane_info_len += sprintf(&flash_plane_info[flash_plane_info_len], "(%s)dp,", cfg_table[i].name);
			}
			if(strncmp(cfg_table[i].partition_type, "eslc", 4) == 0){
				if (flash_plane_info_len == 0)
					flash_plane_info_len = sprintf(flash_plane_info, " pxa3xx_nand.plane_cmdline=");
				flash_plane_info_len += sprintf(&flash_plane_info[flash_plane_info_len], "(%s)eslc,", cfg_table[i].name);
			}else if (strncmp(cfg_table[i].partition_type, "slc", 3) == 0){
				if (flash_plane_info_len == 0)
					flash_plane_info_len = sprintf(flash_plane_info, " pxa3xx_nand.plane_cmdline=");
				flash_plane_info_len += sprintf(&flash_plane_info[flash_plane_info_len], "(%s)slc,", cfg_table[i].name);
			}
		}

		if(!cfg_table[i].invisible)
		{
			if (argc == NAND_PARAM_COUNT)
				switch (cfg_table[i].flash_type) {
				case 1:
					fprintf(flayout, "%s\t\t%d\t%lld\toob\t%s\n", cfg_table[i].name, (int)(cfg_table[i].start/block_size),
						cfg_table[i].size/block_size, cfg_table[i].partition_type);
					break;
				case 2:
					fprintf(flayout, "%s\t\t%d\t%lld\traw\t%s\n", cfg_table[i].name, (int)(cfg_table[i].start/block_size),
						cfg_table[i].size/block_size, cfg_table[i].partition_type);
					break;
				default:
					fprintf(flayout, "%s\t\t%d\t%lld\tnormal\t%s\n", cfg_table[i].name, (int)(cfg_table[i].start/block_size),
						cfg_table[i].size/block_size, cfg_table[i].partition_type);
					break;
				}


			if (argc == EMMC_PARAM_COUNT)
			{
				fprintf(flayout, "%s\t\t%d\t%lld\n", cfg_table[i].name, (int)(cfg_table[i].start/block_size),
					cfg_table[i].size/block_size);

				if (strcmp(cfg_table[i].name, "preboot") == 0)
				{
					fprintf(stderr, "'preboot' cannot be included in the eMMC partition table.\n");
					goto fail_out;
				}

				if (strcmp(cfg_table[i].emmc_operation, "default") && strcmp(cfg_table[i].emmc_operation, "fixed"))
					strcpy(img_name, cfg_table[i].emmc_operation);
				else
					sprintf(img_name, "%s.subimg", cfg_table[i].name);
#ifdef CONFIG_GPT
				fprintf(fimg, "%s,sd%d", img_name, i + 1);
#else
				if (i == 0)
					fprintf(fimg, "%s,%d", img_name, (int)(cfg_table[i].start/1024/1024));
				else if (i < 3)
					fprintf(fimg, "%s,sd%d", img_name, i + 1);
				else
					fprintf(fimg, "%s,sd%d", img_name, i + 2);
#endif
				if (strcmp(cfg_table[i].emmc_burn_option, "first_burn") == 0)
					fprintf(fimg, ",%s\n", cfg_table[i].emmc_burn_option);
				else
					fprintf(fimg, "\n");
			}
		}
		if(cfg_table[i].is_back_up)
			continue;
		strcpy(vt.name, cfg_table[i].name);
		vt.part1_version.major_version = ver_major;
		vt.part1_version.minor_version = ver_minor;
		vt.part1_start_blkind = cfg_table[i].start/block_size;
		vt.part1_blks = cfg_table[i].size/block_size;
		strcpy(vt.part_type,cfg_table[i].partition_type);
#ifdef CONFIG_EMMC_WRITE_PROTECT
		vt.write_protect_flag = 0;
		if(strstr(cfg_table[i].emmc_write_protection, "normal"))
		{
			vt.write_protect_flag |= NORMAL_WP_MASK;
		}
		if(strstr(cfg_table[i].emmc_write_protection, "recovery"))
		{
			vt.write_protect_flag |= RECOVERY_WP_MASK;
		}
#else
		vt.part2_version.major_version = 0;
		vt.part2_version.minor_version = 0;
		if(cfg_table[i].has_back_up)
		{
			vt.part2_start_blkind = cfg_table[i].back_up_entry->start/block_size;
			vt.part2_blks = cfg_table[i].back_up_entry->size/block_size;
		}
		else
		{
			vt.part2_start_blkind = cfg_table[i].start/block_size;
			vt.part2_blks = cfg_table[i].size/block_size;
		}
#endif
		if(fwrite(&vt, sizeof(vt), 1, fvt) != 1)
		{
			fprintf(stderr, "write to %s error.\n", version_table_file);
			goto fail_out;
		}
		ver_t.num_entries += 1;
	}

	fseek(fvt, 0, SEEK_SET);
	if(fwrite(&ver_t, sizeof(ver_t), 1, fvt) != 1) {
		fprintf(stderr, "write to %s error.\n", version_table_file);
		goto fail_out;
	}
#if 0 /* we should not pad version_table now, because we need add crc for it */
	{ /* padding version table file */
		char *padding_buf;
		struct stat st;
		int padding_size;

		if (stat(version_table_file, &st)) {
			fprintf(stderr, "fail to stat %s\n", version_table_file);
			goto fail_out;
		}

		padding_size = VT_SIZE - st.st_size;
		if (padding_size < 0) {
			fprintf(stderr, "too many entries to fit into version table\n");
			goto fail_out;
		}

		padding_buf = malloc(padding_size);
		if (padding_buf == NULL) {
			fprintf(stderr, "fail to allocate buffer for padding bytes\n");
			goto fail_out;
		}
		memset(padding_buf, 0, padding_size);
		fseek(fvt, 0, SEEK_END);
		if (fwrite(padding_buf, padding_size, 1, fvt) != 1) {
			fprintf(stderr, "fail to write padding bytes to %s\n", \
					version_table_file);
			goto fail_out;
		}
	}
#endif
	if (flash_plane_info_len) {
		flash_plane_info[flash_plane_info_len - 1] = '\0';
		if(fwrite(flash_plane_info, flash_plane_info_len - 1, 1, fparam)!= 1)
		{
			fprintf(stderr, "write to %s error.\n", kernel_param_file);
			goto fail_out;
		}
	}
	kernel_param[kernel_param_len-1] = '\0';
	printf("kernel_param=%s%s\n\n", flash_plane_info, kernel_param);

	if(fwrite(kernel_param, kernel_param_len, 1, fparam)!= 1)
	{
		fprintf(stderr, "write to %s error.\n", kernel_param_file);
		goto fail_out;
	}

	if(fcfg != NULL)
		fclose(fcfg);
	if(fparam != NULL)
		fclose(fparam);
	if(fvt!= NULL)
		fclose(fvt);
	if(flayout != NULL)
		fclose(flayout);
	if (argc == EMMC_PARAM_COUNT && fimg != NULL)
		fclose(fimg);
	return 0;
fail_out:
	if(fcfg != NULL)
		fclose(fcfg);
	if(fparam != NULL)
		fclose(fparam);
	if(fvt!= NULL)
		fclose(fvt);
	if(flayout != NULL)
		fclose(flayout);
	if (argc == EMMC_PARAM_COUNT && fimg != NULL)
		fclose(fimg);
	return -1;
}

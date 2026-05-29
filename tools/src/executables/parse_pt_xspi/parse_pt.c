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

#define OU_DONE		0x55504544
#define SECTOR_SIZE 512
#define ToM         2048
#define USE_ZERO_START
#define XSPI_PARAM_COUNT		(12)

int block_size;
long long chip_size;

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
	char filesystem[PART_NAME_MAX_LEN + 1];
	char write_protection[PART_NAME_MAX_LEN + 1];
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
		"kernel_parameter_file version_table_file layout_file [xspi_part_table xspi_part_list xspi_image_list]\n",
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
	strcpy(entry->name, str);
	return 0;
}

int gen_xspi_part_table(char *part_table_path)
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

int gen_xspi_part_list(const char *part_list_path)
{
	int i, ret = -1;
	unsigned int start, size;
	FILE *f_part_out=NULL;
	char *name_start;
	unsigned int offset_from_prev = 0;

	f_part_out = fopen(part_list_path, "w");
	if (f_part_out == NULL)
	{
		fprintf(stderr, "Open %s failed.\n", part_list_path);
		goto END;
	}
	fprintf(f_part_out, "#DOS\n");
	for(i = 0; i < entries; i++)
	{
		start = (unsigned int)(cfg_table[i].start);
		size = (unsigned int)(cfg_table[i].size);
		name_start = strchr(cfg_table[i].name, '@');
		if (name_start == NULL)
			name_start = cfg_table[i].name;
		else
			name_start++;
#ifndef USE_ZERO_START
	fprintf(f_part_out, "%-" PART_NAME_STR_MAX "s,%d\t,%d\t,%-16s\n", name_start, start, size, "");
#else
	if (offset_from_prev == start)
		fprintf(f_part_out, "%-" PART_NAME_STR_MAX "s,0\t,%d\t,%-16s\n", name_start,size, "");
	else
		fprintf(f_part_out, "%-" PART_NAME_STR_MAX "s,%d\t,%d\t,%-16s\n", name_start,start, size, "");
	offset_from_prev = start + size;
#endif

	}

	ret = 0;
END:
	if (f_part_out)
		fclose(f_part_out);
	return ret;
}

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

int main(int argc, char **argv)
{
	int i;
	int kernel_param_len = 0, flash_plane_info_len = 0;
	int ret;
	long long pos1, pos2;
	int _entry=-1;
	int ver_major, ver_minor;
	char *part_cfg_file, *kernel_param_file, *version_table_file, *layout_file;
	char *part_table_path = NULL, *part_list_path = NULL, *image_list_path = NULL;
	FILE *fcfg=NULL, *fparam=NULL, *fvt=NULL, *flayout=NULL, *fimg=NULL;

	char line_buffer[1024];
	char flash_plane_info[1024] = "";
	char kernel_param[2048];
	version_table_t ver_t;
	ver_table_entry_t vt;

	if (argc != XSPI_PARAM_COUNT) {
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
	part_table_path = argv[9];
	part_list_path = argv[10];
	image_list_path = argv[11];
	fimg = fopen(image_list_path, "w");
	if(fimg == NULL)
	{
		fprintf(stderr, "Open %s failed.\n", image_list_path);
		return -1;
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
	pos1=0;
	i=0;
	while(fgets(line_buffer, 512, fcfg))
	{
		// cut the comments chars
		char *comment_pos = (char *)strchr(line_buffer, '#');
		if (comment_pos)
			*comment_pos = '\0';

		if((line_buffer[0] == '#')|| (strlen(line_buffer)<2))
			continue;

		ret = sscanf(line_buffer, "%s%s%hhd%s%s%s",
				cfg_table[i].layout, cfg_table[i].name, &cfg_table[i].flash_plane,
				cfg_table[i].partition_type, cfg_table[i].filesystem, cfg_table[i].write_protection);
		if (ret < 6) {
			fprintf(stderr, "parse entry %d error.\n", i+1);
			goto fail_out;
		}
		if (cfg_table[i].flash_plane != 2)
			cfg_table[i].flash_plane = 1;
		if (!strcmp(cfg_table[i].filesystem, "yaffs"))
			cfg_table[i].flash_type = 1;
		else if (!strcmp(cfg_table[i].filesystem, "raw"))
			cfg_table[i].flash_type = 2;
		else
			cfg_table[i].flash_type = 0;

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
			goto fail_out;
		if(cfg_table[i].start == 0)
		{//increase pos
			cfg_table[i].start = pos1;
			pos1 += cfg_table[i].size;
		}
		else//move pos
			pos1 = cfg_table[i].start+cfg_table[i].size;
		if(pos1>chip_size) {
			fprintf(stderr, "partition %s end %llu exceed chip size.\n", cfg_table[i].name, pos1);
			goto fail_out;
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
				goto fail_out;
			printf("cfg_table[%d].size = %lld\n", i, cfg_table[i].size);
			pos2 -= cfg_table[i].size;
			if(cfg_table[i].start == 0)
				cfg_table[i].start = pos2;
			printf("pos2=%lld\n", pos2);
		}
		if(pos2<pos1)
		{
			fprintf(stderr, "sum of partition size exceed chip size.\n");
			goto fail_out;
		}
		cfg_table[_entry].start = pos1;
		cfg_table[_entry].size = pos2 - pos1;
	}

	if (gen_xspi_part_table(part_table_path))
		goto fail_out;
	if (gen_xspi_part_list(part_list_path))
		goto fail_out;

	//pick out invisible and back up partitions
	for(i=0;i<entries;i++)
	{
		if(i&&(cfg_table[i].start < cfg_table[i-1].start+cfg_table[i-1].size))
		{
			printf("partition %d and %d overlaps.\n", i-1 ,i);
			goto fail_out;
		}
		parse_name(&cfg_table[i]);
		printf("part name %s, off %Ld, size %lld, plane %d, type %d, partition_type %s, fs %s, write_protection %s\n",
			cfg_table[i].name, cfg_table[i].start, cfg_table[i].size,
			cfg_table[i].flash_plane, cfg_table[i].flash_type,
			cfg_table[i].partition_type, cfg_table[i].filesystem, cfg_table[i].write_protection);
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

		/* Skip invisible partitions in kernel parameters */
		if(!cfg_table[i].invisible)
		{
			if (cfg_table[i].has_offset) {
				kernel_param_len += sprintf(&kernel_param[kernel_param_len], "%s@%s(%s),",
					size_buf, start_buf, cfg_table[i].name);
			} else {
				kernel_param_len += sprintf(&kernel_param[kernel_param_len], "%s(%s),",
					size_buf, cfg_table[i].name);
			}
		}

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

		if(!cfg_table[i].invisible)
		{
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

			if (!cfg_table[i].is_back_up)
			{
				sprintf(img_name, "%s.subimg", cfg_table[i].name);
				fprintf(fimg, "%s,mtd%d\n", img_name, i + 1);
			}
		} else if (!cfg_table[i].is_back_up)
			fprintf(fimg, "erase,mtd%d\n", i + 1);

		if(cfg_table[i].is_back_up)
			continue;
		strcpy(vt.name, cfg_table[i].name);
		vt.part1_version.major_version = ver_major;
		vt.part1_version.minor_version = ver_minor;
		vt.part1_start_blkind = cfg_table[i].start/block_size;
		vt.part1_blks = cfg_table[i].size/block_size;
		strcpy(vt.part_type,cfg_table[i].partition_type);

		vt.write_protect_flag = 0;
		if(strstr(cfg_table[i].write_protection, "normal"))
		{
			vt.write_protect_flag |= NORMAL_WP_MASK;
		}
		if(strstr(cfg_table[i].write_protection, "recovery"))
		{
			vt.write_protect_flag |= RECOVERY_WP_MASK;
		}

		{
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
		}
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
	if (fimg != NULL)
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
	if (fimg != NULL)
		fclose(fimg);
	return -1;
}

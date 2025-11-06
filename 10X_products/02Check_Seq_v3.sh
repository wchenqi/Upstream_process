#!/bin/bash
## 本脚本适用于@SRR9130238.1 J00118:334:HNGGWBBXX:6:1101:1164:1156/1 作为header的fastq文件重命名：
#1) 从输入文件夹中提取SRRid对应文件夹
#2) 统计子文件夹内序列对应的序列信息是否完整, 将输出文件进行划分
#3) 将可以使用的输出文件更改文件名后存入新的文件夹

## 关于序列可用性：
#1) 依据fastq开头文件注释信息行的结构判断序列信息是否完整
# @SRR9130238.1 J00118:334:HNGGWBBXX:6:1101:1164:1156/1
# 分别代表SRR的序列编号,测序仪编号,运行编号,flowcell编号,lane编号,tile编号:cluster的X轴坐标;cluster的Y轴坐标,序列读段信息
# 要求序列至少包含/1(Read1)和/2(Read2)信息
# 其他情况：/3 - 单端索引；/3/4 - 双端索引
#2) 输出结果新建文件夹：
#2-1) 为每个信息完整的SRR建立单独文件夹，重命名
#2-2) 生成单独表格记录舍弃SRR文件

## Notion:
# 如果本脚本上接parallel-fastq-dump,输出文件夹里面每个SRR一个文件夹，直接使用02ReName.sh就好

### 设置参数：
indir="/scratch/2025-11-05/med-wangcq/HanCS/GSE171993/01Fastq/"
outdir="/scratch/2025-11-05/med-wangcq/HanCS/GSE171993/02Rename/01test/"
srr_use="all"       # "/scratch/2025-11-05/med-wangcq/HanCS/GSE171993/srr_use.txt"
cores=8             # 并行线程数

### 定义函数
# 处理每个fastq文件：
# 使用范例：process_fastq "srr_dir" "$out_subdir" "wasteFile"
process_fastq(){
    # 需要信息：
    #1) SRR样本路径 —— 用于对内部文件循环
    #2) SRR样本名称 —— 用于命名文件和核对处理样本信息是否匹配
    #3) 输出路径 —— 用于存储
    #4) 问题样本记录文件
    local srr_dir=$1
    local srr_name=$(basename "$srr_dir")
    local out_subdir=$2
    local wasteFile=$3
    # 检查输入参数是否有问题：
    echo "开始处理样本 ${srr_name} 的文件"
    echo "文件路径 ${srr_dir}"
    echo "输出路径 ${out_subdir}"
    echo "失败样本记录文件 ${wasteFile}"
    # 建立输出文件夹
    [ -d $out_subdir ] || {
        mkdir -p $out_subdir
        echo "建立输出文件夹 ${out_subdir}"
    }
    # 得到全部fastq文件
    all_file=$(find "${srr_dir}" -type f -name "*.fastq.gz")
    # 对于路径中所有fastq文件循环
    for file in $all_file; do
        # 跳过非文件(目录，空匹配)
        [ -f $file ] || {
            echo $srr_name >> $wasteFile
            continue
        }
        # 读取文件第一行，提取两个信息[SRR样本信息和fastq文件类型]
        file_1stLine=$(zcat "$file" | head -n 1)
        srr_rcd=$(echo $file_1stLine | awk -F "\." '{print $1}' | sed 's/@//g')
        file_tp=$(echo $file_1stLine | awk -F '/' '{print $NF}')
        echo "SRR id recorded in file is ${srr_rcd}"
        echo "file type is ${file_tp}"
        # 这里添加判断，fastq中记录名称和文件夹名称是否匹配
        [ "$srr_rcd" == "$srr_name" ] || {
            echo "ERROR: Record ${srr_rcd} in fastq file not match dir name ${srr_name}\!\!"
            echo $srr_name >> $wasteFile
            continue
        }
        # 这里可以不动，遇到问题再说
        split_id=1
        printf -v split_id "%03d" "$split_id"
        # 重命名并复制
        case "$file_tp" in
            "1") new_name="${srr_rcd}_S1_L001_R1_${split_id}.fastq.gz" ;;
            "2") new_name="${srr_rcd}_S1_L001_R2_${split_id}.fastq.gz" ;;
            "3") new_name="${srr_rcd}_S1_L001_I1_${split_id}.fastq.gz" ;;
            "4") new_name="${srr_rcd}_S1_L001_I2_${split_id}.fastq.gz" ;;
            *) echo "未知类型: $file_tp，跳过 $file" ; continue ;;
        esac
        cp "$file" "${outdir}/${srr_rcd}/${new_name}"
        done
}

# 导出函数（让Parallel可见）
export -f process_fastq

### 正式调用脚本 ----------------------------------------------------
## 基本设置：
if [ ! -d "$outdir" ]; then
    mkdir -p "$outdir"
    echo "Making new DIRECTORY: ${outdir}"
else
    echo "${outdir} exists\!"
fi

# 这里建立文本文件记录问题样本
outfile="${outdir}/wasted_SRR.txt"
echo "WastedSRR" > "$outfile"  # 初始化舍弃文件

## v3修改
echo "SRR use: ${srr_use}"
# 如果指定处理srr样本(提供txt文件)
if [ $srr_use != "all" ]; then 
    srr_list=`cat $srr_use`
else
# 如果使用全部srr样本
    # 获取所有SRR ID列表
    srr_list=$(ls "$indir" | grep '^SRR' | sort -u)
fi
echo "$srr_list"

# 并行处理：-j 指定并行核心数（如8）
echo "$srr_list" | parallel -j "$cores" process_fastq "${indir}/{}" "${outdir}/{}" "$outfile"



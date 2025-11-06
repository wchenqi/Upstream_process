#!/bin/bash

#IDs=`cat "/data/med-wangcq/01Other/Zhiyang_Li/GSE200496/00Data/SRR_Acc_List.txt"`
#for i in $IDs
#do
#echo $i
#prefetch $i -O "/scratch/2024-12-13/med-wcq/ZhiYang.L/GSE200496/00SRA/" --max-size 300G
#done
PARALLEL_NUM=8
infile="/data/med-wangcq/Chenqi_W/03Splicing/02PublicData/GSE203275/00Data/RNAseq/SRR_Acc_List_test.txt"
OUTPUT_DIR="/scratch/2025-09-29/med-wangcq/WangCQ/01Splicing/02PublicData/GSE203275/RNAseq/01RawData/"
MAX_SIZE=300G

# 定义函数
download(){
    # 声明局部变量
    local sra_id="$1"
    # 下载
    prefetch -O "$OUTPUT_DIR" --max-size "MAX_SIZE" "$sra_id" && \
    echo "$sra_id Done"

}

# 导出变量到环境变量
export -f download
export OUTPUT_DIR MAX_SIZE  # 导出变量供函数使用

# 调用函数
# 记住后面的占位符_不能省略
cat $infile | xargs -n 1 -P $PARALLEL_NUM \
                    bash -c 'download "$@"' _

# 查看已下载和未下载文件数
array1=`cat $infile`
array2=`ls $OUTPUT_DIR`
# -d代表已下载
echo ${array1[@]} ${array2[@]} | sed 's/ /\n/g' | sort | uniq -d | wc -l
# -u代表未下载
echo ${array1[@]} ${array2[@]} | sed 's/ /\n/g' | sort | uniq -u | wc -l

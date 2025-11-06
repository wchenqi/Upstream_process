#!/bin/bash
## 指定参数
indir="/scratch/2025-11-05/med-wangcq/HanCS/GSE171993/01Fastq/"
outdir="/scratch/2025-11-05/med-wangcq/HanCS/GSE171993/02Rename/"
cores=8

## 定义函数
rename_fq(){
    ## 需要参数
    local srr_dir=$1   # 输入样本文件夹
    local srr_id=$(basename $1)     # srr id
    local out_subfile=$2            # 输出文件夹
    echo "输入样本文件夹：${srr_dir}"
    echo "SRR id ${srr_id}"
    echo "输出文件夹 ${out_subfile}"

    ## 处理参数
    # 建立文件夹
    [ -d $out_subfile ] || {
        mkdir -p $out_subfile
        echo "建立输出文件夹"
    }
    # 得到路径下所有文件名
    fq_files=$(find "$srr_dir" -type f -name "*fastq.gz")
    # 对每个样本文件夹里面的fastq文件循环处理
    for f in $fq_files
    do  
        #/paths/SRR14228560_1.fastq.gz
        type=$(basename "$f" | sed -n 's/.*_\([0-9]\)\.fastq\.gz/\1/p')
        echo "$type"
        case "$type" in
            "1")
                new_name="${srr_id}_S1_L001_R1_001.fastq.gz"
                ;;
            "2")
                new_name="${srr_id}_S1_L001_R2_001.fastq.gz"
                ;;
            "3")
                new_name="${srr_id}_S1_L001_I1_001.fastq.gz"
                ;;            
            "4")
                new_name="${srr_id}_S1_L001_I1_001.fastq.gz"
                ;;
            *)
                echo "⚠️  未知文件名: $(basename ${f}), 跳过文件"
                continue
                ;;
        esac
        # 重命名
        cp "$f" "${out_subfile}/${new_name}"
    done
    echo "${srr_id} rename DONE\!\!\!"
}

export -f rename_fq

## 运行函数
IDs=`ls $indir | grep "SR"`
echo "$IDs" | parallel -j $cores rename_fq "${indir}/{}" "${outdir}/{}"



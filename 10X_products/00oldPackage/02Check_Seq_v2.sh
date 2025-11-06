## 本脚本用于从系列文件中提取SRR accession，统计对应的序列信息是否完整
#1) 依据fastq开头文件注释信息行的结构判断序列信息是否完整
# @SRR9130238.1 J00118:334:HNGGWBBXX:6:1101:1164:1156/1
# 分别代表SRR的序列编号,测序仪编号，运行编号，flowcell编号，lane编号，tile编号；cluster的X轴坐标；cluster的Y轴坐标，序列读段信息
# 要求序列至少包含/1(Read1)和/2(Read2)信息 
# 其他情况：/3 - 单端索引；/3/4 - 双端索引
#2) 输出结果新建文件夹：
#2-1) 为每个信息完整的SRR建立单独文件夹，重命名
#2-2) 生成单独表格记录舍弃SRR文件

# 脚本还存在一个问题：
# 有的数据只有索引文件没有/缺损read文件,对路径下面这类文件的判断不知道怎么加到文件路径中

## 输入参数：
indir="/scratch/2025-11-05/med-wangcq/HanCS/GSE171993/01Fastq/"
outdir="/scratch/2025-11-05/med-wangcq/HanCS/GSE171993/02Rename/"

## 处理参数：
#1) 获取路径下所有SRR accession
cd $indir
srr_file=$(ls ./SRR*.fastq.gz* 2>/dev/null | grep -v '\.st$' | sed 's/_.*//' | sort -u)
# 初始化数组
usable=()
# 初始化舍弃SRR输出文件
outfile=${outdir}/wasted_SRR.txt
echo "Wasted SRR" > $outfile

echo "所有SRR前缀: $srr_file"
echo "=========================="

for srr in $srr_file; do  
    echo "处理: $srr"
    
    # 获取该SRR对应的所有文件（排除.st，处理分块文件）
    all_srr=$(ls SRR*.fastq.gz* 2>/dev/null | grep "$srr" | grep -v '\.st$' | sed 's/\.gz\.[0-9]\+$/.gz/' | sort -u)
    
    echo "匹配文件: $all_srr"
    
    # 将文件列表转换为数组并计算长度
    srr_array=($all_srr)
    echo ${srr_array[@]}
    len=${#srr_array[@]}
    echo "文件数量: $len"
    
    # 筛选：只有多于一个文件才添加到usable数组
    if [ $len -gt 1 ]; then
        usable+=("$srr")
        echo "✅ 添加到usable: $srr"
        
        ## 建立文件夹
        mkdir -p "${outdir}/${srr}"
        
        ## ------------------------ 这里注释掉了 ----------------------------------------------------
        # 获取所有完整文件名（不进行去重处理）
        # all_srr_full=$(ls SRR*.fastq.gz* 2>/dev/null | grep "$srr" | grep -v '\.st$')
        # srr_array_full=($all_srr_full)
        # echo ${srr_array_full[@]}

        # for file in "${srr_array_full[@]}"; do
        for file in "${srr_array[@]}"; do
            echo "处理文件: $file"
            
            # 获取文件类型（/1, /2, /3, /4）
            file_tp=$(zcat "$file" | head -n 1 | awk -F '/' '{print $NF}')
            echo "文件类型: $file_tp"
            
            # 处理分块ID
            # if [[ "$file" =~ \.gz\.[0-9]+$ ]]; then
                # 有数字后缀，提取并加2
            #     split_id=$(echo "$file" | grep -oE '\.gz\.[0-9]+$' | grep -oE '[0-9]+$')
            #     split_id=$((split_id + 2))
            # else
                # 没有数字后缀，设为1
                split_id=1
            # fi
            
            # 格式化split_id为3位数
            printf -v split_id "%03d" "$split_id"
            echo $split_id
        
            # 根据文件类型设置新文件名
            case "$file_tp" in
                "1")
                    new_name="${srr}_S1_L001_R1_${split_id}.fastq.gz"
                    ;;
                "2")
                    new_name="${srr}_S1_L001_R2_${split_id}.fastq.gz"
                    ;;
                "3")
                    new_name="${srr}_S1_L001_I1_001.fastq.gz"  # 索引文件通常不需要分块编号
                    ;;
                "4")
                    new_name="${srr}_S1_L001_I2_001.fastq.gz"  # 索引文件通常不需要分块编号
                    ;;
                *)
                    echo "⚠️  未知文件类型: $file_tp，跳过文件: $file"
                    continue
                    ;;
            esac
            
            echo "复制: $file → ${outdir}/${srr}/${new_name}"
            cp "$file" "${outdir}/${srr}/${new_name}"
            
        done
    else
        echo "❌ 跳过: $srr (文件数量不足)"
        echo $srr >> $outfile
    fi
    
    echo "当前usable: ${usable[@]}"
    echo "--------------------------"
done

# 最终结果
echo "=========================="
echo "处理完成!"
echo "可用的SRR样本 (${#usable[@]} 个): ${usable[@]}"

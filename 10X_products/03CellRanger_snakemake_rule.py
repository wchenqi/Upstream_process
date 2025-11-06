#!/usr/bin/python3
## 脚本运行环境: conda activate snakemake
## 本脚本使用snakemake实现对路径下所有脚本进行CellRanger并行处理
## 脚本编写参考deepseek

## 创建项目结构
# 输出路径包含config,log,scripts三个部分
# mkdir -p snakemake_workflow/{logs,Config,Scripts}
# cd snakemake_workflow

# 创建Snakefile
import os
import glob

# 配置文件
configfile: "/data/med-wangcq/01CondaEnv/02Git_repo/00MyGit_wchenqi/Upstream_process/10X_products/03CellRanger_snakemake.config.yaml"

# 自动发现样本函数
def get_sp():
    # 导入输入文件总路径
    indir = config["indir"]
    # 获取所有目录(样本)
    sp = [d for d in os.listdir(indir)
          if os.path.isdir(os.path.join(indir,d))]
    print(f"发现文件 {len(sp)} 个样本: {sp}")
    return sp

# 样本列表：
SAMPLES = get_sp()

# 制定规则 - 定义最终输出
rule all:
    input:
        expand("{outdir}/{sp}/outs/web_summary.html",outdir=config["outdir"],sp=SAMPLES)

# 制定规则 - 定义中间输出
rule CR_count:
    input:
        #检查路径下fastq文件是否存在并符合命名格式
        # 匹配 R1 读长的文件：{sp}_S*_L*_R1_*.fastq.gz
        read1 = os.path.join(config["indir"], "{sp}", "{sp}_S1_L001_R1_001.fastq.gz"),
        # 匹配 R2 读长的文件：{sp}_S*_L*_R2_*.fastq.gz
        read2 = os.path.join(config["indir"], "{sp}", "{sp}_S1_L001_R2_001.fastq.gz")
    # 指定通配符规则
    #wildcard_constraints:
    #    lane = r"\d{3}",
    #    index = r"\d{3}"
    # 配置输出标志文件
    output:
        web_summary = "{outdir}/{sp}/outs/web_summary.html",
        h5file = "{outdir}/{sp}/outs/filtered_feature_bc_matrix.h5"
    # cellranger运行需要的参数
    params:
        sp_id = "{sp}",
        output_dir = "{outdir}",
        transcriptome = config["transcriptome"],
        indir = os.path.join(config["indir"],"{sp}")
    # 运行线程数:
    threads: config["threads"]
    # 指定资源消耗:
    resources:
        mem_gb = config["mem_gb"],
        time = config["time_hours"]
    # 指定log文件:
    log:
        "{outdir}/logs/cellranger_{sp}.log"
    #before_script: 该版本
    #    """
    #    """
    # 运行脚本
    shell:
        """
        # 这里是原先的before_script部分
        echo "当前样本: {params.sp_id}"
        echo "输出路径: {params.output_dir}"
        # 检查路径输入文件是否存在：
        if [ ! -f {input.read1} ]; then
            echo "文件{input.read1}不存在"
            exit 1
        fi
        if [ ! -f {input.read2} ]; then
            echo "文件{input.read2}不存在"
            exit 1
        fi
        # 这里开始正式运行脚本
        echo "样本数量: $(find {params.indir} -maxdepth 1 -type d | wc -l)"
        mkdir -p {params.output_dir}/logs
        # 清除路径：
        rm -rf {params.output_dir}/{params.sp_id}
        cd {params.output_dir}
        cellranger count \
            --id={params.sp_id} \
            --transcriptome={params.transcriptome} \
            --fastqs={params.indir} \
            --sample={params.sp_id} \
            --localcores={threads} > {log} 2>&1
        #    --localmem={resources.mem_gb} > {log} 2>&1
        # 检查脚本是否运行完成
        if [ ! -f {output.web_summary} ]; then
            echo "Error: Cellranger failes for sample {wildcards.sp}" >> {log}
            exit 1
        fi
        """
    
# 到Snakefile的目录下，执行流程
# snakemake -cores 
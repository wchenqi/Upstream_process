#参考： 
# https://zhuanlan.zhihu.com/p/591140275
# https://zhuanlan.zhihu.com/p/536865827

outdir="/scratch/2025-11-05/med-wangcq/HanCS/GSE171993/01Fastq/"
mkdir -p $outdir
#IDs=`ls /scratch/2025-07-21/med-wangcq/02Other/GSE203275/00rawData/01scRNAseq/`
IDs=`ls /scratch/2025-11-05/med-wangcq/HanCS/GSE171993/00Raw/`
for i in $IDs
#SRR9894631 SRR9894632 SRR9894633 
#for i in SRR9894634 SRR9894635 SRR9894636 SRR9894637
do
echo $i
#outdir1=$outdir"/"$i
#echo $outdir1
#mkdir -p $outdir1
infile="/scratch/2025-11-05/med-wangcq/HanCS/GSE171993/00Raw/"$i"/"$i".sra"
echo $infile
#fastq-dump --split-files $infile -O $outdir1 --gzip
time (parallel-fastq-dump -t 40 -O $outdir --split-files --gzip -s $infile)
done

## 如果是ATAC-seq数据：https://zhuanlan.zhihu.com/p/415718382



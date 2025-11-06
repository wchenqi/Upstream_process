#!/bin/bash
## 本脚本用于下载summary statistics文件
# 设置并行数：
para_nm=5
indir="/data/med-wangcq/Chenqi_W/04GWAS/01Data/01GWAS_Catalog/00Data/00info/Harmonized/"
infile=$(ls $indir)
outdir="/data/med-wangcq/Chenqi_W/04GWAS/01Data/01GWAS_Catalog/00Data/02Harmonized/"

# 定义下载函数
download_url() {
    url=$1
    accession=$(basename "$url")
    echo "下载数据：${accession} 中..."
    wget $url
}
export -f download_url
# 实现并行处理
for cleaned_infile in $infile
do
echo $cleaned_infile
dos2unix "${indir}/${cleaned_infile}"
std=`echo $cleaned_infile | sed "s/_datalist.txt//g"` 
echo $std
mkdir -p "${outdir}/${std}"
cd "${outdir}/${std}"
pwd
parallel -j "$para_nm" download_url :::: "${indir}/${cleaned_infile}"
done
# 如果想实现并行处理
# parallel -j "$para_nm" --colsep '\t' download_url $infile


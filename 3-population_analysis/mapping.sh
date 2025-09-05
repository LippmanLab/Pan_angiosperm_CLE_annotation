#!/bin/bash

if [ $# -ne 18 ]; then
    echo "Usage: $0 <threads> <ref> <fastq1> <fastq2> <mem> <out> <index> <label> <min_MQ> <min_BQ> <adjust_MQ> <chr_name> <phred> <ILLUMINACLIP> <LEADING> <TRAILING> <SLIDINGWINDOW> <MINLEN>"
    echo "Usage: $0 <threads> <ref> <fastq1> <fastq2> <mem> <out> <index> <label> <min_MQ> <min_BQ> <adjust_MQ> <chr_name> <phred> <ILLUMINACLIP> <LEADING> <TRAILING> <SLIDINGWINDOW> <MINLEN>"
    echo "Number of arguments provided: $#"
    echo "Arguments provided: $@"
    exit 1
fi

echo "threads (argument 1): $1"
echo "ref (argument 2): $2"
echo "fastq1 (argument 3): $3"
echo "fastq2 (argument 4): $4"
echo "mem (argument 5): $5"
echo "out (argument 6): $6"
echo "index (argument 7): $7"
echo "label (argument 8): $8"
echo "min_MQ (argument 9): $9"
echo "min_BQ (argument 10): ${10}"
echo "adjust_MQ (argument 11): ${11}"
echo "chr_name (argument 12): ${12}"
echo "phred (argument 13): ${13}"
echo "ILLUMINACLIP (argument 14): ${14}"
echo "LEADING (argument 15): ${15}"
echo "TRAILING (argument 16): ${16}"
echo "SLIDINGWINDOW (argument 17): ${17}"
echo "MINLEN (argument 18): ${18}"

echo "Checking required tools..."
# Check if the required tools are available
tools=("trimmomatic" "bwa" "samtools" "bcftools" "tabix")
for tool in "${tools[@]}"; do
    if ! command -v ${tool} &> /dev/null; then
        echo "Error: ${tool} is not available. Please install it and try again."
        exit 1
    fi
done
echo "All required tools are available."

threads=$1
ref=$2
fastq1=$3
fastq2=$4
mem=$5
out=$6
index=$7
label=$8
min_MQ=$9
min_BQ=${10}
adjust_MQ=${11}
chr_name=${12}
phred=${13}
ILLUMINACLIP=${14}
LEADING=${15}
TRAILING=${16}
SLIDINGWINDOW=${17}
MINLEN=${18}

echo "Creating necessary directories..."
# Create necessary directories if they don't exist
mkdir -p ${out}/10_trim
mkdir -p ${out}/20_bam
mkdir -p ${out}/30_vcf
mkdir -p ${out}/log
echo "Directories created."

echo "Starting Step 1: Trimming with Trimmomatic..."
# Step 1: Trimming with Trimmomatic
trim1=${out}/10_trim/${index}_1.trim.fq.gz
unpaired1=${out}/10_trim/${index}_1.unpaired.fq.gz
trim2=${out}/10_trim/${index}_2.trim.fq.gz
unpaired2=${out}/10_trim/${index}_2.unpaired.fq.gz

if [ "$ILLUMINACLIP" == "NULL" ]; then 
    trimmomatic PE -threads ${threads} \
        -phred${phred} ${fastq1} ${fastq2} ${trim1} ${unpaired1} ${trim2} ${unpaired2} \
        LEADING:${LEADING} \
        TRAILING:${TRAILING} \
        SLIDINGWINDOW:${SLIDINGWINDOW} \
        MINLEN:${MINLEN} \
        >> ${out}/log/trimmomatic.log \
        2>&1
else
    trimmomatic PE -threads ${threads} \
        -phred${phred} ${fastq1} ${fastq2} ${trim1} ${unpaired1} ${trim2} ${unpaired2} \
        ILLUMINACLIP:${ILLUMINACLIP} \
        LEADING:${LEADING} \
        TRAILING:${TRAILING} \
        SLIDINGWINDOW:${SLIDINGWINDOW} \
        MINLEN:${MINLEN} \
        >> ${out}/log/trimmomatic.log \
        2>&1
fi
echo "Step 1: Trimming with Trimmomatic completed."
echo "Checking Trimmomatic output files..."
if [ ! -f "${trim1}" ] || [ ! -f "${trim2}" ]; then
    echo "Error: Trimmomatic output files not found."
    echo "Please check the Trimmomatic logs in ${out}/log/trimmomatic.log for more information."
    exit 1
fi
echo "Trimmomatic output files found."


echo "Starting Step 2: Alignment and processing..."
# Step 2: Alignment and processing
bwa mem -t ${threads} \
    ${ref} ${trim1} ${trim2} | \
    samtools fixmate -m \
        - \
        - | \
    samtools sort -m ${mem} \
        -@ ${threads} | \
    samtools markdup -r \
        - \
        - | \
    samtools view -b \
        -f 2 \
        -F 2048 \
        -o ${out}/20_bam/${index}.bam \
        >> ${out}/log/alignment.log \
        2>&1
echo "Step 2: Alignment and processing completed."

echo "Starting Step 3: Indexing BAM files..."
# Step 3: Indexing BAM files
samtools index ${out}/20_bam/${index}.bam \
    >> ${out}/log/samtools.log \
    2>&1
echo "Step 3: Indexing BAM files completed."

echo "Starting Step 4: Variant calling and filtering..."
# Step 4: Variant calling and filtering
bcftools mpileup -a AD,ADF,ADR \
    -B \
    -q ${min_MQ} \
    -Q ${min_BQ} \
    -C ${adjust_MQ} \
    -O u \
    -f ${ref} \
    ${out}/20_bam/${index}.bam | \
    bcftools call -vm \
        -f GQ,GP \
        -O u | \
    bcftools filter -i "INFO/MQ>=${min_MQ}" \
        -O z \
        -o ${out}/30_vcf/qtlseq.vcf.gz \
        >> ${out}/log/bcftools.log \
        2>&1
echo "Step 4: Variant calling and filtering completed."

echo "Starting Step 5: Indexing VCF files..."
# Step 5: Indexing VCF files
tabix -f \
    -p vcf \
    ${out}/30_vcf/qtlseq.vcf.gz \
    >> ${out}/log/tabix.log \
    2>&1
echo "Step 5: Indexing VCF files completed."

echo "Starting Step 6: Concatenating log files..."
# Step 6: Concatenating log files
cat ${out}/log/bcftools.log >> ${out}/log/bcftools.log
cat ${out}/log/tabix.log >> ${out}/log/tabix.log
echo "Step 6: Concatenating log files completed."

echo "Starting Step 7: Removing temporary files..."
# Step 7: Removing temporary files
rm -f ${out}/log/bcftools.log
rm -f ${out}/log/tabix.log
echo "Step 7: Removing temporary files completed."

echo "Pipeline completed successfully!"

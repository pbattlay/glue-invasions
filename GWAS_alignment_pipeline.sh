# Activate conda environment
source activate GWAS_Trepens

# Make list of all fastq files
ls -1 ./GWAS_Pipeline/data/*.fastq.gz > ./GWAS_Pipeline/data/fastq_files.txt

# Remove _1.fq.gz and _2.fq.gz from fastq files
for i in $(cat ./GWAS_Pipeline/data/fastq_files.txt); do
    S1 = ${i%_1.fq.gz}
    S2 = ${i%_2.fq.gz}
    if [ $S1 = $S2 ]; then
        echo $S1 >> ./GWAS_Pipeline/data/fastq_files_no_1_2.txt
    fi
done

# Run fastp on forward and reverse fastq files
for i in $(cat ./GWAS_Pipeline/data/fastq_files_no_1_2.txt); do
    fastp -i $i'_1.fq.gz' -I $i'_2.fq.gz' -o $i'_t_1.fq.gz' -O $i'_t_2.fq.gz' -h $i'_fastp.html' -j $i'_fastp.json' -w 8 
done

# Create bwa index of reference genome
bwa index ./GWAS_Pipeline/data/TrR_v6_haploid_reference.fasta

# Align fastq files to reference genome
for i in $(cat ./GWAS_Pipeline/data/fastq_files_no_1_2.txt); do
    bwa mem -t 8 ./GWAS_Pipeline/data/TrR_v6_haploid_reference.fasta $i'_t_1.fq.gz' $i'_t_2.fq.gz' > $i'_aligned.sam'
done

# Sort and convert sam files to bam files
for i in $(cat ./GWAS_Pipeline/data/fastq_files_no_1_2.txt); do
    samtools view -bS $i'_aligned.sam' | samtools sort -o $i'_aligned_sorted.bam'
done

# Remove duplicates from bam files
for i in $(cat ./GWAS_Pipeline/data/fastq_files_no_1_2.txt); do
    samtools rmdup $i'_aligned_sorted.bam' $i'_aligned_sorted_rmdup.bam'
done

# Index bam files
for i in $(cat ./GWAS_Pipeline/data/fastq_files_no_1_2.txt); do
    samtools index $i'_aligned_sorted_rmdup.bam'
done

# Deactivate conda environment
source deactivate


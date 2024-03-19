# Create list of bam files 
prefixes=("cg" "mis" "fr" "sw")
for prefix in "${prefixes[@]}"
do
    ls -1 ./GWAS_Pipeline/data/${prefix}_*.bam > ./GWAS_Pipeline/data/${prefix}_bam_files.txt
done

# Combine cg_ and mis_ files
cat ./GWAS_Pipeline/data/cg_bam_files.txt ./GWAS_Pipeline/data/mis_bam_files.txt > ./GWAS_Pipeline/data/nam_bam_files.txt

# Combine fr_ and sw_ files
cat ./GWAS_Pipeline/data/fr_bam_files.txt ./GWAS_Pipeline/data/sw_bam_files.txt > ./GWAS_Pipeline/data/eur_bam_files.txt

# Generate genotype likelihoods for each list of bam files
prefixes=("cg" "mis" "fr" "sw" "nam" "eur")

for prefix in "${prefixes[@]}"
do
    angsd -bam ./GWAS_Pipeline/data/${prefix}_bam_files.txt -fai ./GWAS_Pipeline/data/TrR_v6_haploid_reference.fasta -out ./GWAS_Pipeline/data/${prefix} -SNP_pval 1e-6 -doMajorMinor 2 -doMaf 1 -GL 1 -doGlf 2 -doPost 1 -minMaf 0.05 -minMapQ 30 -minQ 20 -doCounts 1 -P 8 
done

# Run PcAngsd using beagle file
for prefix in "${prefixes[@]}"
do
    pcangsd.py --beagle ./GWAS_Pipeline/data/${prefix}.beagle.gz --admix --maf 0.05 --oout ./GWAS_Pipeline/data/${prefix}
done

# Extract the first two principal components
for prefix in "${prefixes[@]}"
do
    awk '{print $1, $2}' ./GWAS_Pipeline/data/${prefix}.cov > ./GWAS_Pipeline/data/${prefix}_covariance.cov
done

#####################
### Manual Set up ###
#####################

# Add two columns to the cov file that specify the common garden and the continent the common garden was in. 
# Populations between 1-50 are from North America, 51- are from Europe
# Before running the GWAS, make sure that the order of the bam files in the BAM file list matches the order of the phenotype list.

# The following is a subset of the 12 GWAS commands that would be run in the terminal for each common garden and the two phenotypes (Survive to Flowering and Seedmass).
# The -minHigh flag is set to 15, though refer to the datatable for the actual number of high quality sites used in each analysis

# Seedmass uses -yQuant flag
angsd -fai ./GWAS_Pipeline/data/TrR_v6_haploid_reference.fasta -doAsso 5 -SNP_pval 1e-6 -doMajorMinor 2 -doMaf 1 -GL 1 -doGlf 2 -doPost 1 -minMaf 0.05 -minMapQ 30 -minQ 20 -minHigh 15 -doIBS 1 -doCounts 1 -cov ./GWAS_Pipeline/data/sw_covariance.cov -bam sw_bam_files.txt -yQuant sw_seedmass.yquant -P 8 -out ./GWAS_Pipeline/data/sw_seedmass_ASSO5

# Seedmass uses -yBin flag
angsd -fai ./GWAS_Pipeline/data/TrR_v6_haploid_reference.fasta -doAsso 5 -SNP_pval 1e-6 -doMajorMinor 2 -doMaf 1 -GL 1 -doGlf 2 -doPost 1 -minMaf 0.05 -minMapQ 30 -minQ 20 -minHigh 15 -doIBS 1 -doCounts 1 -cov ./GWAS_Pipeline/data/sw_covariance.cov -bam sw_bam_files.txt -yBin sw_flow.bin -P 8 -out ./GWAS_Pipeline/data/sw_flow_ASSO5


# The resulting files will contain the file extension of .beagle.gz, .lrt0.gz, .ibs.gz, and .arg.gz 
# To extract the necessary informatiton from the .lrt0.gz file for downstream analysis, the following commands are used: 

# Make a directory to store the csv files
mkdir ./GWAS_Pipeline/data/csv

#extract the necessary information from the .lrt0.gz file
for prefix in "${prefixes[@]}"
do 
    gunzip -c $prefix'_seedmass_ASSO5.lrt0.gz' | awk 'BEGIN {FS = "/t"; OFS = ","} {if($7>0) print $1, $2, $3, $4, $7, $10}' > ./GWAS_Pipeline/data/csv/$prefix'_seedmass_ASSO5.csv'
    gunzip -c $prefix'_flow_ASSO5.lrt0.gz' | awk 'BEGIN {FS = "/t"; OFS = ","} {if($7>0) print $1, $2, $3, $4, $7, $10}' > ./GWAS_Pipeline/data/csv/$prefix'_flow_ASSO5.csv'
done

# Make a list of the csv files
ls -1 ./GWAS_Pipeline/data/csv/*.csv > ./GWAS_Pipeline/data/csv_files.txt
# Add filename to each csv file
for i in $(cat ./GWAS_Pipeline/data/csv_files.txt); do
    awk 'BEGIN {FS = ","; OFS = ","} {print FILENAME, $0}' $i > $i'_FINAL.csv'
done

# Remove original header from each csv file
sed -i '1d' ./GWAS_Pipeline/data/csv/*_FINAL.csv

# Add a new header to each csv file
sed -i '1i RUN,CHR,Position,Major,Minor,LRT,Beta' ./GWAS_Pipeline/data/csv/*_FINAL.csv

# Remove _ASSO5.csv from each csv file
sed -i 's,_ASSO5.csv,,g' ./GWAS_Pipeline/data/csv/*_FINAL.csv

# Sort files into inversion directories for later ease of processing
# Create a new directory for each inversion
mkdir ./GWAS_Pipeline/data/{Hb7a1,Hb7a2,Hb7b,Hb9,Hb13}

# Make a list of the csv files
ls -1 ./GWAS_Pipeline/data/csv/*_FINAL.csv > ./GWAS_Pipeline/data/csv_files.txt

# Subset the csv files by CHR and Position that match 
#Hb7a1
for i in $(cat ./GWAS_Pipeline/data/csv_files.txt)
do 
    awk 'BEGIN {FS = ","; OFS = ","} {if($2 == "Chr04_Occ" && $3 >= 1 && $3 <= 3720000) print $0}' $i > ./GWAS_Pipeline/data/Hb7a1/{$i%_FINAL.csv}'.Hb7a1.csv'
done

# Mark down the number of rows in each file
wc -l ./GWAS_Pipeline/data/Hb7a1/*.Hb7a1.csv > ./GWAS_Pipeline/data/row_count.txt

# Add filename and inversion ID to each row
awk '{print FILENAME, $0}' ./GWAS_Pipeline/data/row_count.txt >> ./GWAS_Pipeline/data/row_counts.txt

#Hb7a2
for i in $(cat ./GWAS_Pipeline/data/csv_files.txt)
do 
    awk 'BEGIN {FS = ","; OFS = ","} {if($2 == "Chr04_Occ" && $3 >= 1400001 && $3 <= 8500000) print $0}' $i > ./GWAS_Pipeline/data/Hb7a2/{$i%_FINAL.csv}'.Hb7a2.csv'
done

# Mark down the number of rows in each file
wc -l ./GWAS_Pipeline/data/Hb7a2/*.Hb7a2.csv > ./GWAS_Pipeline/data/row_count.txt

# Add filename and inversion ID to each row
awk '{print FILENAME, $0}' ./GWAS_Pipeline/data/row_count.txt >> ./GWAS_Pipeline/data/row_counts.txt

#Hb7b
for i in $(cat ./GWAS_Pipeline/data/csv_files.txt)
do 
    awk 'BEGIN {FS = ","; OFS = ","} {if($2 == "Chr04_Occ" && $3 >= 50800001 && $3 <= 54500000) print $0}' $i > ./GWAS_Pipeline/data/Hb7b/{$i%_FINAL.csv}'.Hb7b.csv'
done

# Mark down the number of rows in each file
wc -l ./GWAS_Pipeline/data/Hb7b/*.Hb7b.csv > ./GWAS_Pipeline/data/row_count.txt

# Add filename and inversion ID to each row
awk '{print FILENAME, $0}' ./GWAS_Pipeline/data/row_count.txt >> ./GWAS_Pipeline/data/row_counts.txt

#Hb9
for i in $(cat ./GWAS_Pipeline/data/csv_files.txt)
do 
    awk 'BEGIN {FS = ","; OFS = ","} {if($2 == "Chr05_Occ" && $3 >= 3900001 && $3 <= 5100000) print $0}' $i > ./GWAS_Pipeline/data/Hb9/{$i%_FINAL.csv}'.Hb9.csv'
done

# Mark down the number of rows in each file
wc -l ./GWAS_Pipeline/data/Hb79/*.Hb9.csv > ./GWAS_Pipeline/data/row_count.txt

# Add filename and inversion ID to each row
awk '{print FILENAME, $0}' ./GWAS_Pipeline/data/row_count.txt >> ./GWAS_Pipeline/data/row_counts.txt

#Hb13
for i in $(cat ./GWAS_Pipeline/data/csv_files.txt)
do 
    awk 'BEGIN {FS = ","; OFS = ","} {if($2 == "Chr07_Occ" && $3 >= 1 && $3 <= 1800000) print $0}' $i > ./GWAS_Pipeline/data/Hb13/{$i%_FINAL.csv}'.Hb13.csv'
done

# Mark down the number of rows in each file
wc -l ./GWAS_Pipeline/data/Hb13/*.Hb13.csv > ./GWAS_Pipeline/data/row_count.txt

# Add filename and inversion ID to each row
awk '{print FILENAME, $0}' ./GWAS_Pipeline/data/row_count.txt >> ./GWAS_Pipeline/data/row_counts.txt

# Remove .csv extension from the row_counts.txt file
sed -i 's,.csv,,g' ./GWAS_Pipeline/data/row_counts.txt

# Split the column containing the FILENAMEs into two columns using "." as the delimiter
sed -i 's,.,\t,' ./GWAS_Pipeline/data/row_counts.txt

# Create a new column that divides 0.05 by the second column in the row_counts.txt file
awk 'BEGIN {FS = "\t"; OFS = "\t"} {print $0, 0.05/$2}' ./GWAS_Pipeline/data/row_counts.txt > ./GWAS_Pipeline/data/bonferroni_correction.txt

########
# DONE #
########






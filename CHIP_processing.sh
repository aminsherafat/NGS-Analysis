# __author__: Amin Sherafat
# Goal:  ChIP-seq processing, alignment, and display

#!/bin/bash
### Call program syntax: CHIP-seq-Processing.sh <input fastq file>
### bash CHIP-seq-Processing.sh /archive/fastq/treatA_chip_rep1.fastq | tee -a CHIP-seq.log

### Initialze variables
mkdir $PWD/CHIP_seq_processed/
outPath=$PWD/CHIP_seq_processed/
hg19_chromInfo="/archive/genomes/hg19/hg19_chromInfo.txt"
input1="$1"

### Designate genome to be used for mapping
genomeIdx=/archive/genomes/hg19/bowtieIndex/

### Making name prefix to append output suffix to
prefix1=`echo ${input1}| cut -d "." -f 1`

### 1: QC of the original data
echo "Running fastqc on the original data..."
fastqc -o $outPath ${input1}
echo "... fastqc has finished."
echo "${outPath}${prefix1}_clip.fastq"

### 2: Remove the adaptor sequence
echo "Running fastx_clipper to remove the adapter sequence
GATCGGAAGAGCTCGTATGCCGTCTTCTGCTTGAAA ..."
fastx_clipper -Q 33 -a GATCGGAAGAGCTCGTATGCCGTCTTCTGCTTGAAA -i ${input1} -o
${outPath}${prefix1}_clip.fastq
# Qc of the clipped file
fastqc -o $outPath ${outPath}${prefix1}_clip.fastq
echo "... fast_clipper has finished"

### 3: Trim the clipped data
echo "Trim reads of the original data with Qscores < 32 and minimum length > 30 bases
..."
fastq_quality_trimmer -Q 33 -t 32 -l 30 -i ${outPath}${prefix1}_clip.fastq -o
${outPath}${prefix1}_trim.fastq
echo "... fastx_trimmer has finished."

### 4: Mapping the trimmed data agains hg19 genome using bowtie2
echo "Mapping the trimmed data agains hg19 genome using bowtie2 ..."
bowtie2 -t -x $genomeIdx -1 ${outPath}${prefix1}_trim.fastq -2
${outPath}${prefix2}_trim.fastq -S ${outPath}${prefix1}.sam
bowtie -p3 -v2 -m1 -S $genomeIdx ${outPath}${prefix1}_trim.fastq
${outPath}${prefix1}.sam
echo "... mapping is done."

### 5: Extract chromosome 7 reads
echo "Extracting chr7 from alignment result ..."
grep -w chr7 ${outPath}${prefix1}.sam > ${outPath}${prefix1}_chr7.sam
echo " ... done"

### 6: Convert the resulting .sam file to a .bam
echo "Convert the resulting .sam file to .bam and .bed files sort it ..."
samtools view -S -b ${outPath}${prefix1}_chr7.sam > ${outPath}${prefix1}_chr7.bam

### Convert the resulting .bam file to a .bed and sort it
bedtools bamtobed -i ${outPath}${prefix1}_chr7.bam > ${outPath}${prefix1}_chr7.bed
sortBed -i ${outPath}${prefix1}_chr7.bed > ${outPath}${prefix1}_chr7_sorted.bed
echo "... done"

### 7: Create a bedgraph file
echo "Creating a bedgraph file and its header..."
bedtools genomecov -bg -i ${outPath}${prefix1}_chr7_sorted.bed -g $hg19_chromInfo >
${outPath}${prefix1}_chr7_sorted.bedgrapgh

### UCSC tracklines for bedgraph
awk -v 'BEGIN { print "browser position chr7"
 print "track type=bedGraph name=\"CHIP-seq-treatA\" description=\"CHIPseq-treatA_bedgraph\" visibility=full autoScale=on alwaysZero=on color=0,125,0
windowingFunction=maximum"}
 { print $0}' ${outPath}${prefix}_chr7_sorted.bedgrapgh >
${outPath}${prefix}_chr7_sorted_header.bedgrapgh
echo "... done"
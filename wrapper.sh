#!/bin/bash

### Call program syntax: wrapper.sh <firstInput1> <secondInput>
### bash wrapper.sh SRR412199_head.fastq SRR412199_tail.fastq 2>&1 | tee -a wrapper.log

### Program gets two ouput (head and tail files)
input1="$1"
input2="$2"
fileList=$input1" "$input2

### Output stores in folder processed which is located the program directory
mkdir $PWD/Processed
outPath=$PWD/Processed/

### Designate genome to be used for mapping
genome=/common/blast/data/dm3/dm3_Bowtie2Index/genome

### Make log file
touch wrapper.log

echo "**************************************************"
echo "**************************************************"
echo "The Wrapper programer check quality control the input file, clip, trim and mapped them agains drasophila genome"
echo "and then report the alignment rate and save corresponding quality control at each step."
echo "**************************************************"
echo "**************************************************"

echo "Drasophila genome reference: $genome"
echo "Input files: $input1 and $input2"
echo "Output directory: $outPath"
echo "Log file: $PWD/wrapper.log"
echo ""
echo "##################################################"

for file in ${fileList}
do
	echo "Start the preprocessing of $file..."

	### Making name prefix to append output suffix to 
	prefix=`echo ${file}| cut -d "." -f 1`	
	
	### QC of the original data 	
	echo "Running fastqc on the original data..."
	fastqc -o $outPath ${file}
	fastqc -o $outPath ${file} 
	echo "... fastqc has finished."

	### Remove the adaptor sequence
	echo "Running fastx_clipper to remove the adapter sequence TGCTTGGACTACATATGGTTGAGGGTTGTATGGAATTCTCGGGTGCCAAGG ..."
	fastx_clipper -Q 33 -a TGCTTGGACTACATATGGTTGAGGGTTGTATGGAATTCTCGGGTGCCAAGG -i ${file} -o ${outPath}${prefix}_clip.fastq 
	
	# Qc of the clipped file
	fastqc -o $outPath ${outPath}${prefix}_clip.fastq 
	echo "... fast_clipper has finished"

	### Trim the original data
	echo "Trim reads of the original data with Qscores < 30 and minimum length > 20 bases ..." 
	fastq_quality_trimmer -Q 33 -t 30 -l 20 -i ${file} -o ${outPath}${prefix}_trim.fastq 
	
	# The solution to pre-mapping
	#fastq_quality_trimmer -Q 33 -t 30 -l 20 -i ${outPath}${prefix}_clip.fastq -o ${outPath}${prefix}_trim.fastq
	
	# Qc of the trim file
	fastqc -o $outPath ${outPath}${prefix}_trim.fastq 
	echo "... fastx_trimmer has finished."
	
	### Map the original, clipped, trimmed data
	echo "Mapping the original data agains drasophila genome using bowtie2 ..."
	bowtie2 -t -x $genome -U ${file} -S ${outPath}${prefix}.sam 
	echo "... mapping is done."

	echo "Mapping the clipped data agains drasophila genome using bowtie2 ..."
	bowtie2 -t -x $genome -U ${outPath}${prefix}_clip.fastq -S ${outPath}${prefix}_clip.sam 
	echo "... mapping is done."
	
	echo "Mapping the trimmed data agains drasophila genome using bowtie2 ..."
	bowtie2 -t -x $genome -U ${outPath}${prefix}_trim.fastq -S ${outPath}${prefix}_trim.sam 
	echo "... mapping is done."

	echo "All processing steps of $file is done!"
	echo "##################################################"
done
 


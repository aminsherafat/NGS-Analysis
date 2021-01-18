# __author__: Amin Sherafat
#!/bin/bash
### Call program syntax: spliteGenes.sh inputfile outputfile
fileName="$1"
outFile="$2"
referenceFile="allGene_dat.txt"
#fileLines=`cat $fileName`

for line in $(cat $fileName); do 
	#echo $gene
	awk -v gene="$line" '{if ($1==gene) print $0}' $referenceFile >> $outFile
done 

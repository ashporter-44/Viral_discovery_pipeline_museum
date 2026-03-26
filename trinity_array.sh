#!/bin/bash
#SBATCH --time=150:00:00
#SBATCH --mem=320gb
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --job-name="hanta_trinity"
#SBATCH --array=0-11

## THREE THINGS TO CHECK BEFORE RUNNING##
## 1. How many libraries are being assembled via trinity? Change array range in SBATCH in trinity_array.sh
## 2. Set your sample name, raw and base directories in USER INPUT in trinity_array.sh
## 3. Define whether how many "_" delimiters are in your file name and change in line 44 


#load modules
module load trinity/2.15.1
module load jemalloc
module load perl
module load diamond

##USER INPUT##
#home directory
base="y"
raw=""
PATH=""

#nt and nr databases
#diamond_db="/scratch3/projects/datasets_bioref/diamond_db/nr_221128_v2015.dmnd"
diamond_db=""

##FILES##
# array to store filenames
files=()

# collecting each file name
## Change .fastq to .fastq.qz if gzipped!##

for file in "$raw"/*_R2.fastq; do
    # Check if the file exists
    if [ -f "$file" ]; then
            # Extract the string from the file name
            filename=$(basename "$file" | rev | cut -d'_' -f2- | rev)
#           # Add the extracted filename to the array
            files+=("$filename")
 #   else
       echo "File not found: $file"
    fi
done


# Print all filenames in the array for debugging
echo "Extracted filenames:"
for name in "${files[@]}"; do
    echo "$name"
done

MEMORY=192G
export OMP_NUM_THREADS=${SLURM_NTASKS}

file=${files[$SLURM_ARRAY_TASK_ID]}
qc="$base/$file/qc"
trim="$base/$file/trimmed"
mega="$base/$file/assembled-megahit"
trinity="$base/$file/assembled-trinity"
blastn="$base/$file/blastn"
blastx="$base/$file/blastx"
out_dir=$trinity/trinity_${file}
mkdir $out_dir
rm -f $out_dir/read_partitions
mkdir $MEMDIR/read_partitions
ln -s $MEMDIR/read_partitions $out_dir
# The last 3 lines create an environment variable for what will be run, echo the command that will be run so you can see it in the output file, and the eval actually runs it
CMD="Trinity --seqType fq --max_memory $MEMORY --left $trim/${file}_R1.fq --right $trim/${file}_R2.fq --CPU $SLURM_NTASKS --output $out_dir"
for ((i=0;i<${#ARRAY_TASK_ID[@]};i++)); do echo "${CMD}";done
eval "${CMD}"

##BLASTX ##
for file in "${files[@]}";
do
        #  #trinity nr search
    out_trinity_nr=$blastx/trinity_nr_${file}
    mkdir $out_trinity_nr
        diamond blastx --threads 32 --db $diamond_db --query $trinity/trinity_${file}.Trinity.fasta --out $out_trinity_nr/${file}.nr.txt --max-target-seqs 5 --more-sensitive --outfmt 6 length evalue staxids sscinames sskingdoms skingdoms sphylums --taxonnames $PATH/names.dmp --taxonmap $PATH/prot.accession2taxid.gz
        #viral hits
        outdir=$blastx/hits
        cat $out_trinity_nr/${file}.nr.txt | grep -A0 -E "virus|viral" > $outdir/${file}_trinity_nr.txt
done

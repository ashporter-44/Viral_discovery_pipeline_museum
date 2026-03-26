#!/bin/bash
#SBATCH --time=150:00:00
#SBATCH --mem=356gb
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --job-name="ML_trees"

module load clustal-omega
module load trimal
module load iqtree/3.0.1
module load mafft

#AA alignments for ML trees
clustalo --iterations 1000 -i glycoprotein_raw.fasta -o glyco_align.fa --force
clustalo --iterations 1000 -i nucleocapsid_raw.fasta -o nuclo_align.fa --force
clustalo --iterations 1000 -i rdrp_raw.fasta -o rdrp_align.fa --force

#nuc alignments for ML trees and beast
mafft --localpair --maxiterate 1000 nucleotide_rdrp.fasta > nucleotide_rdrp_align.fa
mafft --localpair --maxiterate 1000 nucleotide_glycoprotein.fasta > nucleotide_glycoprotein_align.fa
mafft --auto --maxiterate 1000 nucleotide_nucleocapsid.fasta > nucleotide_nucleocapsid_align.fa

#trimal for AA and nuc alignments
trimal -in nucleotide_rdrp_align.fa -out nuc_rdrp_trimal.fa -strict
trimal -in nucleotide_nucleocapsid_align.fa -out nuc_nuclo_trimal.fa -strict
trimal -in nucleotide_glycoprotein_align.fa -out nuc_glyco_trimal.fa -strict

#ML trees
iqtree3 -s nuc_glyco_trimal.fa -m TEST -b 1000 
iqtree3 -s nuc_rdrp_trimal.fa -m TEST -b 1000  
iqtree3 -s nuc_nuclo_trimal.fa -m TEST -b 1000 


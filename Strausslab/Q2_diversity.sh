#!/bin/bash

# ----------------SLURM Parameters----------------

#SBATCH -J q2_diveristy
#SBATCH --mem=40g
#SBATCH --time=21:00:00
#SBATCH --ntasks=1
#SBATCH -n 12
#SBATCH -D /ufrc/strauss/your_account/your_working_directory/merged  #PATH OF YOUR WORKING FOLDER
#SBATCH -o logs/q2_diveristy_%j.out
#SBATCH -A strauss

date;hostname;pwd

################################################################################
#
# This script performs standard alpha and beta diversity analyses
## 
################################################################################

# ----------------Housekeeping--------------------
cd models
rm -r diversity
rm -r rarefaction

# ----------------Load Modules--------------------
module load qiime2/2018.8

# ------------------Commands----------------------

qiime feature-table filter-features \
 --i-table ../features/table.qza \
 --m-metadata-file ../biom/feature-table.tsv \
 --p-no-exclude-ids \
 --o-filtered-table filtered-table.qza


qiime diversity alpha-rarefaction \
 --i-table filtered-table.qza \
 --p-max-depth 5166 \
 --i-phylogeny ../biom/rooted-tree-filtered.qza \
 --output-dir rarefaction \
 --m-sample-metadata-file  ../blabla           #INSERT PATH TO VALIDATED MAPPING FILE

 
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny ../biom/rooted-tree-filtered.qza \
  --i-table filtered-table.qza \
  --p-sampling-depth NUMBER \ 			#GO TO THE VISUALIZED TABLE.QZV FILE, INTERACTIVE SAMPLE DETAIL AND CHECK THE SAMPLING DEPTH. CHOOSE A NUMBER THAT ALLOWS YOU TO RETAIN THE MOST SEQUENCES POSSIBLE FOR THE MOST SAMPLES POSSIBLE AND ENTER IT BEFORE THE FWSLASH IN PLACE OF "NUMBER" AND DELETE THIS INSTRUCTION
  --p-n-jobs 12 \				#CHANGE NUMBER OF CORES TO YOUR NEEDS AND DELETE THIS INSTRUCTION
  --output-dir diversity \
  --m-sample-metadata-file  ../blabla           #INSERT PATH TO VALIDATED MAPPING FILE

cd diversity
qiime diversity alpha-group-significance \
  --i-alpha-diversity faith_pd_vector.qza \
  --o-visualization faith-pd-group-significance.qzv \
  --m-sample-metadata-file  ../blabla           #INSERT PATH TO VALIDATED MAPPING FILE


qiime diversity alpha-group-significance \
  --i-alpha-diversity evenness_vector.qza \
  --o-visualization evenness-group-significance.qzv \
  --m-sample-metadata-file  ../blabla           #INSERT PATH TO VALIDATED MAPPING FILE


qiime diversity beta-group-significance \
  --i-distance-matrix unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column PARAMETER \		#CHOOSE ONE OF YOUR PARAMETERS AND DELETE THIS INSTRUCTION
  --o-visualization unweighted-unifrac-biostimulant.qzv \
  --p-pairwise  \
  --m-sample-metadata-file  ../blabla           #INSERT PATH TO VALIDATED MAPPING FILE


qiime emperor plot \
  --i-pcoa unweighted_unifrac_pcoa_results.qza \
  --m-metadata-column PARAMETER \		#CHOOSE ONE OF YOUR NUMERICAL PARAMETERS AND DELETE THIS INSTRUCTION
  --o-visualization unweighted-unifrac-emperor-biostimulant.qzv \
  --m-sample-metadata-file  ../blabla           #INSERT PATH TO VALIDATED MAPPING FILE


module unload qiime2

date

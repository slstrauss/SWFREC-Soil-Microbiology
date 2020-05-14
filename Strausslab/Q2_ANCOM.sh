#!/bin/bash

# ----------------SLURM Parameters----------------

#SBATCH -J q2_ANCOM
#SBATCH --mem=40g
#SBATCH --time=21:00:00
#SBATCH --ntasks=1
#SBATCH -n 12
#SBATCH -D /ufrc/strauss/your_account/your_working_directory/merged  #PATH OF YOUR WORKING FOLDER
#SBATCH -o logs/q2_ANCOM_%j.out
#SBATCH -A strauss

date;hostname;pwd

################################################################################
#
# This script performs ANCOM on your data
# 
################################################################################

# ----------------Housekeeping--------------------
cd models
rm -r ancom
mkdir ancom

# ----------------Load Modules--------------------
module load qiime2

# ------------------Commands----------------------

###YOU MUST EXECUTE THIS COMMAND FOR EACH DIFFERENT PARAMETER YOU WANT TO ANALYZE###

qiime composition add-pseudocount \
    --i-table ../../input/inptab.qza \
    --o-composition-table composition.qza

qiime composition ancom \
   --i-table composition.qza \
   --m-metadata-column PARAMETER \		#CHOOSE ONE OF YOUR NUMERICAL PARAMETERS AND DELETE THIS INSTRUCTION
   --o-visualization ancom.qzv \
   --m-sample-metadata-file  ../blabla           #INSERT PATH TO VALIDATED MAPPING FILE

module unload qiime2

date

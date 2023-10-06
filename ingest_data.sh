#!/bin/bash
#$ -pe smp 2
#$ -l h_vmem=4G
#$ -l h_rt=1:0:0
#$ -cwd
#$ -j y

# Dataset to be processed
GSE="GSE214215"

# Where to output results
RES_DIR="./results"
TMP_DIR="/mnt/e/nextflow_temp/"

# Whether to download data from GEO/SRA
RUN_FETCHNGS=true

# Function creates subfolders within the results
create_folder () {
  if [ ! -e  "${RES_DIR}/$1" ]; then
    mkdir "${RES_DIR}/$1"
  fi
}

create_folder "${RES_DIR}"
create_folder "${GSE}"

# Set nextflow variables
export NXF_TMP="${TMP_DIR}"
export NXF_WORK="${TMP_DIR}/work"
export NXF_OPTS="-Xms1g -Xmx4g"

# Get data using fetchngs
if [ "${RUN_FETCHNGS}" = true ]; then

  # For feeding the study ID to fetchngs
  echo "${GSE}" > "${RES_DIR}/$GSE/study_id.csv"

  nextflow  \
    -log "${RES_DIR}/$GSE/.nextflow.log" \
    run nf-core/fetchngs \
    -r 1.10.0 \
    -profile conda \
    --input "${RES_DIR}/$GSE/study_id.csv" \
    --outdir "${RES_DIR}/$GSE" \
    -c "conf/fetchngs.conf"
fi

# Process data
# nextflow run nf-core/rnaseq \
#   -r 3.12.0 \
#   -profile docker \
#   --input "${RES_DIR}/$GSE/samplesheet/samplesheet.csv" \
#   --outdir "${RES_DIR}/$GSE" \
#   -c "conf/rnaseq.conf"

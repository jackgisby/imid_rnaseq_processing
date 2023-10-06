#!/bin/bash
#$ -pe smp 2
#$ -l h_vmem=4G
#$ -l h_rt=1:0:0
#$ -cwd
#$ -j y

set -e

# Dataset to be processed
GSE="GSM2879618"

# Where to output results
RES_DIR="./results"
TMP_DIR="/mnt/c/Users/Public/Downloads/temp/"

# Whether to download data from GEO/SRA
RUN_FETCHNGS=false

# Function creates subfolders within the results
create_folder () {
  if [ ! -e  "$1" ]; then
    mkdir "$1"
  fi
}

create_folder "${RES_DIR}"
create_folder "${RES_DIR}/${GSE}"
create_folder "${TMP_DIR}"
create_folder "${TMP_DIR}/${GSE}"

# Function to move files we want to keep to permenant results directory
cp_from_tmp () {
  cp -r "${TMP_DIR}/${GSE}/$1" "${RES_DIR}/${GSE}/$1"
}

# Set nextflow variables
export NXF_TMP="${TMP_DIR}"
export NXF_WORK="${TMP_DIR}/work"
export NXF_OPTS="-Xms1g -Xmx4g"

# Get data using fetchngs
if [ "${RUN_FETCHNGS}" = true ]; then

  # For feeding the study ID to fetchngs
  echo "${GSE}" > "${RES_DIR}/${GSE}/study_id.csv"

  nextflow  \
    -log "${RES_DIR}/${GSE}/fetchngs/.nextflow.log" \
    run nf-core/fetchngs \
    -r 1.10.0 \
    -profile docker \
    --input "${RES_DIR}/${GSE}/study_id.csv" \
    --outdir "${TMP_DIR}/${GSE}" \
    -c "conf/fetchngs.conf"

  create_folder "${RES_DIR}/${GSE}/samplesheet"
  cp_from_tmp "samplesheet/samplesheet.csv"
  cp_from_tmp "samplesheet/id_mappings.csv"
  cp_from_tmp "samplesheet/multiqc_config.yml"

fi

# Process data
# First time this pipeline is run, a salmon index will be created. In subsequent runs, use this index. 
#TODO: specify multiqc config?
nextflow \
  -log "${RES_DIR}/${GSE}/rnaseq/.nextflow.log" \
  run nf-core/rnaseq \
  -r 3.12.0 \
  -profile docker \
  --input "${RES_DIR}/$GSE/samplesheet/samplesheet.csv" \
  --outdir "${TMP_DIR}/${GSE}" \
  -c "conf/rnaseq.conf"

cp_from_tmp "multiqc"
cp_from_tmp "salmon"

# Remove temporary files, including fastqs
# rm -r "${TMP_DIR}"

#!/bin/bash
#$ -pe smp 2
#$ -l h_vmem=3G
#$ -l h_rt=1:0:0
#$ -wd ~/nextflow/imid_rnaseq/imid_rnaseq_processing/
#$ -o ~/nextflow/imid_rnaseq/job_out//
#$ -e ~/nextflow/imid_rnaseq/job_out//
#$ -j y

# qsub ~/nextflow/imid_rnaseq/imid_rnaseq_processing/ingest_data.sh

# TODO: Adapt for batch processing
# 1 - Add batch option
# 2 - Change results dir to reflect batch
# 3 - Make it so existing sample IDs are used instead of writing the study ID

## Settings
# Change the GSE variable, along with the -o and -e header
# Remove temporary files after pipeline completion

# Dataset to be processed
GSE=""

# Where to output results
RES_DIR="/data/home/${USER}/nextflow/imid_rnaseq/ingested_data/"
TMP_DIR="/data/scratch/${USER}/temp/"

# Nextflow profile to use
PROFILE="singularity"

# Whether to download data from GEO/SRA
RUN_FETCHNGS=true
RUN_RNASEQ=true
RESUME=false

if [ "${RESUME}" = true ]; then
  RESUME="-resume"
fi

# Fail on error
set -e

# Load nextflow
module load nextflow

nextflow help

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
export NXF_SINGULARITY_CACHEDIR="/data/scratch/${USER}/singularity/"

# Get data using fetchngs
if [ "${RUN_FETCHNGS}" = true ]; then

  # For feeding the study ID to fetchngs
  echo "${GSE}" > "${RES_DIR}/${GSE}/study_id.csv"

  nextflow  \
    -log "${RES_DIR}/${GSE}/fetchngs/.nextflow.log" \
    run nf-core/fetchngs \
    -r 1.10.0 \
    -profile "${PROFILE}" \
    --input "${RES_DIR}/${GSE}/study_id.csv" \
    --outdir "${TMP_DIR}/${GSE}" \
    -c "conf/fetchngs.config" \
    -c "conf/apocrita.config" \
    "${RESUME}"

  create_folder "${RES_DIR}/${GSE}/samplesheet"
  cp_from_tmp "samplesheet/samplesheet.csv"
  cp_from_tmp "samplesheet/id_mappings.csv"
  cp_from_tmp "samplesheet/multiqc_config.yml"

fi

# Process data
# First time this pipeline is run, a salmon index will be created. In subsequent runs, use this index. 
if [ "${RUN_RNASEQ}" = true ]; then
  nextflow \
    -log "${RES_DIR}/${GSE}/rnaseq/.nextflow.log" \
    run nf-core/rnaseq \
    -r 3.12.0 \
    -profile "${PROFILE}" \
    --input "${RES_DIR}/${GSE}/samplesheet/samplesheet.csv" \
    --outdir "${TMP_DIR}/${GSE}" \
    -c "conf/rnaseq.config" \
    -c "conf/apocrita.config" \
    "${RESUME}"

  cp_from_tmp "multiqc"
  cp_from_tmp "salmon"

fi

create_folder "${RES_DIR}/${GSE}/normalised_data"
create_folder "${RES_DIR}/${GSE}/qc"
create_folder "${RES_DIR}/${GSE}/gse_pheno"

# Use nextflow to create normalised dataset with edgeR (TMM) - from gene_counts.rds
# https://bioconductor.org/packages/release/bioc/vignettes/tximport/inst/doc/tximport.html
# https://github.com/nf-core/rnaseq/blob/3.12.0/bin/salmon_tximport.r
nextflow \
  -log "${RES_DIR}/${GSE}/post_processing/.nextflow.log" \
  run main.nf \
  -profile "${PROFILE}" \
  --input "${RES_DIR}/${GSE}/salmon/" \
  --outdir "${RES_DIR}/${GSE}" \
  --geo "${GSE}" \
  -c "conf/apocrita.config" \
  -c "conf/post_processing.config" \
  "${RESUME}"

# Remove temporary files, including fastqs
# rm -r "${TMP_DIR}"

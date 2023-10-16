#!/bin/bash
#$ -pe smp 2
#$ -l h_vmem=4G
#$ -l h_rt=1:0:0
#$ -wd ~/nextflow/imid_rnaseq/imid_rnaseq_processing/
#$ -o ~/nextflow/imid_rnaseq/job_out/
#$ -e ~/nextflow/imid_rnaseq/job_out/
#$ -j y

# qsub ~/nextflow/imid_rnaseq/imid_rnaseq_processing/ingest_data.sh

# Fail on error
set -e

# Load nextflow
module load nextflow

nextflow help

# Dataset to be processed
GSE="GSM2879618"

# Where to output results
RES_DIR="/data/home/${USER}/nextflow/imid_rnaseq/test"
TMP_DIR="/data/scratch/${USER}/temp/"

## Other settings
# Whether to download data from GEO/SRA
RUN_FETCHNGS=false
RUN_RNASEQ=false
RESUME=true

# Nextflow profile to use
PROFILE="singularity"

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

if [ "${RESUME}" = true ]; then
  RESUME="-resume"
fi
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
    -resume \
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

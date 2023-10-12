#!/usr/bin/env Rscript

# Script arguments
args = commandArgs(trailingOnly=TRUE)
if (length(args) < 1) {
  stop("Usage: qc.r <gse>", call.=FALSE)
}
gse <- args[1]

# Debug messages (stderr)
message("Input GSE      (Arg 1): ", gse)

# Load/install packages
if (!require("BiocManager", quietly = TRUE, character.only = TRUE)) install.packages("BiocManager")

for (p in c("GEOquery")) {
  if (!require(p, character.only = TRUE)) {
    BiocManager::install(p, suppressUpdates = TRUE)
    library(p, character.only = TRUE)
  }
}

# Assumes there is a GSEMatrix available
got_geo <- getGEO(gse, GSEMatrix = TRUE)
show(got_geo)

# Return an empty dataframe if pheno data is not successfully retrieved
pheno_data <- tryCatch(
  expr = phenoData(got_geo[[paste0(gse, "_series_matrix.txt.gz")]])@data,
  error = function(e) data.frame()
)
write.csv(pheno_data, "pheno_data.csv")

#!/usr/bin/env Rscript

# Script arguments
args = commandArgs(trailingOnly=TRUE)
if (length(args) < 1) {
  stop("Usage: normalise.r <path>", call.=FALSE)
}
path <- args[1]

# Debug messages (stderr)
message("Input path      (Arg 1): ", path)

# Load/install packages
if (!require("BiocManager", quietly = TRUE, character.only = TRUE)) install.packages("BiocManager")

for (p in c("edgeR", "SummarizedExperiment", "tximport")) {
    if (!require(p, character.only = TRUE)) {
        BiocManager::install(p, suppressUpdates = TRUE)
        library(p, character.only = TRUE)
    }
}

# Convert transcript-level quant files to gene-level counts with tximport
quant_files = list.files(path, pattern = "quant.sf", recursive = T, full.names = T)
names(quant_files) <- basename(dirname(fns))

tx2gene = read.csv(file.path(path, "salmon_tx2gene.tsv"), sep="\t", header = FALSE)
colnames(tx2gene) <- c("TXNAME", "GENEID", "SYMBOL")

# Counts = counts
# Abundances = TPM?
# Length = effective gene lengths
txi = tximport::tximport(quant_files, type = "salmon", tx2gene = tx2gene)
head(txi$counts)

# Normalisation based on https://bioconductor.org/packages/release/bioc/vignettes/tximport/inst/doc/tximport.html
cts <- txi$counts
normMat <- txi$length

# Obtaining per-observation scaling factors for length, adjusted to avoid
# changing the magnitude of the counts.
normMat <- normMat / exp(rowMeans(log(normMat)))
normCts <- cts / normMat

# Computing effective library sizes from scaled counts, to account for
# composition biases between samples.
eff.lib <- calcNormFactors(normCts) * colSums(normCts)

# Combining effective library sizes with the length factors, and calculating
# offsets for a log-link GLM.
normMat <- sweep(normMat, 2, eff.lib, "*")
normMat <- log(normMat)

# Creating a DGEList object for use in edgeR.
y <- DGEList(cts)
y <- scaleOffset(y, normMat)

saveRDS(y, "unfiltered_dgelist.rds")

# filtering without specifying the design
# design <- model.matrix(~condition, data = sampleTable)
keep <- filterByExpr(y)  # , design

y <- y[keep, ]

saveRDS(y, "filtered_dgelist.rds")

cpm <- edgeR::cpm(y, offset = y$offset, log = FALSE)
logcpm <- edgeR::cpm(y, offset = y$offset, log = FALSE)

write.csv(cpm, "filtered_cpm.csv")
write.csv(logcpm, "filtered_logcpm.csv")

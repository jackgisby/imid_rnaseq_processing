#!/usr/bin/env Rscript

# Load/install packages
if (!require("BiocManager", quietly = TRUE, character.only = TRUE)) install.packages("BiocManager")

for (p in c("edgeR", "SummarizedExperiment")) {
    if (!require(p, character.only = TRUE)) {
        BiocManager::install(p, suppressUpdates = TRUE)
        library(p, character.only = TRUE)
    }
}

# Load data as SummarizedExperiment
# Counts = counts
# Abundances = TPM?
# Length = effectie gene lengths
se = readRDS(file.path("salmon.merged.gene_counts.rds"))
print(assays(se))

# Normalisation based on https://bioconductor.org/packages/release/bioc/vignettes/tximport/inst/doc/tximport.html
cts <- assay(se, "counts")
normMat <- assay(se, "length")

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

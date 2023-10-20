#!/usr/bin/env Rscript

# Load/install packages
for (p in c("factoextra", "ggplot2", "ggpubr")) {
  if (!require(p, character.only = TRUE)) {
    install.packages(p, dependencies = TRUE)
    library(p, character.only = TRUE)
  }
}

theme_set(theme_pubr(border = TRUE))
theme_update(text = element_text(size = 8))

filtered_logcpm <- read.csv("filtered_logcpm.csv", row.names = 1)

res.pca <- prcomp(t(filtered_logcpm), center = TRUE, scale. = TRUE)

png("qc_pca.png")
factoextra::fviz_pca_ind(
    res.pca, 
    addEllipses=FALSE, 
    geom="point"
)
dev.off()

# docker build -t jackgisby/imid_rnaseq_processing .
# docker push jackgisby/imid_rnaseq_processing

# use the bioconductor container as a base
FROM bioconductor/bioconductor_docker:latest

# install extra packages
RUN R -e 'install.packages(c("factoextra", "ggplot2", "ggpubr"))'
RUN R -e 'BiocManager::install(c("GEOquery", "edgeR", "SummarizedExperiment", "tximport"))'

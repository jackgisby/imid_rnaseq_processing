// import local modules
include { GET_PHENO } from "$baseDir/modules/get_pheno.nf"
include { NORMALISE } from "$baseDir/modules/normalise.nf"
include { QC        } from "$baseDir/modules/qc.nf"

// main pipeline
workflow POST_PROCESSING {

    salmon_merged_counts = Channel.fromPath("$params.input")

    // Normalise count data
    NORMALISE(salmon_merged_counts)

    // Perform post-quantification QC
    QC(NORMALISE.out.filtered_logcpm)

    // Get clinical information from GEO
    geo_accession = Channel.value(params.geo)

    GET_PHENO(geo_accession)
}

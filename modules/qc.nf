// post-normalisation QC

process QC {

    publishDir "$params.outdir/qc/", mode: params.publish_dir_mode

    input:
    file filtered_logcpm

    output:
    path "qc_pca.png"

    script:
    """
    Rscript --verbose "$projectDir/bin/qc.R"
    """
}
// post-normalisation QC

process GET_PHENO {

    publishDir "$params.outdir/pheno/", mode: params.publish_dir_mode

    input:
    val geo

    output:
    path "pheno_data.csv"

    script:
    """
    Rscript --verbose "$projectDir/bin/get_pheno.R" \
            '$geo'
    """
}
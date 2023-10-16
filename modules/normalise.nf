// normalise the counts data

process NORMALISE {

    publishDir "$params.outdir/normalised_data/", mode: params.publish_dir_mode
    stageInMode 'copy'

    input:
    path salmon_out

    output:
    path "unfiltered_dgelist.rds"
    path "filtered_dgelist.rds"
    path "filtered_cpm.csv"
    path "filtered_logcpm.csv", emit: filtered_logcpm

    script:
    """
    ls
    echo "$projectDir"
    Rscript --verbose "$projectDir/bin/normalise.R" "."
    """
}
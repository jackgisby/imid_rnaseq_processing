#!/usr/bin/env nextflow

// enable module feature
nextflow.enable.dsl = 2

include { POST_PROCESSING } from './workflows/post_processing'

// run workflow in workflows/
workflow {
    POST_PROCESSING()
}

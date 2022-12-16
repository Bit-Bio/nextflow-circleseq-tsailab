#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Bit-Bio/nextflow-circleseq-tsailab
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/Bit-Bio/nextflow-circleseq-tsailab
----------------------------------------------------------------------------------------
*/


////////////////////////////////////////////////////
/* --         DEFAULT PARAMETER VALUES         -- */
////////////////////////////////////////////////////
nextflow.enable.dsl=2
// Some example defaults
params.gene_list = false
params.genome = false
params.gtf = false
params.project = "0045-Aculive"
//params.experiment = "EXP22001598-TsailabGuideSeq"
params.manifest_merged = false //Tried setting this in testing-min.config via nextflow config profiles testmin_local but didn't work - only works via command line
params.manifest_variant = false
params.run_descriptor = false
params.output = false   //as above
params.user_name = "alantracey"
params.temp = "/Users/alantracey/pipelines/nextflow-circleseq-tsailab/test"
params.human_date = new java.util.Date()
params.date = new java.util.Date().format( 'yyyyMMddHHmm')

if (params.output) {
    output_dir = params.output
}

date = params.date

//else if (!params.project or !params.experiment) {
//    throw new Exception("The flags --project and --experiment or --output is required.")
//}
//else if (params.run_descriptor) {
    // eg: s3://bitbio-project/0045-Aculive/EXP22001520-WGS-backbone-detection/
    //output_dir = 's3://bitbio-project/' + params.project + '/' + params.experiment + '/' + params.pipeline_name + '/' + params.run_descriptor + '/'
//} else {
    //output_dir = 's3://bitbio-project/' + params.project + '/' + params.experiment + '/' + params.pipeline_name + '/run/'
//}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
/* --                                                                     -- */
/* --                       HEADER LOG INFO                               -- */
/* --                                                                     -- */
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// Header log info
def summary = [:]

summary['Output dir']       = output_dir
summary['Profile']          = workflow.profile
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir   //run command has single dash (nf built-ins) for workflow options
summary['Run User']         = params.user_name
summary['AWS User']         = workflow.userName
summary['Manifest merged']         = params.manifest_merged   //params have double dash in run command (user defined)
summary['Manifest variant']         = params.manifest_variant
summary['Date']             = params.human_date

if (workflow.profile.contains('awsbatch')) {
    summary['AWS Region']   = params.awsregion
    summary['AWS Queue']    = params.awsqueue
    summary['AWS CLI']      = params.awscli

}

if (workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"

summary['Max memory']                 = params.max_memory
summary['Max CPUs']                   = params.max_cpus
summary['Max time']                   = params.max_time

log.info summary.collect { k,v -> "${k.padRight(20)}: $v" }.join('\n')
log.info "-\033[2m--------------------------------------------------\033[0m-"

/*
 *  ------------------------------------- SECTION - Create initial channels ---------------------------
 */

//avoid params.in or params.out (these are reserved variables)
//params.input is safer
input_M = Channel.fromPath(params.manifest_merged)
input_V = Channel.fromPath(params.manifest_variant)
genome_ch = Channel.fromPath(params.genome)
genomeindex_ch = Channel.fromPath(params.genome + ".*")
genomeindex = genomeindex_ch.collect()
root_dir_ch = Channel.fromPath(params.root_dir)

/*
 *  ------------------------------------- SECTION - PREPROCESSING -------------------------------------
 */




process link_fqsM {
    label 'process_low'
    input:
    path(manifest)
    path (root_dir)

    output:
    path ("*.fastq.gz"), emit: fastqs

    shell:
    """
    source /opt/conda/bin/activate /opt/conda/envs/nextflow-circleseq-tsailabsj_py3-10
    python /test/circleseq/circleseq/link_fq.py $manifest $root_dir
    """
}

process link_fqsV {
    label 'process_low'
    input:
    path(manifest)
    path (root_dir)

    output:
    path ("*.fastq.gz"), emit: fastqs

    shell:
    """
    source /opt/conda/bin/activate /opt/conda/envs/nextflow-circleseq-tsailabsj_py3-10
    python /test/circleseq/circleseq/link_fq.py $manifest $root_dir
    """
}


process all_variant {

    label 'process_low'
    publishDir "${params.output}/", mode: 'copy'
    //beforeScript 'echo "conda init bash ; conda activate nextflow-circleseq-tsailabsj_py2-7" >> ~/.bashrc ; source ~/.bashrc'

    input:
    path (manifest)
    path (genome_ch)
    path (genomeindex)
    path (fastqs)
    output:
    path ("data/StandardOutput/variants/*.txt")
    path ("data/StandardOutput/aligned/*_sorted.bam")
    path ("data/StandardOutput/identified/*.txt")
    path ("data/StandardOutput/visualization/*.svg")

    script:
    """
    source /opt/conda/bin/activate /opt/conda/envs/nextflow-circleseq-tsailabsj_py2-7
    python /test/circleseq/circleseq/circleseq.py all -m $manifest
    """
}

process all_merged {

    label 'process_low'
    publishDir "${params.output}/", mode: 'copy'
    //beforeScript 'echo "conda init bash ; conda activate nextflow-circleseq-tsailabsj_py2-7" >> ~/.bashrc ; source ~/.bashrc'

    input:
    path (manifest)
    path (genome_ch)
    path (genomeindex)
    path (fastqs)
    output:
    path ("data/MergedOutput/fastq/*.fastq.gz")
    path ("data/MergedOutput/aligned/*_sorted.bam")
    path ("data/MergedOutput/identified/*.txt")
    path ("data/MergedOutput/visualization/*.svg")

    script:
    """
    source /opt/conda/bin/activate /opt/conda/envs/nextflow-circleseq-tsailabsj_py2-7
    python /test/circleseq/circleseq/circleseq.py all -m $manifest
    """
}





workflow {
   genomefile = genome_ch.collect()
   fastqsM = link_fqsM(input_M, root_dir_ch)
   fastqsV = link_fqsV(input_V, root_dir_ch)
   allVariantChannel =all_variant(input_V, genomefile, genomeindex, fastqsV)
   allMergedChannel =all_merged(input_M, genomefile, genomeindex, fastqsM)
}


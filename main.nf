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
params.experiment = "EXP22001598-TsailabGuideSeq"
params.manifest = false //Tried setting this in testing-min.config via nextflow config profiles testmin_local but didn't work - only works via command line
params.run_descriptor = false
params.output = false   //as above
params.user_name = "alantracey"
params.temp = "/Users/alantracey/pipelines/nextflow-guideseq-tsailabsj/test"
params.human_date = new java.util.Date()
params.date = new java.util.Date().format( 'yyyyMMddHHmm')
params.forward = false
params.reverse = false
params.index1 = false
params.index2 = false

if (params.output) {
    output_dir = params.output
}

minfreq = params.min_frequency
minqual = params.min_quality
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
summary['Manifest']         = params.manifest   //params have double dash in run command (user defined)
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
input_ch = Channel.fromPath(params.manifest)
genome_ch = Channel.fromPath(params.genome)
//Doing collect on the genome_ch was key to getting process that should have run twice BUT was only running once, to run twice
//genomefile = genome_ch.collect()
//forward_ch = Channel.fromPath(params.forward)
//reverse_ch = Channel.fromPath(params.reverse)
//index1_ch = Channel.fromPath(params.index1)
//index2_ch = Channel.fromPath(params.index2)
root_dir_ch = Channel.fromPath(params.root_dir)
//result=`python /bin/parse_yaml.py`

/*
 *  ------------------------------------- SECTION - PREPROCESSING -------------------------------------
 */







process all {

    label 'process_low'
    publishDir "${params.output}/", mode: 'copy'
    input:
    path(manifest)
    path(genome_ch)
    path (fastqs)
    output:
    path ("demultiplexed/*.fastq")
    path ("umitagged/*.fastq")
    path ("consolidated/*.fastq")
    path ("aligned/*.sam")
    path ("identified/*.txt")
    path ("filtered/*.txt")
    path ("visualization/*.svg")

    script:
    """
    python /opt/conda/envs/nextflow-guideseq-tsailabsj/bin/guideseq.py all -m $manifest
    """
}




workflow {
   genomefile = genome_ch.collect()
   fastqs = root_dir_ch.collect().view()
   allChannel =all(input_ch, genomefile, fastqs)
}


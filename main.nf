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
params.variant = false
params.merge = false

if (params.output) {
    output_dir = params.output
}

date = params.date


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
summary['Merged analysis']          = params.merge
summary['Variant analysis']         = params.variant
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
in_M = Channel.fromPath(params.manifest_merged)
in_V = Channel.fromPath(params.manifest_variant)
genome_ch = Channel.fromPath(params.genome)
gf = genome_ch.collect()
genomeindex_ch = Channel.fromPath(params.genome + ".*")
gi = genomeindex_ch.collect()
root = Channel.fromPath(params.root)

/*
 *  ------------------------------------- SECTION - PREPROCESSING -------------------------------------
 */




process link_fqsM {
    label 'process_low'
    input:
    tuple val (sample), path (manifest), path (root_dir)

    output:
    path ("*.fastq.gz"), emit: fastqs

    shell:
    """
    link_fq.py $sample $manifest $root_dir
    """
}

process link_fqsV {
    label 'process_low'
    input:
    tuple val (sample), path (manifest), path (root_dir)

    output:
    path ("*.fastq.gz"), emit: fastqs

    shell:
    """
    source /opt/conda/bin/activate /opt/conda/envs/nextflow-circleseq-tsailabsj_py3-10
    python /test/circleseq/circleseq/link_fq.py $sample $manifest $root_dir
    """
}

process get_samplesM {
    // Write tmp_samples.csv
    label 'process_low'
    publishDir "${params.output}/", mode: 'copy'

    input:
    path(manifest)

    output:
    path("tmp_samples.csv")

    script:
    """
    get_samples.py $manifest
    echo "Written tmp_samples.csv"
    """
}

process get_samplesV {
    // Write tmp_samples.csv
    label 'process_low'
    publishDir "${params.output}/", mode: 'copy'

    input:
    path(manifest)

    output:
    path("tmp_samples.csv")

    script:
    """
    get_samples.py $manifest
    echo "Written tmp_samples.csv"
    """
}

process align_m {
    if ( workflow.profile == "awsbatch" ) {
    label 'process_medium'
    }
    else    {
    label 'process_low'
    }
    publishDir "${params.output}/", mode: 'copy'

    input:
    tuple val (sample), path (manifest)
    path (genome)
    path (genome_index)
    path (fastqs)
    output:
    path ("data/MergedOutput/aligned/*.bam")

    script:
    """
    python /test/circleseq/circleseq/circleseq.py align -m $manifest -s $sample
    """
}

process align_v {
    if ( workflow.profile == "awsbatch" ) {
    label 'process_medium'
    }
    else    {
    label 'process_low'
    }
    publishDir "${params.output}/", mode: 'copy'

    input:
    tuple val (sample), path (manifest)
    path (genome)
    path (genome_index)
    path (fastqs)
    output:
    path ("data/StandardOutput/aligned/*.bam")

    script:
    """
    python /test/circleseq/circleseq/circleseq.py align -m $manifest -s $sample
    """
}

process identify_m {
    label 'process_low'
    publishDir "${params.output}/", mode: 'copy'

    input:
    tuple val (sample), path (manifest)
    path (read_files)
    path (genome)
    path (genome_index)
    output:
    path ("data/MergedOutput/identified/*.txt")

    script:
    """
    mkdir -p data/MergedOutput/aligned/
    echo *.bam
    echo $sample
    cp ${sample}.bam data/MergedOutput/aligned/
    cp control_${sample}.bam data/MergedOutput/aligned/
    source /opt/conda/bin/activate /opt/conda/envs/nextflow-circleseq-tsailabsj_py2-7
    python /test/circleseq/circleseq/circleseq.py identify -m $manifest -s $sample
    """
}

process identify_v {
    label 'process_low'
    publishDir "${params.output}/", mode: 'copy'

    input:
    tuple val (sample), path (manifest)
    path (read_files)
    path (genome)
    path (genome_index)
    output:
    path ("data/StandardOutput/identified/*.txt")

    script:
    """
    mkdir -p data/StandardOutput/aligned/
    echo *.bam
    echo $sample
    cp ${sample}_sorted.bam data/StandardOutput/aligned/
    cp control_${sample}_sorted.bam data/StandardOutput/aligned/
    source /opt/conda/bin/activate /opt/conda/envs/nextflow-circleseq-tsailabsj_py2-7
    python /test/circleseq/circleseq/circleseq.py identify -m $manifest -s $sample
    """
}

process visualize_m {
    label 'process_low'
    publishDir "${params.output}/", mode: 'copy'

    input:
    tuple val (sample), path (manifest)
    path (identified)
    output:
    path ("data/MergedOutput/visualization/*.svg")

    script:
    """
    mkdir -p data/MergedOutput/identified/
    echo *.txt
    echo $sample

    cp ${sample}_*.txt data/MergedOutput/identified/
    source /opt/conda/bin/activate /opt/conda/envs/nextflow-circleseq-tsailabsj_py2-7
    python /test/circleseq/circleseq/circleseq.py visualize -m $manifest -s $sample
    """
}


process visualize_v {
    label 'process_low'
    publishDir "${params.output}/", mode: 'copy'

    input:
    tuple val (sample), path (manifest)
    path (identified)
    output:
    path ("data/StandardOutput/visualization/*.svg")

    script:
    """
    mkdir -p data/StandardOutput/identified/
    echo *.txt
    echo $sample

    cp ${sample}_*.txt data/StandardOutput/identified/
    source /opt/conda/bin/activate /opt/conda/envs/nextflow-circleseq-tsailabsj_py2-7
    python /test/circleseq/circleseq/circleseq.py visualize -m $manifest -s $sample
    """
}


process variant {
    label 'process_low'
    publishDir "${params.output}/", mode: 'copy'

    input:
    tuple val (sample), path (manifest)
    path (aligned)
    path (identified)
    output:
    path ("data/StandardOutput/visualization/*.svg")

    script:
    """
    mkdir -p data/StandardOutput/aligned/
    mkdir -p data/StandardOutput/identified/
    echo *.txt
    echo *.bam
    echo $sample

    cp ${sample}_sorted.bam data/StandardOutput/aligned/
    cp control_${sample}_sorted.bam data/StandardOutput/aligned/
    cp ${sample}_identified_matched.txt data/StandardOutput/identified/
    source /opt/conda/bin/activate /opt/conda/envs/nextflow-circleseq-tsailabsj_py2-7
    python /test/circleseq/circleseq/circleseq.py visualize -m $manifest -s $sample
    """
}


workflow {

    if (params.merge == true) {

       sChM = get_samplesM(in_M).splitCsv()
       fq_in = sChM.combine(in_M)    //can only combine 1 channel at a time, hence 2 combine statements
               .combine(root)
       fm = link_fqsM(fq_in)
       sm = sChM
            .combine(in_M)
       //3 Collect statements below necessary for parallel execution.  Final collect makes ALL samples available to next
       //process which then uses $sample to select from these
       ma = align_m(sm, \
            gf.collect(), \
            gi.collect(), \
            fm.collect()) | collect
       //Final collect makes ALL sample files available to visualize in one list, then use $sample to select from this
       mi = identify_m(sm, ma, gf.collect(), gi.collect()) | collect
       visualize_m(sm, mi)
    }
    if (params.variant == true) {

       sChV = get_samplesV(in_V).splitCsv()
       fq_in = sChV.combine(in_V)    //can only combine 1 channel at a time, hence 2 combine statements
               .combine(root)
       fv = link_fqsV(fq_in)
       sv = sChV
            .combine(in_V)
       //3 Collect statements below necessary for parallel execution.  Final collect makes ALL samples available to next
       //process which then uses $sample to select from these
       av = align_v(sv, \
            gf.collect(), \
            gi.collect(), \
            fv.collect()) | collect
       //Final collect makes ALL sample files available to visualize in one list, then use $sample to select from this
       vi = identify_v(sv, av, gf.collect(), gi.collect()) | collect
       visualize_v(sv, vi)
       var = variant(sv, av, vi)
    }

}


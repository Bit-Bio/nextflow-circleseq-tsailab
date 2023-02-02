<img src="assets/bit_bio_logo_new.svg" width="300">

# Introduction

This is a repository for CIRCLE-seq analytical software, which takes sample-specific paired end FASTQ files as input and produces a list of CIRCLE-seq detected off-target cleavage sites as output.



## Required docker images

017309998751.dkr.ecr.us-east-1.amazonaws.com/nextflow-circleseq-tsailab:python2.7

017309998751.dkr.ecr.us-east-1.amazonaws.com/nextflow-circleseq-tsailab:python3

The python2.7 image is required for the Circleseq package.


## Input data

Required inputs:
```
--genome <genome.fa>
--manifest_merged <manifest for merged analysis>
--manifest_variant <manifest for variant analysis>
--output <path to directory for collecting output files>
 -work-dir <nextflow working files>
 -profile <eg awsbatch, test_min_local etc>
--root <root directory where input fastq.gz and yaml are stored>
```
 
## Bit-Bio/nextflow-circleseq-tsailab

This is a Nextflow pipeline that performs circle-sequencing analysis, specifically aimed at providing support for the Tsa-ilab at the CRG. The pipeline is hosted on Github at https://github.com/Bit-Bio/nextflow-circleseq-tsailab

Default Parameter Values
The following parameters are set by default in the pipeline:

params.gene_list = false
params.genome = false
params.gtf = false
params.project = "0045-Aculive"
params.manifest_merged = false
params.manifest_variant = false
params.run_descriptor = false
params.output = false
params.user_name = "alantracey"
params.temp = "/Users/alantracey/pipelines/nextflow-circleseq-tsailab/test"
params.human_date = new java.util.Date()
params.date = new java.util.Date().format('yyyyMMddHHmm')
params.variant = false
params.merge = false
Log Info
The pipeline includes header log information that is recorded when the pipeline is run. The following information is recorded:

Output dir
Profile
Launch dir
Working dir
Script dir
Run User
AWS User
Manifest merged
Manifest variant
Merged analysis
Variant analysis
Date
AWS Region (if using awsbatch profile)
AWS Queue (if using awsbatch profile)
AWS CLI (if using awsbatch profile)
Container (if using a container engine)
Max memory
Max CPUs
Max time
Preprocessing
The preprocessing stage of the pipeline performs linking of FASTQ files using the link_fqsM and link_fqsV processes. The input to these processes are the sample, the manifest file path and the root directory path. The output from these processes are the linked FASTQ files. The processes are run within the 017309998751.dkr.ecr.us-east-1.amazonaws.com/nextflow-circleseq-tsailab:python3 container.

Running the pipeline
To run the pipeline, you will need to specify the required inputs such as the manifest and genome files, as well as the output directory. You can also specify the user name and the date. To run the pipeline with a specific profile (such as awsbatch), you can specify this as an option in the command line. For example:

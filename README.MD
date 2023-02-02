<img src="assets/bit_bio_logo_new.svg" width="300">

# Introduction

This is a repository for CIRCLE-seq analytical software, which takes sample-specific paired end FASTQ files as input and produces a list of CIRCLE-seq detected off-target cleavage sites as output.



## Required docker images

017309998751.dkr.ecr.us-east-1.amazonaws.com/nextflow-circleseq-tsailab:python2.7

017309998751.dkr.ecr.us-east-1.amazonaws.com/nextflow-circleseq-tsailab:python3

The python2.7 image is required for the Circleseq package, python3 is required for various packages and modules.


## Input data

Input data can be found in /test/data/input

Required inputs:
```
--genome <eg https://github.com/Bit-Bio/nextflow-circleseq-tsailab/blob/master/test/data/input/CIRCLEseq_test_genome.fa>
--manifest_merged <manifest for merged analysis>
--manifest_variant <manifest for variant analysis>
--output <path to directory for collecting output files>
 -work-dir <nextflow working files>
 -profile <eg awsbatch, test_min_local etc>
--root <root directory where input fastq.gz and yaml are stored>
```
 
## Bit-Bio/nextflow-circleseq-tsailab



### Default Parameter Values
The following parameters are set by default in the pipeline:
```
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
```

### Log Info
The pipeline includes header log information that is recorded when the pipeline is run. The following information is recorded:
```
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
```

### Preprocessing
The preprocessing stage of the pipeline performs linking of FASTQ files using the link_fqsM and link_fqsV processes. The input to these processes are the sample, the manifest file path and the root directory path. The output from these processes are the linked FASTQ files. The processes are run within the 017309998751.dkr.ecr.us-east-1.amazonaws.com/nextflow-circleseq-tsailab:python3 container or the 017309998751.dkr.ecr.us-east-1.amazonaws.com/nextflow-circleseq-tsailab:python2.7 container.  Container switching is controlled within the processes inside main.nf.

### Pipeline flavours
2 analyses can be run - merged and/or variant.  Select `--merge` and or `--variant` to choose which to run

### Running the pipeline
To run the pipeline, you will need to specify the required inputs such as the manifest and genome files, as well as the output directory. You can also specify the user name and the date. To run the pipeline with a specific profile (such as awsbatch), you can specify this as an option in the command line. 

### Minimum local
```
nextflow run main.nf -profile testmin_local --genome <CIRCLEseq_test_genome.fa> --manifest_merged <two_sample_min_local_manifest_merged.yaml> --manifest_variant <two_sample_min_local_manifest.yaml> -work-dir ./work_min -with-report report.html -with-dag flowchart.png --output /Users/alantracey/Aculive/circleseq/min_output -with-docker aa --root /Users/alantracey/Aculive/circleseq/input/ -with-timeline timeline.html --merge
```

### Example minimum merged.yaml
Variant yaml is just a copy of this with merged_analysis: False and variant_analysis: True.  We may want to have separate main.nf files for these 2 variations of the pipeline since in reality I think the decision is to only run merged (I didn't know this when I wrote the nextflow).
```

bwa: bwa
samtools: samtools

window_size: 3
mapq_threshold: 50
start_threshold: 1
gap_threshold: 3
mismatch_threshold: 6
merged_analysis: True
variant_analysis: False

samples:
    TestSample1:
        target: GAGTCCGAGCAGAAGAAGAANGG
        read1: /Users/alantracey/Aculive/circleseq/input/TEST1.r1.fastq.gz
        read2: /Users/alantracey/Aculive/circleseq/input/TEST1.r2.fastq.gz
        controlread1: /Users/alantracey/Aculive/circleseq/input/TEST1_control.r1.fastq.gz
        controlread2: /Users/alantracey/Aculive/circleseq/input/TEST1_control.r2.fastq.gz
        description: TestCell1
    TestSample2:
        target: GAGTCCGAGCAGAAGATGAANGG
        read1: /Users/alantracey/Aculive/circleseq/input/TEST2.r1.fastq.gz
        read2: /Users/alantracey/Aculive/circleseq/input/TEST2.r2.fastq.gz
        controlread1: /Users/alantracey/Aculive/circleseq/input/TEST2_control.r1.fastq.gz
        controlread2: /Users/alantracey/Aculive/circleseq/input/TEST2_control.r2.fastq.gz
        description: TestCell2
```

### Minimum AWSbatch
(With the --merge only being set here, only the merged yaml is being read)
```
nextflow main.nf  --genome "s3://bitbio-project/0045-Aculive/EXP22002494-TsailabCircleSeq/min_test/CIRCLEseq_test_genome.fa"  --manifest_merged "s3://bitbio-project/0045-Aculive/EXP22002494-TsailabCircleSeq/min_test/two_sample_min_local_manifest_merged_s3_jon.yaml"  --manifest_variant "s3://bitbio-project/0045-Aculive/EXP22002494-TsailabCircleSeq/min_test/two_sample_min_local_manifest_s3.yaml" -with-report report.html  -with-dag flowchart.png  -with-timeline timeline.html --output "s3://bitbio-pipelines/nextflow-circleseq-tsailab/min_testa/outputa"  -work-dir "s3://bitbio.nextflow/work/circleseq-tsailab/work" -profile awsbatch --root "s3://bitbio-project/0045-Aculive/EXP22002494-TsailabCircleSeq/min_test/" --merge
```

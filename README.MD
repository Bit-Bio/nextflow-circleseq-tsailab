<img src="assets/bit_bio_logo_new.svg" width="300">

# Introduction

This is a repository for CIRCLE-seq analytical software, which takes sample-specific paired end FASTQ files as input and produces a list of CIRCLE-seq detected off-target cleavage sites as output.

Comparison of the CIRCLE-seq and CHANGE-seq pipelines saw many more sites detected via the CHANGE-seq pipeline.  Shengdar Tsai whose lab wrote both of these pipelines suggested that the CHANGE-seq pipeline is better, so we are using this.




## Min test data


```bash
aws batch submit-job  --job-name alan_changeseq_nf  --job-queue highpriority-eb16b4c0-d8dc-11ea-922f-0a0207fddeaf  --retry-strategy '{"attempts":2,"evaluateOnExit":[{"onStatusReason": "*","onReason": "*","onExitCode": "*","action": "RETRY"}]}'  --job-definition nextflow:21  --container-overrides '{"command":["Bit-Bio/nextflow-changeseq-tsailab","-r","master","--genome","s3://bitbio-project/0045-Aculive/EXP22002494-TsailabCircleSeq/min_test/CIRCLEseq_test_genome.fa","--manifest","s3://bitbio-project/0045-Aculive/EXP22002494-TsailabCircleSeq/min_test/two_sample_s3_alan.yaml","-with-report","report.html","-with-dag","flowchart.png","-with-timeline timeline.html","--output","s3://bitbio-pipelines/nextflow-circleseq-tsailab/min_testb/outputb","-work-dir","s3://bitbio-pipelines/nextflow-changeseq-tsailab/temp/","-profile","awsbatch","--root","s3://bitbio-project/0045-Aculive/EXP22002494-TsailabCircleSeq/min_test/", "clean", "before"]}'
```
 



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

```

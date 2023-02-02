<img src="assets/bit_bio_logo_new.svg" width="300">

# Introduction

This is a repository for CIRCLE-seq analytical software, which takes sample-specific paired end FASTQ files as input and produces a list of CIRCLE-seq detected off-target cleavage sites as output.



## Required docker images

017309998751.dkr.ecr.us-east-1.amazonaws.com/nextflow-circleseq-tsailab:python2.7

017309998751.dkr.ecr.us-east-1.amazonaws.com/nextflow-circleseq-tsailab:python3

`docker build -t <image tag> -f <Process / Module DockerFile> .`

`docker build -t template-container:latest -f containers/Base.Dockerfile .`

If you are using a M1(+) Mac, include the `--platform linux/amd64` flag

`docker build --platform linux/amd64 -t template-container:latest -f containers/Base.Dockerfile .`

## Push to AWS ECR 

The only thing to change here is the image name, and the tag. `(image-name:tag)`

1. `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 017309998751.dkr.ecr.us-east-1.amazonaws.com`
2. `Docker tag template-container:latest 017309998751.dkr.ecr.us-east-1.amazonaws.com/template-container:latest`
3. Log on to AWS and create the `template-container` repository on the ECR
4. `Docker push 017309998751.dkr.ecr.us-east-1.amazonaws.com/template-container:latest`

## To link to a new repo

Remove the template repo as the remote
 
`git remote rm origin`

Add the new repo as the remote

`git remote add origin <url>`

Push your first code 

`git push -u origin main`

## Useful code

To run in interactive mode 

`docker run -it template-container:latest /bin/bash`

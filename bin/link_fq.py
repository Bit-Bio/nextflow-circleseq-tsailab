#!/usr/bin/env python3

import sys
import yaml
import os
import boto3
'''
Written to create symlinks to fastqs from sanitised yaml
'''



def loadYaml(yamlfile, root_dir):
    with open(yamlfile, 'r') as yaml_in:
        yaml_object = yaml.safe_load(yaml_in)
        fastqs_dir=yaml_object['samples']

    #print("Creating symlinks for input to demultiplex process", root_dir)
    fastqLinks=[]
    ignore=["target","description"]
    for sample, fastqs in fastqs_dir.items():
        for k,full_path in fastqs.items():
            if k not in ignore:
                filename = full_path.split("/")[-1]
                fastqLinks.append(filename)
        if "s3" in root_dir:
            s3_client = boto3.client('s3')
            bucket=root_dir.split("/")
            print(bucket[2])
            prefix=root_dir.replace("s3://"+bucket[2]+"/", "")
            print(prefix)
            s3_client.download_file(bucket[2], prefix, filename)
        else:
            for filename in fastqLinks:
                os.symlink(root_dir+"/"+filename, filename)  #Symlink made here (we couldn't pass the path directly from the yaml)
                print("linking fastqs:\t",root_dir+"/"+filename, filename)
         #This line just for debugging - should print all the fastq.gz here
    #yaml_object['undemultiplexed']['forward'].split("/")[0:-1] # + ","+yaml_object['undemultiplexed']['reverse'] +  ","+yaml_object['undemultiplexed']['index1']+ ","+yaml_object['undemultiplexed']['index2']
    #return os.path.dirname(os.path.abspath(yaml_object['undemultiplexed']['forward']))


def main():
    #example usage: python bin/link_fq.py manifest.yaml <root_dir_ie_place_where_inputs_live>
    #eg: python bin/link_fq.py /Users/alantracey/Aculive/circleseq/input/min_local_manifest.yaml /Users/alantracey/Aculive/circleseq/input
    loadYaml(sys.argv[1], sys.argv[2])


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    main()
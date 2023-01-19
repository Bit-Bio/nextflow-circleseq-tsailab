#!/usr/bin/env python3

import sys
import yaml
'''
Written to pull out sample and sequence information from guideseq manifest.yaml to use in the nextflow process
'''

def loadYaml(yamlfile):
    with open(yamlfile, 'r') as yaml_in:
        with open("tmp_samples.csv", "w") as fout:
            yaml_object = yaml.safe_load(yaml_in)
            for sample in list(yaml_object["samples"].keys()):
                fout.write(sample.replace("_","").replace(".","")+"\n")
                #fout.write(sample.replace(".", "") + "\n")


def main():
    loadYaml(sys.argv[1])


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    main()
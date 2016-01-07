from __future__ import print_function

import argparse
import itertools
import re
import regex
import gzip
import string
import swalign
import sys
import collections
from findCleavageSites import regexFromSequence, alignSequences
"""
FASTQ generator function from umi package
"""
def fq(file):
    if re.search('.gz$', file):
        fastq = gzip.open(file, 'rb')
    else:
        fastq = open(file, 'r')
    with fastq as f:
        while True:
            l1 = f.readline()
            if not l1:
                break
            l2 = f.readline()
            l3 = f.readline()
            l4 = f.readline()
            yield [l1, l2, l3, l4]

"""
### Simple reverse_complement method
"""

def reverseComplement(sequence):
    transtab = string.maketrans("ACGT","TGCA")
    return sequence.translate(transtab)[::-1]

def regexFromSequence(seq, lookahead=True, indels=1, mismatches=2):
    """
    Given a sequence with ambiguous base characters, returns a regex that matches for
    the explicit (unambiguous) base characters
    """
    IUPAC_notation_regex = {'N': '[ATCGN]',
                            'Y': '[CTY]',
                            'R': '[AGR]',
                            'W': '[ATW]',
                            'S': '[CGS]',
                            'A': 'A',
                            'T': 'T',
                            'C': 'C',
                            'G': 'G'}

    pattern = ''

    for c in seq:
        pattern += IUPAC_notation_regex[c]

    if lookahead:
        pattern = '(?:' + pattern + ')'
    if mismatches > 0:
        pattern = pattern + '{{s<={}}}'.format(mismatches)
        # pattern = pattern + '{{i<={0},d<={1},1i+1d+s<={2}}}'.format(indels, indels, mismatches)
    return pattern



def alignSequences(targetsite_sequence, window_sequence, max_mismatches = 6):
    """
    Given a targetsite and window, use a fuzzy regex to align the targetsite to
    the window. Returns the best match.
    """

    # Try both strands
    query_regex = regexFromSequence(targetsite_sequence, mismatches=max_mismatches)
    forward_alignment = regex.search(query_regex, window_sequence, regex.BESTMATCH)

    # reverse_regex = regexFromSequence(reverseComplement(targetsite_sequence), mismatches=max_mismatches)
    reverse_alignment = regex.search(query_regex, reverseComplement(window_sequence), regex.BESTMATCH)

    if forward_alignment is None and reverse_alignment is None:
        return ['', '', '', '', '', '']
    else:
        if forward_alignment is None and reverse_alignment is not None:
            strand = '-'
            alignment = reverse_alignment
        elif reverse_alignment is None and forward_alignment is not None:
            strand = '+'
            alignment = forward_alignment
        elif forward_alignment is not None and reverse_alignment is not None:
            forward_mismatches = forward_alignment.fuzzy_counts[0]
            reverse_mismatches = reverse_alignment.fuzzy_counts[0]

            if forward_mismatches > reverse_mismatches:
                strand = '-'
                alignment = reverse_alignment
            else:
                strand = '+'
                alignment = forward_alignment

        match_sequence = alignment.group()
        mismatches = alignment.fuzzy_counts[0]
        length = len(match_sequence)
        start = alignment.start()
        end = alignment.end()

        return [match_sequence, mismatches, length, strand, start, end]

"""
Main function to find off-target sites in reference-free fashion
"""
def analyze(fastq1_filename, fastq2_filename, targetsite, out_base, name='', cells=''):

    read_count = 0
    c = collections.Counter()
    d = collections.defaultdict(list)

    fastq1_file = fq(fastq1_filename)
    fastq2_file = fq(fastq2_filename)
    for r1, r2 in itertools.izip(fastq1_file, fastq2_file):
        r1_sequence = r1[1].rstrip('\n')
        r2_sequence = r2[1].rstrip('\n')
        joined_seq = reverseComplement(r1_sequence) + r2_sequence
        truncated_joined_seq = joined_seq[130:170]
        offtarget, mismatch, length, strand, start, end = alignSequences(targetsite, truncated_joined_seq)
        if offtarget:
            # print(read_count, offtarget,mismatch,length)
            c[offtarget] += 1
            d[offtarget].append(joined_seq)

        read_count += 1
        if not read_count % 100000:
            print(read_count/float(1000000), end=" ", file=sys.stderr)

    print('Finished tabulating reference-free discovery counts.', file=sys.stderr)
    out_filename = out_base + '.txt'

    with open(out_filename, 'w') as o:
        for target_sequence, target_count in c.most_common():
            print(target_sequence, target_count, file=o)
            off_target_fasta_filename = '{0}_{1:04d}_{2}.fasta'.format(out_base, target_count, target_sequence)
            with open(off_target_fasta_filename, 'w') as off_target_fasta_file:
                j = 0
                for sequence in d[target_sequence]:
                    j += 1
                    print('>{0:04d}_{1}_{2}'.format(target_count, target_sequence, j), file=off_target_fasta_file)
                    print(sequence, file=off_target_fasta_file)


def join_write_output(fastq1_filename, fastq2_filename, out):
    fastq1_file = fq(fastq1_filename)
    fastq2_file = fq(fastq2_filename)

    with open(out, 'w') as o:
        for r1, r2 in itertools.izip(fastq1_file, fastq2_file):
            header = '>{0}'.format(r1[0])
            r1_sequence = r1[1].rstrip('\n')
            r2_sequence = r2[1].rstrip('\n')
            joined_seq = reverseComplement(r1_sequence) + r2_sequence
            print(header, end='', file=o)
            print(joined_seq, file=o)


def main():
    parser = argparse.ArgumentParser(description='Identify off-target candidates from Illumina short read sequencing data.')
    parser.add_argument('--fq1', help='FASTQ Read 1', required=True)
    parser.add_argument('--fq2', help='FASTQ Read 2', required=True)
    parser.add_argument('--targetsite', help='Targetsite Sequence', required=True)
    parser.add_argument('--name', help='Targetsite Name', required=False)
    parser.add_argument('--cells', help='Cells', required=False)
    parser.add_argument('--out', help='Output file base', required=True)
    args = parser.parse_args()

    analyze(args.fq1, args.fq2, args.targetsite, args.out, args.name, args.cells)
    # join_write_output(args.fq1, args.fq2, args.out)

if __name__ == "__main__":
    main()

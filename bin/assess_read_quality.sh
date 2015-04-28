#!/bin/bash

set -o nounset
set -o errexit

source definitions.sh

# Run the fastqc tool on each set of trimmed reads to assess quality and check
# that no major adapter sequence contamination remains.
for sample in $SAMPLES; do
    trimmed_fasta=${TRIMMED_READS_DIR}/${sample}.trimmed.fastq
    $FASTQC -o ${TRIMMED_READS_DIR} ${TRIMMED_READS_DIR}/${sample}.trimmed.fastq
done

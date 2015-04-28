#!/bin/bash

set -o nounset
set -o errexit

source definitions.sh

# Extract miRNA sequences (hairpin or mature) for a particular species from
# data downloaded from miRBase, and convert the sequences from RNA to DNA
function extract_mirnas {
    MIRNA_SEQS=$1
    SPECIES_CODE=$2
    OUTPUT_FILE=$3
    MIRNA_TYPE=$4

    TMP_FILE=.tmp.$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    ${MIRDEEP_EXTRACT} ${MIRNA_SEQS} ${SPECIES_CODE} ${MIRNA_TYPE} > ${TMP_FILE}
    ${MIRDEEP_RNA2DNA} ${TMP_FILE} > ${OUTPUT_FILE}
    rm ${TMP_FILE}
}

SPECIES_CODE=$1
MIRNA_MATURE=$2
MIRNA_PRECURSOR=$3

mkdir -p $MIRNA_DATA_DIR

# Extract mature and hairpin miRNA sequences for a particular species from data
# downloaded from miRBase
extract_mirnas ${MIRNA_MATURE_SEQUENCES} ${SPECIES_CODE} ${MIRNA_MATURE} mature
extract_mirnas ${MIRNA_HAIRPIN_SEQUENCES} ${SPECIES_CODE} ${MIRNA_PRECURSOR} ""

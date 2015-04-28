#!/bin/bash

set -o nounset
set -o errexit

source definitions.sh

# Build Bowtie indices for a particular set of reference sequences
function build_bowtie_index {
    PARENT_DIR=$1
    shift
    INDEX_TYPE=$1
    shift
    REFERENCE_FILES=$*

    ${BOWTIE_BUILD} ${REFERENCE_FILES} $(get_bowtie_index ${PARENT_DIR} ${INDEX_TYPE})
}

mkdir -p ${HUMAN_BOWTIE_INDEX_DIR}
mkdir -p ${RAT_BOWTIE_INDEX_DIR}

# Build Bowtie indices for full and repeat-masked human genome sequences
build_bowtie_index ${HUMAN_BOWTIE_INDEX_DIR} PLAIN ${GENOME_DATA_DIR}/${HUMAN_GENOME_FASTA}
build_bowtie_index ${HUMAN_BOWTIE_INDEX_DIR} REPMASK ${GENOME_DATA_DIR}/${HUMAN_GENOME_REPMASK_FASTA}

# Build Bowtie indices for various human RNA types
for rna_type in rRNA RNA45S5 miRNA misc_RNA snoRNA snRNA piRNA; do
    build_bowtie_index ${HUMAN_BOWTIE_INDEX_DIR} ${rna_type} $(get_rna_fasta human ${rna_type})
done

# Build Bowtie indices for full and repeat-masked rat genome sequences
build_bowtie_index ${RAT_BOWTIE_INDEX_DIR} PLAIN ${GENOME_DATA_DIR}/${RAT_GENOME_FASTA}
build_bowtie_index ${RAT_BOWTIE_INDEX_DIR} REPMASK ${GENOME_DATA_DIR}/${RAT_GENOME_REPMASK_FASTA}

# Build Bowtie indices for various rat RNA types
for rna_type in rRNA miRNA piRNA; do
    build_bowtie_index ${RAT_BOWTIE_INDEX_DIR} ${rna_type} $(get_rna_fasta rat ${rna_type})
done

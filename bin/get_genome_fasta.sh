#!/bin/bash

set -o nounset
set -o errexit

source definitions.sh

SPECIES=$1
GENOME_FASTA_FILE=$2
DOWNLOADED_PATH=${GENOME_DATA_DIR}/$2

mkdir -p ${GENOME_DATA_DIR}

# Download and unpack a genome FASTA file for the specified species from
# Ensembl release 78
wget -O ${DOWNLOADED_PATH}.gz ftp://ftp.ensembl.org/pub/release-78/fasta/${SPECIES}/dna/${GENOME_FASTA_FILE}.gz
gunzip ${DOWNLOADED_PATH}.gz

# Adjust FASTA sequence names to contain only the chromosome or contig name
sed -i 's/^>\(.*\) dna.*/>\1/' ${DOWNLOADED_PATH}

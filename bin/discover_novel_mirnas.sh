#!/bin/bash

set -o nounset
set -o errexit

source definitions.sh

PATH=$PATH:$MIRDEEP_DIR

SPECIES=$1
GENOME_FASTA=$2
PROCESSED_READS=$3
MAPPED_READS=$4
MIRNA_MATURE=$5
MIRNA_PRECURSOR=$6

SPECIES_DISCOVERY_DIR=$MIRDEEP_DISCOVERY_DIR/$SPECIES
mkdir -p $SPECIES_DISCOVERY_DIR

# Use the main miRDeep2 tool to discover any novel miRNAs that appear to be
# present in the samples.
$MIRDEEP_MAIN $PROCESSED_READS $GENOME_FASTA $MAPPED_READS $MIRNA_MATURE none $MIRNA_PRECURSOR -P -t ${SPECIES^}

# Clean up various files that the miRDeep tool leaves behind.
mv dir_prepare* $SPECIES_DISCOVERY_DIR
mv error_* $SPECIES_DISCOVERY_DIR
mv expression_* $SPECIES_DISCOVERY_DIR
mv mirdeep_runs $SPECIES_DISCOVERY_DIR
mv mirna_results* $SPECIES_DISCOVERY_DIR
mv miRNAs_expressed* $SPECIES_DISCOVERY_DIR
mv pdfs_* $SPECIES_DISCOVERY_DIR
mv result_* $SPECIES_DISCOVERY_DIR

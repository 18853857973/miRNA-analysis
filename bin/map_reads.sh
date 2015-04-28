#!/bin/bash

set -o nounset
set -o errexit

source definitions.sh

PATH=$PATH:$MIRDEEP_DIR

SPECIES=$1
BOWTIE_INDEX_DIR=$2
MAPPER_CONFIG_FILE=$3
PROCESSED_READS=$4
MAPPED_READS=$5

# Use miRDeep2's mapper tools to align trimmed reads to the genome.
$MIRDEEP_MAPPER $MAPPER_CONFIG_FILE -d -e -h -q -m -r 5 -u -v -o 8 -p $(get_bowtie_index $BOWTIE_INDEX_DIR PLAIN) -s $PROCESSED_READS -t $MAPPED_READS > ${MAPPED_READS_DIR}/${SPECIES}_summary.log 2>&1

# Clean up various files that the mapper tool leaves behind.
mv bowtie.log ${MAPPED_READS_DIR}/${SPECIES}_mapper_bowtie.log
mv mapper.log ${MAPPED_READS_DIR}/${SPECIES}_mapper.log
mv dir_mapper* ${MAPPED_READS_DIR}

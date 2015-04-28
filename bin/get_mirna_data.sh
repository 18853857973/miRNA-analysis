#!/bin/bash

set -o nounset
set -o errexit

source definitions.sh

# Download hairpin or mature miRNA sequences from miRBase version 21
function get_mirna_data {
    SEQUENCE_FILE=${1}.fa
    DESTINATION=$2

    wget ftp://mirbase.org/pub/mirbase/21/${SEQUENCE_FILE}.gz
    gunzip ${SEQUENCE_FILE}.gz
    mv ${SEQUENCE_FILE} ${DESTINATION}
}

mkdir -p ${MIRNA_DATA_DIR}

# Download hairpin and mature miRNA sequences from miRBase version 21
get_mirna_data hairpin ${MIRNA_HAIRPIN_SEQUENCES}
get_mirna_data mature ${MIRNA_MATURE_SEQUENCES}

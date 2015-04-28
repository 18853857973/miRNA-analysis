#!/bin/bash

set -o nounset
set -o errexit

source definitions.sh

# Copy main results into a summary output directory

for species in human rat; do
    SPECIES_DIR=${SUMMARY_DIR}/$species
    mkdir -p ${SPECIES_DIR}

    cp $(single_file_from_pattern ${MIRDEEP_DISCOVERY_DIR}/${species}/result*.html) ${SPECIES_DIR}/miRNA_discovery.html
    cp -r ${MIRDEEP_DISCOVERY_DIR}/${species}/pdfs* ${SPECIES_DIR}
    cp $(single_file_from_pattern ${MIRDEEP_QUANTIFICATION_DIR}/${species}/*.csv) ${SPECIES_DIR}/miRNA_quantification.csv
    cp $(single_file_from_pattern ${MIRDEEP_QUANTIFICATION_DIR}/${species}/*.html) ${SPECIES_DIR}/miRNA_quantification.html
done

for sample in $HUMAN_SAMPLES; do
    cp ${TRIMMED_READS_DIR}/${sample}.trimmed_fastqc.html ${SUMMARY_DIR}/human
done

for sample in $RAT_SAMPLES; do
    cp ${TRIMMED_READS_DIR}/${sample}.trimmed_fastqc.html ${SUMMARY_DIR}/rat
done

cp ${MAPPED_READS_DIR}/human_mapping_summary.csv ${SUMMARY_DIR}/human
cp ${MAPPED_READS_DIR}/rat_mapping_summary.csv ${SUMMARY_DIR}/rat

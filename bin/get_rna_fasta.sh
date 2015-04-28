#!/bin/bash

set -o nounset
set -o errexit

source definitions.sh

# Download sequences for a particular RNA species from Ensembl BioMart. Note
# that the sequences are downloaded with upstream and downstream flanks of 5
# bases, to allow for some indeterminacy in the exact endpoints of the
# annotations.
function get_rna_from_ensembl {
    SPECIES=$1
    RNA_TYPE=$2
    FASTA_FILE=$3

    wget -O $FASTA_FILE "http://www.ensembl.org/biomart/martservice?query=<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE Query><Query  virtualSchemaName = \"default\" formatter = \"FASTA\" header = \"0\" uniqueRows = \"0\" count = \"\" datasetConfigVersion = \"0.6\" ><Dataset name = \"${SPECIES}_gene_ensembl\" interface = \"default\" ><Filter name = \"biotype\" value = \"${RNA_TYPE}\"/><Attribute name = \"ensembl_gene_id\" /><Attribute name = \"ensembl_transcript_id\" /><Filter name = \"downstream_flank\" value = \"5\"/><Filter name = \"upstream_flank\" value = \"5\"/><Attribute name = \"cdna\" /></Dataset></Query>"
}

mkdir -p ${GENOME_DATA_DIR}

# Download human sequences for various RNA species
for rna_type in rRNA miRNA misc_RNA snoRNA snRNA; do
    get_rna_from_ensembl hsapiens ${rna_type} $(get_rna_fasta human $rna_type)
done

# Download human sequence for a representative copy of the 45S pre-rRNA transcript
wget -O $(get_rna_fasta human RNA45S5) "http://www.ensembl.org/Homo_sapiens/Export/Output/Location?db=core;flank3_display=0;flank5_display=0;output=fasta;r=21:8433217-8446577;strand=feature;coding=yes;cdna=yes;peptide=yes;utr3=yes;exon=yes;intron=yes;genomic=unmasked;utr5=yes;_format=Text"

# Download rat sequences for various RNA species - note that there are fewer
# RNA types for the rat for which annotations exist in Ensembl
for rna_type in rRNA miRNA; do
    get_rna_from_ensembl rnorvegicus ${rna_type} $(get_rna_fasta rat $rna_type)
done

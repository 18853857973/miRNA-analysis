#!/bin/bash

set -o nounset
set -o errexit

#############
# Input data
#############

# Directory containing the raw read data
export FASTA_DIR=...

# Human piRNA sequences - downloaded via the following NCBI query:
# http://www.ncbi.nlm.nih.gov/nuccore/?term=(piRNA%5BTitle%5D)+AND+homo+sapiens%5BOrganism%5D
export HUMAN_PIRNA_SEQUENCES=...
# Rat piRNA sequences - downloaded via the following NCBI query:
# http://www.ncbi.nlm.nih.gov/nuccore/?term=(piRNA%5BTitle%5D)+AND+rattus+norvegicus%5BOrganism%5D
export RAT_PIRNA_SEQUENCES=...

# Identifiers for human sequencing samples
export HUMAN_SAMPLES=...
# Identifiers for rat sequencing samples
export RAT_SAMPLES=...
export SAMPLES="$HUMAN_SAMPLES $RAT_SAMPLES"

#########
# Output
#########

# Path to the top-level output directory (this, and all other output
# directories, will be created)
export OUTPUT_DIR=results

# Path to directory for genome and miRNA data to be used as input to
# the main analyses
export DATA_DIR=${OUTPUT_DIR}/data
# Path to directory in which input genome data will be placed
export GENOME_DATA_DIR=${DATA_DIR}/genome
# Name of human genome FASTA file to be downloaded from Ensembl
export HUMAN_GENOME_FASTA=Homo_sapiens.GRCh38.dna.primary_assembly.fa
# Name of repeat-masked human genome FASTA file to be downloaded from Ensembl
export HUMAN_GENOME_REPMASK_FASTA=Homo_sapiens.GRCh38.dna_rm.primary_assembly.fa
# Name of rat genome FASTA file to be downloaded from Ensembl
export RAT_GENOME_FASTA=Rattus_norvegicus.Rnor_5.0.dna.toplevel.fa
# Name of repeat-masked rat genome FASTA file to be downloaded from Ensembl
export RAT_GENOME_REPMASK_FASTA=Rattus_norvegicus.Rnor_5.0.dna_rm.toplevel.fa
# Directory in which human Bowtie indices will be placed
export HUMAN_BOWTIE_INDEX_DIR=${GENOME_DATA_DIR}/human_bowtie
# Directory in which rat Bowtie indices will be placed
export RAT_BOWTIE_INDEX_DIR=${GENOME_DATA_DIR}/rat_bowtie
# Path to directory in which input miRNA data will be placed
export MIRNA_DATA_DIR=${DATA_DIR}/mirna
# Path to file containing microRNA hairpin sequences to be downloaded from miRBase
export MIRNA_HAIRPIN_SEQUENCES=${MIRNA_DATA_DIR}/hairpin.fa
# Path to file containing microRNA mature sequences to be downloaded from miRBase
export MIRNA_MATURE_SEQUENCES=${MIRNA_DATA_DIR}/mature.fa

# Output directory for trimmed read data
export TRIMMED_READS_DIR=${OUTPUT_DIR}/trimmed
# Output directory for mapped read data
export MAPPED_READS_DIR=${OUTPUT_DIR}/mapped
# Main output directory for miRDeep2 runs
export MIRDEEP_OUTPUT_DIR=$OUTPUT_DIR/mirdeep
# Output directory for miRDeep2 miRNA discovery data
export MIRDEEP_DISCOVERY_DIR=$MIRDEEP_OUTPUT_DIR/discovery
# Output directory for miRDeep2 miRNA quantification data
export MIRDEEP_QUANTIFICATION_DIR=$MIRDEEP_OUTPUT_DIR/quantification
# Output directory for summary data for the whole analysis
export SUMMARY_DIR=${OUTPUT_DIR}/summary

########
# Tools
########

# Path to the "bowtie-build" executable
export BOWTIE_BUILD=...
# Path to the "bowtie" executable
export BOWTIE=...
# Path to the "cutadapt" executable
export CUTADAPT=...
# Path to the "fastqc" executable
export FASTQC=...
# Path to the miRDeep2 installation directory
export MIRDEEP_DIR=...
# Paths to individual miRDeep2 scripts and libraries
export MIRDEEP_EXTRACT=$MIRDEEP_DIR/extract_miRNAs.pl
export MIRDEEP_MAPPER=$MIRDEEP_DIR/mapper.pl
export MIRDEEP_MAIN=$MIRDEEP_DIR/miRDeep2.pl
export MIRDEEP_QUANTIFIER=$MIRDEEP_DIR/quantifier.pl
export MIRDEEP_RNA2DNA=$MIRDEEP_DIR/rna2dna.pl
export PERL5LIB=$MIRDEEP_DIR/lib/PDF/API2/

# Location of analysis scripts
export BIN_DIR=bin

######################
# Species definitions
######################

# Homo sapiens species code in miRBase
export HUMAN_SPECIES_CODE=hsa
# Rattus norvegicus species code in miRBase
export RAT_SPECIES_CODE=rno

###################
# Common functions
###################

# Get the prefix for Bowtie index files for a particular type of sequence
function get_bowtie_index {
    PARENT_DIR=$1
    INDEX_TYPE=$2

    echo ${PARENT_DIR}/${INDEX_TYPE}_index
}

# Get the FASTA file containing sequence for a particular species and RNA type
function get_rna_fasta {
    SPECIES=$1
    RNA_TYPE=$2

    echo ${GENOME_DATA_DIR}/${SPECIES}_${RNA_TYPE}.fa
}

# Return the file name of the single file whose name matches a pattern
function single_file_from_pattern {
    pattern=$1

    files=($pattern)
    echo ${files[0]}
}

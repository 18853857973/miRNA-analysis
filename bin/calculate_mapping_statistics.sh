#!/bin/bash

set -o nounset
set -o errexit

source definitions.sh

# Use Bowtie to map reads from a set of samples to a particular set of
# reference sequences.
function map_reads {
    INPUT_READS_DIR=$1
    shift
    INPUT_READS_FASTQ_SUFFIX=$1
    shift
    INDEX_DIR=$1
    shift
    INDEX_TYPE=$1
    shift
    MAPPING_TYPE=$1
    shift
    SAMPLES_TO_MAP=$*

    for sample in $SAMPLES_TO_MAP; do
        input_reads_fastq=${INPUT_READS_DIR}/${sample}.${INPUT_READS_FASTQ_SUFFIX}
        mapped_reads_bam=${MAPPED_READS_DIR}/${sample}.${MAPPING_TYPE}_aligned.bam
        unaligned_reads_fastq=${MAPPED_READS_DIR}/${sample}.${MAPPING_TYPE}_unaligned.fastq
        aligned_reads_fastq=${MAPPED_READS_DIR}/${sample}.${MAPPING_TYPE}_aligned.fastq

        $BOWTIE -p 8 -q -n 1 -e 80 -l 18 --un $unaligned_reads_fastq --al $aligned_reads_fastq $(get_bowtie_index ${INDEX_DIR} ${INDEX_TYPE}) $input_reads_fastq $mapped_reads_bam >> ${MAPPED_READS_DIR}/${sample}.${MAPPING_TYPE}.bowtie.log 2>&1
    done
}

# Use Bowtie to map reads from a set of samples to reference piRNA sequences.
# Note that because it was not possible to include up- and downstream flanking
# regions in the downloaded piRNA sequences (as was done for all other RNA
# species), we also attempt to map truncated version of the reads to the
# reference sequences (though only in cases where the read is long enough to
# trim bases at each end and still be reasonably confident of an unambiguous
# mapping).
function map_pirna_reads {
    INPUT_READS_DIR=$1
    shift
    INPUT_READS_FASTQ_SUFFIX=$1
    shift
    INDEX_DIR=$1
    shift
    SAMPLES_TO_MAP=$*

    map_reads ${INPUT_READS_DIR} ${INPUT_READS_FASTQ_SUFFIX} ${INDEX_DIR} piRNA piRNA ${SAMPLES_TO_MAP}

    for sample in $SAMPLES_TO_MAP; do
        paste - - - - < ${INPUT_READS_DIR}/${sample}.piRNA_unaligned.fastq | 
            tr '\t' '_' | 
            awk -F'_' 'length($2) > 20 && length ($2) <= 25  {print $1 "_" substr($2, 2, length($2)-2) "_" $3 "_" substr($4, 2, length($4)-2)}; length($2) > 25 && length ($2) <= 30  {print $1 "_" substr($2, 4, length($2)-6) "_" $3 "_" substr($4, 4, length($4)-6) }; length($2) > 30  {print $1 "_" substr($2, 7, length($2)-12), "_" $3 "_" substr($4, 7, length($4)-12)}'| 
            tr '_' '\n' > ${INPUT_READS_DIR}/${sample}.piRNA_unaligned_trimmed.fastq

        paste - - - - < ${INPUT_READS_DIR}/${sample}.piRNA_unaligned.fastq | 
            tr '\t' '_' | 
            awk -F'_' 'length($2) <= 20' | 
            tr '_' '\n' > ${INPUT_READS_DIR}/${sample}.piRNA_unaligned_untrimmed.fastq
    done

    map_reads ${INPUT_READS_DIR} piRNA_unaligned_trimmed.fastq ${INDEX_DIR} piRNA tpRNA ${SAMPLES_TO_MAP}
}

# Extract the number of reads that Bowtie attempted to map from a Bowtie log file
function get_reads_processed_count {
    MAPPED_READS_DIR=$1
    SAMPLE=$2
    MAPPING_TYPE=$3

    grep "reads processed" $1/$2.$3.bowtie.log | sed 's/.*reads processed: \([0-9]*\)/\1/'
}

# Extract the number of reads that Bowtie successfully aligned from a Bowtie log file
function get_aligned_reads_count {
    MAPPED_READS_DIR=$1
    SAMPLE=$2
    MAPPING_TYPE=$3

    grep "reported alignment" $1/$2.$3.bowtie.log | sed 's/.*reported alignment: \([0-9]*\) (.*/\1/'
}

# Extract the number of reads that Bowtie failed to align from a Bowtie log file
function get_unaligned_reads_count {
    MAPPED_READS_DIR=$1
    SAMPLE=$2
    MAPPING_TYPE=$3

    grep "failed to align" $1/$2.$3.bowtie.log | sed 's/.*failed to align: \([0-9]*\) (.*/\1/'
}

# Transpose data (i.e. swap rows and columns) in a space-separated file. Output
# is comma-separated.
function transpose_data {
    INPUT_FILE=$1
    OUTPUT_FILE=2

    rm -f $2

    cols=$(head -n 1 $1 | wc -w)
    for (( i=1; i <= $cols; i++)); do 
        cut -d" " -f $i $1 | tr $'\n' $',' | sed -e "s/,$/\n/g" >> $2
    done

    rm $1
}

# Map reads from human samples to various genomic and RNA references
map_reads ${TRIMMED_READS_DIR} trimmed.fastq ${HUMAN_BOWTIE_INDEX_DIR} PLAIN PLAIN ${HUMAN_SAMPLES}
map_reads ${MAPPED_READS_DIR} PLAIN_aligned.fastq ${HUMAN_BOWTIE_INDEX_DIR} miRNA miRNA ${HUMAN_SAMPLES}
map_reads ${MAPPED_READS_DIR} miRNA_unaligned.fastq ${HUMAN_BOWTIE_INDEX_DIR} REPMASK REPMASK ${HUMAN_SAMPLES}
map_reads ${MAPPED_READS_DIR} REPMASK_aligned.fastq ${HUMAN_BOWTIE_INDEX_DIR} misc_RNA misc_RNA ${HUMAN_SAMPLES}
map_reads ${MAPPED_READS_DIR} misc_RNA_unaligned.fastq ${HUMAN_BOWTIE_INDEX_DIR} rRNA rRNA ${HUMAN_SAMPLES}
map_reads ${MAPPED_READS_DIR} rRNA_unaligned.fastq ${HUMAN_BOWTIE_INDEX_DIR} RNA45S5 RNA45S5 ${HUMAN_SAMPLES}
map_reads ${MAPPED_READS_DIR} RNA45S5_unaligned.fastq ${HUMAN_BOWTIE_INDEX_DIR} snRNA snRNA ${HUMAN_SAMPLES}
map_reads ${MAPPED_READS_DIR} snRNA_unaligned.fastq ${HUMAN_BOWTIE_INDEX_DIR} snoRNA snoRNA ${HUMAN_SAMPLES}
map_pirna_reads ${MAPPED_READS_DIR} snoRNA_unaligned.fastq ${HUMAN_BOWTIE_INDEX_DIR} ${HUMAN_SAMPLES}

# Map reads from rat samples to various genomic and RNA references
map_reads ${TRIMMED_READS_DIR} trimmed.fastq ${RAT_BOWTIE_INDEX_DIR} PLAIN PLAIN ${RAT_SAMPLES}
map_reads ${MAPPED_READS_DIR} PLAIN_aligned.fastq ${RAT_BOWTIE_INDEX_DIR} miRNA miRNA ${RAT_SAMPLES}
map_reads ${MAPPED_READS_DIR} miRNA_unaligned.fastq ${RAT_BOWTIE_INDEX_DIR} REPMASK REPMASK ${RAT_SAMPLES}
map_reads ${MAPPED_READS_DIR} REPMASK_aligned.fastq ${RAT_BOWTIE_INDEX_DIR} rRNA rRNA ${RAT_SAMPLES}
map_pirna_reads ${MAPPED_READS_DIR} rRNA_unaligned.fastq ${RAT_BOWTIE_INDEX_DIR} ${RAT_SAMPLES}

MAPPING_TMP_FILE=.mapping_tmp

# Extract human read mapping statistics from Bowtie log files and output to a
# summary CSV file. The data written for each sample is:
#   Sample name
#   Total no. reads processed
#   No. reads aligned to genome
#   No. reads failed to align to genome
#   No. reads aligned to genome which mapped to miRNAs
#   No. remaining aligned reads which mapped to repetitive sequences within genome
#   No. remaining aligned reads which mapped to ribosomal RNA sequences
#   No. remaining aligned reads which mapped to small nuclear RNA sequences
#   No. remaining aligned reads which mapped to small nucleolar RNA sequences
#   No. remaining aligned reads which mapped to piRNA sequences
echo "sample total mapped unmapped miRNA repeats misc_RNA rRNA snRNA snoRNA piRNA" > ${MAPPING_TMP_FILE}
for sample in ${HUMAN_SAMPLES}; do
    echo ${sample} $(get_reads_processed_count $MAPPED_READS_DIR $sample PLAIN) $(get_aligned_reads_count $MAPPED_READS_DIR $sample PLAIN) $(get_unaligned_reads_count $MAPPED_READS_DIR $sample PLAIN) $(get_aligned_reads_count $MAPPED_READS_DIR $sample miRNA) $(get_unaligned_reads_count $MAPPED_READS_DIR $sample REPMASK) $(get_aligned_reads_count $MAPPED_READS_DIR $sample misc_RNA) $(($(get_aligned_reads_count $MAPPED_READS_DIR $sample rRNA) + $(get_aligned_reads_count $MAPPED_READS_DIR $sample RNA45S5))) $(get_aligned_reads_count $MAPPED_READS_DIR $sample snRNA) $(get_aligned_reads_count $MAPPED_READS_DIR $sample snoRNA) $(($(get_aligned_reads_count $MAPPED_READS_DIR $sample piRNA) + $(get_aligned_reads_count $MAPPED_READS_DIR $sample tpRNA))) >> ${MAPPING_TMP_FILE}
done

transpose_data ${MAPPING_TMP_FILE} ${MAPPED_READS_DIR}/human_mapping_summary.csv

# Extract rat read mapping statistics from Bowtie log files and output to a
# summary CSV file. The data written for each sample is:
#   Sample name
#   Total no. reads processed
#   No. reads aligned to genome
#   No. reads failed to align to genome
#   No. reads aligned to genome which mapped to miRNAs
#   No. remaining aligned reads which mapped to repetitive sequences within genome
#   No. remaining aligned reads which mapped to ribosomal RNA sequences
echo "sample total mapped unmapped miRNA repeats rRNA" > ${MAPPING_TMP_FILE}
for sample in ${RAT_SAMPLES}; do
    echo ${sample} $(get_reads_processed_count $MAPPED_READS_DIR $sample PLAIN) $(get_aligned_reads_count $MAPPED_READS_DIR $sample PLAIN) $(get_unaligned_reads_count $MAPPED_READS_DIR $sample PLAIN) $(get_aligned_reads_count $MAPPED_READS_DIR $sample miRNA) $(get_unaligned_reads_count $MAPPED_READS_DIR $sample REPMASK) $(get_aligned_reads_count $MAPPED_READS_DIR $sample rRNA) >> ${MAPPING_TMP_FILE}
done

transpose_data ${MAPPING_TMP_FILE} ${MAPPED_READS_DIR}/rat_mapping_summary.csv

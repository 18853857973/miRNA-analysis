#!/bin/bash

set -o nounset
set -o errexit

source definitions.sh

# Extract novel miRNA sequences from the output of miRDeep2's main algorithm
function extract_mirna_sequences {
    ids_to_extract=$1
    species_code=$2
    input_sequences=$3
    output_sequences=$4

    grep -f $ids_to_extract -A 1 -w --no-group-separator $input_sequences |
        sed 's/>/>'"$species_code"'-/' > $output_sequences
}

PATH=$PATH:$MIRDEEP_DIR

SPECIES=$1
SPECIES_CODE=$2
PROCESSED_READS=$3
MIRNA_MATURE=$4
MIRNA_PRECURSOR=$5

DISCOVERY_DIR=$MIRDEEP_DISCOVERY_DIR/$SPECIES
QUANTIFICATION_DIR=$MIRDEEP_QUANTIFICATION_DIR/$SPECIES
mkdir -p $QUANTIFICATION_DIR

# First we need to append the mature and precursor sequences for the novel
# miRNAs to those of the known miRNAs, so that the total set of sequences can
# be used as input for miRDeep2's quantification tool.

# Find IDs of "high confidence" novel miRNAs. The definition of high confidence
# I have used here is:
#    - miRDeep2 score > 3 : at this score, miRDeep2 estimates a true positive
#    rate of approximately 89 +/- 3% in humans and 93 +/- 5% in the rat 
#    - the miRNA did not raise an "rfam alert" - i.e. it does not have sequence
#    similarity to reference rRNAs and tRNAs.
#    - the miRNA has a significant p-value from the 'randfold' tool (indicating
#    the implied precursor RNA structure is energetically stable)
#    - the sequence does not match a known miRBase miRNA.
discovery_results=$(single_file_from_pattern $DISCOVERY_DIR/result*.csv)
novel_ids=$QUANTIFICATION_DIR/novel_ids.txt
sed -n '/novel miRNAs predicted by miRDeep2/,/miRBase miRNAs not detected by miRDeep2/p' $discovery_results | sed '1,2d;$d' | awk -F $'\t' '$2 > 3 && $4 == "-" && $9 == "yes" && $10 == "-" {print $1}' > $novel_ids

# Extract predicted mature and precursor sequences for these novel miRNAs
mature_sequences=$(single_file_from_pattern $DISCOVERY_DIR/mirna_results*/novel_mature*.fa)
hc_mature_sequences=$QUANTIFICATION_DIR/novel_mature.fa
extract_mirna_sequences $novel_ids $SPECIES_CODE $mature_sequences $hc_mature_sequences

precursor_sequences=$(single_file_from_pattern $DISCOVERY_DIR/mirna_results*/novel_pres*.fa)
hc_precursor_sequences=$QUANTIFICATION_DIR/novel_precursor.fa
extract_mirna_sequences $novel_ids $SPECIES_CODE $precursor_sequences $hc_precursor_sequences

# Concatenate known and novel miRNA precursor and mature sequences
all_mature_sequences=$QUANTIFICATION_DIR/all_mature.fa
all_precursor_sequences=$QUANTIFICATION_DIR/all_precursor.fa

cat $MIRNA_MATURE $hc_mature_sequences > $all_mature_sequences
cat $MIRNA_PRECURSOR $hc_precursor_sequences > $all_precursor_sequences

# Finally, use miRDeep2's quantifier tool to obtain counts for reads mapping to
# precursor and mature sequences.
$MIRDEEP_QUANTIFIER -p $all_precursor_sequences -m $all_mature_sequences -r $PROCESSED_READS -t ${SPECIES^} -k -d -P

# Clean up various files that the quantifier tool leaves behind
mv expression_* $QUANTIFICATION_DIR
mv miRNAs_expressed* $QUANTIFICATION_DIR

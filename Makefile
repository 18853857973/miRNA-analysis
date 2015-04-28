###############
# Target names
###############

# Each of these targets can be run individually (together with the targets that
# it depends on) via:
#       ./run_analysis.sh <task_name>
#  e.g. ./run_analysis.sh .discover_novel_mirnas
DOWNLOAD_GENOME_FASTA=.download_genome_fasta
DOWNLOAD_MIRNA_DATA=.download_mirna_data
CREATE_BOWTIE_INDICES=.create_bowtie_indices
TRIM_READS=.trim_reads
ASSESS_TRIMMED_QUALITY=.assess_trimmed_quality
CONSTRUCT_MAPPING_CONFIG_FILES=.construct_mapping_config_files
MAP_READS=.map_reads
CREATE_MIRNA_SEQUENCES=.create_mirna_sequences
DISCOVER_NOVEL_MIRNAS=.discover_novel_mirnas
QUANTIFY_MIRNAS=.quantify_mirnas
CALCULATE_MAPPING_STATISTICS=.calculate_mapping_statistics
SUMMARISE_RESULTS=.summarise_results

#######################
# Variable definitions
#######################

HUMAN_MAPPER_CONFIG_FILE=$(MAPPED_READS_DIR)/human_mapper_config.txt
HUMAN_PROCESSED_READS=$(MAPPED_READS_DIR)/human_reads_collapsed.fa
HUMAN_MAPPED_READS=$(MAPPED_READS_DIR)/human_reads_vs_genome.arf
HUMAN_MIRNA_MATURE=$(MIRNA_DATA_DIR)/human_mature.fa
HUMAN_MIRNA_PRECURSOR=$(MIRNA_DATA_DIR)/human_precursor.fa

RAT_MAPPER_CONFIG_FILE=$(MAPPED_READS_DIR)/rat_mapper_config.txt
RAT_PROCESSED_READS=$(MAPPED_READS_DIR)/rat_reads_collapsed.fa
RAT_MAPPED_READS=$(MAPPED_READS_DIR)/rat_reads_vs_genome.arf
RAT_MIRNA_MATURE=$(MIRNA_DATA_DIR)/rat_mature.fa
RAT_MIRNA_PRECURSOR=$(MIRNA_DATA_DIR)/rat_precursor.fa

#####################
# Target definitions
#####################

.PHONY : all clean clean_results 

ifndef SUMMARY_DIR
$(error Execute make file via "run_analysis.sh".)
endif

# Target to be executed when running
#    ./run_analysis.sh
all: $(SUMMARISE_RESULTS)

# Summarise the main results of miRNA discovery and quantification
$(SUMMARISE_RESULTS): $(ASSESS_TRIMMED_QUALITY) $(QUANTIFY_MIRNAS) $(CALCULATE_MAPPING_STATISTICS)
	$(BIN_DIR)/summarise_results.sh
	touch $@

# Calculate what proportion of each sample maps to miRNAs and various other RNA
# species
$(CALCULATE_MAPPING_STATISTICS): $(CREATE_BOWTIE_INDICES)
	$(BIN_DIR)/calculate_mapping_statistics.sh
	touch $@

# Quantify the abundance of miRNAs using miRDeep2's quantification tool
$(QUANTIFY_MIRNAS): $(DISCOVER_NOVEL_MIRNAS)
	$(BIN_DIR)/quantify_mirnas.sh human $(HUMAN_SPECIES_CODE) $(HUMAN_PROCESSED_READS) $(HUMAN_MIRNA_MATURE) $(HUMAN_MIRNA_PRECURSOR)
	$(BIN_DIR)/quantify_mirnas.sh rat $(RAT_SPECIES_CODE) $(RAT_PROCESSED_READS) $(RAT_MIRNA_MATURE) $(RAT_MIRNA_PRECURSOR)
	touch $@

# Discover novel miRNAs using miRDeep2's main algorithm
$(DISCOVER_NOVEL_MIRNAS): $(MAP_READS) $(CREATE_MIRNA_SEQUENCES)
	$(BIN_DIR)/discover_novel_mirnas.sh human $(GENOME_DATA_DIR)/$(HUMAN_GENOME_FASTA) $(HUMAN_PROCESSED_READS) $(HUMAN_MAPPED_READS) $(HUMAN_MIRNA_MATURE) $(HUMAN_MIRNA_PRECURSOR)
	$(BIN_DIR)/discover_novel_mirnas.sh rat $(GENOME_DATA_DIR)/$(RAT_GENOME_FASTA) $(RAT_PROCESSED_READS) $(RAT_MAPPED_READS) $(RAT_MIRNA_MATURE) $(RAT_MIRNA_PRECURSOR)
	touch $@

# Extract hairpin and mature miRNA sequences from data downloaded from miRBase
$(CREATE_MIRNA_SEQUENCES): $(DOWNLOAD_MIRNA_DATA)
	$(BIN_DIR)/create_mirna_sequences.sh $(HUMAN_SPECIES_CODE) $(HUMAN_MIRNA_MATURE) $(HUMAN_MIRNA_PRECURSOR)
	$(BIN_DIR)/create_mirna_sequences.sh $(RAT_SPECIES_CODE) $(RAT_MIRNA_MATURE) $(RAT_MIRNA_PRECURSOR)
	touch $@

# Map reads to the genome with miRDeep2's mapping tool
$(MAP_READS): $(CONSTRUCT_MAPPING_CONFIG_FILES) $(TRIM_READS) $(CREATE_BOWTIE_INDICES)
	$(BIN_DIR)/map_reads.sh human $(HUMAN_BOWTIE_INDEX_DIR) $(HUMAN_MAPPER_CONFIG_FILE) $(HUMAN_PROCESSED_READS) $(HUMAN_MAPPED_READS)
	$(BIN_DIR)/map_reads.sh rat $(RAT_BOWTIE_INDEX_DIR) $(RAT_MAPPER_CONFIG_FILE) $(RAT_PROCESSED_READS) $(RAT_MAPPED_READS)
	touch $@

# Create configuration files that allow miRDeep2 to track which sample each
# read came from
$(CONSTRUCT_MAPPING_CONFIG_FILES): 
	$(BIN_DIR)/construct_mapping_config.sh $(HUMAN_MAPPER_CONFIG_FILE) $(HUMAN_SAMPLES)
	$(BIN_DIR)/construct_mapping_config.sh $(RAT_MAPPER_CONFIG_FILE) $(RAT_SAMPLES)
	touch $@

# Assess trimmed read quality with fastqc
$(ASSESS_TRIMMED_QUALITY): $(TRIM_READS)
	$(BIN_DIR)/assess_read_quality.sh
	touch $@
	
# Trim adaptors from reads with cutadapt
$(TRIM_READS): 
	$(BIN_DIR)/trim_reads.sh
	touch $@

# Create Bowtie indices for genome data and RNA sequences
$(CREATE_BOWTIE_INDICES): $(DOWNLOAD_GENOME_FASTA)
	$(BIN_DIR)/create_bowtie_indices.sh
	touch $@

# Download miRNA sequences from miRBase
$(DOWNLOAD_MIRNA_DATA): 
	$(BIN_DIR)/get_mirna_data.sh
	touch $@

# Download genome data files and sequences for various RNA species
$(DOWNLOAD_GENOME_FASTA): 
	$(BIN_DIR)/get_genome_fasta.sh homo_sapiens $(HUMAN_GENOME_FASTA)
	$(BIN_DIR)/get_genome_fasta.sh homo_sapiens $(HUMAN_GENOME_REPMASK_FASTA)
	$(BIN_DIR)/get_genome_fasta.sh rattus_norvegicus $(RAT_GENOME_FASTA)
	$(BIN_DIR)/get_genome_fasta.sh rattus_norvegicus $(RAT_GENOME_REPMASK_FASTA)
	$(BIN_DIR)/get_rna_fasta.sh
	cp $(HUMAN_PIRNA_SEQUENCES) $(GENOME_DATA_DIR)/human_piRNA.fa
	cp $(RAT_PIRNA_SEQUENCES) $(GENOME_DATA_DIR)/rat_piRNA.fa
	touch $@

# Remove all results and downloaded data
clean: clean_results
	rm -f $(CREATE_BOWTIE_INDICES)
	rm -f $(DOWNLOAD_GENOME_FASTA)
	rm -f $(DOWNLOAD_MIRNA_DATA)
	rm -rf $(OUTPUT_DIR)

# Remove all results of trimming, mapping, and miRNA discovery and
# quantification, but not downloaded data or Bowtie indices created for that
# data
clean_results: 
	rm -f $(SUMMARISE_RESULTS)
	rm -f $(CALCULATE_MAPPING_STATISTICS)
	rm -f $(QUANTIFY_MIRNAS)
	rm -f $(DISCOVER_NOVEL_MIRNAS)
	rm -f $(CREATE_MIRNA_SEQUENCES)
	rm -f $(MAP_READS)
	rm -f $(CONSTRUCT_MAPPING_CONFIG_FILES)
	rm -f $(ASSESS_TRIMMED_QUALITY)
	rm -f $(TRIM_READS)
	rm -rf $(TRIMMED_READS_DIR)
	rm -rf $(MAPPED_READS_DIR)
	rm -rf $(MIRDEEP_OUTPUT_DIR)
	rm -rf ${SUMMARY_DIR}

version 1.0


struct MachineSizes {
    String? concatenate
    String? trim
    String? align
    String? merge
    String? mark
    String? filter
    String? footprint
    String? peaks
    String? score
    String? normalize
    String? qc
    String? convert
    String? unpack
}

struct ReferenceMachineSizes {
    String build_bwa_index
    String get_center_sites
    String get_chrom_info
    String get_chrom_sizes
    String build_fasta_index
    String build_bowtie_index
    String build_mappable_only_bed
    String subtract_blacklists_from_mappable_regions
}

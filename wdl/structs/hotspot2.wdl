version 1.0


struct HotSpot2Reference {
    File chrom_sizes
    File center_sites
    File mappable_regions
    
}


struct HotSpot2Params {
    Float hotspot_threshold
    Float? site_call_threshold
    String? peaks_definition
}


struct HotSpot2Peaks {
    File allcalls
    Int? allcalls_count
    File cleavage
    File cutcounts
    File density_starch
    File density_bw
    File fragments
    File hotspots
    Int? hotspots_count
    File peaks
    File narrowpeaks
    Int? narrowpeaks_count
    File spot_score
}

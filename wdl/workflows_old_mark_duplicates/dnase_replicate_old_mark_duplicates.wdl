version 1.0


import "../../wdl/structs/dnase.wdl"
import "../../wdl/structs/sizes.wdl"
import "../../wdl/workflows/maybe_unpack_references.wdl" as references
import "../../wdl/workflows/concatenate_trim_and_align_fastqs.wdl" as raw_fastqs
import "merge_mark_and_filter_bams_old_mark_duplicates.wdl" as name_sorted_bams
import "../../wdl/workflows/call_hotspots_and_peaks_and_get_spot_score.wdl" as nuclear_bam
import "../../wdl/workflows/call_footprints.wdl" as hotspots
import "../../wdl/workflows/calculate_and_gather_qc.wdl" as qc_files 
import "../../wdl/workflows/normalize_and_convert_files.wdl" as bams_and_peaks


workflow dnase_replicate {
    input {
        Replicate replicate
        References references
        MachineSizes machine_sizes = read_json("wdl/default_machine_sizes.json")
    }

    call references.maybe_unpack_references as unpacked {
         input:
             replicate=replicate,
             packed_references=references,
             machine_sizes=machine_sizes,
    }

    call raw_fastqs.concatenate_trim_and_align_fastqs {
        input:
            replicate=replicate,
            references=unpacked.references,
            machine_sizes=machine_sizes,
    }

    call name_sorted_bams.merge_mark_and_filter_bams {
        input:
            name_sorted_bams=concatenate_trim_and_align_fastqs.name_sorted_bams,
            references=unpacked.references,
            machine_sizes=machine_sizes,
    }

    call nuclear_bam.call_hotspots_and_peaks_and_get_spot_score {
        input:
            nuclear_bam=merge_mark_and_filter_bams.nuclear_bam,
            replicate=replicate,
            references=unpacked.references,
            machine_sizes=machine_sizes,
    }

    call hotspots.call_footprints {
        input:
            five_percent_hotspots_starch=call_hotspots_and_peaks_and_get_spot_score.five_percent_peaks.hotspots,
            nuclear_bam=merge_mark_and_filter_bams.nuclear_bam,
            references=unpacked.references,
            machine_sizes=machine_sizes,
    }

    call qc_files.calculate_and_gather_qc {
        input:
            files_for_calculation=object {
               unfiltered_bam: merge_mark_and_filter_bams.unfiltered_bam,
               nuclear_bam: merge_mark_and_filter_bams.nuclear_bam
            },
            files_to_gather=object {
                duplication_metrics: merge_mark_and_filter_bams.duplication_metrics,
                spot_score: call_hotspots_and_peaks_and_get_spot_score.spot_score,
                trimstats: concatenate_trim_and_align_fastqs.trimstats,
                five_percent_peaks: call_hotspots_and_peaks_and_get_spot_score.five_percent_peaks,
                tenth_of_one_percent_peaks: call_hotspots_and_peaks_and_get_spot_score.tenth_of_one_percent_peaks,
                dispersion_model: call_footprints.dispersion_model,
                one_percent_footprints_count: call_footprints.one_percent_footprints_count
            },
            replicate=replicate,
            machine_sizes=machine_sizes,
    }

    call bams_and_peaks.normalize_and_convert_files {
        input:
            nuclear_bam=merge_mark_and_filter_bams.nuclear_bam,
            one_percent_footprints_bed=call_footprints.one_percent_footprints_bed,
            tenth_of_one_percent_peaks=call_hotspots_and_peaks_and_get_spot_score.tenth_of_one_percent_peaks,
            five_percent_peaks=call_hotspots_and_peaks_and_get_spot_score.five_percent_peaks,
            references=unpacked.references,
            machine_sizes=machine_sizes,
    }

    output {
        Analysis analysis = object {
            replicate: replicate,
            unfiltered_bam: merge_mark_and_filter_bams.unfiltered_bam,
            nuclear_bam: merge_mark_and_filter_bams.nuclear_bam,
            normalized_density_bw: normalize_and_convert_files.normalized_density_bw,
            five_percent_allcalls_bed_gz: normalize_and_convert_files.five_percent_allcalls_bed_gz,
            five_percent_allcalls_bigbed: normalize_and_convert_files.five_percent_allcalls_bigbed,
            tenth_of_one_percent_narrowpeaks_bed_gz: normalize_and_convert_files.tenth_of_one_percent_narrowpeaks_bed_gz,
            tenth_of_one_percent_narrowpeaks_bigbed: normalize_and_convert_files.tenth_of_one_percent_narrowpeaks_bigbed,
            tenth_of_one_percent_peaks_starch: call_hotspots_and_peaks_and_get_spot_score.tenth_of_one_percent_peaks.peaks,
            five_percent_narrowpeaks_bed_gz: normalize_and_convert_files.five_percent_narrowpeaks_bed_gz,
            five_percent_narrowpeaks_bigbed: normalize_and_convert_files.five_percent_narrowpeaks_bigbed,
            one_percent_footprints_bed_gz: normalize_and_convert_files.one_percent_footprints_bed_gz,
            one_percent_footprints_bigbed: normalize_and_convert_files.one_percent_footprints_bigbed,
            qc: object {
                unfiltered_bam_qc: calculate_and_gather_qc.unfiltered_bam_qc,
                nuclear_bam_qc: calculate_and_gather_qc.nuclear_bam_qc,
                peaks_qc: calculate_and_gather_qc.peaks_qc,
                footprints_qc: calculate_and_gather_qc.footprints_qc
            }
        }
    }
}

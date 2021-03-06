version 1.0


import "../structs/resources.wdl"


task trim_fastq_reads_to_length {
    input {
        File input_file 
        Int trim_length
        Resources resources
        String output_filename = "trimmed"
    }

    String prefix = basename(input_file)

    command <<<
        ln ~{input_file} .
        awk 'NR%2==0 {print substr($0, 1, ~{trim_length})} NR%2!=0' ~{prefix} \
            > ~{output_filename}
    >>>

    output {
        File trimmed = output_filename
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}


task shift_bed_reads_start_and_end_range {
    input {
        File bed
        Int bin_size
        Int window_size
        Resources resources
        String out = "shifted.bed"
    }

    command <<<
        awk \
            -v "binI=~{bin_size}" \
            -v "win=~{window_size}" \
            'BEGIN{halfBin=binI/2; shiftFactor=win-halfBin}
            {print $1 "\t" $2 + shiftFactor "\t" $3 - shiftFactor "\t" "id" "\t" $4}' \
            ~{bed} \
            > ~{out}
    >>>

    output {
        File shifted_bed = out
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}


task clean_reference_fasta_headers {
    input {
        File fasta
        Resources resources
        String out = "cleaned.fa" 
    }

    command <<<
        awk \
            '/^>/{$0=$1} 1' \
            ~{fasta} \
            > ~{out}
    >>>

    output {
        File cleaned_fasta = out
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}

task convert_fai_to_bed_format {
    input {
        File fai
        Resources resources
        String out = "fai_to.bed"
    }

    command <<<
        awk \
            'BEGIN{OFS="\t"} {print $1, 0, $2}' \
            ~{fai} \
            > ~{out}
    >>>

    output {
        File bed = out
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}


task merge_adjacent_bed {
    input {
        File bed
        Resources resources
        String out = "adjacent_merged.bed"
    }

    command {
        awk \
            -f $(which merge_adjacent_bed.awk) \
            ~{bed} \
            > ~{out}
    }

    output {
        File adjacent_merged_bed = out
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}


task convert_chrom_sizes_to_chrom_info {
    input {
        File chrom_sizes
        Resources resources
        String out = "chromInfo.bed"
    }

    command <<< 
        awk \
            'BEGIN{OFS="\t"} {print $1, $2, $3, $1}' \
            ~{chrom_sizes} \
            > ~{out}
    >>>

    output {
        File chrom_info = out
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}


task normalize_bed_values {
    input {
        File bed
        Int number_of_reads
        Int scale
        Resources resources
    }

    String out = "normalized." + basename(bed)

    command <<<
        awk \
            '{
                current_value=$5;
                normalized_value=(current_value / ~{number_of_reads}) * ~{scale};
                print $1 "\t" $2 "\t" $3 "\t" $4 "\t" normalized_value
            }' \
            ~{bed} \
            > ~{out}
    >>>

    output {
        File normalized_bed = out
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}


task extract_histogram_from_picard_insert_size_metrics {
    input {
        File insert_size_metrics
        Resources resources
        String out = "histogram.tsv"
    }

    command <<<
        awk \
            '/## HISTOGRAM/{x=1;next}x' \
            ~{insert_size_metrics} \
            > ~{out}
    >>>

    output {
        File histogram = out
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}


task filter_and_window_footprints_bedgraph {
    input {
        File bedgraph
        Float threshold
        Int window
        Resources resources
    }

    String out = basename(bedgraph, "bedgraph") + ".fps." + threshold + ".bedgraph"

    command <<<
        awk \
            -v OFS="\t" \
            -v threshold=~{threshold} \
            -v window=~{window} \
            '$8 <= threshold {print $1, $2 - window, $3 + window;}' \
            ~{bedgraph} \
            > ~{out}
    >>>

    output {
        File footprints_bedgraph = out
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}


task add_name_and_score_to_footprints_bed {
    input {
        File bed
        Float threshold
        Resources resources
    }

    String out = "footprints.fps." + threshold + ".bed"

    command <<<
        awk \
            -v OFS="\t" \
            -v threshold=~{threshold} \
            '{$4="."; $5=threshold; print;}' \
            ~{bed} \
            > ~{out}
    >>>

    output {
        File footprints_bed = out
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}

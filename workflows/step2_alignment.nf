nextflow.enable.dsl = 2

// Step 2: BWA-MEM alignment, duplicate marking, BAM QC, BQSR.

params.sample       = 'HG002'
params.accession    = 'SRR14724472'
params.r1           = null                       // required: standardized R1 path chosen by the launcher
params.r2           = null                       // required: standardized R2 path chosen by the launcher
params.ref_dir      = 'data/reference'
params.interval     = 'chr20'                    // QC depth/breadth and BQSR training region
params.targets      = 'data/reference/idt_capture_novogene.grch38.bed'
params.outdir       = 'results/raw_results/02_alignment'
params.bwa_threads  = 4
params.java_mem     = '4g'

process BWA_MEM_SORT {
    tag "${id}"

    input:
    tuple val(id), path(r1), path(r2)
    path ref_files

    output:
    tuple val(id), path("${id}.sorted.bam")

    script:
    """
    bwa mem -t ${params.bwa_threads} -K 100000000 -Y \\
        -R '@RG\\tID:${params.accession}\\tSM:${params.sample}\\tPL:ILLUMINA\\tLB:${params.sample}_lib1\\tPU:${params.accession}' \\
        Homo_sapiens_assembly38.fasta ${r1} ${r2} \\
      | samtools sort -@ 2 -m 768M -o ${id}.sorted.bam -
    test -s ${id}.sorted.bam
    samtools quickcheck -v ${id}.sorted.bam
    """
}

process INDEX_SORTED {
    tag "${id}"
    publishDir "${params.outdir}/sorted", mode: 'copy'

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path(bam), path("${bam}.bai")

    script:
    """
    samtools index -@ 2 ${bam}
    """
}

process MARK_DUPLICATES {
    tag "${id}"
    publishDir "${params.outdir}/markdup", mode: 'copy'

    input:
    tuple val(id), path(bam), path(bai)

    output:
    tuple val(id), path("${id}.markdup.bam"), path("${id}.markdup.bai"), emit: bam
    path "${id}.markdup_metrics.txt", emit: metrics

    // Duplicates are flagged, not removed.
    script:
    """
    gatk --java-options "-Xmx${params.java_mem}" MarkDuplicates \\
        -I ${bam} -O ${id}.markdup.bam -M ${id}.markdup_metrics.txt \\
        --REMOVE_DUPLICATES false --CREATE_INDEX true --TMP_DIR .
    test -s ${id}.markdup.bam
    test -s ${id}.markdup.bai
    test -s ${id}.markdup_metrics.txt
    """
}

process BAM_VALIDATE {
    tag "${id}"
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    tuple val(id), path(bam), path(bai)
    path ref_files

    output:
    path "${id}.validatesam.txt"

    // bwa and Picard compute NM differently at IUPAC bases in GRCh38; other error types still fail.
    script:
    """
    gatk --java-options "-Xmx${params.java_mem}" ValidateSamFile \\
        -I ${bam} -R Homo_sapiens_assembly38.fasta --MODE SUMMARY \\
        --IGNORE INVALID_TAG_NM \\
        > ${id}.validatesam.txt
    """
}

process BAM_SAMTOOLS_QC {
    tag "${id}"
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    tuple val(id), path(bam), path(bai)

    output:
    path "${id}.stats.txt"
    path "${id}.${params.interval}.coverage.tsv"

    script:
    """
    samtools stats -@ 2 ${bam} > ${id}.stats.txt
    samtools coverage -r ${params.interval} ${bam} > ${id}.${params.interval}.coverage.tsv
    """
}

process BAM_CHECK {
    tag "${id}:${stage}"
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    tuple val(stage), val(id), path(bam), path(bai)

    output:
    path "${id}.${stage}.flagstat.txt"

    script:
    """
    test -s ${bam}
    test -s ${bai}
    samtools quickcheck -v ${bam}
    samtools flagstat -@ 2 ${bam} > ${id}.${stage}.flagstat.txt
    test -s ${id}.${stage}.flagstat.txt
    """
}

process INSERT_SIZE {
    tag "${id}"
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    tuple val(id), path(bam), path(bai)

    output:
    path "${id}.insert_size_metrics.txt"
    path "${id}.insert_size_histogram.pdf", optional: true

    script:
    """
    gatk --java-options "-Xmx${params.java_mem}" CollectInsertSizeMetrics \\
        -I ${bam} -O ${id}.insert_size_metrics.txt -H ${id}.insert_size_histogram.pdf
    """
}

process HS_METRICS {
    tag "${id}"
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    tuple val(id), path(bam), path(bai)
    path ref_files
    path targets

    output:
    path "${id}.hs_metrics.txt"
    path "${id}.per_target_coverage.txt"

    // Bait set is unpublished; the target BED is used for both bait and target intervals.
    script:
    """
    gatk BedToIntervalList -I ${targets} -O targets.interval_list -SD Homo_sapiens_assembly38.dict
    gatk --java-options "-Xmx${params.java_mem}" CollectHsMetrics \\
        -I ${bam} -R Homo_sapiens_assembly38.fasta \\
        --BAIT_INTERVALS targets.interval_list --TARGET_INTERVALS targets.interval_list \\
        -O ${id}.hs_metrics.txt --PER_TARGET_COVERAGE ${id}.per_target_coverage.txt
    """
}

process BASE_RECALIBRATOR {
    tag "${id}"
    publishDir "${params.outdir}/bqsr", mode: 'copy'

    input:
    tuple val(id), path(bam), path(bai)
    path ref_files
    path known_sites

    output:
    path "${id}.recal.table"

    script:
    """
    gatk --java-options "-Xmx${params.java_mem}" BaseRecalibrator \\
        -I ${bam} -R Homo_sapiens_assembly38.fasta \\
        --known-sites Homo_sapiens_assembly38.dbsnp138.vcf \\
        --known-sites Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \\
        -L ${params.interval} -O ${id}.recal.table
    """
}

process APPLY_BQSR {
    tag "${id}"
    publishDir "${params.outdir}/bqsr", mode: 'copy'

    input:
    tuple val(id), path(bam), path(bai)
    path table
    path ref_files

    output:
    tuple val(id), path("${id}.recal.bam"), path("${id}.recal.bai")

    script:
    """
    gatk --java-options "-Xmx${params.java_mem}" ApplyBQSR \\
        -I ${bam} -R Homo_sapiens_assembly38.fasta \\
        --bqsr-recal-file ${table} -O ${id}.recal.bam
    test -s ${id}.recal.bam
    test -s ${id}.recal.bai
    """
}

workflow {
    if( !params.r1 || !params.r2 )
        error "--r1 and --r2 are required"
    reads = Channel.of(tuple(
        params.sample,
        file(params.r1, checkIfExists: true),
        file(params.r2, checkIfExists: true)
    ))

    ref_files = Channel.value(
        files("${params.ref_dir}/Homo_sapiens_assembly38.fasta*") +
        [file("${params.ref_dir}/Homo_sapiens_assembly38.dict", checkIfExists: true)]
    )
    known_sites = Channel.value(
        files("${params.ref_dir}/Homo_sapiens_assembly38.dbsnp138.vcf*") +
        files("${params.ref_dir}/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz*")
    )

    sorted = INDEX_SORTED(BWA_MEM_SORT(reads, ref_files))
    md     = MARK_DUPLICATES(sorted)

    BAM_VALIDATE(md.bam, ref_files)
    BAM_SAMTOOLS_QC(md.bam)
    INSERT_SIZE(md.bam)
    HS_METRICS(md.bam, ref_files, file(params.targets, checkIfExists: true))

    table = BASE_RECALIBRATOR(md.bam, ref_files, known_sites)
    recal = APPLY_BQSR(md.bam, table, ref_files)

    checks = sorted.map { id, bam, bai -> tuple('sorted', id, bam, bai) }
        .mix(md.bam.map { id, bam, bai -> tuple('markdup', id, bam, bai) })
        .mix(recal.map { id, bam, bai -> tuple('recal', id, bam, bai) })
    BAM_CHECK(checks)
}

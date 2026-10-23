nextflow.enable.dsl = 2

// Step 1: raw QC, recorded QC decision, optional fastp trimming, post-trim QC.

params.accession      = 'SRR14724472'            // HG002 / NA24385
params.reads_dir      = 'data/raw_input'         // md5-verified ENA downloads
params.outdir         = 'results/raw_results/01_fastqc'

// Two-pass use: first run without --decision (raw FastQC, then stop); review reports; rerun with --decision.
params.decision       = null                     // proceed | trim | hold
params.justification  = null                     // required with --decision

// fastp settings (explicit, no silent defaults)
params.adapter_r1     = 'AGATCGGAAGAGCACACGTCTGAACTCCAGTCA'  // Illumina TruSeq
params.adapter_r2     = 'AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT'
params.qualified_q    = 20     // base is "qualified" if Phred >= this
params.unqualified_pct = 40    // drop read if > this % of bases are unqualified
params.n_base_limit   = 5      // drop read if > this many N bases
params.min_length     = 50     // drop read/pair shorter than this after trimming
params.trim_poly_g    = true   // NovaSeq two-colour chemistry artefact

process FASTQC {
    tag "${id}:${stage}"
    publishDir { "${params.outdir}/fastqc_${stage}" }, mode: 'copy'

    input:
    tuple val(stage), val(id), path(r1), path(r2)

    output:
    path "*_fastqc.{html,zip}"

    script:
    """
    fastqc --threads 2 --outdir . ${r1} ${r2}
    """
}

process RECORD_DECISION {
    publishDir params.outdir, mode: 'copy'

    output:
    path 'qc_decision.json'

    script:
    """
    printf '{"accession": "%s", "decision": "%s", "justification": "%s", "date": "%s"}\\n' \\
        '${params.accession}' '${params.decision}' '${params.justification}' "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" > qc_decision.json
    """
}

process FASTP {
    tag "${id}"
    publishDir "${params.outdir}/trimmed", mode: 'copy'

    input:
    tuple val(id), path(r1), path(r2)

    output:
    tuple val(id), path("trimmed_read_1.fastq.gz"), path("trimmed_read_2.fastq.gz"), emit: reads
    path "${id}.fastp.{html,json}", emit: reports

    // No --merge, --correction or --dedup: all disabled by default and left off deliberately.
    script:
    """
    fastp \\
        --in1 ${r1} --in2 ${r2} \\
        --out1 trimmed_read_1.fastq.gz --out2 trimmed_read_2.fastq.gz \\
        --adapter_sequence ${params.adapter_r1} \\
        --adapter_sequence_r2 ${params.adapter_r2} \\
        --qualified_quality_phred ${params.qualified_q} \\
        --unqualified_percent_limit ${params.unqualified_pct} \\
        --n_base_limit ${params.n_base_limit} \\
        --length_required ${params.min_length} \\
        ${params.trim_poly_g ? '--trim_poly_g' : '--disable_trim_poly_g'} \\
        --thread ${task.cpus} \\
        --html ${id}.fastp.html --json ${id}.fastp.json
    """
}

workflow {
    if( params.decision && !(params.decision in ['proceed', 'trim', 'hold']) )
        error "--decision must be proceed, trim or hold"
    if( params.decision && !params.justification )
        error "--justification is required with --decision"

    raw = Channel.of(tuple(
        params.accession,
        file("${params.reads_dir}/${params.accession}_1.fastq.gz", checkIfExists: true),
        file("${params.reads_dir}/${params.accession}_2.fastq.gz", checkIfExists: true)
    ))
    qc_inputs = raw.map { id, r1, r2 -> tuple('raw', id, r1, r2) }

    if( !params.decision ) {
        log.info "Raw QC only. Review ${params.outdir}/fastqc_raw, then rerun with --decision proceed|trim|hold --justification '...'"
    }
    else {
        RECORD_DECISION()
        if( params.decision == 'hold' ) {
            log.warn "Decision: hold. Not passing reads onward."
        }
        else if( params.decision == 'trim' ) {
            trimmed = FASTP(raw).reads
            qc_inputs = qc_inputs.mix(trimmed.map { id, r1, r2 -> tuple('trimmed', id, r1, r2) })
            trimmed.view { "Selected FASTQ for step 2: ${it[1]}, ${it[2]}" }
        }
        else {
            raw.view { "Selected FASTQ for step 2 (original): ${it[1]}, ${it[2]}" }   // proceed: unchanged
        }
    }

    FASTQC(qc_inputs)
}

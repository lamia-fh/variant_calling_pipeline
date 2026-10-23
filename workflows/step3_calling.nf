nextflow.enable.dsl = 2

// Step 3: HaplotypeCaller (GVCF) -> GenotypeGVCFs -> hard filtering -> PASS VCF -> VCF QC. Exome targets on chr20.

params.sample       = 'HG002'
params.bam          = 'results/raw_results/02_alignment/bqsr/HG002.recal.bam'
params.bai          = 'results/raw_results/02_alignment/bqsr/HG002.recal.bai'
params.ref_dir      = 'data/reference'
params.targets      = 'data/reference/idt_capture_novogene.grch38.bed'
params.interval     = 'chr20'
params.padding      = 100
params.outdir       = 'results/raw_results/03_calling'
params.java_mem     = '4g'

// GATK hard-filter recommendations for germline short variants.
params.snp_filters   = 'QD < 2.0 || QUAL < 30.0 || SOR > 3.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0'
params.indel_filters = 'QD < 2.0 || QUAL < 30.0 || FS > 200.0 || ReadPosRankSum < -20.0'

process HAPLOTYPECALLER {
    tag "${id}"
    publishDir "${params.outdir}/gvcf", mode: 'copy'

    input:
    tuple val(id), path(bam), path(bai)
    path ref_files
    path targets

    output:
    tuple val(id), path("${id}.g.vcf.gz"), path("${id}.g.vcf.gz.tbi")

    script:
    """
    gatk --java-options "-Xmx${params.java_mem}" HaplotypeCaller \\
        -R Homo_sapiens_assembly38.fasta -I ${bam} -O ${id}.g.vcf.gz -ERC GVCF \\
        -L ${targets} -L ${params.interval} --interval-set-rule INTERSECTION -ip ${params.padding}
    test -s ${id}.g.vcf.gz.tbi
    """
}

process GENOTYPE_GVCFS {
    tag "${id}"
    publishDir "${params.outdir}/raw", mode: 'copy'

    input:
    tuple val(id), path(gvcf), path(tbi)
    path ref_files
    path targets

    output:
    tuple val(id), path("${id}.raw.vcf.gz"), path("${id}.raw.vcf.gz.tbi")

    script:
    """
    gatk --java-options "-Xmx${params.java_mem}" GenotypeGVCFs \\
        -R Homo_sapiens_assembly38.fasta -V ${gvcf} -O ${id}.raw.vcf.gz \\
        -L ${targets} -L ${params.interval} --interval-set-rule INTERSECTION -ip ${params.padding}
    test -s ${id}.raw.vcf.gz.tbi
    """
}

process SELECT_FILTER {
    tag "${id}"

    input:
    tuple val(id), path(vcf), path(tbi)
    path ref_files

    output:
    tuple val(id), path("${id}.snps.filtered.vcf.gz"), path("${id}.indels.filtered.vcf.gz"), path("${id}.other.vcf.gz")

    // Filters label records (FILTER column); nothing is removed here. MNP/mixed/symbolic records are kept unfiltered.
    script:
    """
    gatk SelectVariants -R Homo_sapiens_assembly38.fasta -V ${vcf} --select-type-to-include SNP -O snps.vcf.gz
    gatk SelectVariants -R Homo_sapiens_assembly38.fasta -V ${vcf} --select-type-to-include INDEL -O indels.vcf.gz
    gatk SelectVariants -R Homo_sapiens_assembly38.fasta -V ${vcf} \\
        --select-type-to-exclude SNP --select-type-to-exclude INDEL -O ${id}.other.vcf.gz
    gatk VariantFiltration -R Homo_sapiens_assembly38.fasta -V snps.vcf.gz \\
        --filter-name SNP_HARD --filter-expression "${params.snp_filters}" -O ${id}.snps.filtered.vcf.gz
    gatk VariantFiltration -R Homo_sapiens_assembly38.fasta -V indels.vcf.gz \\
        --filter-name INDEL_HARD --filter-expression "${params.indel_filters}" -O ${id}.indels.filtered.vcf.gz
    """
}

process MERGE_LABEL {
    tag "${id}"
    publishDir "${params.outdir}/filtered", mode: 'copy'

    input:
    tuple val(id), path(snps), path(indels), path(other)

    output:
    tuple val(id), path("${id}.labelled.vcf.gz"), path("${id}.labelled.vcf.gz.tbi")

    script:
    """
    gatk MergeVcfs -I ${snps} -I ${indels} -I ${other} -O ${id}.labelled.vcf.gz
    test -s ${id}.labelled.vcf.gz.tbi
    """
}

process BCFTOOLS_PASS {
    tag "${id}"
    publishDir "${params.outdir}/filtered", mode: 'copy'

    input:
    tuple val(id), path(vcf), path(tbi)

    output:
    tuple val(id), path("${id}.pass.vcf.gz"), path("${id}.pass.vcf.gz.tbi"), emit: pass
    path "${id}.labelled.bcftools_stats.txt", emit: stats_all
    path "${id}.pass.bcftools_stats.txt", emit: stats_pass

    script:
    """
    bcftools view -f PASS -Oz -o ${id}.pass.vcf.gz ${vcf}
    bcftools index -t ${id}.pass.vcf.gz
    bcftools stats ${vcf} > ${id}.labelled.bcftools_stats.txt
    bcftools stats ${id}.pass.vcf.gz > ${id}.pass.bcftools_stats.txt
    """
}

process VALIDATE_VCF {
    tag "${id}"
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    tuple val(id), path(vcf), path(tbi)
    path ref_files

    output:
    path "${id}.validate_variants.log"

    script:
    """
    gatk ValidateVariants -R Homo_sapiens_assembly38.fasta -V ${vcf} > ${id}.validate_variants.log 2>&1
    """
}

workflow {
    bam = Channel.of(tuple(
        params.sample,
        file(params.bam, checkIfExists: true),
        file(params.bai, checkIfExists: true)
    ))
    ref_files = Channel.value(
        files("${params.ref_dir}/Homo_sapiens_assembly38.fasta*") +
        [file("${params.ref_dir}/Homo_sapiens_assembly38.dict", checkIfExists: true)]
    )
    targets = Channel.value(file(params.targets, checkIfExists: true))

    gvcf     = HAPLOTYPECALLER(bam, ref_files, targets)
    raw      = GENOTYPE_GVCFS(gvcf, ref_files, targets)
    filtered = MERGE_LABEL(SELECT_FILTER(raw, ref_files))
    passed   = BCFTOOLS_PASS(filtered)
    VALIDATE_VCF(passed.pass, ref_files)
}

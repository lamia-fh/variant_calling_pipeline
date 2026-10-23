# Nextflow Variant Calling Workflow: Step-by-Step Explanation

## Purpose and scope

This workflow turns paired-end DNA sequencing reads into a quality-reviewed set of small genetic variants: single-nucleotide polymorphisms (SNPs) and short insertions/deletions (indels). The diagram specifies NA12878 / HG001, alignment against the full GRCh38 reference, and variant analysis focused on chromosome 20 (chr20). A separate, later stage compares calls with Genome in a Bottle (GIAB) benchmark data. [file:1]

The main logic is:

`Check reads → align reads → prepare and assess alignments → call variants → filter and validate outputs → benchmark accuracy`

Status: this is an explanation of the proposed design, not evidence that the pipeline has run or achieved a particular accuracy. The diagram explicitly labels it as not yet executed or accuracy-validated. [file:1]

## 1. Read QC and optional trimming

### 1.1 Paired reads: the starting input

- Purpose: provide the original sequence observations for the sample.
- What they contain: R1 and R2 are the two reads from each paired-end DNA fragment. FASTQ files contain sequence bases and their associated quality scores.
- Output to the next step: `R1.fastq.gz` and `R2.fastq.gz`.

The read pairs are kept together through preprocessing so that alignment can use their paired-end relationship. [web:17]

### 1.2 FastQC: inspect the reads before changing them

- Purpose: identify quality patterns or possible problems before alignment.
- What it does: produces summaries of read quality and sequence characteristics, including potential adapter contamination.
- Output: an HTML report for review and a ZIP archive containing report data.

FastQC diagnoses potential problems; it does not trim or repair the reads. [web:17]

### 1.3 Review QC: decide whether intervention is needed

- Purpose: turn the QC report into a processing decision.
- What happens in this design:
  - Keep the original reads when trimming is not needed.
  - Send reads to `fastp` when adapter contamination warrants trimming.
  - Investigate or hold the sample when other concerns require attention.
- Output: a decision about which route the reads should follow.

This is a review gate, not an instruction to trim every sample automatically. [file:1]

### 1.4 fastp: trim adapters and apply configured read filtering

- Purpose: remove unwanted technical sequence and apply selected preprocessing rules before alignment.
- What it does: trims adapter sequence and can perform quality- or length-based filtering and trimming, depending on its settings.
- Output: processed paired FASTQ files, plus HTML and JSON reports.

Adapter trimming removes sequencing-library sequence that is not part of the intended DNA fragment. Quality trimming and other filtering actions depend on the options used; they should not be assumed merely because `fastp` was run. [web:17][web:27]

### 1.5 FastQC and review after trimming: check the result

- Purpose: verify that the preprocessing addressed the original concern and assess the remaining reads.
- What it does: repeats read-level QC on the processed files and reviews the results.
- Output: post-trimming FastQC reports and a decision to proceed or investigate further.

This second review is explicitly included in the diagram rather than treating trimming as automatically successful. [file:1]

### 1.6 Selected paired FASTQ: choose the alignment input

- Purpose: provide one clearly identified pair of read files for alignment.
- What happens: select either the original reads or the reviewed, trimmed reads.
- Output: the paired `.fastq.gz` files passed to alignment.

This is a handoff point, not another sequence-processing tool. [file:1]

## 2. Alignment, BAM QC, and recalibration

### 2.1 Full GRCh38 reference resources: define the coordinate system

- Purpose: supply the reference genome and supporting lookup files used by the alignment and GATK steps.
- Inputs shown: reference FASTA (`.fa`), FASTA index (`.fai`), sequence dictionary (`.dict`), and BWA indexes.
- Design scope: align against the full GRCh38 reference even though the downstream analysis focuses on chr20.

These are workflow inputs, not sequencing results. The diagram distinguishes full-reference alignment from chromosome-restricted analysis. [file:1]

### 2.2 BWA-MEM: place reads on the reference genome

- Purpose: determine where the sequencing reads most likely originated in the reference genome.
- What it does: aligns the selected reads to GRCh38, producing alignment records that include genomic positions and alignment information.
- Output in this design: SAM alignment records streamed directly into `SAMtools sort`, rather than saved as a separate intermediate SAM file. [file:1][web:30]

### 2.3 SAMtools sort: organize alignments by genomic position

- Purpose: put the alignments in the order required for efficient regional access and downstream processing.
- What it does: sorts alignment records by reference coordinate and writes them in BAM format.
- Output: a coordinate-sorted `.bam` file.

Sorting organizes existing alignments; it does not redo the alignment. Coordinate sorting is required for the BAM indexing used here. [web:20]

### 2.4 SAMtools index: create a lookup file for the sorted BAM

- Purpose: allow tools to access a genomic region without reading the entire BAM sequentially.
- What it does: builds an index for the coordinate-sorted alignment file.
- Output: the BAM and its `.bai` index in this design.

The index is a companion lookup file, not a second copy of the read alignments. [web:20]

### 2.5 GATK MarkDuplicates: flag potentially redundant read evidence

- Purpose: reduce the risk of treating multiple copies of the same original DNA fragment as independent evidence.
- What it does: identifies reads that appear to be duplicates and marks them in the BAM; it also writes duplication metrics.
- Output: a duplicate-marked BAM and metrics text file.

In this workflow, duplicates are flagged, not removed. Calling the output a “deduplicated BAM” can therefore be misleading: the records remain in the file, with flags that downstream tools can use. [file:1][web:3][web:14]

### 2.6 Re-index and validate the marked BAM: make the new file usable

- Purpose: ensure that the modified BAM has its own corresponding index and passes structural checks.
- What it does: indexes the marked BAM and runs the `ValidateSamFile` check shown in the diagram.
- Output: `.bam`, `.bai`, and a validation report.

This is a file-readiness check, not a demonstration that variant calls will be accurate. [file:1]

### 2.7 Alignment QC reports: assess the evidence available for calling

The diagram groups several complementary checks beneath the alignment steps:

| Tool or metric | Purpose | Question it helps answer |
|---|---|---|
| `SAMtools flagstat` | Summarize alignment categories from read flags | How many reads are mapped, paired, or marked as duplicates? |
| `SAMtools stats` | Summarize alignment and sequence statistics | Are there unusual patterns in the aligned data? |
| `SAMtools coverage` | Summarize coverage over the target region | How well is chr20 represented by the reads? |
| `Picard CollectInsertSizeMetrics` | Summarize inferred fragment lengths | Does the paired-end insert-size pattern look appropriate for the library? |

The design calls for reports on mapping, duplicates, insert sizes, and chr20 depth and breadth. Depth describes how many reads cover a position; breadth describes how much of the region is covered at a stated depth criterion. These metrics help assess the input evidence, rather than directly measuring variant accuracy. [file:1][web:5][web:25]

### 2.8 Known variant sites: help separate real variation from sequencing error

- Purpose: provide known variable positions for base-quality recalibration.
- What they do: help prevent genuine variation at those positions from being treated as sequencing error when the recalibration model is estimated.
- Input: indexed known-sites VCF files compatible with the reference.

These resources support error modelling. They are not the same thing as the GIAB truth dataset used later to evaluate the final calls. [web:3][file:1]

### 2.9 GATK BaseRecalibrator: learn systematic base-quality errors

- Purpose: estimate how the reported base-quality scores differ from observed error patterns.
- What it does: builds a model using the alignment data, reference, known sites, and relevant read covariates.
- Output: a recalibration table.

A base-quality score expresses confidence in an individual sequenced base. This step learns adjustments to those confidence scores; it does not yet produce the recalibrated BAM. [web:3]

### 2.10 GATK ApplyBQSR: apply the learned quality adjustments

- Purpose: make the base-quality scores better reflect the modelled error patterns.
- What it does: applies the recalibration table to the BAM.
- Output: a recalibrated BAM and corresponding index in this design.

The operation adjusts base-quality scores, rather than re-aligning reads or replacing their sequence bases. It needs both the BAM and the recalibration table. [web:3][file:1]

## 3. Variant calling, filtering, and output QC

### 3.1 Recalibrated BAM: hand off the prepared evidence

- Purpose: provide the alignment evidence used for variant calling.
- Input: the recalibrated `.bam` and its `.bai` index.
- Scope: the design specifies chr20 variant analysis after alignment to the full reference.

This box is a data handoff, not an additional transformation. [file:1]

### 3.2 GATK HaplotypeCaller: identify candidate variants and record evidence

- Purpose: identify possible SNPs and short indels from the aligned reads.
- What it does: uses local haplotype assembly and evaluates the read evidence. In GVCF mode, it records variant evidence and reference-confidence information for subsequent genotyping.
- Output: `.g.vcf.gz` and an index.

The GVCF is an intermediate evidence file, not the final filtered variant list. [web:3][web:8]

### 3.3 GATK GenotypeGVCFs: turn GVCF evidence into genotype calls

- Purpose: produce a conventional VCF containing genotype calls from GVCF evidence.
- What it does: evaluates the evidence and assigns genotypes at variant sites.
- Output: a raw, unfiltered `.vcf.gz` and index.

In this single-sample design, this is not automatically a multi-sample joint-genotyping analysis. The broader GATK workflow can also use this stage to genotype across multiple samples. “Raw” means that the downstream filtering shown here has not yet been applied. [web:3][web:8][file:1]

### 3.4 GATK SelectVariants: separate record types for appropriate handling

- Purpose: route SNPs and indels into the relevant filtering paths.
- What it does: selects records according to their variant type.
- Output: type-specific VCF files for the next operation.

The diagram also preserves other record types separately, rather than silently discarding them. Their preservation does not imply that they pass the SNP/indel filters. [web:14][file:1]

### 3.5 GATK VariantFiltration: label calls that fail quality rules

- Purpose: identify variants whose annotations do not meet the selected quality criteria.
- What it does: applies explicit hard-filtering rules and records failed filters in the VCF `FILTER` field.
- Output: filter-labelled SNP and indel VCF files.

Labelling a variant as failing is different from removing its record. The diagram does not specify the actual expressions or thresholds, so it does not yet fully define the filtering policy. [web:6][web:14][file:1]

### 3.6 BCFtools view and index: create usable callsets

- Purpose: provide both an auditable labelled callset and a restricted PASS-only callset.
- What it does: selects the desired records, writes compressed VCF outputs, and indexes them for regional access.
- Output: labelled and PASS-only `.vcf.gz` files with indexes.

`PASS` means that a record passed the filters applied in this workflow; it is not proof that the variant is biologically true. The diagram specifies `.tbi` indexes, so the implementation must explicitly produce those if required: BCFtools otherwise creates CSI indexes by default. [web:18][file:1]

### 3.7 BCFtools stats: summarize the final callsets

- Purpose: provide an overview of the variants produced by the pipeline.
- What it does: generates statistics describing VCF contents, such as counts and variant-type summaries.
- Output: text-based statistics reports.

These summaries help reveal unexpected patterns or changes between callsets, but do not independently establish sensitivity or precision. [web:18]

### 3.8 GATK ValidateVariants: check VCF consistency

- Purpose: check that the VCF satisfies the selected format and consistency requirements.
- What it does: validates the VCF and, depending on the checks enabled, tests consistency with supplied resources such as the reference.
- Output: a validation log.

A structurally valid VCF may still contain incorrect calls or miss real variants. File validation and biological accuracy assessment are different tasks. [web:21]

## 4. Later benchmarking against GIAB truth

### 4.1 GIAB truth VCF and benchmark BED: define the comparison target

- Purpose: provide benchmark variants and the genomic regions where comparison is supported.
- Inputs: the HG001 truth VCF, its index, and the associated benchmark-region BED.
- Requirement: the query calls and truth resources must correspond to the same sample and use compatible reference coordinates.

The truth VCF lists benchmark variants; the BED defines the regions used for evaluation. Absence of a truth record outside those regions should not automatically be treated as evidence that a query call is false. [web:2][web:12]

### 4.2 BEDtools intersect: define the chr20 evaluation region

- Purpose: limit evaluation to the overlap between chr20 analysis regions and the GIAB benchmark regions.
- What it does: intersects the region definitions.
- Output: a chr20 evaluation BED file.

This step defines where performance is measured; it does not compare the variant calls itself. [file:1]

### 4.3 hap.py or RTG vcfeval: compare query calls with truth

- Purpose: determine which calls agree with the benchmark and which are missed or unsupported within the evaluation region.
- What it does: compares query and truth variants using approaches that account for the fact that equivalent sequence changes can have different VCF representations.
- Inputs: query VCF, truth VCF, reference, and evaluation regions.
- Output: comparison results and performance summaries.

This is more informative than matching VCF lines literally, especially for indels and complex representations. [web:2][web:12]

### 4.4 Precision, recall, and F1: quantify calling performance

| Metric | Plain-language meaning | Formula |
|---|---|---|
| Precision | Of the evaluated calls made by the pipeline, what fraction agree with truth? | `TP / (TP + FP)` |
| Recall | Of the benchmark variants, what fraction did the pipeline recover? | `TP / (TP + FN)` |
| F1 | A combined measure balancing precision and recall | `2 × precision × recall / (precision + recall)` |

`TP` means true positives, `FP` means false positives, and `FN` means false negatives, under the comparator's matching and counting rules. Report SNPs and indels separately, and state the truth release, evaluated regions, matching settings, and callset being assessed. These results describe performance within the benchmarked scope, not necessarily across the whole genome. [web:2][web:4][web:12]

## 5. Nextflow, Docker, and provenance

These elements support the entire workflow rather than one individual biological analysis step.

### 5.1 Nextflow: coordinate execution

- Purpose: organize the tools and file handoffs into an executable workflow.
- Role in this design: connect the processing stages and collect run-level execution outputs. [file:1]

### 5.2 Docker: specify the software environment

- Purpose in this design: package the software used by the processing steps in defined container environments.
- Provenance requirement: record image digests as well as tool versions so that the intended software environment is identifiable. [file:1]

### 5.3 Provenance records: document what was run

The diagram calls for recording:

- Container image digests.
- Input/reference checksums.
- The workflow's Git commit.
- Tool versions.
- Resolved parameter values.

Together, these records document the inputs, code, software, and settings associated with an execution. The diagram lists them as design requirements; their actual capture still needs implementation and verification. [file:1]

### 5.4 Execution reports: inspect how the run behaved

- `report.html`: summarizes the run, tasks, and resource use.
- `trace.tsv`: records task-level execution information; the exact fields and delimiter are configurable.
- `timeline.html`: shows when tasks ran and how long they took.

These outputs support operational review and troubleshooting. They do not replace read QC, VCF validation, or benchmarking against truth. [web:19]

## Key distinctions to remember

1. Read QC asks whether the starting sequence data look suitable. [web:17]
2. Alignment QC asks whether the reads provide suitable mapped evidence. [web:5][web:25]
3. Filtering applies a stated policy for retaining or labelling variant calls. [web:6][web:14]
4. File validation asks whether an output satisfies structural and consistency requirements. [web:21]
5. Benchmarking asks how accurately the pipeline recovered known variants within an explicitly defined evaluation scope. [web:2][web:12]

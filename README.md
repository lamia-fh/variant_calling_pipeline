# Variant Calling Pipeline

A Nextflow-based WES variant-calling pipeline for paired-end Illumina reads using FastQC, fastp, BWA, SAMtools, GATK, and bcftools.

Environment: Linux/WSL2 + Docker.

## Overview

The pipeline processes paired-end HG002 reads against GRCh38. Alignment covers the full reference, while recalibration QC and variant calling are scoped to chr20 and the configured capture targets. Each stage is launched separately so raw-read QC can be reviewed before reads proceed.

## Features

- Staged, reproducible Nextflow workflows with containerised tools (Docker profile).
- Explicit QC gate: choose `proceed`, `trim`, or `hold` after reviewing raw FastQC reports; the decision is recorded as JSON.
- GATK best-practice steps: duplicate marking, BQSR, HaplotypeCaller (GVCF), GenotypeGVCFs, and hard filtering.
- QC at each stage: FastQC, SAMtools/Picard BAM metrics, hybrid-selection metrics, bcftools stats, and VCF validation.
- Launcher scripts with preflight checks, logging, and `-resume`.

## Pipeline Overview

```
FASTQ
 ↓
Quality Control (FastQC) → QC decision (proceed | trim | hold)
 ↓
Optional trimming (fastp) + post-trim FastQC
 ↓
Alignment (BWA-MEM) + sorting/indexing (SAMtools)
 ↓
Mark Duplicates (GATK) + BAM QC
 ↓
Base Quality Score Recalibration (BQSR)
 ↓
Variant Calling (GATK HaplotypeCaller, GVCF)
 ↓
Genotyping (GenotypeGVCFs)
 ↓
Hard-filter labelling (SNP / INDEL)
 ↓
PASS Variant Selection (bcftools) + VCF QC
```

## Tools Used

| Tool | Version | Used for |
|---|---|---|
| Nextflow | - | Workflow management |
| FastQC | 0.12.1 | Read quality control |
| fastp | 0.23.4 | Optional adapter/quality trimming |
| BWA, SAMtools | mulled biocontainer (see `workflows/nextflow.config`) | Alignment, sorting, indexing, BAM QC |
| GATK | 4.5.0.0 | Duplicates, BQSR, calling, filtering, metrics |
| bcftools | 1.20 | PASS selection and VCF statistics |
| Docker | - | Container runtime |

## Project Structure

```
variant_calling_pipeline/
├── README.md
├── scripts/
│   ├── run_step1_fastqc.sh
│   ├── run_step2_alignment.sh
│   └── run_step3_calling.sh
├── workflows/
│   ├── nextflow.config
│   ├── step1_fastqc.nf
│   ├── step2_alignment.nf
│   └── step3_calling.nf
├── data/
│   ├── raw_input/      # FASTQ files
│   └── reference/      # GRCh38 reference, known sites, capture BED
├── results/
│   ├── raw_results/    # 01_fastqc, 02_alignment, 03_calling
│   ├── summary/        # written QC summaries
│   └── nextflow/       # per-run reports, traces, timelines
└── logs/               # launcher logs
```

## Workflow Steps

1. **Read QC and decision** (`workflows/step1_fastqc.nf`): run FastQC on raw reads. Review the reports and explicitly choose `proceed`, `trim`, or `hold`. The `trim` option runs fastp and FastQC on the trimmed reads; `proceed` keeps the original reads. The decision and its justification are recorded in `results/raw_results/01_fastqc/qc_decision.json`.
2. **Alignment and recalibration** (`workflows/step2_alignment.nf`): align reads with BWA-MEM, sort and index with SAMtools, mark duplicates with GATK, generate BAM QC metrics, and apply BQSR using the known-sites files.
3. **Variant calling and filtering** (`workflows/step3_calling.nf`): create a GVCF with GATK HaplotypeCaller, genotype it, label SNP and indel hard-filter failures, preserve other record types, and produce a PASS-only VCF plus QC reports.

A later GIAB benchmarking stage is planned but not implemented in the current Nextflow workflows.

## Getting Started

### Prerequisites

- Nextflow, Java, and a running Docker daemon. The launch scripts use the Docker profile and container images configured in `workflows/nextflow.config`.
- Python 3 (used by the step 2 launcher to read the QC decision).

### Inputs

- Paired FASTQ inputs at `data/raw_input/SRR14724472_1.fastq.gz` and `data/raw_input/SRR14724472_2.fastq.gz`.
- GRCh38 reference, BWA indexes, sequence dictionary, and known-sites files in `data/reference/`.
- The capture target BED at `data/reference/idt_capture_novogene.grch38.bed`.

`data/reference/download_references.sh` downloads the GRCh38 reference and known-sites files into `data/reference/`; it does not download the capture BED or raw reads. The script may install `aria2` using `sudo` if it is missing.

## Configuration

Container images and per-process CPUs, plus Nextflow report/trace/timeline paths, are set in `workflows/nextflow.config`. Workflow parameters (reference directory, capture BED, interval, output directories, hard-filter expressions, fastp settings) are defined at the top of each `workflows/step*.nf` file and can be overridden on the command line.

## Example Dataset

HG002 / NA24385 exome, SRA accession `SRR14724472`. See [`data/raw_input/raw_data.md`](data/raw_input/raw_data.md) for download instructions and [`data/reference/reference_files.md`](data/reference/reference_files.md) for the reference bundle.

## Running the Pipeline

Run commands from the repository root. First generate raw-read QC reports:

```bash
./scripts/run_step1_fastqc.sh
```

Review the HTML reports under `results/raw_results/01_fastqc/fastqc_raw/`, then record a decision and justification:

```bash
./scripts/run_step1_fastqc.sh proceed "Reviewed raw FastQC reports; keep original reads"
# Or trim adapters/low-quality sequence:
./scripts/run_step1_fastqc.sh trim "Reviewed raw FastQC reports; adapter trimming required"
# Or stop pending investigation:
./scripts/run_step1_fastqc.sh hold "Investigate the reported read-quality issue"
```

Only `proceed` and `trim` allow the next stage to run. After choosing one, run alignment and then calling:

```bash
./scripts/run_step2_alignment.sh
./scripts/run_step3_calling.sh
```

The launch scripts perform basic input and environment checks, use Nextflow's Docker profile, and enable `-resume`. Step 2 reads the QC decision to select original or trimmed FASTQs. Step 3 expects the recalibrated BAM and index produced by step 2.

## Output

- `results/raw_results/01_fastqc/`: FastQC reports, optional fastp outputs, and the QC decision record.
- `results/raw_results/02_alignment/`: sorted, duplicate-marked, and recalibrated BAM files, indexes, and alignment QC metrics.
- `results/raw_results/03_calling/`: GVCF, raw VCF, labelled VCF, PASS-only VCF, and calling QC outputs.
- `results/nextflow/`: per-run Nextflow reports, traces, and timelines.
- `logs/`: launcher logs.

### Example Output

```
results/raw_results/
 ├── 01_fastqc/
 │    ├── qc_decision.json
 │    └── fastqc_raw/SRR14724472_{1,2}_fastqc.html
 ├── 02_alignment/
 │    ├── sorted/HG002.sorted.bam(.bai)
 │    ├── markdup/HG002.markdup.bam, HG002.markdup_metrics.txt
 │    ├── bqsr/HG002.recal.table, HG002.recal.bam(.bai)
 │    └── qc/*.flagstat.txt, *.stats.txt, *.hs_metrics.txt, ...
 └── 03_calling/
      ├── gvcf/HG002.g.vcf.gz
      ├── raw/HG002.raw.vcf.gz
      ├── filtered/HG002.labelled.vcf.gz, HG002.pass.vcf.gz, *.bcftools_stats.txt
      └── qc/
```

The PASS VCF contains records that pass the configured hard filters; it is not a substitute for truth-set benchmarking. Outputs and workflow execution alone do not establish variant-calling accuracy.
# Proposed Project: Reproducible Germline Variant Calling with Nextflow

## 1. Project Overview

Develop a containerized, reproducible bioinformatics workflow that converts paired-end DNA sequencing reads into quality-reviewed germline SNP and small-indel calls.

The project will demonstrate scientific data processing, workflow orchestration, quality control, validation, and provenance tracking. A separate benchmarking phase will evaluate variant-calling accuracy against a Genome in a Bottle (GIAB) reference dataset.

## 2. Objectives

- Implement a modular variant-calling pipeline using Nextflow and Docker.
- Incorporate conditional adapter trimming and explicit QC review checkpoints.
- Validate intermediate BAM files and final VCF outputs.
- Automatically capture software versions, resource checksums, parameters, and execution metadata.
- Evaluate accuracy over a defined genomic region when suitable input coverage is available.

## 3. Initial Scope

| Component | Proposed scope |
|---|---|
| Sample | NA12878, also known as HG001 |
| Input | Verified paired-end Illumina whole-genome sequencing data |
| Reference | Full GRCh38 reference for alignment |
| Analysis region | Chromosome 20 |
| Variant types | Germline SNPs and small indels |
| Workflow manager | Nextflow |
| Software packaging | Docker containers with recorded image identities |
| Development environment | Ubuntu under WSL2 on Windows |
| Accuracy assessment | Later comparison against a compatible HG001 GIAB benchmark |

The initial deliverable will be a documented chr20 demonstration, not a complete high-coverage whole-genome analysis or clinically validated pipeline.

## 4. Proposed Workflow

```text
Verify input data and reference resources
                    ↓
              Raw-read QC
                    ↓
     Optional adapter trimming + post-trim QC
                    ↓
         Align against full GRCh38
                    ↓
       Sort, index, and mark duplicates
                    ↓
     Validate BAM and review alignment metrics
                    ↓
       Base-quality score recalibration
                    ↓
       Variant calling and genotyping
                    ↓
       Separate SNP and indel filtering
                    ↓
        VCF validation and QC reporting
                    ↓
       Reviewed outputs and provenance
                    ↓
     Later: GIAB accuracy benchmarking
```

### Work Packages

| Work package | Proposed activities | Main outputs |
|---|---|---|
| Input preparation | Verify sample identity, sequencing metadata, read pairing, checksums, reference compatibility, and indexes | Input manifest and verified resource inventory |
| Read QC and preprocessing | Run FastQC; review results; apply fastp adapter trimming only when justified; repeat QC if trimmed | QC reports, preprocessing decision, selected paired FASTQ |
| Alignment and processing | Run BWA-MEM, SAMtools sorting/indexing, and GATK duplicate marking | Sorted and duplicate-marked BAMs, indexes, duplicate metrics |
| BAM validation and alignment QC | Validate BAM structure; assess mapping, duplicates, insert size, and chr20 depth/breadth | Validation logs and alignment QC tables |
| Recalibration and calling | Run BQSR, HaplotypeCaller, and GenotypeGVCFs with explicit chr20 scope | Recalibration table, recalibrated BAM, GVCF, raw VCF |
| Filtering and VCF QC | Apply separate SNP/indel filters; preserve other record types; validate and summarize callsets | Filter-labelled and PASS-only VCFs, indexes, QC summaries |
| Accuracy benchmarking | Prepare compatible GIAB truth and benchmark regions; compare the exact final callset using hap.py or RTG | SNP/indel precision, recall, F1, and supporting counts |

## 5. Workflow Engineering and Provenance

The implementation will use separate Nextflow processes for meaningful analysis stages, with explicit file dependencies and sample metadata.

Engineering features will include:

- Configurable parameters and local/test execution profiles.
- Containerized tools with recorded versions and image identities.
- Restart support through Nextflow caching and `-resume`.
- Input, reference, known-site, and output checksums.
- Git commit and working-tree status.
- Resolved parameters, execution logs, resource reports, trace, and timeline.
- Staged runs for human QC review rather than assuming every decision can be automated.

## 6. Testing and Validation Strategy

| Validation level | Proposed evidence |
|---|---|
| Static checks | Valid workflow configuration and script syntax |
| Input validation | Rejection of missing mates, missing indexes, incompatible resources, or invalid parameters |
| Functional testing | A fixed small dataset completes with readable, correctly identified outputs |
| Failure handling | Validation failures prevent dependent analysis from proceeding |
| Reproducibility testing | A documented clean-environment run reproduces expected behavior |
| Accuracy benchmarking | Same-sample GIAB comparison over explicitly defined chr20 benchmark regions |

Successful execution, acceptable QC, and demonstrated accuracy will be reported as separate outcomes.

## 7. Deliverables

- Version-controlled GitHub repository.
- Modular Nextflow workflow and configuration examples.
- Container specifications and recorded software versions.
- Step-by-step setup and execution documentation.
- Architecture diagram showing tools and file types.
- QC reports, validation summaries, and representative outputs.
- Automated tests and an accurately described CI workflow.
- Provenance manifests and execution reports.
- GIAB benchmark report, if completed.

## 8. Proposed Milestones

1. Environment and inputs ready — verify WSL2/Docker, select sequencing data, and prepare compatible references.
2. Functional pipeline complete — execute the workflow on a small test dataset.
3. QC and validation integrated — review reads, alignments, BAM structure, and VCF outputs.
4. Reproducibility demonstrated — capture provenance and test restart and clean-environment execution.
5. Accuracy evaluated — benchmark suitable HG001 data within declared chr20 regions.
6. Portfolio release prepared — publish documentation, measured results, limitations, and a versioned release.

## 9. Limitations and Future Extensions

Initial limitations include single-sample analysis, chr20-only variant calling, potentially sparse input coverage, and unoptimized hard-filter thresholds.

Future extensions may include contamination assessment, annotation, cloud/HPC execution, interval-based parallelization, and multi-sample joint genotyping. These will remain outside the initial release so the project prioritizes a testable, well-documented workflow over unnecessary scope.

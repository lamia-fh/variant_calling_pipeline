# HG002 Alignment QC Report

## Overall assessment

HG002 has strong mapping and paired-end alignment metrics, preserved alignment counts across processing stages, and no reported SAM validation errors. Coverage adequacy remains unresolved: only 8.49% of chromosome 20 is covered, so suitability depends on whether this is whole-genome, targeted/exome, or intentionally restricted data. These reports alone do not establish readiness for variant calling. [file:1][file:3][file:5][file:6][file:8]

## Scope and provenance

Eight supplied reports were reviewed:

| File | Purpose |
|---|---|
| `HG002.sorted.flagstat-6.txt` | Alignment summary before duplicate marking |
| `HG002.markdup.flagstat-4.txt` | Alignment summary after duplicate marking |
| `HG002.recal.flagstat-5.txt` | Alignment summary after recalibration |
| `HG002.stats-7.txt` | Detailed samtools statistics |
| `HG002.insert_size_metrics-3.txt` | Picard fragment-length statistics and histogram counts |
| `HG002.insert_size_histogram-2.pdf` | Graphical insert-size report |
| `HG002.chr20.coverage.tsv` | Chromosome 20 coverage summary |
| `HG002.validatesam-8.txt` | Validation outcome |

The stats report explicitly analyzes `HG002.markdup.bam`; the insert-size reports also identify that BAM as input. The short validation output does not identify the validated BAM or command. The coverage table does not record its generating command or filtering settings. [file:7][file:4][file:2][file:8][file:1]

## 1. Alignment yield and pairing

| Metric | Result | Interpretation |
|---|---:|---|
| Total alignment records | 37,555,952 | Includes supplementary records |
| Primary reads | 37,301,062 | Excludes secondary and supplementary records |
| Read pairs | 18,650,531 | Equal read-1 and read-2 counts |
| Read length | 151 bp | Uniform read length in the stats report |
| Primary mapped reads | 37,258,958; 99.89% | High mapping fraction |
| Unmapped primary reads | 42,104; approximately 0.11% | Small unmapped fraction |
| Properly paired reads | 36,883,852; 98.88% | Most satisfy the aligner's proper-pair criteria |
| Singletons | 35,414; 0.09% | Mapped read with unmapped mate |
| Reads with mate on another chromosome | 158,252; approximately 0.42% of paired primary reads | Discordant interchromosomal placements |
| Supplementary alignment records | 254,890 | Additional segments of split alignments |
| Secondary alignment records | 0 | No alternative alignments flagged as secondary |

Counts and printed percentages come from flagstat and stats; other percentages are derived from those counts. These categories overlap and must not be added together. High mapping does not guarantee unique placement, sufficient coverage, or correct sample identity. [file:3][file:7][web:24]

### Mapping-confidence limitation

There are 2,225,497 mapped primary reads with MAPQ 0, approximately 5.97% of mapped primary reads. Therefore, the 99.89% mapping rate includes a meaningful low-confidence component. Coverage after an explicitly defined mapping-quality filter is needed to assess usable evidence. [file:7][web:9]

## 2. Duplicate marking and processing consistency

| Stage | Total records | Duplicate-flagged records |
|---|---:|---:|
| Sorted | 37,555,952 | 0 |
| Duplicate-marked | 37,555,952 | 3,219,155 |
| Recalibrated | 37,555,952 | 3,219,155 |

Mapping, pairing, singleton, and supplementary counts are unchanged across the three reports. Duplicate marking added flags without removing records. Approximately 8.63% of primary reads are duplicate-flagged; this is not the same as a count of duplicate pairs or original molecules. [file:6][file:5][file:3]

Zero duplicate flags before marking does not establish zero biological duplication. Duplicate marking infers redundant observations from alignment properties and sets the duplicate bit, `0x400` (decimal 1024), while retaining records unless removal is requested. Matching coordinates do not prove molecular identity. [web:36][web:38][web:41]

The identical markdup and recal flagstat outputs support preservation of alignment-level counts. They cannot demonstrate effective base-quality recalibration because flagstat does not measure calibration performance. [file:5][file:3][web:24]

## 3. Insert-size distribution

Picard reports the FR category with duplicates excluded. [file:4]

| Metric | Result |
|---|---:|
| Median insert size | 261 bp |
| Mode | 219 bp |
| Median absolute deviation | 56 bp |
| Trimmed mean | 276.42 bp |
| Trimmed standard deviation | 91.09 bp |
| Read pairs in reported category | 16,918,559 |
| Minimum | 2 bp |
| Maximum | 231,960,500 bp |
| Width encompassing 50% of pairs, centered on median | 113 bp |
| Width encompassing 90% of pairs, centered on median | 275 bp |
| Width encompassing 99% of pairs, centered on median | 643 bp |

The histogram counts peak at 219 bp and show a longer right tail. The extreme maximum is not representative of the main library distribution. The command uses `DEVIATIONS=10`, and Picard trims anomalous distances for mean, standard deviation, and plotting. The outlier warrants inspection, but does not imply that typical fragments span hundreds of megabases. [file:4][web:11][web:26]

Samtools reports an insert-size average of 273.6 bp and standard deviation of 84.3 bp. These need not equal Picard's values because the inclusion and summarization rules differ. [file:7][file:4][web:11]

## 4. Chromosome 20 coverage

| Metric | Result |
|---|---:|
| Assessed interval | chr20:1–64,444,167 |
| Reads counted | 823,992 |
| Covered reference positions | 5,471,577 |
| Breadth at at least 1× | 8.49041% |
| Mean depth across assessed chromosome | 1.91303× |
| Mean base quality | 36.1 |
| Mean mapping quality | 59.5 |

Coverage breadth is the percentage of positions with at least one aligned base; mean depth is the average aligned-base count per reference position. Neither is a direct measure of the fraction of intended targets reaching a variant-calling depth threshold. [file:1][web:10]

Derived from the reported breadth and depth:

- Approximately 91.51% of assessed chr20 positions have no coverage under the report's counting rules.
- Mean depth over covered positions is approximately `1.91303 / 0.0849041 = 22.53×`.
- The 22.53× value is an average over covered positions, not a minimum or median.

This indicates concentrated coverage, not uniformly shallow coverage. [file:1]

### Assay-dependent interpretation

- For whole-chromosome WGS analysis, most chr20 positions lack evidence in this report.
- For exome/targeted sequencing, evaluate coverage over the intended target BED rather than the entire chromosome.
- For an intentionally restricted dataset, the limited breadth may be expected.

The assay, subsetting history, and coverage command are not supplied, so a coverage pass/fail decision cannot be justified yet. [file:1][web:10]

## 5. Base qualities and reference differences

The stats report records mean base quality Q36 and an NM-derived alignment difference rate of `3.154872e-03`, approximately 0.3155%. The latter divides NM-derived differences by CIGAR-counted mapped bases. It should not be interpreted as a pure sequencing-error rate: these reports do not separate biological variation from sequencing and alignment effects. [file:7][web:9]

## 6. Structural validation

The validation output states `No errors found` and returns `0`. This supports successful validation under the checks performed, not adequate coverage, correct sample identity, or accurate downstream calls. The input BAM and validation options are not included in this output. [file:8]

## 7. Priority follow-up

1. Establish assay type, intended genomic scope, reference, and any subsetting.
2. Recover the coverage command and filtering settings.
3. Measure coverage on intended intervals with explicit duplicate, MAPQ, and base-quality handling.
4. Report fractions of intended bases reaching relevant thresholds, such as 10×, 20×, and 30×, rather than mean depth alone.
5. Review the MAPQ distribution and the coverage retained after filtering.
6. Evaluate recalibration using calibration-specific diagnostics rather than unchanged flagstat counts.
7. Investigate extreme insert-size outliers if relevant to the downstream analysis.

These follow-ups address the specific limitations exposed by the supplied reports; no universal assay-independent QC threshold is applied here. [file:1][file:7][file:4][file:3][file:5][web:9][web:10][web:11]

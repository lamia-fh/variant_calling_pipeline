# Raw-Read QC Report: HG002 Whole-Exome Sequencing

## Report information

- Run accession: SRR14724472
- Sample: HG002 / NA24385
- Library: paired-end whole-exome sequencing, IDT capture
- Instrument: Illumina NovaSeq 6000
- QC software: FastQC v0.12.1
- FastQC report date: 21 October 2026
- Interpretation date: 22 October 2026
- Inputs reviewed:
  - `SRR14724472_1_fastqc.html` — R1
  - `SRR14724472_2_fastqc-2.html` — R2
  - Screenshots of the per-sequence GC-content plots for both mates

Dataset context was identified in the published Kuura workflow evaluation. Statistics and module statuses below come from the supplied FastQC reports. GC-plot observations come from the supplied screenshots. [web:77][file:1][file:2][file:100][file:101]

## 1. Executive assessment

**Disposition:** Proceed to alignment with the GC-distribution finding recorded as unresolved. Do not reject the dataset or trim reads solely to change the GC module status.

Both mates pass 9 of the 10 reported FastQC modules. The only failure is per-sequence GC content. Base-quality, N-content, duplication, adapter-content, and overrepresented-sequence screens pass in both files. [file:1][file:2]

The GC plots show closely matching, asymmetric distributions in R1 and R2, with a broad lower-GC shoulder and a steeper higher-GC decline than the modeled normal distribution. No distinct narrow secondary spike is apparent. These findings are compatible with a shared library-composition effect, but do not establish capture bias or exclude contamination. [file:100][file:101][web:23]

Final suitability for variant calling remains dependent on mapping, duplicate assessment, target coverage, coverage uniformity, and capture-aware GC-dropout evaluation. [web:88][web:91]

## 2. Basic sequencing statistics

| Metric | R1 | R2 |
|---|---:|---:|
| Input FASTQ | SRR14724472_1.fastq.gz | SRR14724472_2.fastq.gz |
| Total reads | 18,650,531 | 18,650,531 |
| Total bases, as reported | 2.8 Gbp | 2.8 Gbp |
| Read length | 151 bases | 151 bases |
| Overall GC content | 52% | 52% |
| Sequences flagged as poor quality | 0 | 0 |
| Quality encoding | Sanger / Illumina 1.9 | Sanger / Illumina 1.9 |

Source: supplied FastQC reports. [file:1][file:2]

Combined output is approximately 5.6 Gbp. The files contain 18,650,531 reads each, consistent with approximately 18.65 million read pairs if pairing is intact. Matching counts alone do not verify corresponding read identifiers or order.

The zero poor-quality flag count does not mean there are no sequencing errors or low-quality bases. The reported GC percentages are rounded summary values, not exact GC measurements to arbitrary precision. [web:6][web:38]

## 3. FastQC module results

| Module | R1 | R2 | Interpretation |
|---|---|---|---|
| Basic Statistics | Pass | Pass | Basic input properties were reported successfully; this is not an overall biological quality verdict. |
| Per base sequence quality | Pass | Pass | No position triggered the module's warning or failure criteria. |
| Per sequence quality scores | Pass | Pass | The distribution of read-average quality did not trigger a flag. |
| Per base sequence content | Pass | Pass | No positional A/T or G/C imbalance large enough to trigger the module. |
| Per sequence GC content | Fail | Fail | The distribution of GC percentages across reads differs substantially from the modeled normal distribution. |
| Per base N content | Pass | Pass | Ambiguous-base frequencies did not trigger a flag. |
| Sequence Length Distribution | Pass | Pass | Both files report a fixed length of 151 bases. |
| Sequence Duplication Levels | Pass | Pass | No excessive-duplication flag in this sequence-based screen; zero PCR duplication is not established. |
| Overrepresented sequences | Pass | Pass | Both reports state “No overrepresented sequences.” |
| Adapter Content | Pass | Pass | The screened adapter sequences did not trigger a warning or failure; complete absence is not established. |

Statuses are from the supplied reports; module interpretations follow FastQC guidance. [file:1][file:2][web:6][web:23][web:36]

## 4. Detailed GC-distribution assessment

### 4.1 Plot interpretation

- X-axis: GC percentage within individual reads.
- Y-axis: read frequency/count represented at each GC percentage.
- Burgundy curve: observed per-read GC distribution.
- Blue curve: FastQC's modeled normal distribution, based on the observed modal GC content—not on a human reference genome or capture-target BED. [file:100][file:101][web:23]

### 4.2 Visual findings

| Feature | R1 and R2 observation |
|---|---|
| Main observed peak | Approximately 60–62% GC |
| Lower-GC side | Broad shoulder around approximately 35–50% GC, above the theoretical curve |
| Higher-GC side | Rapid decline after approximately 65% GC; observed counts below the theoretical curve |
| Mate concordance | Very similar peak positions and overall shapes |
| Narrow secondary spike | Not apparent in either screenshot |

All numerical positions in this table are approximate visual estimates. They were not extracted from the underlying FastQC tabular data. [file:100][file:101]

### 4.3 Reason for the failure

The observed curves are asymmetric and differ substantially from the normal distribution used by FastQC. Under default thresholds, the module fails when summed deviations from the model represent more than 30% of reads. This is a model-mismatch statistic, not a contamination percentage. [web:23]

The failure is therefore about distribution shape, not a determination that 52% overall GC is unacceptable.

### 4.4 Why the peak and overall GC differ

The peak near 60–62% identifies the most common per-read GC percentage: the mode. Overall GC describes the fraction of all sequenced bases that are G or C. The broad lower-GC population can pull the overall value below the mode, so a peak near 61% and an overall GC of 52% are not contradictory. [file:1][file:2][file:100][file:101]

### 4.5 Working interpretation

1. Similar profiles in both mates support a shared library effect rather than an obvious problem isolated to one mate.
2. Non-random composition is plausible because this is an exome-capture library, but capture composition has not been demonstrated as the cause.
3. No narrow secondary spike is apparent, and adapter/overrepresented-sequence screens pass. There is no corroborating flag for a dominant individual adapter-derived sequence, but contamination remains unexcluded.
4. The shortage of very high-GC reads relative to the modeled curve is not proof of GC dropout: the model does not represent the actual target territory. [file:1][file:2][file:100][file:101][web:6][web:23][web:77]

## 5. Recommended follow-up

These are planned actions, not completed analyses.

### 5.1 Input verification

- Confirm downloaded FASTQ checksums against the archive values, if not already completed.
- Check compressed-file integrity.
- Verify matching read-pair identifiers and order, not just equal counts.
- Preserve the raw FASTQs and original QC outputs.

GC percentage is not a substitute for file-integrity or pairing checks.

### 5.2 Alignment-level QC

Proceed through the normal full-reference alignment workflow. Once a sorted BAM is available:

- Examine mapping and pairing summaries.
- Review any substantial unexplained unmapped-read population.
- Assess duplicates after alignment and duplicate marking.
- Use mapping evidence as supporting information, not a definitive contamination test.

`samtools flagstat` reports alignment-flag categories, while `samtools stats` provides broader statistics including GC distributions for first and last mates. [web:89][web:92]

### 5.3 Capture-aware coverage and GC assessment

Run Picard/GATK `CollectHsMetrics` using the coordinate-sorted, duplicate-marked BAM, matching reference FASTA, and appropriate bait and target interval lists. Enable per-target coverage output. Verify assembly and contig compatibility; bait and target intervals are not automatically interchangeable. [web:88]

Review:

| Metric | Investigation objective |
|---|---|
| Mean target coverage | Establish average depth across intended targets. |
| Fraction of target bases reaching selected depths | Assess coverage against the project's analysis requirements. |
| Coverage uniformity | Identify whether the average masks poorly covered targets. |
| AT_DROPOUT and GC_DROPOUT | Assess underrepresentation of low- and high-GC targets. |
| Target GC versus mean coverage | Determine whether coverage systematically varies with target composition. |

These metrics are more directly relevant to exome variant-calling suitability than the raw-read GC flag alone. [web:88][web:91][web:94]

### 5.4 Conditional investigation and preprocessing

- If target coverage is adequate and no other concerns emerge: document the GC profile as consistent with the library design and continue.
- If coverage decreases substantially at particular target GC levels: document affected targets and limitations on interpretation.
- If unexplained sequence populations or poor mapping raise concerns: investigate sequence identity or contamination.
- If adapters or quality problems are independently demonstrated: apply targeted preprocessing and rerun QC.
- Do not remove reads solely because their GC content differs from the main peak, or trim solely to make the GC module pass. [web:6][web:23][web:88][web:91]

## 6. Limitations and unresolved questions

- This assessment covers raw-read QC and visual GC-plot review, not an executed alignment or variant-calling analysis.
- Exact Q30 percentages, duplication percentages, adapter percentages, and precise GC-curve values were not established from the supplied report text.
- An independently published numerical GC percentage for SRR14724472 was not verified in the preceding review. This does not establish that no such value exists.
- GC composition alone cannot identify contamination or establish its absence.
- No universal expected GC percentage or target-coverage threshold is assigned here.
- Raw-read QC does not establish sample identity, target completeness, or variant-call accuracy.

## 7. QC log entry

> FastQC v0.12.1 analysis of SRR14724472 identified 18,650,531 reads in each mate, with a uniform read length of 151 bases and 52% overall GC content. Both mates passed 9 of 10 reported modules; only per-sequence GC content failed. Visual review showed closely matching, asymmetric distributions with a main peak near 60–62% GC, a broad lower-GC shoulder, and a steeper higher-GC decline than the theoretical distribution. No distinct narrow secondary spike was apparent. The dataset is considered reasonable to advance to alignment, with the GC observation unresolved pending capture-aware coverage and dropout assessment. [file:1][file:2][file:100][file:101][web:23][web:88]

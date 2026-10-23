# How to Read Each HG002 Alignment QC File

## Quick orientation

These files are summaries of alignment data, not the BAM alignment files themselves. Most are plain text; the coverage file is tab-separated text and the insert-size PDF is a plot. Each report answers a different question and may analyze a different processing stage or genomic scope. [file:1][file:2][file:3][file:4][file:5][file:6][file:7][file:8]

| File | Main question |
|---|---|
| `HG002.sorted.flagstat-6.txt` | How did reads align before duplicate marking? |
| `HG002.markdup.flagstat-4.txt` | What changed after duplicate marking? |
| `HG002.recal.flagstat-5.txt` | Were alignment counts preserved after recalibration? |
| `HG002.stats-7.txt` | What do detailed quality and alignment distributions show? |
| `HG002.insert_size_metrics-3.txt` | What are the numerical fragment-length statistics? |
| `HG002.insert_size_histogram-2.pdf` | What shape does the fragment-length distribution have? |
| `HG002.chr20.coverage.tsv` | How much of chr20 is covered, and at what average depth? |
| `HG002.validatesam-8.txt` | Did structural validation report errors? |

## 1. The flagstat files: common format

Open the three short files in a text editor or terminal:

```bash
cat HG002.sorted.flagstat-6.txt
cat HG002.markdup.flagstat-4.txt
cat HG002.recal.flagstat-5.txt
```

### Reading counts and percentages

Example:

```text
37555952 + 0 in total (QC-passed reads + QC-failed reads)
```

The first number counts records without the platform/vendor QC-failure flag; the second counts records with that flag. `+ 0` does not mean every record passed every analytical QC criterion. Flagstat primarily summarizes flags already stored in the BAM. [web:24]

Example:

```text
37513848 + 0 mapped (99.89% : N/A)
```

The two percentage positions correspond to the QC-passed and QC-failed groups. `N/A` appears when a percentage cannot be calculated for the empty QC-failed group. Different rows use different denominators. [web:24]

### Reading the individual rows

| Row | Meaning |
|---|---|
| `in total` | All alignment records, including supplementary and secondary records |
| `primary` | Main records, excluding secondary and supplementary alignments |
| `secondary` | Alternative alignments flagged as secondary |
| `supplementary` | Additional alignment segments, such as split-read segments |
| `duplicates` | Records carrying the duplicate flag |
| `primary duplicates` | Duplicate-flagged primary records |
| `mapped` | Mapped records, including additional alignment records |
| `primary mapped` | Mapped primary records |
| `paired in sequencing` | Primary records belonging to paired-end sequencing |
| `read1`, `read2` | First and second reads of a pair |
| `properly paired` | Reads satisfying the aligner's proper-pair criteria |
| `with itself and mate mapped` | Both members of the pair are mapped |
| `singletons` | This read maps but its mate does not |
| `with mate mapped to a different chr` | Interchromosomal pair placements |
| Same row with `mapQ>=5` | That category restricted by mapping quality |

Categories overlap: a read can be primary, mapped, properly paired, and duplicate-flagged at once. Do not sum every row. Read counts are not pair counts; a complete pair usually contributes two primary records. [web:24][file:3]

## 2. `HG002.sorted.flagstat-6.txt`

### What it provides

This is the baseline alignment summary before duplicate marking. It contains 37,555,952 total alignment records, 37,301,062 primary reads, and zero duplicate flags. [file:6]

### What to inspect

- Primary mapped percentage: 99.89%.
- Properly paired percentage: 98.88%.
- Read-1 and read-2 counts: 18,650,531 each.
- Supplementary records: 254,890.
- Singletons and interchromosomal mates.

Zero duplicates here means zero records are flagged as duplicates, not that no redundant molecules were sequenced. [file:6][web:25]

## 3. `HG002.markdup.flagstat-4.txt`

### What it provides

This summarizes the duplicate-marked alignment. Compare it directly with the sorted report: total records remain 37,555,952 while duplicate-flagged records increase to 3,219,155. Mapping and pairing counts remain unchanged. [file:5][file:6]

### What duplicate marking means

Duplicate-marking tools infer redundant observations using alignment positions and orientations, including mate information. They select a representative and mark redundant observations with bit `0x400` (decimal 1024). Setting this bit adds a property; the complete flag may contain several bits and need not equal 1024. [web:36][web:38]

```text
Pair A: same fragment endpoints → representative, unflagged
Pair B: same fragment endpoints → duplicate-flagged
Pair C: same fragment endpoints → duplicate-flagged
```

If both mates of B and C are marked, this example produces four duplicate-flagged records. A record count must not be interpreted as a duplicate-pair or original-molecule count. Matching coordinates also do not prove molecular identity. [web:38][web:41]

In your reports, the increase reflects labeling existing records, not adding new reads. Approximately 8.63% of primary reads are flagged. They remain in the BAM because total counts did not decrease. [file:5][file:6]

## 4. `HG002.recal.flagstat-5.txt`

### What it provides

This checks the alignment categories after the recalibration stage. Its counts match the duplicate-marked report, including 3,219,155 duplicate-flagged records. [file:3][file:5]

### What it does not provide

It does not evaluate whether recalibrated base qualities match observed error probabilities. Identical flagstat reports establish preservation of these count categories, not successful calibration. [file:3][file:5][web:24]

## 5. `HG002.stats-7.txt`

### How to open and navigate

```bash
less -S HG002.stats-7.txt
```

Within `less`, search for `/^SN` or `/^COV`; press `q` to exit. Extract the summary section with:

```bash
grep '^SN' HG002.stats-7.txt | cut -f 2-
```

The header identifies samtools 1.16.1 and the command `stats -@ 2 HG002.markdup.bam`. This report describes the duplicate-marked BAM, not the recalibrated BAM. [file:7]

### The `SN` section

Each line has a section code, metric name, value, and sometimes a comment:

```text
SN    average length:    151
SN    average quality:   36.0
SN    reads MQ0:         2225497
SN    error rate:        3.154872e-03
```

Useful fields:

| Field | Value | Interpretation |
|---|---:|---|
| `is sorted` | 1 | Indicates sorted records |
| `raw total sequences` | 37,301,062 | Primary-read count |
| `total length` | 5,632,460,362 | Sequence bases, ignoring clipping |
| `average length` | 151 | Average read length in bases |
| `average quality` | 36.0 | Average reported base quality |
| `reads MQ0` | 2,225,497 | Mapped reads with MAPQ zero |
| `bases mapped (cigar)` | 5,610,309,052 | Mapped-base count using alignment operations |
| `mismatches` | 17,699,806 | NM-derived difference count |
| `error rate` | 0.003154872 | NM-derived differences divided by CIGAR-counted mapped bases |
| `insert size average` | 273.6 | samtools mean insert size in bp |

Approximately 5.97% of mapped primary reads have MAPQ zero. The reported difference rate is approximately 0.3155%; it is not a pure sequencing-error measurement. [file:7][web:9]

### Distribution sections

Read the comment above each section for its exact columns.

| Prefix | Information |
|---|---|
| `CHK` | Checksums of names, sequences, and qualities |
| `FFQ`, `LFQ` | Base-quality histograms by cycle for read 1 and read 2 |
| `GCF`, `GCL` | Per-read GC-content distributions for each mate |
| `GCC`, `GCT` | Per-cycle composition with different orientation conventions |
| `FBC`, `LBC` | Per-cycle composition separately for each mate |
| `FTC`, `LTC` | Total A/C/G/T/N counts for each mate |
| `IS` | Insert sizes and pair orientations |
| `RL`, `FRL`, `LRL` | Combined and mate-specific read-length distributions |
| `ID`, `IC` | Indel-size and indel-by-cycle statistics |
| `COV` | Coverage-depth distribution |
| `GCD` | Depth summaries stratified by GC content |

For example, in `FFQ`/`LFQ`, the first numeric field is the cycle and subsequent fields are counts for quality-score bins. These rows are histograms, not lists of mean qualities. [file:7][web:9]

Example coverage row:

```text
COV    1-1    1    62068176
```

This counts 62,068,176 reference positions at depth 1. It is not a read count. This BAM-wide distribution is not the chr20-only coverage table, and positive-depth bins alone do not supply the full zero-inclusive genomic denominator. [file:7][web:9]

## 6. `HG002.insert_size_metrics-3.txt`

### How to open it

```bash
less -S HG002.insert_size_metrics-3.txt
```

This is a multi-section tab-delimited report, not one simple spreadsheet table. [file:4]

### Section A: metadata and command

Lines starting with `#` record provenance and settings:

```text
INPUT HG002.markdup.bam
INCLUDE_DUPLICATES false
METRIC_ACCUMULATION_LEVEL ALL_READS
DEVIATIONS 10.0
```

Duplicates are excluded, results are pooled at the all-reads level, and Picard uses trimming for mean, standard deviation, and plotting. [file:4][web:11]

### Section B: summary metrics

Match each header to the value directly beneath it.

| Column | Value | Meaning |
|---|---:|---|
| `MEDIAN_INSERT_SIZE` | 261 | Median fragment span in bp |
| `MODE_INSERT_SIZE` | 219 | Most frequent insert size |
| `MEDIAN_ABSOLUTE_DEVIATION` | 56 | Robust spread around the median |
| `MIN_INSERT_SIZE` | 2 | Minimum reported value |
| `MAX_INSERT_SIZE` | 231,960,500 | Maximum, including an extreme outlier |
| `MEAN_INSERT_SIZE` | 276.42 | Trimmed mean |
| `STANDARD_DEVIATION` | 91.09 | Standard deviation of the trimmed distribution |
| `READ_PAIRS` | 16,918,559 | Pairs in the reported category |
| `PAIR_ORIENTATION` | FR | Forward/reverse category |
| `WIDTH_OF_50_PERCENT` | 113 | Median-centered width encompassing 50% of pairs |
| `WIDTH_OF_90_PERCENT` | 275 | Median-centered width encompassing 90% of pairs |
| `WIDTH_OF_99_PERCENT` | 643 | Median-centered width encompassing 99% of pairs |

Widths are not upper size limits: a width of 275 bp does not mean 90% of fragments are shorter than 275 bp. The maximum does not describe typical library fragments, and it is not included untrimmed in the reported mean. [file:4][web:26][web:11]

### Section C: histogram counts

```text
insert_size    All_Reads.fr_count
219            87431
```

This means 87,431 counted FR pairs have insert size 219 bp. These counts underlie the graphical distribution. [file:4]

## 7. `HG002.insert_size_histogram-2.pdf`

Open in a PDF viewer. It is the graphical companion to the insert-size metrics and identifies `HG002.markdup.bam` as its input. [file:2]

### Reading the axes

- Horizontal axis: insert size in bp.
- Left vertical axis: count at each insert size.
- Right vertical axis: cumulative fraction of reads with insert size greater than the horizontal-axis value.
- `FR`: orientation category.

On the right axis, 0.1 means approximately 10% exceed the chosen size. Do not confuse this with the fraction below that size. [file:2]

Use the plot to examine the main peak, width, and tails; use the numerical metrics for exact values. The numerical peak is 219 bp. Picard's plotting treatment means the main plotted range does not extend to the extreme 231.96-Mb maximum. [file:4][web:11]

## 8. `HG002.chr20.coverage.tsv`

### How to open it

Import into a spreadsheet using a tab delimiter, or use:

```bash
column -t -s $'\t' HG002.chr20.coverage.tsv
```

It contains one header and one data row. [file:1]

### Reading each column

| Column | Value | Meaning |
|---|---:|---|
| `#rname` | chr20 | Reference sequence |
| `startpos` | 1 | Start of assessed interval |
| `endpos` | 64,444,167 | End of assessed interval |
| `numreads` | 823,992 | Reads counted under the tool's filtering rules |
| `covbases` | 5,471,577 | Reference positions covered at least once |
| `coverage` | 8.49041 | Percent of assessed positions covered |
| `meandepth` | 1.91303 | Average depth across the full assessed interval |
| `meanbaseq` | 36.1 | Mean base quality |
| `meanmapq` | 59.5 | Mean mapping quality |

`coverage` is a percentage, while `meandepth` is a depth. The mean includes the uncovered positions in the assessed interval. [file:1][web:10]

The covered portion averages approximately 22.53×, calculated as `1.91303 / 0.0849041`; this does not mean every covered base reaches that depth. The table does not identify exact coverage gaps or the fraction of targets reaching 20×. Targeted/exome analysis needs the intended target intervals as its denominator. [file:1][web:10]

## 9. `HG002.validatesam-8.txt`

```bash
cat HG002.validatesam-8.txt
```

Contents:

```text
No errors found
Tool returned:
0
```

This reports successful validation under the checks performed. It does not prove adequate coverage, sample identity, or downstream variant accuracy. The short output does not identify the input BAM or validation options. [file:8]

## Recommended reading order

1. Validation: check for reported structural errors.
2. Sorted flagstat: establish the baseline.
3. Markdup flagstat: verify the change in duplicate flags and preservation of counts.
4. Recal flagstat: check preservation of alignment categories.
5. Stats `SN`, then relevant distributions: examine quality and low-confidence reads.
6. Insert-size metrics and PDF: connect exact values to distribution shape.
7. Coverage TSV: assess genomic breadth and depth in the intended assay context.

Always distinguish alignment records, primary reads, read pairs, sequence bases, and covered reference positions. Their denominators are different, and these reports are not interchangeable. [file:1][file:3][file:4][file:5][file:6][file:7][file:8]

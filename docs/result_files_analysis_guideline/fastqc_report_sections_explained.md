# Purpose and Importance of Each Section of a FastQC Report

Each section of a FastQC report answers a different question about your reads: Are the base calls reliable? Does the sequence composition look expected? Are adapters present? Is the library overly repetitive?

The most important principle is **context**: a warning or failure means “investigate this pattern,” not automatically “discard the data.” FastQC’s thresholds are primarily tuned for random whole-genome sequencing and can flag expected patterns in targeted libraries such as exome sequencing. [web:6]

Your reports contain a summary followed by 10 analysis sections. Below is what each section measures, why it matters, and how it applies to your results.

## 1. Summary: where should you focus your attention?

The summary is a dashboard listing each module with a pass, warning, or failure flag.

- Pass: the module did not cross its warning or failure thresholds.
- Warning: a pattern deserves closer inspection.
- Failure: the pattern deviates substantially from that module’s expectations.

Its purpose is to direct your attention—not to provide a single overall verdict on the sample. A failure in sequence composition has a different meaning from a failure in base-call quality. [web:6]

In your reports, both mates pass nine modules and fail only “Per sequence GC content.” This localizes the flagged issue to the distribution of sequence composition, rather than the base-quality modules. [file:1][file:2]

## 2. Basic Statistics: what data are you analyzing?

### Purpose

This section identifies the input file and reports its basic properties:

| Field | What it tells you | Why it matters |
|---|---|---|
| Filename | Which file was analyzed | Helps prevent sample or mate mix-ups. |
| File type | The type of sequence data | Confirms how FastQC interpreted the input. |
| Encoding | How quality scores are represented | Quality values must be decoded correctly. |
| Total sequences | Number of reads in that file | Establishes sequencing output per mate. |
| Total bases | Total amount of sequence | Helps describe the size of the dataset. |
| Sequence length | Read length or range of lengths | Establishes the read structure. |
| %GC | Overall percentage of G and C bases | Provides a broad composition check. |

These are descriptive statistics, not a demonstration that the sample is suitable for every downstream analysis. [web:38][web:6]

### Your results

Each file contains 18,650,531 reads, all 151 bases long, with 52% GC and approximately 2.8 Gbp per file. Matching read counts are reassuring for paired-end inputs, but do not by themselves verify matching read identifiers or order. [file:1][file:2]

The “0 sequences flagged as poor quality” field should not be interpreted as “zero sequencing errors”; evaluate quality using the quality-specific modules. [file:1][file:2][web:6]

## 3. Per base sequence quality: which positions are reliable?

### Purpose

This module summarizes base-call quality at each position along the reads.

Conceptually, it asks:

> Across all reads, how reliable is base 1? Base 2? … Base 151?

The x-axis represents position along the read, sometimes grouped into bins. The y-axis represents quality score; higher scores mean greater base-call confidence. [web:36]

### How to read the plot

- Red line: median quality.
- Yellow box: middle 50% of quality scores.
- Whiskers: 10th to 90th percentiles.
- Blue line: mean quality.
- Background colors: broad quality bands, with green representing better-quality calls. [web:36]

### Why it matters

This section reveals whether quality declines toward the read ends or drops at particular sequencing cycles. That helps distinguish a localized low-quality tail from a problem affecting much of the read, and informs whether quality trimming merits consideration. Removing everything after an isolated internal dip can unnecessarily discard later good-quality sequence. [web:36]

### Your results

Both mates pass. No position triggered the module’s warning or failure criteria, but that does not mean every individual base has high quality. [file:1][file:2][web:36]

## 4. Per sequence quality scores: are some entire reads poor quality?

### Purpose

This module calculates the average quality score for each read and plots the distribution of those averages.

It asks:

> Are most reads consistently good, or is there a population of low-quality reads? [web:6]

### Why it matters

A per-position plot combines information across reads. This second view helps reveal whether a subset of entire reads has poor average quality.

The distinction is:

| Module | What it groups together |
|---|---|
| Per base quality | The same position across many reads |
| Per sequence quality | All positions within each individual read |

A distribution concentrated at high average quality is reassuring; a substantial low-quality population warrants investigation. [web:6]

### Your results

Both mates pass, meaning the read-average quality distribution did not trigger a flag. This complements, rather than duplicates, the per-base quality result. [file:1][file:2]

## 5. Per base sequence content: is composition biased at particular positions?

### Purpose

This plot shows the percentage of A, T, G, and C at each position along the reads.

It asks:

> Do particular positions contain an unexpectedly high proportion of one nucleotide? [web:34]

### Why it matters

Position-dependent bias can reflect library preparation or enrichment rather than sequencing errors. Some library types naturally produce strong composition bias near the beginning of reads, so this module must be interpreted in light of the protocol. [web:34][web:6]

For a random DNA library, the proportions should generally remain relatively stable along the read, with A approximately matching T and G approximately matching C. All four bases do not have to equal 25%; the overall GC composition can differ. [web:34][web:6]

### Your results

Both mates pass. FastQC did not detect a positional A/T or G/C imbalance large enough to trigger this module. That does not establish that every position has identical composition. [file:1][file:2][web:34]

## 6. Per sequence GC content: does the library contain an unusual mixture of sequences?

### Purpose

This module calculates the GC percentage of each read and compares the observed distribution with a modeled normal distribution.

It asks:

> How much does GC content vary between reads, and does that variation fit the model? [web:23]

### Why it matters

An unusual distribution can reflect a biased subset of sequences or contamination. For example, a sharp additional peak can indicate a highly represented contaminant, whereas broader deviations can have other explanations. However, the model does not know the expected GC percentage of your organism; it builds its reference distribution using the observed modal GC content. [web:23]

The key distinction is:

- Basic Statistics %GC: one overall percentage for the file.
- Per sequence GC content: the distribution of individual-read GC percentages. [web:38][web:23]

### Your results

Both mates fail despite having the same overall GC content of 52%. The flag concerns the distribution’s shape—not a judgment that “52% is too high.” [file:1][file:2][web:23]

For targeted capture data, FastQC’s random-library assumptions may not fit well. Capture composition is therefore a plausible explanation, but the failure alone cannot distinguish that explanation from contamination or other bias. [web:6][web:23]

## 7. Per base N content: where could the sequencer not identify a base?

### Purpose

This plot shows the percentage of calls reported as `N` at each position.

An `N` means the base was not assigned confidently as A, T, G, or C. [web:32]

### Why it matters

A peak in N content can identify a problematic sequencing cycle or region of the reads. This is different from an ordinary low-confidence base call:

- A low-quality `A` still gives a proposed identity.
- An `N` leaves that identity unresolved. [web:32][web:6]

A low N-content profile is reassuring because fewer positions lack a usable nucleotide identity. [web:6]

### Your results

Both mates pass. Ambiguous calls did not reach the module’s warning or failure levels; passing does not necessarily mean there are no Ns whatsoever. [file:1][file:2]

## 8. Sequence Length Distribution: do the reads have the expected lengths?

### Purpose

This section shows how many reads occur at each read length.

It asks:

> Are all reads the intended length, or is there a mixture of lengths? [web:32][web:38]

### Why it matters

Read length provides important context for interpreting other modules. For example, if relatively few reads extend to the final positions, a quality problem at those positions may represent only a small subset of the dataset. FastQC specifically advises checking length distribution when interpreting quality flags in variable-length libraries. [web:36]

A mixture of lengths is not inherently bad: the meaning depends on the sequencing and processing workflow.

### Your results

Both files report a fixed read length of 151 bases and pass this module. This is consistent with uniform-length inputs, but does not alone prove that no previous processing occurred. [file:1][file:2]

## 9. Sequence Duplication Levels: how repetitive is the library?

### Purpose

This module estimates how often identical read sequences recur.

It asks:

> Are we observing many different sequences, or repeatedly observing the same sequences? [web:6][web:32]

### Why it matters

Repeated sequences can arise from different causes:

- PCR amplification can generate multiple copies from the same original fragment.
- High sequencing depth can repeatedly sample the same sequences.
- Biological abundance can make some sequences genuinely common, especially in RNA sequencing. [web:6]

Consequently, duplicate sequence does not automatically mean a technical artifact. FastQC provides a sequence-based estimate; it does not establish how many independent original molecules were present or identify every PCR duplicate. [web:6][web:32]

### Your results

Both mates pass. This is reassuring as an initial repetition screen, but should not be reported as “no duplicates” or used as a substitute for downstream duplicate assessment. [file:1][file:2][web:32]

## 10. Overrepresented sequences: which specific sequences are unusually common?

### Purpose

This module lists individual sequences that appear unusually frequently and compares them with known contaminants to suggest possible sources.

It asks:

> Is there a particular sequence that is dominating the dataset? [web:6]

### Why it matters

It can provide a concrete explanation for patterns seen elsewhere—for example, an abundant adapter-derived sequence might also contribute to a GC-distribution anomaly. Some abundant sequences can also be biologically expected, depending on library type. [web:6][web:23]

This differs from duplication analysis:

| Module | Main question |
|---|---|
| Duplication levels | How repetitive is the library overall? |
| Overrepresented sequences | Which particular sequences are unusually frequent? |

The two views are related, but answer different questions. [web:6]

### Your results

Both reports explicitly state “No overrepresented sequences.” No individual sequence met the reporting criteria in this screen; this is not a universal test proving the absence of contamination. [file:1][file:2][web:6]

## 11. Adapter Content: did sequencing extend into synthetic library adapters?

### Purpose

This module searches for adapter sequences and shows their cumulative occurrence along the read.

Adapters are synthetic sequences used during library preparation. If a library insert is shorter than the sequencing read, the sequencer can read through the insert into an adapter at the 3′ end. [web:6]

### Why it matters

This section helps determine whether adapter trimming should be considered and where adapter read-through begins. A rise toward the end of the read is consistent with a subset of inserts being shorter than the read length. [web:6]

The plot is cumulative: it represents reads in which an adapter has been encountered by a given position, rather than simply the fraction of bases at that position that are adapter-derived. [web:32][web:6]

### Your results

Both mates pass. The adapter sequences screened did not trigger a warning or failure. This provides no flagged reason for aggressive adapter trimming, but it does not establish that every possible adapter sequence is absent. [file:1][file:2][web:6]

## How the sections fit together

Think of the report as three complementary layers:

| Layer | Sections | What you learn |
|---|---|---|
| Base-call reliability | Per base quality, per sequence quality, N content | Whether nucleotide calls are consistently usable |
| Library composition | Per base content, per sequence GC, duplication, overrepresented sequences, adapters | Whether the library has unexpected bias, repetition, or technical sequence |
| Dataset structure | Basic Statistics, length distribution | What data you have and whether its structure is expected |

These layers explain why your GC failure can coexist with passing quality scores: a read can have confidently called bases while belonging to a library whose sequence composition differs from FastQC’s model. [web:6][web:23]

FastQC is therefore an initial raw-read assessment—not a measurement of mapping performance, target coverage, or variant-call accuracy. Your reports support confidence in the initial base-quality screen while leaving the GC-distribution finding for contextual and downstream evaluation. [file:1][file:2][web:6]

# Raw input sequences (FASTQ)

Sample: HG002 / NA24385, accession `SRR14724472` (paired-end Illumina, exome).

Expected files in `data/raw_input/`:

| Local file | Used by |
|---|---|
| `SRR14724472_1.fastq.gz` | step 1 (FastQC, fastp), step 2 (alignment) |
| `SRR14724472_2.fastq.gz` | step 1 (FastQC, fastp), step 2 (alignment) |

`scripts/run_step2_alignment.sh` also creates the symlinks `data/raw_input/raw_read_1.fastq.gz` and `data/raw_input/raw_read_2.fastq.gz` pointing to these files.

## Links

- ENA record: https://www.ebi.ac.uk/ena/browser/view/SRR14724472
- ENA file report (FTP URLs and md5 values): https://www.ebi.ac.uk/ena/portal/api/filereport?accession=SRR14724472&result=read_run&fields=run_accession,fastq_ftp,fastq_md5,fastq_bytes&format=tsv
- NCBI SRA record: https://www.ncbi.nlm.nih.gov/sra/SRR14724472

## How to obtain

ENA hosts the FASTQ files directly, so no conversion from `.sra` is needed.

1. Get the download URLs and md5 values from the ENA file report above (columns `fastq_ftp` and `fastq_md5`).
2. Download both mates into `data/raw_input/`:

```bash
mkdir -p data/raw_input
cd data/raw_input
# Replace <URL_1> and <URL_2> with the fastq_ftp values (prefix with ftp:// or https://)
aria2c -x 8 -s 8 --continue=true <URL_1> <URL_2>
```

3. Verify the downloads against the `fastq_md5` values:

```bash
md5sum SRR14724472_1.fastq.gz SRR14724472_2.fastq.gz
```

4. Run step 1 (raw QC):

```bash
bash scripts/run_step1_fastqc.sh
```

Alternative using SRA Toolkit (this needs conversion and compression):

```bash
prefetch SRR14724472
fasterq-dump --split-files SRR14724472
gzip SRR14724472_1.fastq SRR14724472_2.fastq
```

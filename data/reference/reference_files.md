# Reference files

All files go in `data/reference/`. Source: Broad hg38/v0 bundle (GRCh38).

Base URL: `https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/`

## Required files

| Local file | Used by | Download |
|---|---|---|
| `Homo_sapiens_assembly38.fasta` | alignment, calling | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta) |
| `Homo_sapiens_assembly38.fasta.fai` | GATK, samtools | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.fai) |
| `Homo_sapiens_assembly38.dict` | GATK, BED to interval list | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.dict) |
| `Homo_sapiens_assembly38.fasta.amb` | BWA index | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.64.amb) |
| `Homo_sapiens_assembly38.fasta.ann` | BWA index | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.64.ann) |
| `Homo_sapiens_assembly38.fasta.bwt` | BWA index | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.64.bwt) |
| `Homo_sapiens_assembly38.fasta.pac` | BWA index | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.64.pac) |
| `Homo_sapiens_assembly38.fasta.sa` | BWA index | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.64.sa) |
| `Homo_sapiens_assembly38.fasta.alt` | BWA alt-aware mapping | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.64.alt) |
| `Homo_sapiens_assembly38.dbsnp138.vcf` | BQSR known sites | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf) |
| `Homo_sapiens_assembly38.dbsnp138.vcf.idx` | BQSR known sites index | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf.idx) |
| `Mills_and_1000G_gold_standard.indels.hg38.vcf.gz` | BQSR known sites | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz) |
| `Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi` | BQSR known sites index | [link](https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi) |
| `idt_capture_novogene.grch38.bed` | capture targets (HS metrics, calling intervals) | Not part of the Broad bundle; obtain from the sequencing vendor (Novogene / IDT) |

The BWA index files are published as `Homo_sapiens_assembly38.fasta.64.<ext>`. They are saved locally without the `.64`.

## How to obtain

Run the download script. It writes `config/reference-downloads.txt` and fetches everything with `aria2c`:

```bash
bash data/reference/download_references.sh
```

Or download from the existing manifest:

```bash
aria2c --input-file=config/reference-downloads.txt --continue=true \
    --max-concurrent-downloads=2 --split=8 --max-connection-per-server=8
```

The script installs `aria2` with `sudo apt-get` if it is missing.

## Checks

```bash
gzip -t data/reference/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
grep -w '^chr20' data/reference/Homo_sapiens_assembly38.fasta.fai
```

These checks do not replace verifying checksums against the publisher.

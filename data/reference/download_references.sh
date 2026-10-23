#!/usr/bin/env bash
set -euo pipefail

if ! command -v aria2c >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y aria2
fi

PROJECT="$(cd "$(dirname "$0")/../.." && pwd)"
BASE="https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0"

mkdir -p "$PROJECT"/{data/reference,config}
cd "$PROJECT"

MANIFEST="$PROJECT/config/reference-downloads.txt"
: > "$MANIFEST"

add_download() {
    local remote="$1"
    local folder="$2"
    local output="${3:-$remote}"
    printf '%s\n  dir=%s\n  out=%s\n' \
        "$BASE/$remote" "$PROJECT/$folder" "$output" >> "$MANIFEST"
}

add_download Homo_sapiens_assembly38.fasta     data/reference
add_download Homo_sapiens_assembly38.fasta.fai data/reference
add_download Homo_sapiens_assembly38.dict      data/reference

for ext in amb ann bwt pac sa alt; do
    add_download \
        "Homo_sapiens_assembly38.fasta.64.$ext" \
        data/reference \
        "Homo_sapiens_assembly38.fasta.$ext"
done

add_download Homo_sapiens_assembly38.dbsnp138.vcf     data/reference
add_download Homo_sapiens_assembly38.dbsnp138.vcf.idx data/reference
add_download Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
    data/reference
add_download Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi \
    data/reference

aria2c \
    --input-file="$MANIFEST" \
    --continue=true \
    --max-concurrent-downloads=2 \
    --max-connection-per-server=8 \
    --split=8 \
    --min-split-size=20M \
    --max-tries=10 \
    --retry-wait=10 \
    --connect-timeout=30 \
    --timeout=60 \
    --auto-file-renaming=false \
    --allow-overwrite=false \
    --file-allocation=none \
    --summary-interval=600

# Basic checks do not replace publisher-checksum verification.
gzip -t data/reference/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
grep -w '^chr20' data/reference/Homo_sapiens_assembly38.fasta.fai

echo
echo "Downloads completed and basic checks passed."
echo "Reference: $PROJECT/data/reference/Homo_sapiens_assembly38.fasta"
echo "Reference and known sites: $PROJECT/data/reference/"

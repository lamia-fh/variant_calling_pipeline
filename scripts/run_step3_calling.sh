#!/usr/bin/env bash
# Step 3 runner: HaplotypeCaller, GenotypeGVCFs, hard filtering, PASS VCF and VCF QC.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.local/bin:$PATH"

run_id=$(date +%Y%m%d_%H%M%S)
run_dir="results/nextflow/${run_id}_calling"
mkdir -p logs "$run_dir"
exec > >(tee -a "logs/calling_${run_id}.log") 2>&1

fail() { echo "ERROR: $*" >&2; exit 1; }

echo "== Preflight ($run_id) =="
pwd
command -v nextflow >/dev/null 2>&1 || fail "Nextflow is not installed or is not on PATH."
docker info >/dev/null 2>&1 || fail "Docker is not running; start Docker Desktop."
free -h
df -h .

[[ -s workflows/step3_calling.nf ]] || fail "Missing or empty workflows/step3_calling.nf."

for f in results/raw_results/02_alignment/bqsr/HG002.recal.bam results/raw_results/02_alignment/bqsr/HG002.recal.bai \
         data/reference/idt_capture_novogene.grch38.bed \
         data/reference/Homo_sapiens_assembly38.fasta data/reference/Homo_sapiens_assembly38.fasta.fai \
         data/reference/Homo_sapiens_assembly38.dict; do
    [[ -s "$f" ]] || fail "Missing or empty input: $f"
done

echo "== Running step 3 =="
nextflow run workflows/step3_calling.nf -c workflows/nextflow.config -profile docker -resume \
    -with-report "$run_dir/report.html" \
    -with-trace "$run_dir/trace.tsv" \
    -with-timeline "$run_dir/timeline.html"

echo "Final PASS VCF:  results/raw_results/03_calling/filtered/"
echo "VCF QC:          results/raw_results/03_calling/qc/ and results/raw_results/03_calling/filtered/*bcftools_stats.txt"
echo "Run reports:     $run_dir/"
echo "Launcher log:    logs/calling_${run_id}.log"

#!/usr/bin/env bash
# Step 2 runner: alignment, MarkDuplicates, BAM QC, BQSR. Uses the step 1 decision to pick the input reads.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.local/bin:$PATH"

# Sample-specific source accession; the workflow only ever sees standardized names.
ACCESSION="${ACCESSION:-SRR14724472}"
run_id=$(date +%Y%m%d_%H%M%S)
run_dir="results/nextflow/${run_id}"
mkdir -p logs "$run_dir"
exec > >(tee -a "logs/alignment_${run_id}.log") 2>&1

fail() { echo "ERROR: $*" >&2; exit 1; }

echo "== Preflight ($run_id) =="
pwd
command -v python3 >/dev/null 2>&1 || fail "python3 is not installed."
command -v nextflow >/dev/null 2>&1 || fail "Nextflow is not installed or is not on PATH."
command -v java >/dev/null 2>&1 || fail "Java is not installed."
nextflow -version | grep -m1 'version'
java -version 2>&1 | head -1
docker info >/dev/null 2>&1 || fail "Docker is not running; start Docker Desktop."
free -h
df -h .

[[ -s workflows/step2_alignment.nf ]] || fail "Missing or empty workflows/step2_alignment.nf."

decision_file="results/raw_results/01_fastqc/qc_decision.json"
[[ -s "$decision_file" ]] || fail "Missing $decision_file; finish step 1 first."
python3 -m json.tool "$decision_file" >/dev/null || fail "$decision_file is not valid JSON."

decision=$(python3 - "$decision_file" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle).get("decision")

if value not in {"proceed", "trim"}:
    raise SystemExit(f"Step 1 decision is {value!r}; step 2 will not run.")

print(value)
PY
)
echo "Step 1 decision: $decision"

# Standardized input names so every run/sample uses the same paths.
if [[ "$decision" == "trim" ]]; then
    r1="results/raw_results/01_fastqc/trimmed/trimmed_read_1.fastq.gz"
    r2="results/raw_results/01_fastqc/trimmed/trimmed_read_2.fastq.gz"
else
    [[ -d data/raw_input ]] || fail "Missing raw-read directory: data/raw_input"
    for mate in 1 2; do
        src="data/raw_input/${ACCESSION}_${mate}.fastq.gz"
        [[ -s "$src" ]] || fail "Missing or empty raw FASTQ: $src"
        [[ -e "data/raw_input/raw_read_${mate}.fastq.gz" ]] ||
            ln -s "${ACCESSION}_${mate}.fastq.gz" "data/raw_input/raw_read_${mate}.fastq.gz"
    done
    r1="data/raw_input/raw_read_1.fastq.gz"
    r2="data/raw_input/raw_read_2.fastq.gz"
fi
for file in "$r1" "$r2"; do
    [[ -s "$file" ]] || fail "Missing or empty FASTQ: $file"
done

ref="data/reference"
for f in Homo_sapiens_assembly38.fasta{,.fai,.amb,.ann,.bwt,.pac,.sa,.alt} \
         Homo_sapiens_assembly38.dict \
         Homo_sapiens_assembly38.dbsnp138.vcf{,.idx} \
         Mills_and_1000G_gold_standard.indels.hg38.vcf.gz{,.tbi}; do
    [[ -s "$ref/$f" ]] || fail "Missing or empty reference file: $ref/$f"
done

echo "== Running step 2 =="
nextflow run workflows/step2_alignment.nf -c workflows/nextflow.config -profile docker -resume --r1 "$r1" --r2 "$r2" \
    -with-report "$run_dir/report.html" \
    -with-trace "$run_dir/trace.tsv" \
    -with-timeline "$run_dir/timeline.html"

echo "Recalibrated BAM: results/raw_results/02_alignment/bqsr/"
echo "QC reports:       results/raw_results/02_alignment/qc/"
echo "Run reports:      $run_dir/"
echo "Launcher log:     logs/alignment_${run_id}.log"

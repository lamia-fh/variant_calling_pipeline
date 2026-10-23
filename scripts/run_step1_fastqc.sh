#!/usr/bin/env bash
# Step 1 runner.
#   scripts/run_step1_fastqc.sh                              -> raw FastQC only
#   scripts/run_step1_fastqc.sh proceed "justification"      -> record decision, pass original R1/R2 onward
#   scripts/run_step1_fastqc.sh trim    "justification"      -> record decision, fastp + post-trim FastQC
#   scripts/run_step1_fastqc.sh hold    "justification"      -> record decision, stop for investigation
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.local/bin:$PATH"

decision="${1:-}"
justification="${2:-}"

if [[ -z "$decision" ]]; then
    nextflow run workflows/step1_fastqc.nf -c workflows/nextflow.config -profile docker -resume
    echo "Raw QC reports: results/raw_results/01_fastqc/fastqc_raw/ (open the *_fastqc.html files)"
    echo "Next: $0 proceed|trim|hold \"justification\""
    exit 0
fi

if [[ ! "$decision" =~ ^(proceed|trim|hold)$ || -z "$justification" ]]; then
    echo "Usage: $0 [proceed|trim|hold \"justification\"]" >&2
    exit 1
fi

nextflow run workflows/step1_fastqc.nf -c workflows/nextflow.config -profile docker -resume \
    --decision "$decision" --justification "$justification"
echo "Decision recorded: results/raw_results/01_fastqc/qc_decision.json"

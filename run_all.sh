#!/usr/bin/env bash
# Runs the full pipeline. Usage: bash run_all.sh <path to SmellyCode++ CSV> [work dir]
# Your outputs go to the work dir (default: work/); results/ holds the outputs of the reported run for comparison.
set -euo pipefail
CSV="${1:?give the path to the SmellyCode++ CSV}"
W="${2:-work}"
mkdir -p "$W"
python src/step1_clean_group.py "$CSV" "$W" | tee "$W/step1.log"       # ~2 min
python src/step2_split.py "$W"              | tee "$W/step2.log"       # seconds
python src/clusters.py "$W"                 | tee "$W/clusters.log"    # seconds
python src/step3_tune.py "$W"               | tee "$W/step3.log"       # ~30 min on 2 CPU cores
python src/step4_test.py "$W"               | tee "$W/step4.log"       # ~8 min
python src/step5_contrast.py "$W" "$CSV"    | tee "$W/step5.log"       # ~5 min
python src/step6_facts.py "$CSV" "$W"       | tee "$W/facts.log"       # ~1 min
python src/fig3.py "$W/results.json" "$W/fig3.png"
echo "done: compare $W/results.json with results/results.json"

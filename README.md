# Cross-project prediction of Java code smells on SmellyCode++

Code, split manifest and outputs for the paper *A Study on Cross-Project Prediction of Java Code Smells Using Classical Machine-Learning Models* (V. I. Nefolovhodwe, Durban University of Technology, 2026).

The pipeline compares Random Forest, Logistic Regression and XGBoost (one binary classifier per smell) under project-grouped validation. Nothing is fitted before the split, every data-dependent step is re-fitted inside training folds, and the frozen models are scored once on 18 test projects.

## 1. Get the data

SmellyCode++ (Alomari *et al.*, 2025) is on figshare under CC0 1.0: <https://doi.org/10.6084/m9.figshare.28519385>

- Download `multi-smell-dataset-v1_2.csv` (618 MB). The direct link is <https://ndownloader.figshare.com/files/52714583>.
- The figshare record holds two identical copies (file ids 52714583 and 52714586), and a bulk download prefixes the file names with these ids.
- SHA-256 of the file used: `971a81da3f55326a5a56bae59c3cde34c4ebab1a99615ac0c474ce5ecf5029d2`
- Put the CSV in `data/`. Any file name works, because the path is passed to the scripts.

## 2. Install

Python 3.13 was used. Install the pinned versions:

```
pip install -r requirements.txt
```

A CPU is enough: the reported run used two cores and no GPU.

## 3. Run

```
bash run_all.sh data/multi-smell-dataset-v1_2.csv
```

The full run takes about 45 minutes, most of it the grid search in step 3. Your outputs go to `work/`. The `results/` folder holds the outputs of the reported run so you can compare.

To run in Google Colab, upload this folder as a zip and open `SmellyCode_cross_project.ipynb`.

| Step | Script | What it does | Main outputs |
|---|---|---|---|
| 1 | `src/step1_clean_group.py` | Rule-based checks. Drops code whose copies carry contradictory labels and keeps one copy of other duplicates. Screens cross-project near-duplicates with MinHash (5-token shingles, Jaccard ≥ 0.8) and links projects into groups at a 10% overlap threshold. | `clean.pkl`, `clean_log.json`, `near_dup_project_pairs.csv` |
| 2 | `src/step2_split.py` | Seeded project-level split: StratifiedGroupKFold on four-label combination keys, `random_state = 42`. Builds the inner folds and asserts that all partitions and folds are disjoint. | `split_manifest.csv`, `table1.csv`, `split_info.json` |
| – | `src/clusters.py` | Forms the metric clusters used for permutation importance (\|ρ\| ≥ 0.95, training projects only). | `clusters.log` |
| 3 | `src/step3_tune.py` | Grid search with grouped 5-fold CV on the training projects, with and without class weighting. Thresholds come from out-of-fold predictions. | `cv_all_configs.csv`, `cv_best.pkl` |
| 4 | `src/step4_test.py` | Selects weighting and the best model on validation, then refits and scores the test projects once. Computes project-bootstrap CIs, per-project F1, co-occurrence, stratified recall, held-out permutation importance and rank agreement. | `results.json` |
| 5 | `src/step5_contrast.py` | Sensitivity check on the training projects only: a random 80/20 split of the raw data and of the cleaned data, compared with grouped CV. | `contrast.json` |
| 6 | `src/step6_facts.py` | Descriptive facts quoted in the paper: the Thrift share, where the removed labels came from, metric correlations, and how class snippets compare with Long Method samples in length. | `facts.log` |
| – | `src/fig3.py` | Draws Fig. 3. | `fig3.png` |

## 4. Where the paper's numbers come from

| In the paper | Source |
|---|---|
| Section V (cleaning counts, near-duplicate screening, exclusions, kept metrics) | `clean_log.json`, `step3.log` (first line), `facts.log` |
| Table I and the list of test projects | `table1.csv`, `split_info.json`, `split_manifest.csv` |
| Table II (validation) | `results.json` → `validation` |
| Tables III–IV and Section VI-C (test, bootstrap CIs, per-project F1) | `results.json` → `test` |
| Table V and Section VI-D | `results.json` → `weighting_delta`, `stratified_recall`, `cooccurrence` |
| Fig. 3 and Section VI-E | `results.json` → `perm_test`, `perm_val`, `rank_agreement`, `cross_model_perm_rho` |
| Section VII (random-split contrast, granularity) | `contrast.json`, `facts.log` |

## 5. Notes

- **Project count.** The released file has 89 distinct project identifiers, although 103 projects are reported for the dataset. No project pair reached the linking threshold, so the 89 projects are the 89 groups.
- **Leakage controls.** Only rule-based checks and de-duplication, which estimate nothing from the data, run before the split. Correlation screening, the log transform and scaling (Logistic Regression only), and class weights sit inside the model pipelines, so they are re-fitted in every training fold. Test rows are used only in step 4, after every setting has been chosen from validation results.
- **Determinism.** All seeds are 42. Re-running steps 1–2 reproduced the split manifest, Table I and the cleaning log exactly; in `near_dup_project_pairs.csv`, only the order of tied rows can differ.

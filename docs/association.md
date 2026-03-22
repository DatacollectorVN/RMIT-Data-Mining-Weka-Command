# Weka Association Rules Reference

All association algorithms listed here are compatible with `run_model.sh`. Set `"task"` to `"association"` and `"evaluation.mode"` to `"dataset"`.

```json
{
  "task": "association",
  "algorithm": "weka.associations.Apriori",
  "options": ["-N", "10", "-C", "0.9"],
  "evaluation": {
    "mode": "dataset",
    "dataset": "/absolute/path/to/data.arff"
  }
}
```

> **Important:** Association rule mining requires **nominal (categorical) attributes**. Numeric attributes must be discretized beforehand using `run_data.sh` with `weka.filters.unsupervised.attribute.Discretize`.

> **Tip:** Run `bash app/utils/model_helper.sh <algorithm.class.Name>` to print the full option list directly from the JAR.

---

## Quick Reference

| Name | Weka Class | Method |
|------|-----------|--------|
| Apriori | `weka.associations.Apriori` | Breadth-first candidate generation |
| FPGrowth | `weka.associations.FPGrowth` | FP-tree (no candidate generation) |
| FilteredAssociator | `weka.associations.FilteredAssociator` | Wrapper with built-in filtering |

---

## Key Concepts

| Term | Definition |
|------|-----------|
| **Support** | Fraction of transactions that contain an itemset. `support(A→B) = P(A∪B)` |
| **Confidence** | How often the rule is correct. `confidence(A→B) = P(B\|A)` |
| **Lift** | How much more likely B is given A vs. baseline. `lift = confidence / P(B)`. Lift > 1 means positive correlation |
| **Leverage** | Difference between observed and expected co-occurrence. `leverage = P(A∪B) - P(A)×P(B)` |
| **Conviction** | Measures rule implication strength. `conviction = (1-P(B)) / (1-confidence)` |

---

## Apriori

**Class:** `weka.associations.Apriori`

Classic breadth-first association rule miner. Iteratively reduces minimum support until the required number of rules is found.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-N` | `<num>` | `10` | Required number of rules to output |
| `-T` | `0\|1\|2\|3` | `0` | Metric to rank rules: `0`=confidence, `1`=lift, `2`=leverage, `3`=conviction |
| `-C` | `<num>` | `0.9` | Minimum metric score (minimum confidence by default) |
| `-M` | `<num>` | `0.1` | Lower bound for minimum support |
| `-U` | `<num>` | `1.0` | Upper bound for minimum support |
| `-D` | `<num>` | `0.05` | Delta by which minimum support is decreased each iteration |
| `-S` | `<num>` | — | Significance level for statistical testing of rules (disabled by default) |
| `-I` | flag | off | Also output the discovered itemsets |
| `-R` | flag | off | Remove attributes that are entirely missing |
| `-A` | flag | off | Mine class association rules (supervised) |
| `-Z` | flag | off | Treat zero (first nominal value) as missing |
| `-c` | `<index>` | `last` | Class attribute index (used with `-A`) |

**Config example — top 20 rules by confidence:**
```json
{
  "task": "association",
  "algorithm": "weka.associations.Apriori",
  "options": ["-N", "20", "-C", "0.8", "-M", "0.05"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

**Config example — rank by lift:**
```json
{
  "task": "association",
  "algorithm": "weka.associations.Apriori",
  "options": ["-N", "15", "-T", "1", "-C", "1.5", "-M", "0.05"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

**Config example — output itemsets too:**
```json
{
  "task": "association",
  "algorithm": "weka.associations.Apriori",
  "options": ["-N", "10", "-C", "0.9", "-I"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

---

## FPGrowth

**Class:** `weka.associations.FPGrowth`

FP-tree based association rule miner. Avoids expensive candidate generation — much faster than Apriori on dense datasets with many items.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-N` | `<num>` | `10` | Required number of rules |
| `-T` | `0\|1\|2\|3` | `0` | Ranking metric: `0`=confidence, `1`=lift, `2`=leverage, `3`=conviction |
| `-C` | `<num>` | `0.9` | Minimum metric score |
| `-M` | `<num>` | `0.1` | Lower bound for minimum support (as fraction or instance count) |
| `-U` | `<num>` | `1.0` | Upper bound for minimum support |
| `-D` | `<num>` | `0.05` | Delta for minimum support reduction per iteration |
| `-I` | `<num>` | `-1` | Maximum items per itemset (`-1` = no limit) |
| `-P` | `<num>` | `2` | Index of positive value for binary attributes (dense instances) |
| `-S` | flag | off | Find all rules meeting support/metric constraints (disables iterative reduction) |
| `-transactions` | `<comma-separated items>` | — | Only consider transactions containing these items |
| `-rules` | `<comma-separated items>` | — | Only print rules containing these items |
| `-use-or` | flag | off | Use OR instead of AND for `-transactions`/`-rules` filters |

**Config example — standard run:**
```json
{
  "task": "association",
  "algorithm": "weka.associations.FPGrowth",
  "options": ["-N", "10", "-C", "0.9", "-M", "0.1"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

**Config example — rank by lift, low support threshold:**
```json
{
  "task": "association",
  "algorithm": "weka.associations.FPGrowth",
  "options": ["-N", "20", "-T", "1", "-C", "1.2", "-M", "0.02"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

**Config example — find all rules (no iteration):**
```json
{
  "task": "association",
  "algorithm": "weka.associations.FPGrowth",
  "options": ["-S", "-C", "0.8", "-M", "0.1"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

---

## FilteredAssociator

**Class:** `weka.associations.FilteredAssociator`

A wrapper that applies a filter to the data before running an association algorithm. Useful for automatically handling missing values or attribute types without a separate preprocessing step.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-F` | `"<filter class [opts]>"` | `ReplaceMissingValues` | Filter to apply before mining |
| `-W` | `<classname>` | `weka.associations.Apriori` | Base association algorithm |
| `-c` | `<index>` | `-1` | Class index (unset by default) |

**Config example — replace missing values then run Apriori:**
```json
{
  "task": "association",
  "algorithm": "weka.associations.FilteredAssociator",
  "options": [
    "-F", "weka.filters.unsupervised.attribute.ReplaceMissingValues",
    "-W", "weka.associations.Apriori -- -N 10 -C 0.9"
  ],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

---

## Data Requirements

Association rule mining in Weka requires nominal data. Use `run_data.sh` to prepare your dataset:

```json
{
  "input": "/path/to/data.arff",
  "is_debug": false,
  "steps": [
    {
      "name": "replace_missing",
      "filter": "weka.filters.unsupervised.attribute.ReplaceMissingValues",
      "options": []
    },
    {
      "name": "discretize",
      "filter": "weka.filters.unsupervised.attribute.Discretize",
      "options": ["-B", "5"]
    },
    {
      "name": "numeric_to_nominal",
      "filter": "weka.filters.unsupervised.attribute.NumericToNominal",
      "options": ["-R", "first-last"]
    }
  ]
}
```

---

## Choosing an Algorithm

| Situation | Recommended |
|-----------|------------|
| Standard use / interpretable | `Apriori` |
| Large datasets / many items | `FPGrowth` |
| Data has missing values | `FilteredAssociator` or preprocess with `run_data.sh` |
| Rank by lift or leverage | Both support `-T 1` (lift) or `-T 2` (leverage) |
| Find ALL rules above threshold | `FPGrowth -S` |

---

## Metric Thresholds Guide

| Metric (`-T`) | Typical minimum (`-C`) | Interpretation |
|---------------|----------------------|----------------|
| Confidence (`0`) | `0.7` – `0.9` | At least 70–90% of A transactions also contain B |
| Lift (`1`) | `1.2` – `2.0` | B is 1.2–2× more likely given A than by chance |
| Leverage (`2`) | `0.01` – `0.05` | Small positive values indicate meaningful co-occurrence |
| Conviction (`3`) | `1.5` – `3.0` | Higher values indicate stronger implication |

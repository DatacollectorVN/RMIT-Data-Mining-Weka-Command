# Weka Preprocessor Reference

All filters listed here are compatible with `run_data.sh`. Set the `filter` field to the full class name and pass flags as individual strings in the `options` array.

```json
{
  "name": "my_step",
  "filter": "weka.filters.unsupervised.attribute.Normalize",
  "options": ["-S", "1.0", "-T", "0.0"]
}
```

> **Tip:** Run `bash app/utils/model_helper.sh <filter.class.Name>` to print the full option list for any filter directly from the JAR.

---

## Unsupervised Attribute Filters

Operate on attributes (columns) without needing a class label.

### ReplaceMissingValues

**Class:** `weka.filters.unsupervised.attribute.ReplaceMissingValues`

Replaces missing numeric values with the mean and missing nominal values with the mode of the attribute.

| Option | Description |
|--------|-------------|
| (none) | No configurable options |

**Config example:**
```json
{
  "name": "replace_missing",
  "filter": "weka.filters.unsupervised.attribute.ReplaceMissingValues",
  "options": []
}
```

---

### Normalize

**Class:** `weka.filters.unsupervised.attribute.Normalize`

Scales all numeric attributes into a given range. Default: 0–1.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-S` | `<num>` | `1.0` | Scaling factor for the output range |
| `-T` | `<num>` | `0.0` | Translation (shift) of the output range |

Result range = `[T, S + T]`. Default gives `[0.0, 1.0]`.

**Config example:**
```json
{
  "name": "normalize",
  "filter": "weka.filters.unsupervised.attribute.Normalize",
  "options": ["-S", "1.0", "-T", "0.0"]
}
```

---

### Standardize

**Class:** `weka.filters.unsupervised.attribute.Standardize`

Standardizes all numeric attributes to zero mean and unit variance (z-score normalization).

| Option | Description |
|--------|-------------|
| (none) | No configurable options |

**Config example:**
```json
{
  "name": "standardize",
  "filter": "weka.filters.unsupervised.attribute.Standardize",
  "options": []
}
```

---

### Discretize (Unsupervised)

**Class:** `weka.filters.unsupervised.attribute.Discretize`

Bins numeric attributes into discrete intervals using equal-width or equal-frequency binning.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-B` | `<num>` | `10` | Maximum number of bins |
| `-M` | `<num>` | `-1` | Desired weight of instances per bin (equal-frequency). Overrides `-B` when positive |
| `-F` | flag | off | Use equal-frequency instead of equal-width |
| `-O` | flag | off | Optimize bin count using leave-one-out entropy estimate |
| `-R` | `<col1,col2-col4,...>` | `first-last` | Columns to discretize (`first`, `last`, ranges, and lists are valid) |
| `-V` | flag | off | Invert column selection |
| `-D` | flag | off | Output binary attributes for each bin |
| `-Y` | flag | off | Use bin numbers instead of ranges as attribute values |
| `-precision` | `<int>` | `6` | Decimal precision for bin boundary labels |

**Config example — equal-width, 5 bins, all attributes:**
```json
{
  "name": "discretize",
  "filter": "weka.filters.unsupervised.attribute.Discretize",
  "options": ["-B", "5"]
}
```

**Config example — equal-frequency on attributes 1–3:**
```json
{
  "name": "discretize_freq",
  "filter": "weka.filters.unsupervised.attribute.Discretize",
  "options": ["-F", "-B", "10", "-R", "1-3"]
}
```

---

### Remove

**Class:** `weka.filters.unsupervised.attribute.Remove`

Removes attributes by index. Supports single indexes, comma-separated lists, and ranges.

| Option | Value | Description |
|--------|-------|-------------|
| `-R` | `<index1,index2-index4,...>` | Columns to remove. `first` and `last` are valid. |
| `-V` | flag | Invert selection — keep only the specified columns |

**Config example — remove columns 1 and 2:**
```json
{
  "name": "remove_attr",
  "filter": "weka.filters.unsupervised.attribute.Remove",
  "options": ["-R", "1,2"]
}
```

**Config example — keep only columns 3 to 10:**
```json
{
  "name": "keep_cols",
  "filter": "weka.filters.unsupervised.attribute.Remove",
  "options": ["-R", "3-10", "-V"]
}
```

---

### NominalToBinary

**Class:** `weka.filters.unsupervised.attribute.NominalToBinary`

Converts nominal attributes to binary (one-hot) numeric attributes.

| Option | Value | Description |
|--------|-------|-------------|
| `-R` | `<col1,col2-col4,...>` | Columns to convert (default: `first-last`) |
| `-V` | flag | Invert column selection |
| `-N` | flag | Encode binary attributes as nominal instead of numeric |
| `-A` | flag | Always create a new attribute for each nominal value, even for binary attributes |

**Config example:**
```json
{
  "name": "nominal_to_binary",
  "filter": "weka.filters.unsupervised.attribute.NominalToBinary",
  "options": []
}
```

---

### StringToNominal

**Class:** `weka.filters.unsupervised.attribute.StringToNominal`

Converts string attributes to nominal (categorical) attributes.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-R` | `<col>` | `last` | Attribute(s) to convert. Ranges and lists are valid |
| `-V` | flag | off | Invert the column range |

**Config example — convert last attribute:**
```json
{
  "name": "string_to_nominal",
  "filter": "weka.filters.unsupervised.attribute.StringToNominal",
  "options": ["-R", "last"]
}
```

---

### NumericToNominal

**Class:** `weka.filters.unsupervised.attribute.NumericToNominal`

Converts numeric attributes to nominal. Useful when an integer-coded categorical variable is stored as numeric.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-R` | `<col1,col2-col4,...>` | `first-last` | Columns to convert |
| `-V` | flag | off | Invert column selection |

**Config example — convert column 5 only:**
```json
{
  "name": "numeric_to_nominal",
  "filter": "weka.filters.unsupervised.attribute.NumericToNominal",
  "options": ["-R", "5"]
}
```

---

### PrincipalComponents

**Class:** `weka.filters.unsupervised.attribute.PrincipalComponents`

Performs Principal Component Analysis (PCA) to reduce dimensionality by projecting data onto the principal components that explain the most variance. Requires `app/mtj-1.0.4.jar`.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-R` | `<0.0–1.0>` | `0.95` | Proportion of total variance the retained components must account for |
| `-A` | `<num>` | `5` | Max number of original attribute names to include in transformed attribute labels (`-1` = all) |
| `-M` | `<num>` | `-1` | Max number of PC attributes to keep (`-1` = keep all that satisfy `-R`) |
| `-C` | flag | off | Center data (use covariance matrix) instead of standardizing (correlation matrix) |

**Config example — retain 95% variance (default):**
```json
{
  "name": "pca",
  "filter": "weka.filters.unsupervised.attribute.PrincipalComponents",
  "options": []
}
```

**Config example — retain 99% variance, keep up to 10 components:**
```json
{
  "name": "pca_99",
  "filter": "weka.filters.unsupervised.attribute.PrincipalComponents",
  "options": ["-R", "0.99", "-M", "10"]
}
```

---

## Unsupervised Instance Filters

Operate on rows (instances) without needing a class label.

### Resample (Unsupervised)

**Class:** `weka.filters.unsupervised.instance.Resample`

Randomly resamples the dataset with or without replacement.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-S` | `<num>` | `1` | Random seed |
| `-Z` | `<num>` | `100` | Output size as a percentage of input (e.g. `50` = half the data) |
| `-no-replacement` | flag | off | Sample without replacement |
| `-V` | flag | off | Invert selection (only with `-no-replacement`) |

**Config example — 80% sample without replacement:**
```json
{
  "name": "resample_80",
  "filter": "weka.filters.unsupervised.instance.Resample",
  "options": ["-Z", "80", "-no-replacement", "-S", "42"]
}
```

---

### RemoveWithValues

**Class:** `weka.filters.unsupervised.instance.RemoveWithValues`

Removes instances based on the value of a chosen attribute.

| Option | Value | Description |
|--------|-------|-------------|
| `-C` | `<num>` | Attribute index to filter on |
| `-S` | `<num>` | Numeric threshold — removes instances with values **below** this |
| `-L` | `<index1,index2-index4,...>` | Nominal label indexes to match for removal |
| `-M` | flag | Treat missing values as matching (default: missing values do not match) |
| `-V` | flag | Invert matching — remove instances that do NOT match |
| `-H` | flag | Remove header references to excluded nominal values |

**Config example — remove instances where attribute 3 is label index 1:**
```json
{
  "name": "remove_class1",
  "filter": "weka.filters.unsupervised.instance.RemoveWithValues",
  "options": ["-C", "3", "-L", "1"]
}
```

---

## Supervised Attribute Filters

Require a class attribute to be set. Use `-c` if needed (or set `evaluation.dataset` with the class as the last attribute).

### AttributeSelection

**Class:** `weka.filters.supervised.attribute.AttributeSelection`

Selects the most relevant attributes using an evaluator and a search strategy.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-E` | `"<EvaluatorClass [opts]>"` | `CfsSubsetEval` | Attribute/subset evaluator |
| `-S` | `"<SearchClass [opts]>"` | `BestFirst` | Search method |

**Common evaluators:**

| Class | Description |
|-------|-------------|
| `weka.attributeSelection.CfsSubsetEval` | Correlation-based feature selection |
| `weka.attributeSelection.InfoGainAttributeEval` | Information gain per attribute |
| `weka.attributeSelection.GainRatioAttributeEval` | Gain ratio per attribute |
| `weka.attributeSelection.ReliefFAttributeEval` | Relief-F scoring |

**Common search strategies:**

| Class | Description |
|-------|-------------|
| `weka.attributeSelection.BestFirst` | Best-first greedy search |
| `weka.attributeSelection.Ranker` | Ranks individual attributes (use with per-attribute evaluators) |
| `weka.attributeSelection.GreedyStepwise` | Forward/backward greedy selection |

**Config example — CFS with BestFirst forward search:**
```json
{
  "name": "feature_selection",
  "filter": "weka.filters.supervised.attribute.AttributeSelection",
  "options": [
    "-E", "weka.attributeSelection.CfsSubsetEval",
    "-S", "weka.attributeSelection.BestFirst -D 1 -N 5"
  ]
}
```

**Config example — InfoGain with Ranker (top 10 attributes):**
```json
{
  "name": "infogain_top10",
  "filter": "weka.filters.supervised.attribute.AttributeSelection",
  "options": [
    "-E", "weka.attributeSelection.InfoGainAttributeEval",
    "-S", "weka.attributeSelection.Ranker -N 10"
  ]
}
```

---

### Discretize (Supervised — MDL)

**Class:** `weka.filters.supervised.attribute.Discretize`

Discretizes numeric attributes using Fayyad & Irani's MDL (Minimum Description Length) method — a class-aware, data-driven approach that determines the optimal bin boundaries automatically.

| Option | Value | Description |
|--------|-------|-------------|
| `-R` | `<col1,col2-col4,...>` | Columns to discretize (default: none → all numeric) |
| `-V` | flag | Invert column selection |
| `-D` | flag | Output binary attributes for discretized values |
| `-Y` | flag | Use bin numbers instead of ranges |
| `-E` | flag | Use better encoding of split point for MDL |
| `-K` | flag | Use Kononenko's MDL criterion instead of Fayyad & Irani's |
| `-precision` | `<int>` | Decimal precision for boundary labels (default: `6`) |

**Config example:**
```json
{
  "name": "mdl_discretize",
  "filter": "weka.filters.supervised.attribute.Discretize",
  "options": []
}
```

---

## Supervised Instance Filters

Require a class attribute. Used to balance or subsample datasets.

### Resample (Supervised)

**Class:** `weka.filters.supervised.instance.Resample`

Resamples the dataset with optional class distribution balancing.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-S` | `<num>` | `1` | Random seed |
| `-Z` | `<num>` | `100` | Output size as a percentage of input |
| `-B` | `<num>` | `0` | Bias towards uniform class distribution. `0` = original distribution, `1` = fully uniform |
| `-no-replacement` | flag | off | Sample without replacement |
| `-V` | flag | off | Invert selection (only with `-no-replacement`) |

**Config example — 100% resample with uniform class distribution:**
```json
{
  "name": "balance_classes",
  "filter": "weka.filters.supervised.instance.Resample",
  "options": ["-B", "1.0", "-Z", "100", "-S", "42"]
}
```

---

### SpreadSubsample

**Class:** `weka.filters.supervised.instance.SpreadSubsample`

Undersamples the majority class to achieve a specified class ratio.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-S` | `<num>` | `1` | Random seed |
| `-M` | `<num>` | `0` | Maximum class distribution spread. `0` = no limit, `1` = uniform, `10` = max 10:1 ratio |
| `-X` | `<num>` | `0` | Maximum instance count for any class (`0` = unlimited) |
| `-W` | flag | off | Adjust weights to maintain total class weight |

**Config example — enforce uniform class distribution:**
```json
{
  "name": "undersample",
  "filter": "weka.filters.supervised.instance.SpreadSubsample",
  "options": ["-M", "1.0", "-S", "42"]
}
```

---

## Column Range Syntax

Many filters accept `-R` for specifying attribute ranges. The syntax is consistent across all filters:

| Syntax | Meaning |
|--------|---------|
| `1` | Attribute at index 1 |
| `1,3,5` | Attributes 1, 3, and 5 |
| `2-5` | Attributes 2 through 5 |
| `1,3-5,7` | Attributes 1, 3, 4, 5, and 7 |
| `first` | First attribute |
| `last` | Last attribute |
| `first-last` | All attributes |

---

## Common Pipeline Recipes

### Basic cleanup before classification
```json
{
  "steps": [
    { "name": "replace_missing", "filter": "weka.filters.unsupervised.attribute.ReplaceMissingValues", "options": [] },
    { "name": "normalize", "filter": "weka.filters.unsupervised.attribute.Normalize", "options": [] }
  ]
}
```

### Convert types then remove irrelevant attributes
```json
{
  "steps": [
    { "name": "str_to_nominal", "filter": "weka.filters.unsupervised.attribute.StringToNominal", "options": ["-R", "first-last"] },
    { "name": "remove_id", "filter": "weka.filters.unsupervised.attribute.Remove", "options": ["-R", "1"] }
  ]
}
```

### Class imbalance — undersample majority
```json
{
  "steps": [
    { "name": "replace_missing", "filter": "weka.filters.unsupervised.attribute.ReplaceMissingValues", "options": [] },
    { "name": "undersample", "filter": "weka.filters.supervised.instance.SpreadSubsample", "options": ["-M", "1.0", "-S", "1"] }
  ]
}
```

### Feature selection pipeline
```json
{
  "steps": [
    { "name": "replace_missing", "filter": "weka.filters.unsupervised.attribute.ReplaceMissingValues", "options": [] },
    { "name": "select_features", "filter": "weka.filters.supervised.attribute.AttributeSelection", "options": ["-E", "weka.attributeSelection.InfoGainAttributeEval", "-S", "weka.attributeSelection.Ranker -N 10"] }
  ]
}
```

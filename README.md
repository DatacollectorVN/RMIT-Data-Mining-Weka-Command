# RMIT Data Mining - Weka Command Runner

A bash-based toolkit for Weka experiments. Two entry points cover the full workflow:

- **`app/run_data.sh`** — preprocess raw ARFF files through a configurable filter pipeline
- **`app/run_model.sh`** — run classification, regression, clustering, or association tasks on processed data

Both scripts are configured via JSON files and save all outputs to versioned, timestamped paths automatically.

> Note: Developed and tested on macOS. Linux may work but is not verified. Windows is not supported.

## Project Structure

```
.
├── app/
│   ├── weka.jar                              # Weka application JAR
│   ├── run_data.sh                           # Data preprocessing pipeline runner
│   ├── run_model.sh                          # Model training / evaluation runner
│   ├── data/
│   │   └── example_preprocess.json           # Preprocessing pipeline config example
│   ├── models/
│   │   ├── classification/
│   │   │   ├── example_crossval.json
│   │   │   ├── example_traintest.json
│   │   │   └── example_ibk_crossval.json
│   │   ├── clustering/
│   │   │   └── example_kmeans.json
│   │   └── association/
│   │       └── example_apriori.json
│   └── utils/
│       └── model_helper.sh                   # Print algorithm-specific options
├── data/                                     # Raw ARFF datasets
├── .rmit_datasets/                           # Processed datasets output (auto-created)
├── .rmit_reports/                            # Model run reports output (auto-created)
├── docs/
│   ├── classification.md                     # Classifier parameters reference
│   ├── clustering.md                         # Clusterer parameters reference
│   ├── association.md                        # Association rule parameters reference
│   ├── preprocessing.md                      # Filter parameters reference
│   └── model_visualization.md                # Weka GUI visualization guide
└── README.md
```

## Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| `java` | Run Weka JAR | `brew install --cask temurin` |
| `jq` | Parse JSON config | `brew install jq` |
| `uuidgen` | Generate unique run IDs | Built-in on macOS |

---

## Documentation

Detailed parameter references for all supported algorithms and filters:

| File | Contents |
|------|---------|
| [`docs/classification.md`](docs/classification.md) | All classifiers with parameters and config examples |
| [`docs/clustering.md`](docs/clustering.md) | All clusterers with parameters and config examples |
| [`docs/association.md`](docs/association.md) | Association rule algorithms with parameters and config examples |
| [`docs/preprocessing.md`](docs/preprocessing.md) | All Weka filters for data preprocessing |
| [`docs/model_visualization.md`](docs/model_visualization.md) | How to load and visualize saved models in the Weka GUI |

---

## Data Preprocessing — `run_data.sh`

### Usage

```bash
bash app/run_data.sh <path/to/config.json>
```

**Example:**

```bash
bash app/run_data.sh app/data/example_preprocess.json
```

### Config Schema

```json
{
  "input": "/absolute/path/to/data.arff",
  "is_debug": false,
  "steps": [
    {
      "name": "replace_missing",
      "filter": "weka.filters.unsupervised.attribute.ReplaceMissingValues",
      "options": []
    },
    {
      "name": "normalize",
      "filter": "weka.filters.unsupervised.attribute.Normalize",
      "options": []
    },
    {
      "name": "remove_attr",
      "filter": "weka.filters.unsupervised.attribute.Remove",
      "options": ["-R", "1"]
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `input` | string | yes | Absolute path to input `.arff` file |
| `is_debug` | boolean | no | If `true`, saves each step's output separately (default: `false`) |
| `steps[].name` | string | yes | Label used in filenames and logs |
| `steps[].filter` | string | yes | Full Weka filter class name |
| `steps[].options` | array | no | Filter options passed directly to Weka |

### Output Paths

**Normal run** (`is_debug: false`):
```
.rmit_datasets/
  20260322/
    chronic_kidney_disease_3f2504e0/
      chronic_kidney_disease_20260322_143022.arff
```

**Debug run** (`is_debug: true`) — each step also saved:
```
.rmit_datasets/
  20260322/
    chronic_kidney_disease_3f2504e0/
      chronic_kidney_disease_20260322_143022.arff
      steps/
        001_replace_missing_20260322_143022.arff
        002_normalize_20260322_143022.arff
        003_remove_attr_20260322_143022.arff
```

### Common Weka Filters

| Purpose | Filter Class |
|---------|-------------|
| Replace missing values | `weka.filters.unsupervised.attribute.ReplaceMissingValues` |
| Normalize attributes (0–1) | `weka.filters.unsupervised.attribute.Normalize` |
| Standardize attributes (mean=0) | `weka.filters.unsupervised.attribute.Standardize` |
| Discretize numeric attributes | `weka.filters.unsupervised.attribute.Discretize` |
| Remove attributes by index | `weka.filters.unsupervised.attribute.Remove` |
| Nominal to binary encoding | `weka.filters.unsupervised.attribute.NominalToBinary` |
| String to nominal | `weka.filters.unsupervised.attribute.StringToNominal` |
| Resample (balance/undersample) | `weka.filters.supervised.instance.Resample` |
| SMOTE (oversample minority) | `weka.filters.supervised.instance.SMOTE` |

---

## Model Training — `run_model.sh`

### Usage

```bash
bash app/run_model.sh <path/to/config.json>
```

**Examples:**

```bash
# Classification
bash app/run_model.sh app/models/classification/example_crossval.json

# Clustering
bash app/run_model.sh app/models/clustering/example_kmeans.json

# Association rules
bash app/run_model.sh app/models/association/example_apriori.json
```

Each run saves output to:
```
.rmit_reports/20260322/20260322_143022/
  report_classification_J48.txt    ← evaluation metrics
  config.json                      ← copy of the config used
  model_classification_J48.model   ← serialized model (loadable in Weka GUI)
```

Set `"save_model": false` in the config to skip saving the model file. See [`docs/model_visualization.md`](docs/model_visualization.md) for how to load and visualize the saved model in Weka Explorer.

### Config Schema

All model configs share the same structure. The `task` field controls routing.

**Classification / Regression — Cross-validation:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.trees.J48",
  "options": ["-C", "0.25", "-M", "2"],
  "evaluation": {
    "mode": "cross-validation",
    "folds": 10,
    "dataset": "/absolute/path/to/data.arff"
  }
}
```

**Classification / Regression — Train/Test split:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.trees.J48",
  "options": ["-C", "0.25", "-M", "2"],
  "evaluation": {
    "mode": "train-test",
    "train_file": "/absolute/path/to/train.arff",
    "test_file": "/absolute/path/to/test.arff"
  }
}
```

**Clustering:**
```json
{
  "task": "clustering",
  "algorithm": "weka.clusterers.SimpleKMeans",
  "options": ["-N", "3", "-S", "10"],
  "evaluation": {
    "mode": "dataset",
    "dataset": "/absolute/path/to/data.arff"
  }
}
```

**Association Rules:**
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

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task` | string | yes | `classification`, `regression`, `clustering`, or `association` |
| `algorithm` | string | yes | Full Weka class name |
| `options` | array | no | Algorithm options passed directly to Weka |
| `evaluation.mode` | string | yes | `cross-validation`, `train-test`, or `dataset` |
| `evaluation.folds` | number | no | Folds for cross-validation (default: `10`) |
| `evaluation.dataset` | string | varies | Absolute path to `.arff` file |
| `evaluation.train_file` | string | train-test | Absolute path to training `.arff` file |
| `evaluation.test_file` | string | train-test | Absolute path to testing `.arff` file |

### Common Algorithms

**Classifiers / Regressors** (`weka.classifiers.*`)

| Name | Weka Class |
|------|-----------|
| Decision Tree (J48) | `weka.classifiers.trees.J48` |
| Naive Bayes | `weka.classifiers.bayes.NaiveBayes` |
| Random Forest | `weka.classifiers.trees.RandomForest` |
| SVM (SMO) | `weka.classifiers.functions.SMO` |
| k-Nearest Neighbour (IBk) | `weka.classifiers.lazy.IBk` |
| Logistic Regression | `weka.classifiers.functions.Logistic` |
| Linear Regression | `weka.classifiers.functions.LinearRegression` |

**Clusterers** (`weka.clusterers.*`)

| Name | Weka Class |
|------|-----------|
| k-Means | `weka.clusterers.SimpleKMeans` |
| EM (Expectation Maximisation) | `weka.clusterers.EM` |

**Association Rules** (`weka.associations.*`)

| Name | Weka Class |
|------|-----------|
| Apriori | `weka.associations.Apriori` |
| FP-Growth | `weka.associations.FPGrowth` |

---

## Discovering Options

Use `model_helper.sh` to print all available CLI options for any Weka algorithm or filter:

```bash
bash app/utils/model_helper.sh weka.classifiers.lazy.IBk
bash app/utils/model_helper.sh weka.clusterers.SimpleKMeans
bash app/utils/model_helper.sh weka.filters.unsupervised.attribute.Normalize
```

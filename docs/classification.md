# Weka Classification & Regression Reference

All classifiers listed here are compatible with `train_models.sh`. Set `"task"` to `"classification"` or `"regression"` and each model's `"algorithm"` field to the full class name.

```json
{
  "task": "classification",
  "evaluation": {
    "mode": "cross-validation",
    "folds": 10,
    "dataset": "/absolute/path/to/data.arff"
  },
  "models": [
    { "name": "J48", "algorithm": "weka.classifiers.trees.J48", "options": ["-C", "0.25", "-M", "2"] }
  ]
}
```

> **Tip:** Run `bash app/utils/model_helper.sh <classifier.class.Name>` to print the full option list for any classifier directly from the JAR.

> **Note:** `LinearRegression` and `PrincipalComponents` require the MTJ matrix library (`app/mtj-1.0.4.jar`). Ensure it is present — the scripts include it automatically if found.

---

## Quick Reference

| Name | Weka Class | Type |
|------|-----------|------|
| ZeroR | `weka.classifiers.rules.ZeroR` | Baseline |
| OneR | `weka.classifiers.rules.OneR` | Rule |
| PART | `weka.classifiers.rules.PART` | Rule |
| Naive Bayes | `weka.classifiers.bayes.NaiveBayes` | Probabilistic |
| Bayes Net | `weka.classifiers.bayes.BayesNet` | Probabilistic |
| J48 (C4.5 Decision Tree) | `weka.classifiers.trees.J48` | Tree |
| REPTree | `weka.classifiers.trees.REPTree` | Tree |
| Random Forest | `weka.classifiers.trees.RandomForest` | Ensemble |
| AdaBoost | `weka.classifiers.meta.AdaBoostM1` | Ensemble |
| Bagging | `weka.classifiers.meta.Bagging` | Ensemble |
| IBk (k-NN) | `weka.classifiers.lazy.IBk` | Lazy |
| KStar | `weka.classifiers.lazy.KStar` | Lazy |
| Logistic Regression | `weka.classifiers.functions.Logistic` | Function |
| Linear Regression | `weka.classifiers.functions.LinearRegression` | Function |
| SVM (SMO) | `weka.classifiers.functions.SMO` | Function |

---

## Baseline / Rule Classifiers

### ZeroR

**Class:** `weka.classifiers.rules.ZeroR`

Predicts the majority class for classification or the mean for regression. Used as a baseline to measure how much a real classifier improves over a trivial predictor.

| Option | Description |
|--------|-------------|
| (none) | No configurable options |

**Config example:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.rules.ZeroR",
  "options": [],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

### OneR

**Class:** `weka.classifiers.rules.OneR`

Generates a single rule based on the best single attribute. Simple, fast, and interpretable.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-B` | `<num>` | `6` | Minimum number of instances per bucket when discretizing numeric attributes |

**Config example:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.rules.OneR",
  "options": ["-B", "6"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

### PART

**Class:** `weka.classifiers.rules.PART`

Generates a rule list (decision list) using partial decision trees. More expressive than OneR.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-C` | `<num>` | `0.25` | Confidence threshold for pruning |
| `-M` | `<num>` | `2` | Minimum objects per leaf |
| `-R` | flag | off | Use reduced error pruning instead of C4.5 pruning |
| `-N` | `<num>` | `3` | Number of folds for reduced error pruning |
| `-B` | flag | off | Use binary splits only |
| `-U` | flag | off | Generate unpruned decision list |
| `-Q` | `<seed>` | `1` | Seed for random data shuffling |

**Config example:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.rules.PART",
  "options": ["-C", "0.25", "-M", "2"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

## Probabilistic Classifiers

### NaiveBayes

**Class:** `weka.classifiers.bayes.NaiveBayes`

Applies Bayes' theorem with naive (independent) feature assumption. Works well even with small datasets and missing values.

| Option | Default | Description |
|--------|---------|-------------|
| `-K` | off | Use kernel density estimator for numeric attributes instead of normal distribution |
| `-D` | off | Use supervised discretization for numeric attributes |

**Config example — standard:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.bayes.NaiveBayes",
  "options": [],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

**Config example — with kernel density:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.bayes.NaiveBayes",
  "options": ["-K"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

## Tree Classifiers

### J48 (C4.5 Decision Tree)

**Class:** `weka.classifiers.trees.J48`

Weka's implementation of Quinlan's C4.5 decision tree. The most widely used decision tree algorithm — supports pruning, continuous attributes, and missing values.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-C` | `<num>` | `0.25` | Confidence threshold for pruning. Lower = more pruning |
| `-M` | `<num>` | `2` | Minimum instances per leaf |
| `-U` | flag | off | Use unpruned tree |
| `-R` | flag | off | Use reduced error pruning (instead of C4.5 pruning) |
| `-N` | `<num>` | `3` | Number of folds for reduced error pruning |
| `-B` | flag | off | Binary splits only |
| `-S` | flag | off | Do not perform subtree raising |
| `-A` | flag | off | Laplace smoothing for predicted probabilities |
| `-Q` | `<seed>` | `1` | Seed for random data shuffling |

**Config example — default pruned tree:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.trees.J48",
  "options": ["-C", "0.25", "-M", "2"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

**Config example — unpruned tree:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.trees.J48",
  "options": ["-U"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

### REPTree

**Class:** `weka.classifiers.trees.REPTree`

Fast decision/regression tree using reduced-error pruning. More efficient than J48 and also handles regression tasks.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-M` | `<num>` | `2` | Minimum instances per leaf |
| `-V` | `<num>` | `1e-3` | Minimum variance proportion for a split (regression) |
| `-N` | `<num>` | `3` | Number of folds for reduced error pruning |
| `-S` | `<seed>` | `1` | Seed for random data shuffling |
| `-P` | flag | off | No pruning |
| `-L` | `<num>` | `-1` | Maximum tree depth (`-1` = no limit) |

**Config example:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.trees.REPTree",
  "options": ["-M", "2", "-N", "3"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

## Ensemble Classifiers

### RandomForest

**Class:** `weka.classifiers.trees.RandomForest`

Ensemble of decision trees trained on random feature subsets using bagging. Strong general-purpose classifier.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-I` | `<num>` | `100` | Number of trees |
| `-K` | `<num>` | `0` | Number of random features per split (`0` = `log2(features)+1`) |
| `-M` | `<num>` | `1` | Minimum instances per leaf |
| `-P` | `<num>` | `100` | Bag size as percentage of training data |
| `-O` | flag | off | Calculate out-of-bag error |
| `-attribute-importance` | flag | off | Compute and output attribute importance |
| `-num-slots` | `<num>` | `1` | Parallel execution slots (`0` = auto-detect cores) |
| `-S` | `<seed>` | `1` | Random seed |

**Config example — 200 trees:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.trees.RandomForest",
  "options": ["-I", "200", "-K", "0", "-S", "42"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

**Config example — with attribute importance and parallel:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.trees.RandomForest",
  "options": ["-I", "100", "-attribute-importance", "-num-slots", "0"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

### AdaBoostM1

**Class:** `weka.classifiers.meta.AdaBoostM1`

Boosting ensemble that iteratively focuses on misclassified instances. Wraps a base classifier (default: Decision Stump).

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-I` | `<num>` | `10` | Number of boosting iterations |
| `-W` | `<classname>` | `weka.classifiers.trees.DecisionStump` | Base classifier |
| `-P` | `<num>` | `100` | Percentage of weight mass to base training on |
| `-Q` | flag | off | Use resampling instead of reweighting |
| `-S` | `<seed>` | `1` | Random seed |

**Config example — 50 iterations with J48 base:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.meta.AdaBoostM1",
  "options": ["-I", "50", "-W", "weka.classifiers.trees.J48"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

### Bagging

**Class:** `weka.classifiers.meta.Bagging`

Bootstrap aggregating ensemble. Trains multiple instances of a base classifier on resampled datasets and aggregates predictions.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-I` | `<num>` | `10` | Number of iterations (bags) |
| `-W` | `<classname>` | `weka.classifiers.trees.REPTree` | Base classifier |
| `-P` | `<num>` | `100` | Bag size as percentage of training data |
| `-O` | flag | off | Calculate out-of-bag error |
| `-S` | `<seed>` | `1` | Random seed |
| `-num-slots` | `<num>` | `1` | Parallel execution slots (`0` = auto-detect cores) |

**Config example:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.meta.Bagging",
  "options": ["-I", "50", "-W", "weka.classifiers.trees.J48", "-P", "100"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

## Lazy / Instance-Based Classifiers

### IBk (k-Nearest Neighbours)

**Class:** `weka.classifiers.lazy.IBk`

Classifies based on the k nearest training instances. No explicit model is built — the entire training set is used at prediction time.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-K` | `<num>` | `1` | Number of nearest neighbours |
| `-I` | flag | off | Weight neighbours by inverse distance |
| `-F` | flag | off | Weight neighbours by `1 - distance` |
| `-X` | flag | off | Auto-select best k via hold-one-out on training data |
| `-W` | `<num>` | `0` | Maximum training window size (0 = unlimited) |
| `-A` | `<classname>` | `LinearNNSearch` | Nearest neighbour search algorithm |

**Config example — 3-NN with inverse distance weighting:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.lazy.IBk",
  "options": ["-K", "3", "-I"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

**Config example — auto-select k:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.lazy.IBk",
  "options": ["-K", "10", "-X"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

### KStar

**Class:** `weka.classifiers.lazy.KStar`

Instance-based classifier using an entropy-based distance function. Handles missing values and mixed attribute types well.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-B` | `<num>` | `20` | Manual blend percentage (controls smoothing) |
| `-E` | flag | off | Enable entropic auto-blend (symbolic class only) |
| `-M` | `<char>` | `a` | Missing value treatment: `a`=average, `d`=delete, `m`=maxdiff, `n`=normal |

**Config example:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.lazy.KStar",
  "options": ["-B", "20", "-M", "a"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

## Function-Based Classifiers

### Logistic Regression

**Class:** `weka.classifiers.functions.Logistic`

Multinomial logistic regression with ridge regularisation. Suitable for binary and multiclass problems.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-R` | `<num>` | `1e-8` | Ridge parameter (regularisation strength) |
| `-M` | `<num>` | `-1` | Maximum iterations (`-1` = until convergence) |
| `-C` | flag | off | Use conjugate gradient descent instead of BFGS |
| `-S` | flag | off | Do not standardize attributes before training |

**Config example:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.functions.Logistic",
  "options": ["-R", "1e-8", "-M", "500"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

---

### Linear Regression

**Class:** `weka.classifiers.functions.LinearRegression`

Fits a linear model to predict a **numeric** class attribute using ordinary least squares with optional attribute selection and ridge regularisation. Requires `app/mtj-1.0.4.jar`.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-S` | `0\|1\|2` | `0` | Attribute selection method: `0`=M5 method, `1`=none, `2`=greedy stepwise |
| `-R` | `<num>` | `1e-8` | Ridge parameter (regularisation — prevents overfitting with correlated attributes) |
| `-C` | flag | off | Do not eliminate collinear attributes |
| `-use-qr` | flag | off | Use QR decomposition instead of normal equations (more numerically stable) |
| `-additional-stats` | flag | off | Output additional statistics (std errors, t-stats) |
| `-minimal` | flag | off | Conserve memory — skips storing dataset headers (model cannot be printed) |

**Config example — default (M5 attribute selection):**
```json
{
  "task": "regression",
  "algorithm": "weka.classifiers.functions.LinearRegression",
  "options": [],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

**Config example — no attribute selection, higher ridge:**
```json
{
  "task": "regression",
  "algorithm": "weka.classifiers.functions.LinearRegression",
  "options": ["-S", "1", "-R", "1.0e-4"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

### SMO (Support Vector Machine)

**Class:** `weka.classifiers.functions.SMO`

Support Vector Machine using Sequential Minimal Optimization. Supports multiple kernels and handles multiclass via one-vs-one decomposition.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-C` | `<num>` | `1.0` | Complexity constant (regularisation — higher = less regularisation) |
| `-N` | `0\|1\|2` | `0` | Normalisation: `0`=normalize, `1`=standardize, `2`=neither |
| `-K` | `<classname>` | `PolyKernel` | Kernel function |
| `-L` | `<num>` | `1e-3` | Tolerance parameter |
| `-P` | `<num>` | `1e-12` | Epsilon for round-off error |
| `-M` | flag | off | Fit calibration models to SVM outputs (enables probability estimates) |

**Common kernels:**

| Kernel | Class |
|--------|-------|
| Polynomial | `weka.classifiers.functions.supportVector.PolyKernel` |
| RBF (Gaussian) | `weka.classifiers.functions.supportVector.RBFKernel` |
| Normalised Polynomial | `weka.classifiers.functions.supportVector.NormalizedPolyKernel` |

**Config example — linear SVM (`PolyKernel` with exponent 1):**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.functions.SMO",
  "options": ["-C", "1.0", "-K", "weka.classifiers.functions.supportVector.PolyKernel -E 1"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

**Config example — RBF kernel:**
```json
{
  "task": "classification",
  "algorithm": "weka.classifiers.functions.SMO",
  "options": ["-C", "1.0", "-K", "weka.classifiers.functions.supportVector.RBFKernel -G 0.01"],
  "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "/path/to/data.arff" }
}
```

---

## Evaluation Modes

### Cross-Validation
```json
"evaluation": {
  "mode": "cross-validation",
  "folds": 10,
  "dataset": "/path/to/data.arff"
}
```

### Train / Test Split
```json
"evaluation": {
  "mode": "train-test",
  "train_file": "/path/to/train.arff",
  "test_file": "/path/to/test.arff"
}
```

---

## Choosing a Classifier

| Situation | Recommended |
|-----------|------------|
| Baseline / sanity check | `ZeroR`, `OneR` |
| Interpretable rules | `J48`, `PART` |
| Best general accuracy | `RandomForest` |
| Small dataset | `NaiveBayes`, `IBk` |
| Boosting weak learners | `AdaBoostM1` |
| SVM for binary/linear | `SMO` with `PolyKernel -E 1` |
| SVM for non-linear | `SMO` with `RBFKernel` |
| Probabilistic output | `NaiveBayes`, `Logistic`, `SMO -M` |

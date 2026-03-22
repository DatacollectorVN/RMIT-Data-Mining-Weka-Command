# Weka Model Visualization Guide

After running `train_models.sh`, a `.model` file is saved alongside the report inside each model's named subfolder. This guide explains how to load it into the Weka GUI and use every visualization available.

## Output Structure

Each run produces:

```
.rmit_reports/
  20260322/
    20260322_110525/
      report_classification_OneR.txt   ← evaluation metrics
      config.json                      ← config used for this run
      model_classification_OneR.model  ← serialized trained model ← load this
```

---

## Step 1 — Launch Weka Explorer

From the project root:

```bash
java --add-opens java.base/java.lang=ALL-UNNAMED -jar app/weka.jar
```

Click **Explorer** in the Weka GUI Chooser window.

---

## Step 2 — Load Your Dataset

1. Go to the **Preprocess** tab
2. Click **Open file...**
3. Select your `.arff` dataset (e.g. `data/chronic_kidney_disease.arff`)
4. Confirm the attributes are loaded correctly

---

## Step 3 — Go to the Classify Tab

Click the **Classify** tab at the top.

---

## Step 4 — Load the Saved Model

1. In the **Result list** panel (bottom left), right-click anywhere
2. Select **Load model...**
3. Navigate to your `.rmit_reports/YYYYMMDD/YYYYMMDD_HHMMSS/` folder
4. Select the `.model` file (e.g. `model_classification_OneR.model`)

The model will appear as an entry in the Result list.

---

## Step 5 — Visualizations

Right-click the loaded model entry in the Result list to access all options:

### View in main window
Displays the full text output — model structure, evaluation summary, confusion matrix, per-class statistics.

---

### Visualize classifier errors

A scatter plot where:
- **X axis** and **Y axis** are configurable (any attribute or predicted/actual class)
- **Blue squares** = correctly classified instances
- **Red crosses** = misclassified instances

Useful for spotting which regions of the feature space the model struggles with.

> Requires the dataset to be loaded in Preprocess first.

---

### Visualize tree *(J48, REPTree only)*

An interactive rendering of the decision tree:

- Click any node to expand/collapse branches
- Hover over nodes to see split criteria and instance counts
- Right-click → **Save as PNG** to export the tree diagram
- Use the **Magnifier** slider to zoom in/out

> Only available for tree-based classifiers (J48, REPTree, etc.).

---

### Visualize margin curve

Plots the **margin distribution** — the difference between the probability assigned to the correct class and the highest probability assigned to any other class.

- A curve shifted right = the model is more confident in correct predictions
- Useful for comparing confidence across different models

---

### Visualize threshold curve

Plots **ROC (Receiver Operating Characteristic)** and **Precision-Recall** curves for each class:

1. Select the target class from the dropdown
2. Choose axes:
   - **ROC curve**: X = False Positive Rate, Y = True Positive Rate
   - **PR curve**: X = Recall, Y = Precision
3. The **AUC** (Area Under Curve) is shown in the title — higher is better

| AUC Range | Interpretation |
|-----------|---------------|
| 0.5 | No discrimination (random) |
| 0.7 – 0.8 | Acceptable |
| 0.8 – 0.9 | Excellent |
| > 0.9 | Outstanding |

---

### Visualize cost/benefit analysis

An interactive chart showing the trade-off between:
- **True Positive Rate** (sensitivity / recall)
- **False Positive Rate** (fall-out)

Drag the threshold slider to see how classification threshold affects the cost/benefit balance. Useful when misclassification costs are unequal (e.g. medical diagnosis).

---

## Evaluation Metrics in the Report

The `.txt` report file contains the same metrics visible in the Weka GUI:

| Metric | Description |
|--------|-------------|
| **Correctly Classified Instances** | Overall accuracy |
| **Kappa statistic** | Agreement beyond chance. `> 0.8` = strong agreement |
| **Mean absolute error (MAE)** | Average prediction error magnitude |
| **Root mean squared error (RMSE)** | Penalises large errors more than MAE |
| **Relative absolute error (RAE)** | MAE relative to a baseline ZeroR prediction |
| **Root relative squared error (RRSE)** | RMSE relative to baseline |

### Per-class statistics

| Metric | Description |
|--------|-------------|
| **TP Rate** | True Positive Rate (Recall / Sensitivity) = `TP / (TP + FN)` |
| **FP Rate** | False Positive Rate = `FP / (FP + TN)` |
| **Precision** | `TP / (TP + FP)` |
| **Recall** | Same as TP Rate |
| **F-Measure** | Harmonic mean of Precision and Recall |
| **MCC** | Matthews Correlation Coefficient — robust for imbalanced classes |
| **ROC Area** | AUC of the ROC curve for this class |
| **PRC Area** | AUC of the Precision-Recall curve for this class |

### Confusion matrix

```
              a         b    <-- classified as
            395         5  |  a = ckd
              0         0  |  b = notckd
```

Rows = actual class, columns = predicted class. Diagonal = correct predictions.

---

## Re-evaluate a Saved Model on New Data

To apply a saved model to a new test set from the command line:

```bash
java --add-opens java.base/java.lang=ALL-UNNAMED \
  -cp app/weka.jar \
  weka.classifiers.trees.J48 \
  -l .rmit_reports/20260322/20260322_110525/model_classification_J48.model \
  -T /path/to/new_test.arff \
  -p 0
```

| Flag | Description |
|------|-------------|
| `-l` | Load model from file |
| `-T` | Test set ARFF file |
| `-p 0` | Output predictions (0 = no extra attributes) |

Or in the Weka GUI: Classify tab → right-click result → **Re-evaluate model on current test set**.

---

## Supported Visualizations by Algorithm

| Algorithm | Tree | Errors | Threshold | Margin | Cost/Benefit |
|-----------|------|--------|-----------|--------|-------------|
| J48 | ✓ | ✓ | ✓ | ✓ | ✓ |
| REPTree | ✓ | ✓ | ✓ | ✓ | ✓ |
| RandomForest | — | ✓ | ✓ | ✓ | ✓ |
| NaiveBayes | — | ✓ | ✓ | ✓ | ✓ |
| IBk | — | ✓ | ✓ | ✓ | ✓ |
| SMO | — | ✓ | ✓ | — | ✓ |
| Logistic | — | ✓ | ✓ | ✓ | ✓ |
| OneR | — | ✓ | ✓ | — | ✓ |
| SimpleKMeans | — | — | — | — | — |
| EM | — | — | — | — | — |

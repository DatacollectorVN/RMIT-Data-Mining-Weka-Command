# Weka Clustering Reference

All clusterers listed here are compatible with `run_model.sh`. Set `"task"` to `"clustering"` and `"evaluation.mode"` to `"dataset"`.

```json
{
  "task": "clustering",
  "algorithm": "weka.clusterers.SimpleKMeans",
  "options": ["-N", "3", "-S", "42"],
  "evaluation": {
    "mode": "dataset",
    "dataset": "/absolute/path/to/data.arff"
  }
}
```

> **Note:** Clustering does not use a class label during training. If your ARFF has a class attribute, Weka ignores it during clustering but uses it for classes-to-clusters evaluation in the output.

> **Tip:** Run `bash app/utils/model_helper.sh <clusterer.class.Name>` to print the full option list for any clusterer.

---

## Quick Reference

| Name | Weka Class | Method |
|------|-----------|--------|
| SimpleKMeans | `weka.clusterers.SimpleKMeans` | Centroid-based |
| EM | `weka.clusterers.EM` | Probabilistic (Gaussian mixture) |
| HierarchicalClusterer | `weka.clusterers.HierarchicalClusterer` | Hierarchical |
| Canopy | `weka.clusterers.Canopy` | Canopy / approximate |
| FarthestFirst | `weka.clusterers.FarthestFirst` | Centroid-based |

---

## Centroid-Based Clusterers

### SimpleKMeans

**Class:** `weka.clusterers.SimpleKMeans`

Standard k-means clustering. Assigns each instance to the nearest centroid and iterates until convergence.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-N` | `<num>` | `2` | Number of clusters |
| `-init` | `0\|1\|2\|3` | `0` | Initialisation method: `0`=random, `1`=k-means++, `2`=canopy, `3`=farthest first |
| `-S` | `<seed>` | `10` | Random number seed |
| `-max-iterations` | `<num>` | `500` | Maximum iterations |
| `-A` | `<classname>` | `EuclideanDistance` | Distance function |
| `-C` | flag | off | Use canopies to reduce distance calculations |
| `-num-slots` | `<num>` | `1` | Parallel execution slots (`0` = auto) |

**Config example — 3 clusters, k-means++ init:**
```json
{
  "task": "clustering",
  "algorithm": "weka.clusterers.SimpleKMeans",
  "options": ["-N", "3", "-init", "1", "-S", "42"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

**Config example — Manhattan distance:**
```json
{
  "task": "clustering",
  "algorithm": "weka.clusterers.SimpleKMeans",
  "options": ["-N", "4", "-A", "weka.core.ManhattanDistance", "-S", "1"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

---

### FarthestFirst

**Class:** `weka.clusterers.FarthestFirst`

A fast approximation to k-means. Initialises cluster centres by always picking the point farthest from all existing centres. Much faster than k-means for large datasets but less accurate.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-N` | `<num>` | `2` | Number of clusters |
| `-S` | `<seed>` | `1` | Random seed |

**Config example:**
```json
{
  "task": "clustering",
  "algorithm": "weka.clusterers.FarthestFirst",
  "options": ["-N", "3", "-S", "1"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

---

## Probabilistic Clusterers

### EM (Expectation Maximisation)

**Class:** `weka.clusterers.EM`

Fits a Gaussian mixture model using the EM algorithm. Assigns soft (probabilistic) cluster memberships. Can auto-select the number of clusters via cross-validation.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-N` | `<num>` | `-1` | Number of clusters. `-1` = auto-select via cross-validation |
| `-X` | `<num>` | `10` | Number of CV folds to find best cluster count (when `-N -1`) |
| `-K` | `<num>` | `10` | Number of k-means runs for initialisation |
| `-max` | `<num>` | `-1` | Maximum clusters to consider during CV (`-1` = no limit) |
| `-ll-cv` | `<num>` | `1e-6` | Minimum log-likelihood improvement required to increase cluster count |
| `-M` | `<num>` | `1e-6` | Minimum allowable standard deviation for normal density |
| `-S` | `<seed>` | `100` | Random seed |
| `-I` | `<num>` | `100` | Maximum EM iterations |

**Config example — fixed 3 clusters:**
```json
{
  "task": "clustering",
  "algorithm": "weka.clusterers.EM",
  "options": ["-N", "3", "-S", "42"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

**Config example — auto-select cluster count:**
```json
{
  "task": "clustering",
  "algorithm": "weka.clusterers.EM",
  "options": ["-N", "-1", "-X", "10", "-S", "1"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

---

## Hierarchical Clusterers

### HierarchicalClusterer

**Class:** `weka.clusterers.HierarchicalClusterer`

Agglomerative hierarchical clustering. Builds a dendrogram by merging the closest pair of clusters at each step using a chosen linkage criterion.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-N` | `<num>` | `2` | Number of clusters to extract from the dendrogram |
| `-L` | see below | `SINGLE` | Linkage type |
| `-A` | `<classname>` | `EuclideanDistance` | Distance function |
| `-P` | flag | off | Print dendrogram in Newick format |
| `-B` | flag | off | Interpret distance as branch length (not node height) |

**Linkage types (`-L`):**

| Value | Method | Description |
|-------|--------|-------------|
| `SINGLE` | Single linkage | Min distance between clusters |
| `COMPLETE` | Complete linkage | Max distance between clusters |
| `AVERAGE` | Average linkage (UPGMA) | Average distance between all pairs |
| `MEAN` | Mean linkage | Distance between cluster centroids |
| `CENTROID` | Centroid linkage | Euclidean distance between centroids |
| `WARD` | Ward's method | Minimise total within-cluster variance |
| `ADJCOMPLETE` | Adjusted complete | Complete linkage adjusted for size |
| `NEIGHBOR_JOINING` | Neighbour joining | Phylogenetic-style joining |

**Config example — Ward linkage, 4 clusters:**
```json
{
  "task": "clustering",
  "algorithm": "weka.clusterers.HierarchicalClusterer",
  "options": ["-N", "4", "-L", "WARD"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

**Config example — complete linkage with Manhattan distance:**
```json
{
  "task": "clustering",
  "algorithm": "weka.clusterers.HierarchicalClusterer",
  "options": ["-N", "3", "-L", "COMPLETE", "-A", "weka.core.ManhattanDistance"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

---

## Canopy Clustering

### Canopy

**Class:** `weka.clusterers.Canopy`

Fast approximate clustering using two distance thresholds (T1, T2) to assign instances to overlapping canopies. Often used to initialise SimpleKMeans.

| Option | Value | Default | Description |
|--------|-------|---------|-------------|
| `-N` | `<num>` | `2` | Number of clusters |
| `-t2` | `<num>` | `-1.25` | T2 distance (inner threshold — instances within T2 are permanently assigned) |
| `-t1` | `<num>` | `-1.5` | T1 distance (outer threshold — instances within T1 are loosely assigned) |
| `-max-candidates` | `<num>` | `100` | Max candidate canopies to retain in memory |
| `-periodic-pruning` | `<num>` | `10000` | How often to prune low-density canopies (every N instances) |
| `-min-density` | `<num>` | `2` | Minimum density to retain a canopy |
| `-S` | `<seed>` | `1` | Random seed |

**Config example:**
```json
{
  "task": "clustering",
  "algorithm": "weka.clusterers.Canopy",
  "options": ["-N", "3", "-S", "1"],
  "evaluation": { "mode": "dataset", "dataset": "/path/to/data.arff" }
}
```

---

## Distance Functions

The `-A` option on `SimpleKMeans` and `HierarchicalClusterer` accepts any Weka distance function class:

| Distance | Class |
|----------|-------|
| Euclidean (default) | `weka.core.EuclideanDistance` |
| Manhattan | `weka.core.ManhattanDistance` |
| Chebyshev | `weka.core.ChebyshevDistance` |
| Minkowski | `weka.core.MinkowskiDistance` |

---

## Choosing a Clusterer

| Situation | Recommended |
|-----------|------------|
| Known number of clusters | `SimpleKMeans` with `-init 1` (k-means++) |
| Unknown number of clusters | `EM` with `-N -1` |
| Interpretable hierarchy / dendrogram | `HierarchicalClusterer` with `WARD` |
| Very large dataset (speed priority) | `FarthestFirst` or `Canopy` |
| Soft/probabilistic cluster membership | `EM` |

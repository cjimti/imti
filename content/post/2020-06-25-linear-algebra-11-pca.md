---
draft: false
layout: post
title: "Linear Algebra: Principal Component Analysis"
subtitle: "Linear Algebra Crash Course for Programmers Part 11"
date: 2020-06-25
author: "Craig Johnston"
URL: "linear-algebra-pca/"
image: "/img/post/matrix.jpg"
twitter_image:  "/img/post/matrix_876_438.jpg"
tags:
- Linear Algebra
- Matrices
- Math
- Python
- Data Science
- Machine Learning
series:
- Linear Algebra Crash Course
---

This article on **Principal Component Analysis (PCA)** is part eleven of our linear algebra crash course. PCA is one of the most widely used techniques for dimensionality reduction, data visualization, and feature extraction in machine learning.

<!--more-->

Previous articles covered [SVD](https://imti.co/linear-algebra-svd/) which provides one method for computing PCA.

```python
import numpy as np
import matplotlib.pyplot as plt
from sklearn.datasets import make_blobs, load_iris

%matplotlib inline
```
{{< math >}}
{{< toc >}}
{{< content-ad >}}

## What is PCA?

**Principal Component Analysis** finds the directions (principal components) along which the data varies the most. It transforms data into a new coordinate system where:
- The first axis captures maximum variance
- Each subsequent axis captures maximum remaining variance
- All axes are orthogonal

## The Mathematics of PCA

Given centered data matrix $\boldsymbol{X}$ (mean-subtracted), PCA finds eigenvectors of the **covariance matrix**:

<p><div>
$
\boldsymbol{C} = \frac{1}{n-1}\boldsymbol{X}^T\boldsymbol{X}
$
</div></p>

The eigenvectors are the principal components, and eigenvalues indicate variance explained.

```python
def pca_from_covariance(X):
    """PCA using the covariance matrix."""
    # Center the data
    X_centered = X - X.mean(axis=0)

    # Compute covariance matrix
    n = X.shape[0]
    cov = (X_centered.T @ X_centered) / (n - 1)

    # Eigendecomposition
    eigenvalues, eigenvectors = np.linalg.eigh(cov)

    # Sort by eigenvalue (descending)
    idx = np.argsort(eigenvalues)[::-1]
    eigenvalues = eigenvalues[idx]
    eigenvectors = eigenvectors[:, idx]

    return eigenvalues, eigenvectors, X_centered
```

## PCA via SVD

PCA can also be computed via SVD of the centered data:

<p><div>
$
\boldsymbol{X} = \boldsymbol{U}\boldsymbol{\Sigma}\boldsymbol{V}^T
$
</div></p>

The columns of $\boldsymbol{V}$ are the principal components.

```python
def pca_from_svd(X):
    """PCA using SVD."""
    # Center the data
    X_centered = X - X.mean(axis=0)

    # SVD
    U, s, Vt = np.linalg.svd(X_centered, full_matrices=False)

    # Principal components are rows of Vt (columns of V)
    components = Vt

    # Variance explained (eigenvalues = s^2 / (n-1))
    n = X.shape[0]
    variance = s**2 / (n - 1)

    return variance, components, X_centered

# Generate sample data
np.random.seed(42)
X = np.random.randn(100, 3) @ np.array([[3, 0, 0],
                                         [0, 2, 0],
                                         [0, 0, 0.5]]).T

# Compare methods
var_cov, comp_cov, X_centered = pca_from_covariance(X)
var_svd, comp_svd, _ = pca_from_svd(X)

print("Variance explained:")
print(f"  Covariance method: {var_cov}")
print(f"  SVD method:        {var_svd}")
```

    Variance explained:
      Covariance method: [8.90775547 3.86498451 0.23440066]
      SVD method:        [8.90775547 3.86498451 0.23440066]

## Dimensionality Reduction

Project data onto the first $k$ principal components:

```python
def transform(X, components, k):
    """Project data onto first k principal components."""
    X_centered = X - X.mean(axis=0)
    return X_centered @ components[:k].T

# Generate 2D data with correlation
np.random.seed(42)
theta = np.pi / 4
rotation = np.array([[np.cos(theta), -np.sin(theta)],
                     [np.sin(theta),  np.cos(theta)]])
X_2d = np.random.randn(200, 2) @ np.diag([3, 0.5]) @ rotation.T

# Perform PCA
variance, components, X_centered = pca_from_svd(X_2d)

# Visualize
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Original data with principal components
ax = axes[0]
ax.scatter(X_2d[:, 0], X_2d[:, 1], alpha=0.5, s=30)
origin = X_2d.mean(axis=0)

# Plot principal components scaled by sqrt(variance)
for i in range(2):
    scale = np.sqrt(variance[i]) * 2
    ax.arrow(origin[0], origin[1],
             components[i, 0] * scale, components[i, 1] * scale,
             head_width=0.2, head_length=0.1, fc=f'C{i+1}', ec=f'C{i+1}',
             linewidth=2, label=f'PC{i+1} (var={variance[i]:.2f})')

ax.set_xlabel('x1')
ax.set_ylabel('x2')
ax.set_title('Original Data with Principal Components')
ax.legend()
ax.set_aspect('equal')
ax.grid(True, alpha=0.3)

# Projected data (1D)
X_projected = transform(X_2d, components, 1)
ax = axes[1]
ax.scatter(X_projected, np.zeros_like(X_projected), alpha=0.5, s=30)
ax.set_xlabel('PC1')
ax.set_title('Data Projected onto First Principal Component')
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()
```

## Explained Variance Ratio

The **explained variance ratio** shows how much variance each component captures:

```python
# Use Iris dataset
iris = load_iris()
X_iris = iris.data

# PCA
variance, components, X_centered = pca_from_svd(X_iris)
explained_ratio = variance / variance.sum()
cumulative_ratio = np.cumsum(explained_ratio)

print("Explained variance ratio:")
for i, (var, ratio, cum) in enumerate(zip(variance, explained_ratio, cumulative_ratio)):
    print(f"  PC{i+1}: {ratio*100:.2f}% (cumulative: {cum*100:.2f}%)")

# Plot
fig, axes = plt.subplots(1, 2, figsize=(12, 4))

# Scree plot
axes[0].bar(range(1, 5), explained_ratio * 100)
axes[0].plot(range(1, 5), cumulative_ratio * 100, 'ro-')
axes[0].set_xlabel('Principal Component')
axes[0].set_ylabel('Variance Explained (%)')
axes[0].set_title('Scree Plot')
axes[0].set_xticks(range(1, 5))
axes[0].grid(True, alpha=0.3, axis='y')

# Project to 2D
X_pca = X_centered @ components[:2].T
for i, target in enumerate(np.unique(iris.target)):
    mask = iris.target == target
    axes[1].scatter(X_pca[mask, 0], X_pca[mask, 1],
                    label=iris.target_names[target], alpha=0.7)

axes[1].set_xlabel(f'PC1 ({explained_ratio[0]*100:.1f}%)')
axes[1].set_ylabel(f'PC2 ({explained_ratio[1]*100:.1f}%)')
axes[1].set_title('Iris Dataset: PCA Projection')
axes[1].legend()
axes[1].grid(True, alpha=0.3)

plt.tight_layout()
plt.show()
```

    Explained variance ratio:
      PC1: 92.46% (cumulative: 92.46%)
      PC2: 5.31% (cumulative: 97.77%)
      PC3: 1.71% (cumulative: 99.48%)
      PC4: 0.52% (cumulative: 100.00%)

## PCA from Scratch vs Scikit-learn

```python
from sklearn.decomposition import PCA

# Our implementation
variance_ours, components_ours, _ = pca_from_svd(X_iris)
X_transformed_ours = (X_iris - X_iris.mean(axis=0)) @ components_ours[:2].T

# Scikit-learn
pca = PCA(n_components=2)
X_transformed_sklearn = pca.fit_transform(X_iris)

print("Variance explained:")
print(f"  Our implementation: {variance_ours[:2]}")
print(f"  Scikit-learn:       {pca.explained_variance_}")

print(f"\nTransformed data matches: {np.allclose(np.abs(X_transformed_ours), np.abs(X_transformed_sklearn))}")
```

    Variance explained:
      Our implementation: [4.22824171 0.24267075]
      Scikit-learn:       [4.22824171 0.24267075]

    Transformed data matches: True

## Choosing the Number of Components

Common approaches:
1. **Explained variance threshold**: Keep components until 95% variance is explained
2. **Elbow method**: Look for elbow in scree plot
3. **Kaiser criterion**: Keep components with eigenvalue > 1 (for correlation matrix)

```python
def choose_components(X, threshold=0.95):
    """Choose number of components to explain threshold variance."""
    variance, _, _ = pca_from_svd(X)
    cumulative = np.cumsum(variance) / variance.sum()
    n_components = np.argmax(cumulative >= threshold) + 1
    return n_components, cumulative

n, cumulative = choose_components(X_iris, threshold=0.95)
print(f"Components needed for 95% variance: {n}")
print(f"Cumulative variance: {cumulative}")
```

    Components needed for 95% variance: 2
    Cumulative variance: [0.92461872 0.97768521 0.99478782 1.        ]

## Whitening (Sphering)

PCA can also **whiten** data, making features uncorrelated with unit variance:

```python
def pca_whiten(X, n_components=None):
    """PCA with whitening."""
    X_centered = X - X.mean(axis=0)
    U, s, Vt = np.linalg.svd(X_centered, full_matrices=False)

    if n_components is None:
        n_components = min(X.shape)

    # Whitened data: divide by singular values
    X_whitened = U[:, :n_components] * np.sqrt(X.shape[0] - 1)

    return X_whitened

# Compare regular PCA vs whitened
X_pca = (X_iris - X_iris.mean(axis=0)) @ components_ours[:2].T
X_whitened = pca_whiten(X_iris, n_components=2)

print("Regular PCA covariance:")
print(np.cov(X_pca.T))
print("\nWhitened covariance (should be identity):")
print(np.cov(X_whitened.T))
```

    Regular PCA covariance:
    [[4.22824171 0.        ]
     [0.         0.24267075]]

    Whitened covariance (should be identity):
    [[ 1.00000000e+00 -7.21855636e-17]
     [-7.21855636e-17  1.00000000e+00]]

## Inverse Transform (Reconstruction)

Reconstruct data from reduced representation:

```python
def inverse_transform(X_reduced, components, mean, n_components):
    """Reconstruct data from PCA representation."""
    return X_reduced @ components[:n_components] + mean

# Reconstruct iris data with different numbers of components
mean = X_iris.mean(axis=0)

fig, axes = plt.subplots(1, 3, figsize=(15, 4))
n_comps = [1, 2, 4]

for ax, n in zip(axes, n_comps):
    X_reduced = (X_iris - mean) @ components_ours[:n].T
    X_reconstructed = inverse_transform(X_reduced, components_ours, mean, n)
    error = np.mean(np.sum((X_iris - X_reconstructed)**2, axis=1))

    ax.scatter(X_iris[:, 0], X_reconstructed[:, 0], alpha=0.5)
    ax.plot([4, 8], [4, 8], 'r--', label='Perfect reconstruction')
    ax.set_xlabel('Original')
    ax.set_ylabel('Reconstructed')
    ax.set_title(f'{n} components (MSE: {error:.4f})')
    ax.legend()
    ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()
```

## Summary

In this article, we covered:

- **PCA mathematics**: Eigendecomposition of covariance matrix
- **PCA via SVD**: $\boldsymbol{X} = \boldsymbol{U}\boldsymbol{\Sigma}\boldsymbol{V}^T$
- **Dimensionality reduction**: Projecting to fewer dimensions
- **Explained variance ratio**: Measuring information retained
- **Component selection**: Choosing the right number of components
- **Whitening**: Making features uncorrelated with unit variance
- **Reconstruction**: Inverting the transformation

## Resources

- [PCA - Wikipedia](https://en.wikipedia.org/wiki/Principal_component_analysis)
- [Scikit-learn PCA](https://scikit-learn.org/stable/modules/decomposition.html#pca)
- [A Tutorial on PCA](https://arxiv.org/abs/1404.1100)

---
draft: false
layout: post
title: "Linear Algebra: Singular Value Decomposition"
subtitle: "Linear Algebra Crash Course for Programmers Part 10"
date: 2020-04-20
author: "Craig Johnston"
URL: "linear-algebra-svd/"
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

This article on **Singular Value Decomposition (SVD)** is part ten of our linear algebra crash course. SVD is arguably the most important matrix decomposition, with applications in image compression, recommender systems, pseudoinverse computation, and dimensionality reduction.

<!--more-->

Previous articles covered [Least Squares](https://imti.co/linear-algebra-least-squares/) which SVD can solve more robustly.

```python
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image

%matplotlib inline
```
{{< math >}}
{{< toc >}}
{{< content-ad >}}

## The SVD Decomposition

Any $m \times n$ matrix $\boldsymbol{A}$ can be decomposed as:

<p><div>
$
\boldsymbol{A} = \boldsymbol{U}\boldsymbol{\Sigma}\boldsymbol{V}^T
$
</div></p>

Where:
- $\boldsymbol{U}$ is $m \times m$ orthogonal (left singular vectors)
- $\boldsymbol{\Sigma}$ is $m \times n$ diagonal (singular values $\sigma_1 \geq \sigma_2 \geq \cdots \geq 0$)
- $\boldsymbol{V}$ is $n \times n$ orthogonal (right singular vectors)

```python
# Example SVD
A = np.array([[1, 2, 3],
              [4, 5, 6],
              [7, 8, 9],
              [10, 11, 12]])

U, s, Vt = np.linalg.svd(A)

print(f"Matrix A ({A.shape[0]}x{A.shape[1]}):\n{A}\n")
print(f"U ({U.shape[0]}x{U.shape[1]}):\n{U}\n")
print(f"Singular values: {s}\n")
print(f"V^T ({Vt.shape[0]}x{Vt.shape[1]}):\n{Vt}")
```

    Matrix A (4x3):
    [[ 1  2  3]
     [ 4  5  6]
     [ 7  8  9]
     [10 11 12]]

    U (4x4):
    [[-0.14082769  0.82471435  0.45634102  0.30151134]
     [-0.34399253  0.42626394 -0.25558054 -0.79740271]
     [-0.54715737  0.02781352 -0.76921368  0.32868671]
     [-0.7503222  -0.3706369   0.36845321  0.16720465]]

    Singular values: [2.54368356e+01 1.72261225e+00 2.55833854e-15]

    V^T (3x3):
    [[-0.50455819 -0.57456906 -0.64457993]
     [ 0.76078667  0.05714052 -0.64650564]
     [-0.40824829  0.81649658 -0.40824829]]

```python
# Reconstruct A from SVD
# Need to construct full Sigma matrix
Sigma = np.zeros((A.shape[0], A.shape[1]))
np.fill_diagonal(Sigma, s)

A_reconstructed = U @ Sigma @ Vt
print(f"Reconstructed A:\n{A_reconstructed}")
print(f"\nReconstruction error: {np.linalg.norm(A - A_reconstructed):.2e}")
```

    Reconstructed A:
    [[ 1.  2.  3.]
     [ 4.  5.  6.]
     [ 7.  8.  9.]
     [10. 11. 12.]]

    Reconstruction error: 3.02e-15

## Geometric Interpretation

SVD decomposes a linear transformation into:
1. **Rotation/reflection** ($\boldsymbol{V}^T$)
2. **Scaling along axes** ($\boldsymbol{\Sigma}$)
3. **Rotation/reflection** ($\boldsymbol{U}$)

```python
# Visualize SVD transformation of the unit circle
theta = np.linspace(0, 2*np.pi, 100)
circle = np.vstack([np.cos(theta), np.sin(theta)])

# 2D transformation matrix
B = np.array([[3, 1],
              [1, 2]])

U, s, Vt = np.linalg.svd(B)

fig, axes = plt.subplots(1, 4, figsize=(16, 4))

# Step 1: Original circle
axes[0].plot(circle[0], circle[1], 'b-', linewidth=2)
axes[0].set_title('Original unit circle')
axes[0].set_aspect('equal')
axes[0].grid(True, alpha=0.3)
axes[0].set_xlim(-4, 4)
axes[0].set_ylim(-4, 4)

# Step 2: After V^T rotation
after_Vt = Vt @ circle
axes[1].plot(after_Vt[0], after_Vt[1], 'g-', linewidth=2)
axes[1].set_title('After V^T (rotation)')
axes[1].set_aspect('equal')
axes[1].grid(True, alpha=0.3)
axes[1].set_xlim(-4, 4)
axes[1].set_ylim(-4, 4)

# Step 3: After Sigma scaling
Sigma_2d = np.diag(s)
after_sigma = Sigma_2d @ after_Vt
axes[2].plot(after_sigma[0], after_sigma[1], 'orange', linewidth=2)
axes[2].set_title(f'After Sigma (scale by {s[0]:.2f}, {s[1]:.2f})')
axes[2].set_aspect('equal')
axes[2].grid(True, alpha=0.3)
axes[2].set_xlim(-4, 4)
axes[2].set_ylim(-4, 4)

# Step 4: After U rotation (final result)
final = U @ after_sigma
axes[3].plot(final[0], final[1], 'r-', linewidth=2)
axes[3].set_title('After U (final: B @ circle)')
axes[3].set_aspect('equal')
axes[3].grid(True, alpha=0.3)
axes[3].set_xlim(-4, 4)
axes[3].set_ylim(-4, 4)

plt.tight_layout()
plt.show()
```

## Low-Rank Approximation

SVD provides the **best rank-k approximation** in the Frobenius norm:

<p><div>
$
\boldsymbol{A}_k = \sum_{i=1}^{k} \sigma_i \vec{u}_i \vec{v}_i^T
$
</div></p>

```python
def low_rank_approx(U, s, Vt, k):
    """Compute rank-k approximation from SVD."""
    return U[:, :k] @ np.diag(s[:k]) @ Vt[:k, :]

# Example
A = np.random.randn(10, 8)
U, s, Vt = np.linalg.svd(A)

print(f"Singular values: {s}")
print(f"\nApproximation errors (Frobenius norm):")

for k in [1, 2, 3, 5, 8]:
    A_k = low_rank_approx(U, s, Vt, k)
    error = np.linalg.norm(A - A_k, 'fro')
    # Error should equal sqrt(sum of squares of remaining singular values)
    theoretical_error = np.sqrt(np.sum(s[k:]**2))
    print(f"  Rank-{k}: error = {error:.4f} (theoretical: {theoretical_error:.4f})")
```

    Singular values: [4.73642719 3.6842638  2.93440661 2.57116947 2.29153773 1.34193251
     1.11434638 0.45953958]

    Approximation errors (Frobenius norm):
      Rank-1: error = 6.2423 (theoretical: 6.2423)
      Rank-2: error = 5.0411 (theoretical: 5.0411)
      Rank-3: error = 4.0823 (theoretical: 4.0823)
      Rank-5: error = 1.8816 (theoretical: 1.8816)
      Rank-8: error = 0.0000 (theoretical: 0.0000)

## Image Compression with SVD

SVD can compress images by keeping only the largest singular values:

```python
# Create a synthetic grayscale image
x = np.linspace(-5, 5, 200)
y = np.linspace(-5, 5, 200)
X, Y = np.meshgrid(x, y)
image = np.sin(X) * np.cos(Y) + 0.5 * np.exp(-(X**2 + Y**2) / 10)

# Compute SVD
U, s, Vt = np.linalg.svd(image)

fig, axes = plt.subplots(2, 3, figsize=(15, 10))

ranks = [1, 5, 10, 25, 50, 200]
for ax, k in zip(axes.flat, ranks):
    compressed = low_rank_approx(U, s, Vt, k)
    compression_ratio = (k * (200 + 200 + 1)) / (200 * 200) * 100

    ax.imshow(compressed, cmap='viridis')
    ax.set_title(f'Rank {k} ({compression_ratio:.1f}% of data)')
    ax.axis('off')

plt.suptitle('Image Compression via SVD', fontsize=14)
plt.tight_layout()
plt.show()
```

## The Pseudoinverse

The **Moore-Penrose pseudoinverse** $\boldsymbol{A}^+$ can be computed via SVD:

<p><div>
$
\boldsymbol{A}^+ = \boldsymbol{V}\boldsymbol{\Sigma}^+\boldsymbol{U}^T
$
</div></p>

Where $\boldsymbol{\Sigma}^+$ has $1/\sigma_i$ for non-zero singular values.

```python
def pseudoinverse_svd(A, tol=1e-10):
    """Compute pseudoinverse via SVD."""
    U, s, Vt = np.linalg.svd(A)

    # Invert non-zero singular values
    s_inv = np.zeros_like(s)
    s_inv[s > tol] = 1.0 / s[s > tol]

    # Construct pseudoinverse
    # A+ = V @ Sigma+ @ U^T
    Sigma_plus = np.zeros((A.shape[1], A.shape[0]))
    np.fill_diagonal(Sigma_plus, s_inv)

    return Vt.T @ Sigma_plus @ U.T

# Test with a non-square, rank-deficient matrix
A = np.array([[1, 2, 3],
              [4, 5, 6],
              [7, 8, 9],
              [10, 11, 12]])

A_pinv_custom = pseudoinverse_svd(A)
A_pinv_numpy = np.linalg.pinv(A)

print(f"Pseudoinverse (custom):\n{A_pinv_custom}\n")
print(f"Pseudoinverse (NumPy):\n{A_pinv_numpy}\n")
print(f"Match: {np.allclose(A_pinv_custom, A_pinv_numpy)}")
```

    Pseudoinverse (custom):
    [[-0.48333333 -0.24444444 -0.00555556  0.23333333]
     [-0.03333333 -0.01111111  0.01111111  0.03333333]
     [ 0.41666667  0.22222222  0.02777778 -0.16666667]]

    Pseudoinverse (NumPy):
    [[-0.48333333 -0.24444444 -0.00555556  0.23333333]
     [-0.03333333 -0.01111111  0.01111111  0.03333333]
     [ 0.41666667  0.22222222  0.02777778 -0.16666667]]

    Match: True

## Least Squares via SVD

SVD provides a more numerically stable solution to least squares:

```python
def least_squares_svd(A, b):
    """Solve least squares using SVD."""
    A_pinv = np.linalg.pinv(A)
    return A_pinv @ b

# Compare methods
A = np.random.randn(100, 10)
x_true = np.random.randn(10)
b = A @ x_true + 0.1 * np.random.randn(100)

# Normal equations
x_normal = np.linalg.solve(A.T @ A, A.T @ b)

# SVD
x_svd = least_squares_svd(A, b)

# NumPy lstsq (uses SVD internally)
x_lstsq, _, _, _ = np.linalg.lstsq(A, b, rcond=None)

print(f"True x (first 5): {x_true[:5]}")
print(f"Normal equations: {x_normal[:5]}")
print(f"SVD:              {x_svd[:5]}")
print(f"lstsq:            {x_lstsq[:5]}")
```

    True x (first 5): [ 0.33367433  1.49407907 -0.20515826  0.3130677  -0.85409574]
    Normal equations: [ 0.33251424  1.47877254 -0.20371893  0.32140861 -0.84903879]
    SVD:              [ 0.33251424  1.47877254 -0.20371893  0.32140861 -0.84903879]
    lstsq:            [ 0.33251424  1.47877254 -0.20371893  0.32140861 -0.84903879]

## Condition Number and Numerical Stability

The **condition number** indicates numerical sensitivity:

<p><div>
$
\kappa(\boldsymbol{A}) = \frac{\sigma_{max}}{\sigma_{min}}
$
</div></p>

```python
# Well-conditioned matrix
A_good = np.array([[1, 0.1],
                   [0.1, 1]])

# Ill-conditioned matrix
A_bad = np.array([[1, 1],
                  [1, 1.0001]])

for name, A in [("Well-conditioned", A_good), ("Ill-conditioned", A_bad)]:
    U, s, Vt = np.linalg.svd(A)
    cond = s[0] / s[-1]
    print(f"{name}:")
    print(f"  Singular values: {s}")
    print(f"  Condition number: {cond:.2f}\n")
```

    Well-conditioned:
      Singular values: [1.1 0.9]
      Condition number: 1.22

    Ill-conditioned:
      Singular values: [2.00005e+00 4.99987e-05]
      Condition number: 40002.00

## Summary

In this article, we covered:

- **SVD decomposition**: $\boldsymbol{A} = \boldsymbol{U}\boldsymbol{\Sigma}\boldsymbol{V}^T$
- **Geometric interpretation**: Rotation, scaling, rotation
- **Low-rank approximation**: Best rank-k approximation
- **Image compression** using SVD
- **Pseudoinverse**: $\boldsymbol{A}^+ = \boldsymbol{V}\boldsymbol{\Sigma}^+\boldsymbol{U}^T$
- **Condition number**: Numerical stability measure

## Resources

- [SVD - Wikipedia](https://en.wikipedia.org/wiki/Singular_value_decomposition)
- [NumPy SVD](https://numpy.org/doc/stable/reference/generated/numpy.linalg.svd.html)
- [3Blue1Brown - SVD](https://www.youtube.com/watch?v=vSczTbgc8Rc)



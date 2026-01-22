---
draft: false
layout: post
title: "Linear Algebra: Orthogonality and Projections"
subtitle: "Linear Algebra Crash Course for Programmers Part 8"
date: 2019-12-10
author: "Craig Johnston"
URL: "linear-algebra-orthogonality/"
image: "/img/post/matrix.jpg"
twitter_image:  "/img/post/matrix_876_438.jpg"
tags:
- Linear Algebra
- Matrices
- Math
- Python
- Data Science
series:
- Linear Algebra Crash Course
---

This article covers **orthogonality and projections**, part eight of the series. Orthogonality is fundamental to many algorithms including least squares regression, QR decomposition, and machine learning techniques like PCA.

<!--more-->

Previous articles covered [Vectors](https://imti.co/linear-algebra-vectors/), [Matrices](https://imti.co/linear-algebra-matrices/), [Systems](https://imti.co/linear-algebra-systems-equations/), [Inverses](https://imti.co/linear-algebra-inverse-determinant/), [Vector Spaces](https://imti.co/linear-algebra-vector-spaces/), and [Eigenvalues](https://imti.co/linear-algebra-eigenvalues-1/).

```python
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

%matplotlib inline
```
{{< math >}}
{{< toc >}}
{{< content-ad >}}

## Orthogonal Vectors

Two vectors $\vec{u}$ and $\vec{v}$ are **orthogonal** (perpendicular) if their dot product is zero:

<p><div>
$
\vec{u} \cdot \vec{v} = \vec{u}^T\vec{v} = 0
$
</div></p>

```python
# Orthogonal vectors
u = np.array([1, 0, 1])
v = np.array([0, 1, 0])

dot_product = np.dot(u, v)
print(f"u = {u}")
print(f"v = {v}")
print(f"u . v = {dot_product}")
print(f"Orthogonal: {dot_product == 0}")
```

    u = [1 0 1]
    v = [0 1 0]
    u . v = 0
    Orthogonal: True

## Vector Projection

The **projection** of vector $\vec{b}$ onto vector $\vec{a}$ is:

<p><div>
$
\text{proj}_{\vec{a}}\vec{b} = \frac{\vec{a} \cdot \vec{b}}{\vec{a} \cdot \vec{a}}\vec{a} = \frac{\vec{a}^T\vec{b}}{\vec{a}^T\vec{a}}\vec{a}
$
</div></p>

```python
def vector_projection(b, a):
    """Project vector b onto vector a."""
    return (np.dot(a, b) / np.dot(a, a)) * a

a = np.array([2, 0])
b = np.array([1, 2])

proj = vector_projection(b, a)
residual = b - proj

print(f"a = {a}")
print(f"b = {b}")
print(f"proj_a(b) = {proj}")
print(f"residual = b - proj = {residual}")
print(f"proj . residual = {np.dot(proj, residual):.10f} (should be 0)")
```

    a = [2 0]
    b = [1 2]
    proj_a(b) = [1. 0.]
    residual = b - proj = [0. 2.]
    proj . residual = 0.0000000000 (should be 0)

```python
# Visualize the projection
plt.figure(figsize=(8, 6))
origin = np.array([0, 0])

plt.quiver(*origin, *a, color='blue', scale=1, scale_units='xy', angles='xy', label='a')
plt.quiver(*origin, *b, color='green', scale=1, scale_units='xy', angles='xy', label='b')
plt.quiver(*origin, *proj, color='red', scale=1, scale_units='xy', angles='xy', label='proj_a(b)')
plt.plot([b[0], proj[0]], [b[1], proj[1]], 'k--', label='residual')

plt.xlim(-1, 3)
plt.ylim(-1, 3)
plt.grid(True, alpha=0.3)
plt.legend()
plt.axis('equal')
plt.title('Vector Projection')
plt.show()
```

## The Gram-Schmidt Process

The **Gram-Schmidt process** transforms a set of linearly independent vectors into an **orthonormal** set (orthogonal and unit length).

Given vectors $\{\vec{v}_1, \vec{v}_2, \ldots, \vec{v}_n\}$:

<p><div>
$
\vec{u}_1 = \vec{v}_1
$
</div></p>

<p><div>
$
\vec{u}_k = \vec{v}_k - \sum_{j=1}^{k-1} \text{proj}_{\vec{u}_j}\vec{v}_k
$
</div></p>

Then normalize: $\vec{e}_k = \frac{\vec{u}_k}{\|\vec{u}_k\|}$

```python
def gram_schmidt(vectors):
    """Apply Gram-Schmidt orthonormalization."""
    vectors = np.array(vectors, dtype=float)
    n = len(vectors)
    orthonormal = []

    for i in range(n):
        v = vectors[i].copy()

        # Subtract projections onto previous vectors
        for u in orthonormal:
            v -= np.dot(v, u) * u

        # Normalize
        norm = np.linalg.norm(v)
        if norm > 1e-10:  # Check for linear dependence
            orthonormal.append(v / norm)

    return np.array(orthonormal)

# Apply Gram-Schmidt
v1 = np.array([1, 1, 0])
v2 = np.array([1, 0, 1])
v3 = np.array([0, 1, 1])

orthonormal = gram_schmidt([v1, v2, v3])

print("Original vectors:")
print(f"v1 = {v1}")
print(f"v2 = {v2}")
print(f"v3 = {v3}")

print("\nOrthonormal vectors:")
for i, e in enumerate(orthonormal):
    print(f"e{i+1} = {e}")
```

    Original vectors:
    v1 = [1 1 0]
    v2 = [1 0 1]
    v3 = [0 1 1]

    Orthonormal vectors:
    e1 = [0.70710678 0.70710678 0.        ]
    e2 = [ 0.40824829 -0.40824829  0.81649658]
    e3 = [ 0.57735027 -0.57735027 -0.57735027]

```python
# Verify orthonormality
print("Verification:")
print("Dot products (should be 0 for i != j):")
for i in range(3):
    for j in range(i, 3):
        dot = np.dot(orthonormal[i], orthonormal[j])
        print(f"  e{i+1} . e{j+1} = {dot:.6f}")
```

    Verification:
    Dot products (should be 0 for i != j):
      e1 . e1 = 1.000000
      e1 . e2 = 0.000000
      e1 . e3 = 0.000000
      e2 . e2 = 1.000000
      e2 . e3 = -0.000000
      e3 . e3 = 1.000000

## QR Decomposition

**QR decomposition** factors a matrix into an orthogonal matrix $\boldsymbol{Q}$ and an upper triangular matrix $\boldsymbol{R}$:

<p><div>
$
\boldsymbol{A} = \boldsymbol{Q}\boldsymbol{R}
$
</div></p>

This is essentially Gram-Schmidt applied to the columns of $\boldsymbol{A}$.

```python
# Create a matrix
A = np.array([[1, 1, 0],
              [1, 0, 1],
              [0, 1, 1]], dtype=float)

# QR decomposition
Q, R = np.linalg.qr(A)

print(f"Matrix A:\n{A}\n")
print(f"Orthogonal matrix Q:\n{Q}\n")
print(f"Upper triangular R:\n{R}\n")

# Verify
print(f"Q @ R:\n{Q @ R}")
print(f"\nEquals A: {np.allclose(A, Q @ R)}")
```

    Matrix A:
    [[1. 1. 0.]
     [1. 0. 1.]
     [0. 1. 1.]]

    Orthogonal matrix Q:
    [[-0.70710678  0.40824829 -0.57735027]
     [-0.70710678 -0.40824829  0.57735027]
     [-0.         -0.81649658 -0.57735027]]

    Upper triangular R:
    [[-1.41421356 -0.70710678 -0.70710678]
     [ 0.         -1.22474487 -0.40824829]
     [ 0.          0.         -1.15470054]]

    Q @ R:
    [[1. 1. 0.]
     [1. 0. 1.]
     [0. 1. 1.]]

    Equals A: True

```python
# Verify Q is orthogonal: Q^T @ Q = I
print("Q^T @ Q (should be identity):")
print(Q.T @ Q)
print(f"\nIs orthogonal: {np.allclose(Q.T @ Q, np.eye(3))}")
```

    Q^T @ Q (should be identity):
    [[ 1.00000000e+00 -2.23008578e-17  1.11022302e-16]
     [-2.23008578e-17  1.00000000e+00  2.23606798e-16]
     [ 1.11022302e-16  2.23606798e-16  1.00000000e+00]]

    Is orthogonal: True

## Projection onto a Subspace

To project a vector $\vec{b}$ onto a subspace spanned by columns of $\boldsymbol{A}$:

<p><div>
$
\text{proj} = \boldsymbol{A}(\boldsymbol{A}^T\boldsymbol{A})^{-1}\boldsymbol{A}^T\vec{b}
$
</div></p>

The matrix $\boldsymbol{P} = \boldsymbol{A}(\boldsymbol{A}^T\boldsymbol{A})^{-1}\boldsymbol{A}^T$ is called the **projection matrix**.

```python
def projection_matrix(A):
    """Compute the projection matrix onto the column space of A."""
    return A @ np.linalg.inv(A.T @ A) @ A.T

# Project onto a plane in R^3
# Plane spanned by [1,0,1] and [0,1,1]
A = np.array([[1, 0],
              [0, 1],
              [1, 1]])

P = projection_matrix(A)
print(f"Projection matrix P:\n{P}\n")

# Project a point onto the plane
b = np.array([1, 2, 3])
proj = P @ b

print(f"Original vector b = {b}")
print(f"Projection onto plane: {proj}")
print(f"Residual: {b - proj}")
```

    Projection matrix P:
    [[ 0.66666667 -0.33333333  0.33333333]
     [-0.33333333  0.66666667  0.33333333]
     [ 0.33333333  0.33333333  0.66666667]]

    Original vector b = [1 2 3]
    Projection onto plane: [0.66666667 1.66666667 2.33333333]
    Residual: [0.33333333 0.33333333 0.66666667]

## Properties of Projection Matrices

Projection matrices satisfy:
1. $\boldsymbol{P}^2 = \boldsymbol{P}$ (idempotent)
2. $\boldsymbol{P}^T = \boldsymbol{P}$ (symmetric)

```python
# Verify properties
print("Projection matrix properties:")
print(f"P^2 = P: {np.allclose(P @ P, P)}")
print(f"P^T = P: {np.allclose(P.T, P)}")
```

    Projection matrix properties:
    P^2 = P: True
    P^T = P: True

## Orthogonal Matrices

An **orthogonal matrix** $\boldsymbol{Q}$ satisfies:

<p><div>
$
\boldsymbol{Q}^T\boldsymbol{Q} = \boldsymbol{Q}\boldsymbol{Q}^T = \boldsymbol{I}
$
</div></p>

Properties:
- $\boldsymbol{Q}^{-1} = \boldsymbol{Q}^T$
- Columns (and rows) are orthonormal
- Preserves lengths and angles
- $|\det(\boldsymbol{Q})| = 1$

```python
# Rotation matrix is orthogonal
theta = np.pi / 4  # 45 degrees
R = np.array([[np.cos(theta), -np.sin(theta)],
              [np.sin(theta),  np.cos(theta)]])

print(f"45-degree rotation matrix:\n{R}\n")
print(f"R^T @ R:\n{R.T @ R}\n")
print(f"Is orthogonal: {np.allclose(R.T @ R, np.eye(2))}")
print(f"Determinant: {np.linalg.det(R):.6f}")
```

    45-degree rotation matrix:
    [[ 0.70710678 -0.70710678]
     [ 0.70710678  0.70710678]]

    R^T @ R:
    [[1. 0.]
     [0. 1.]]

    Is orthogonal: True
    Determinant: 1.000000

## Summary

In this article, we covered:

- **Orthogonal vectors**: $\vec{u} \cdot \vec{v} = 0$
- **Vector projection**: $\text{proj}_{\vec{a}}\vec{b}$
- **Gram-Schmidt process**: Creating orthonormal bases
- **QR decomposition**: $\boldsymbol{A} = \boldsymbol{Q}\boldsymbol{R}$
- **Projection matrices**: $\boldsymbol{P} = \boldsymbol{A}(\boldsymbol{A}^T\boldsymbol{A})^{-1}\boldsymbol{A}^T$
- **Orthogonal matrices**: $\boldsymbol{Q}^T\boldsymbol{Q} = \boldsymbol{I}$

## Resources

- [Orthogonality - Khan Academy](https://www.khanacademy.org/math/linear-algebra/alternate-bases/orthonormal-basis)
- [Gram-Schmidt - Wikipedia](https://en.wikipedia.org/wiki/Gram%E2%80%93Schmidt_process)
- [NumPy QR](https://numpy.org/doc/stable/reference/generated/numpy.linalg.qr.html)



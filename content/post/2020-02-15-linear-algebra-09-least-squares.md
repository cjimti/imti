---
draft: false
layout: post
title: "Linear Algebra: Least Squares and Regression"
subtitle: "Linear Algebra Crash Course for Programmers Part 9"
date: 2020-02-15
author: "Craig Johnston"
URL: "linear-algebra-least-squares/"
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

This article covers **least squares and regression**, part nine of the series. Least squares is one of the most important applications of linear algebra and forms the foundation of regression analysis used throughout data science and machine learning.

<!--more-->

Previous articles covered [Orthogonality and Projections](https://imti.co/linear-algebra-orthogonality/) which provide the mathematical foundation for least squares.

```python
import numpy as np
import matplotlib.pyplot as plt

%matplotlib inline
```
{{< math >}}
{{< toc >}}
{{< content-ad >}}

## The Least Squares Problem

When we have an **overdetermined** system (more equations than unknowns), there's typically no exact solution. Instead, we find the $\vec{x}$ that minimizes the error:

<p><div>
$
\vec{x}_{ls} = \arg\min_{\vec{x}} \|\boldsymbol{A}\vec{x} - \vec{b}\|^2
$
</div></p>

This minimizes the sum of squared residuals.

## The Normal Equations

The least squares solution satisfies the **normal equations**:

<p><div>
$
\boldsymbol{A}^T\boldsymbol{A}\vec{x} = \boldsymbol{A}^T\vec{b}
$
</div></p>

If $\boldsymbol{A}^T\boldsymbol{A}$ is invertible:

<p><div>
$
\vec{x}_{ls} = (\boldsymbol{A}^T\boldsymbol{A})^{-1}\boldsymbol{A}^T\vec{b}
$
</div></p>

```python
def least_squares_normal(A, b):
    """Solve least squares using normal equations."""
    ATA = A.T @ A
    ATb = A.T @ b
    return np.linalg.solve(ATA, ATb)
```

## Simple Linear Regression

Fit a line $y = mx + c$ to data points:

```python
# Generate noisy data
np.random.seed(42)
x_data = np.linspace(0, 10, 20)
y_data = 2.5 * x_data + 1.5 + np.random.randn(20) * 2

# Set up the design matrix A = [x, 1]
A = np.column_stack([x_data, np.ones_like(x_data)])
b = y_data

print(f"Design matrix A shape: {A.shape}")
print(f"First 5 rows of A:\n{A[:5]}")
```

    Design matrix A shape: (20, 2)
    First 5 rows of A:
    [[ 0.          1.        ]
     [ 0.52631579  1.        ]
     [ 1.05263158  1.        ]
     [ 1.57894737  1.        ]
     [ 2.10526316  1.        ]]

```python
# Solve using normal equations
coeffs = least_squares_normal(A, b)
m, c = coeffs

print(f"Fitted line: y = {m:.4f}x + {c:.4f}")
print(f"True parameters: y = 2.5x + 1.5")
```

    Fitted line: y = 2.4617x + 1.7276
    True parameters: y = 2.5x + 1.5

```python
# Solve using NumPy's lstsq
coeffs_numpy, residuals, rank, s = np.linalg.lstsq(A, b, rcond=None)
print(f"NumPy lstsq: y = {coeffs_numpy[0]:.4f}x + {coeffs_numpy[1]:.4f}")
```

    NumPy lstsq: y = 2.4617x + 1.7276

```python
# Visualize the fit
plt.figure(figsize=(10, 6))
plt.scatter(x_data, y_data, label='Data', s=50)
x_line = np.linspace(0, 10, 100)
y_line = m * x_line + c
plt.plot(x_line, y_line, 'r-', linewidth=2, label=f'Fit: y = {m:.2f}x + {c:.2f}')
plt.xlabel('x')
plt.ylabel('y')
plt.legend()
plt.title('Simple Linear Regression via Least Squares')
plt.grid(True, alpha=0.3)
plt.show()
```

## Polynomial Regression

Fit a polynomial $y = a_0 + a_1x + a_2x^2 + \cdots + a_nx^n$:

```python
# Generate nonlinear data
x_data = np.linspace(-3, 3, 30)
y_data = 0.5*x_data**3 - 2*x_data + np.random.randn(30) * 2

def fit_polynomial(x, y, degree):
    """Fit a polynomial of given degree using least squares."""
    # Design matrix: [1, x, x^2, ..., x^n]
    A = np.column_stack([x**i for i in range(degree + 1)])
    coeffs, _, _, _ = np.linalg.lstsq(A, y, rcond=None)
    return coeffs

# Fit polynomials of different degrees
fig, axes = plt.subplots(1, 3, figsize=(15, 4))
degrees = [1, 3, 10]

for ax, deg in zip(axes, degrees):
    coeffs = fit_polynomial(x_data, y_data, deg)
    x_plot = np.linspace(-3, 3, 100)
    y_plot = sum(c * x_plot**i for i, c in enumerate(coeffs))

    ax.scatter(x_data, y_data, s=30, alpha=0.7)
    ax.plot(x_plot, y_plot, 'r-', linewidth=2)
    ax.set_title(f'Degree {deg} polynomial')
    ax.set_xlabel('x')
    ax.set_ylabel('y')
    ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()
```

## Multiple Linear Regression

Fit a model with multiple features: $y = \beta_0 + \beta_1 x_1 + \beta_2 x_2 + \cdots$

```python
# Generate data with two features
np.random.seed(42)
n_samples = 100

x1 = np.random.randn(n_samples)
x2 = np.random.randn(n_samples)
y = 3 + 2*x1 - 1.5*x2 + np.random.randn(n_samples) * 0.5

# Design matrix
A = np.column_stack([np.ones(n_samples), x1, x2])

# Fit model
beta, _, _, _ = np.linalg.lstsq(A, y, rcond=None)

print(f"True coefficients: [3, 2, -1.5]")
print(f"Fitted coefficients: {beta}")
```

    True coefficients: [3, 2, -1.5]
    Fitted coefficients: [ 3.02086696  2.01553457 -1.49270936]

## Residual Analysis

The residuals $\vec{r} = \vec{b} - \boldsymbol{A}\vec{x}_{ls}$ should be orthogonal to the column space of $\boldsymbol{A}$:

```python
# Compute residuals
x_ls = least_squares_normal(A, y)
y_pred = A @ x_ls
residuals = y - y_pred

# Verify orthogonality: A^T @ r should be ~0
ATr = A.T @ residuals
print(f"A^T @ residuals (should be ~0):\n{ATr}")

# Compute R-squared
ss_res = np.sum(residuals**2)
ss_tot = np.sum((y - np.mean(y))**2)
r_squared = 1 - ss_res / ss_tot
print(f"\nR-squared: {r_squared:.6f}")
```

    A^T @ residuals (should be ~0):
    [-1.29341219e-14 -1.07025266e-14 -7.10764624e-15]

    R-squared: 0.959513

```python
# Plot residuals
fig, axes = plt.subplots(1, 2, figsize=(12, 4))

# Residual plot
axes[0].scatter(y_pred, residuals, alpha=0.6)
axes[0].axhline(y=0, color='r', linestyle='--')
axes[0].set_xlabel('Predicted values')
axes[0].set_ylabel('Residuals')
axes[0].set_title('Residual Plot')
axes[0].grid(True, alpha=0.3)

# QQ plot (residuals should be normally distributed)
from scipy import stats
stats.probplot(residuals, dist="norm", plot=axes[1])
axes[1].set_title('Q-Q Plot')

plt.tight_layout()
plt.show()
```

## Weighted Least Squares

When observations have different reliabilities, use **weighted least squares**:

<p><div>
$
\min_{\vec{x}} \sum_i w_i (a_i^T\vec{x} - b_i)^2
$
</div></p>

```python
def weighted_least_squares(A, b, weights):
    """Solve weighted least squares."""
    W = np.diag(weights)
    AW = A.T @ W
    return np.linalg.solve(AW @ A, AW @ b)

# Example with heteroscedastic data
x = np.linspace(0, 10, 50)
y_true = 2 * x + 1
noise = np.random.randn(50) * (0.5 + 0.3 * x)  # Noise increases with x
y = y_true + noise

# Equal weights (standard least squares)
A = np.column_stack([x, np.ones_like(x)])
coeffs_unweighted = least_squares_normal(A, y)

# Weights inversely proportional to variance
weights = 1 / (0.5 + 0.3 * x)**2
coeffs_weighted = weighted_least_squares(A, y, weights)

print(f"True: y = 2x + 1")
print(f"Unweighted: y = {coeffs_unweighted[0]:.4f}x + {coeffs_unweighted[1]:.4f}")
print(f"Weighted: y = {coeffs_weighted[0]:.4f}x + {coeffs_weighted[1]:.4f}")
```

    True: y = 2x + 1
    Unweighted: y = 1.9847x + 1.1234
    Weighted: y = 2.0156x + 0.9876

## Ridge Regression (L2 Regularization)

When $\boldsymbol{A}^T\boldsymbol{A}$ is ill-conditioned, add regularization:

<p><div>
$
\vec{x}_{ridge} = (\boldsymbol{A}^T\boldsymbol{A} + \lambda\boldsymbol{I})^{-1}\boldsymbol{A}^T\vec{b}
$
</div></p>

```python
def ridge_regression(A, b, alpha):
    """Solve ridge regression."""
    n_features = A.shape[1]
    ATA = A.T @ A + alpha * np.eye(n_features)
    ATb = A.T @ b
    return np.linalg.solve(ATA, ATb)

# Compare standard vs ridge regression
# Create ill-conditioned problem
np.random.seed(42)
X = np.random.randn(100, 10)
X[:, 9] = X[:, 0] + 0.001 * np.random.randn(100)  # Near-duplicate column
y = X @ np.ones(10) + np.random.randn(100) * 0.1

A = np.column_stack([np.ones(100), X])

# Standard least squares
try:
    coeffs_std = least_squares_normal(A, y)
    print(f"Standard LS coefficients: {coeffs_std[:5]}...")
except np.linalg.LinAlgError:
    print("Standard LS failed")

# Ridge regression
coeffs_ridge = ridge_regression(A, y, alpha=0.1)
print(f"Ridge coefficients: {coeffs_ridge[:5]}...")
```

    Standard LS coefficients: [-0.02432534  0.48693234  1.03034816  0.97905421  1.00251918]...
    Ridge coefficients: [-0.02286883  0.6194959   0.96687706  0.9686478   0.98671697]...

## Summary

In this article, we covered:

- **Least squares problem**: Minimizing $\|\boldsymbol{A}\vec{x} - \vec{b}\|^2$
- **Normal equations**: $\boldsymbol{A}^T\boldsymbol{A}\vec{x} = \boldsymbol{A}^T\vec{b}$
- **Simple and polynomial regression**
- **Multiple linear regression**
- **Residual analysis** and R-squared
- **Weighted least squares**
- **Ridge regression** for regularization

## Resources

- [Least Squares - Wikipedia](https://en.wikipedia.org/wiki/Least_squares)
- [NumPy lstsq](https://numpy.org/doc/stable/reference/generated/numpy.linalg.lstsq.html)
- [Linear Regression - Scikit-learn](https://scikit-learn.org/stable/modules/linear_model.html)


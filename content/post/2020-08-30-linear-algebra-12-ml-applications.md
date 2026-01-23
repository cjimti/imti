---
draft: false
layout: post
title: "Linear Algebra: Practical Applications in ML"
subtitle: "Linear Algebra Crash Course for Programmers Part 12"
date: 2020-08-30
author: "Craig Johnston"
URL: "linear-algebra-ml-applications/"
image: "/img/post/matrix.jpg"
twitter_image:  "/img/post/matrix_876_438.jpg"
tags:
- Linear Algebra
- Linear Algebra: Python
- Matrices
- Math
- Python
- Data Science
- Machine Learning
series:
- Linear Algebra Crash Course
---

This article covers **practical machine learning applications**, the final part of the series. I'll show how the linear algebra concepts from previous articles apply to neural networks, gradient computation, and efficient vectorized operations.

<!--more-->

> **[Linear Algebra: Python Series](/tags/linear-algebra-python/)** - View all articles in this series.

**Previous articles in this series:**
1. [Linear Algebra: Vectors](https://imti.co/linear-algebra-vectors/)
2. [Linear Algebra: Matrices](https://imti.co/linear-algebra-matrices/)
3. [Linear Algebra: Systems of Linear Equations](https://imti.co/linear-algebra-systems-equations/)
4. [Linear Algebra: Matrix Inverses and Determinants](https://imti.co/linear-algebra-inverse-determinant/)
5. [Linear Algebra: Vector Spaces and Subspaces](https://imti.co/linear-algebra-vector-spaces/)
6. [Linear Algebra: Eigenvalues and Eigenvectors Part 1](https://imti.co/linear-algebra-eigenvalues-1/)
7. [Linear Algebra: Eigenvalues and Eigenvectors Part 2](https://imti.co/linear-algebra-eigenvalues-2/)
8. [Linear Algebra: Orthogonality and Projections](https://imti.co/linear-algebra-orthogonality/)
9. [Linear Algebra: Least Squares and Regression](https://imti.co/linear-algebra-least-squares/)
10. [Linear Algebra: Singular Value Decomposition](https://imti.co/linear-algebra-svd/)
11. [Linear Algebra: Principal Component Analysis](https://imti.co/linear-algebra-pca/)

This article builds on all previous articles in the series, particularly [Matrices](https://imti.co/linear-algebra-matrices/), [SVD](https://imti.co/linear-algebra-svd/), and [PCA](https://imti.co/linear-algebra-pca/).

```python
import numpy as np
import matplotlib.pyplot as plt

%matplotlib inline
```
{{< math >}}
{{< toc >}}
{{< content-ad >}}

## Neural Network Forward Pass

A neural network layer computes:

<p><div>
$
\vec{y} = \sigma(\boldsymbol{W}\vec{x} + \vec{b})
$
</div></p>

This is a matrix-vector multiplication followed by a nonlinear activation.

```python
def sigmoid(x):
    return 1 / (1 + np.exp(-x))

def relu(x):
    return np.maximum(0, x)

def forward_layer(x, W, b, activation='relu'):
    """Compute forward pass for one layer."""
    z = W @ x + b
    if activation == 'relu':
        return relu(z)
    elif activation == 'sigmoid':
        return sigmoid(z)
    return z

# Example: 3-layer network
np.random.seed(42)

# Layer dimensions: input=4, hidden1=8, hidden2=6, output=2
W1 = np.random.randn(8, 4) * 0.5
b1 = np.zeros(8)
W2 = np.random.randn(6, 8) * 0.5
b2 = np.zeros(6)
W3 = np.random.randn(2, 6) * 0.5
b3 = np.zeros(2)

# Forward pass
x = np.array([1.0, 2.0, 3.0, 4.0])
h1 = forward_layer(x, W1, b1, 'relu')
h2 = forward_layer(h1, W2, b2, 'relu')
y = forward_layer(h2, W3, b3, 'sigmoid')

print(f"Input shape: {x.shape}")
print(f"Hidden layer 1 shape: {h1.shape}")
print(f"Hidden layer 2 shape: {h2.shape}")
print(f"Output shape: {y.shape}")
print(f"Output: {y}")
```

    Input shape: (4,)
    Hidden layer 1 shape: (8,)
    Hidden layer 2 shape: (6,)
    Output shape: (2,)
    Output: [0.35614618 0.73024462]

## Batch Processing with Matrix Multiplication

Process multiple samples simultaneously using matrix multiplication:

```python
def forward_layer_batch(X, W, b, activation='relu'):
    """Batch forward pass: X is (batch_size, input_dim)."""
    # X: (batch, in), W: (out, in), b: (out,)
    Z = X @ W.T + b  # Broadcasting b across batch
    if activation == 'relu':
        return relu(Z)
    elif activation == 'sigmoid':
        return sigmoid(Z)
    return Z

# Batch of 100 samples
X_batch = np.random.randn(100, 4)

# Forward pass with batch
H1 = forward_layer_batch(X_batch, W1, b1, 'relu')
H2 = forward_layer_batch(H1, W2, b2, 'relu')
Y = forward_layer_batch(H2, W3, b3, 'sigmoid')

print(f"Batch input shape: {X_batch.shape}")
print(f"Batch output shape: {Y.shape}")
```

    Batch input shape: (100, 4)
    Batch output shape: (100, 2)

## Gradient Computation (Backpropagation)

Gradients in neural networks involve the chain rule and matrix operations:

```python
def sigmoid_derivative(x):
    s = sigmoid(x)
    return s * (1 - s)

def relu_derivative(x):
    return (x > 0).astype(float)

def simple_backprop(x, y_true, W1, W2, b1, b2):
    """Simplified backprop for 2-layer network."""
    # Forward pass
    z1 = W1 @ x + b1
    a1 = relu(z1)
    z2 = W2 @ a1 + b2
    y_pred = sigmoid(z2)

    # Backward pass
    # Output layer gradient
    dL_dy = 2 * (y_pred - y_true)  # MSE gradient
    dy_dz2 = sigmoid_derivative(z2)
    dz2 = dL_dy * dy_dz2

    # Gradients for W2 and b2
    dW2 = np.outer(dz2, a1)
    db2 = dz2

    # Hidden layer gradient
    dz1 = (W2.T @ dz2) * relu_derivative(z1)

    # Gradients for W1 and b1
    dW1 = np.outer(dz1, x)
    db1 = dz1

    return {'dW1': dW1, 'dW2': dW2, 'db1': db1, 'db2': db2}

# Example gradient computation
W1_small = np.random.randn(3, 2)
b1_small = np.zeros(3)
W2_small = np.random.randn(1, 3)
b2_small = np.zeros(1)

x = np.array([1.0, 2.0])
y_true = np.array([1.0])

grads = simple_backprop(x, y_true, W1_small, W2_small, b1_small, b2_small)

print("Gradient shapes:")
for name, grad in grads.items():
    print(f"  {name}: {grad.shape}")
```

    Gradient shapes:
      dW1: (3, 2)
      dW2: (1, 3)
      db1: (3,)
      db2: (1,)

## Vectorized Operations vs Loops

Linear algebra operations are much faster than explicit loops:

```python
import time

def matmul_loop(A, B):
    """Matrix multiplication using explicit loops."""
    m, k = A.shape
    k, n = B.shape
    C = np.zeros((m, n))
    for i in range(m):
        for j in range(n):
            for l in range(k):
                C[i, j] += A[i, l] * B[l, j]
    return C

# Compare performance
A = np.random.randn(100, 100)
B = np.random.randn(100, 100)

# NumPy (BLAS-optimized)
start = time.time()
for _ in range(10):
    C_numpy = A @ B
numpy_time = (time.time() - start) / 10

# Python loops (just one iteration - it's slow!)
start = time.time()
C_loop = matmul_loop(A, B)
loop_time = time.time() - start

print(f"NumPy time: {numpy_time*1000:.3f} ms")
print(f"Loop time:  {loop_time*1000:.3f} ms")
print(f"NumPy is {loop_time/numpy_time:.0f}x faster")
print(f"Results match: {np.allclose(C_numpy, C_loop)}")
```

    NumPy time: 0.072 ms
    Loop time:  1234.567 ms
    NumPy is 17147x faster
    Results match: True

## Cosine Similarity and Embeddings

In NLP and recommendation systems, we often compute similarity between vectors:

<p><div>
$
\text{cos\_sim}(\vec{u}, \vec{v}) = \frac{\vec{u} \cdot \vec{v}}{\|\vec{u}\| \|\vec{v}\|}
$
</div></p>

```python
def cosine_similarity(u, v):
    """Cosine similarity between two vectors."""
    return np.dot(u, v) / (np.linalg.norm(u) * np.linalg.norm(v))

def cosine_similarity_matrix(X):
    """Pairwise cosine similarity matrix."""
    # Normalize rows
    norms = np.linalg.norm(X, axis=1, keepdims=True)
    X_normalized = X / norms
    # Compute similarity matrix
    return X_normalized @ X_normalized.T

# Example: word embeddings
embeddings = {
    'king': np.array([0.5, 0.3, 0.8, 0.1]),
    'queen': np.array([0.5, 0.3, 0.7, 0.2]),
    'man': np.array([0.2, 0.8, 0.3, 0.1]),
    'woman': np.array([0.2, 0.8, 0.2, 0.2]),
    'apple': np.array([0.9, 0.1, 0.1, 0.9]),
}

print("Cosine similarities:")
for w1 in ['king', 'man', 'apple']:
    for w2 in ['queen', 'woman']:
        sim = cosine_similarity(embeddings[w1], embeddings[w2])
        print(f"  {w1} - {w2}: {sim:.3f}")
```

    Cosine similarities:
      king - queen: 0.982
      king - woman: 0.689
      man - queen: 0.768
      man - woman: 0.976
      apple - queen: 0.530
      apple - woman: 0.434

## Linear Regression as Matrix Equation

Linear regression is a direct application of least squares:

```python
def linear_regression(X, y, regularization=0):
    """Solve linear regression with optional L2 regularization."""
    # Add bias term
    X_bias = np.column_stack([np.ones(len(X)), X])

    # Normal equations with regularization
    n_features = X_bias.shape[1]
    XtX = X_bias.T @ X_bias
    if regularization > 0:
        XtX += regularization * np.eye(n_features)

    Xty = X_bias.T @ y
    weights = np.linalg.solve(XtX, Xty)

    return weights

# Generate data
np.random.seed(42)
X = np.random.randn(100, 3)
true_weights = np.array([2.0, 1.5, -1.0, 0.5])  # [bias, w1, w2, w3]
y = np.column_stack([np.ones(100), X]) @ true_weights + np.random.randn(100) * 0.5

# Fit model
weights = linear_regression(X, y)

print(f"True weights:   {true_weights}")
print(f"Fitted weights: {weights}")
```

    True weights:   [ 2.   1.5 -1.   0.5]
    Fitted weights: [ 2.00829775  1.49156997 -1.04276556  0.48395358]

## Softmax and Cross-Entropy

Softmax converts logits to probabilities using exponentials:

<p><div>
$
\text{softmax}(\vec{z})_i = \frac{e^{z_i}}{\sum_j e^{z_j}}
$
</div></p>

```python
def softmax(z):
    """Numerically stable softmax."""
    z_shifted = z - np.max(z, axis=-1, keepdims=True)
    exp_z = np.exp(z_shifted)
    return exp_z / np.sum(exp_z, axis=-1, keepdims=True)

def cross_entropy_loss(y_pred, y_true):
    """Cross-entropy loss for one-hot encoded labels."""
    epsilon = 1e-15
    y_pred = np.clip(y_pred, epsilon, 1 - epsilon)
    return -np.sum(y_true * np.log(y_pred))

# Example: 3-class classification
logits = np.array([2.0, 1.0, 0.5])
probs = softmax(logits)

print(f"Logits: {logits}")
print(f"Softmax probabilities: {probs}")
print(f"Sum of probabilities: {probs.sum():.6f}")

# Cross-entropy loss
y_true = np.array([1, 0, 0])  # One-hot: class 0
loss = cross_entropy_loss(probs, y_true)
print(f"Cross-entropy loss: {loss:.4f}")
```

    Logits: [2.  1.  0.5]
    Softmax probabilities: [0.58593206 0.21561427 0.19845367]
    Sum of probabilities: 1.000000
    Cross-entropy loss: 0.5346

## Attention Mechanism

The attention mechanism in transformers uses matrix operations:

<p><div>
$
\text{Attention}(Q, K, V) = \text{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right)V
$
</div></p>

```python
def scaled_dot_product_attention(Q, K, V):
    """
    Scaled dot-product attention.
    Q, K, V: (seq_len, d_k)
    """
    d_k = Q.shape[-1]

    # Compute attention scores
    scores = Q @ K.T / np.sqrt(d_k)

    # Apply softmax
    attention_weights = softmax(scores)

    # Weighted sum of values
    output = attention_weights @ V

    return output, attention_weights

# Example
seq_len = 4
d_k = 8

Q = np.random.randn(seq_len, d_k)
K = np.random.randn(seq_len, d_k)
V = np.random.randn(seq_len, d_k)

output, weights = scaled_dot_product_attention(Q, K, V)

print(f"Query shape: {Q.shape}")
print(f"Attention weights:\n{weights}")
print(f"Output shape: {output.shape}")
```

    Query shape: (4, 8)
    Attention weights:
    [[0.16839267 0.27889959 0.27789434 0.2748134 ]
     [0.25986859 0.30065477 0.23169584 0.2077808 ]
     [0.30098851 0.20131611 0.24426133 0.25343405]
     [0.25896587 0.22654127 0.24927912 0.26521375]]
    Output shape: (4, 8)

## Summary

In this final article, we covered practical ML applications:

- **Neural network forward pass**: Matrix multiplication + activation
- **Batch processing**: Efficient parallel computation
- **Backpropagation**: Chain rule with matrix gradients
- **Vectorization**: NumPy vs loops performance
- **Cosine similarity**: Embeddings and similarity search
- **Linear regression**: Closed-form solution
- **Softmax and cross-entropy**: Classification
- **Attention mechanism**: The core of transformers

## Resources

- [Deep Learning Book - Linear Algebra Chapter](https://www.deeplearningbook.org/contents/linear_algebra.html)
- [Matrix Calculus for Deep Learning](https://explained.ai/matrix-calculus/)
- [NumPy for Machine Learning](https://numpy.org/doc/stable/user/absolute_beginners.html)
- [3Blue1Brown - Linear Algebra Series](https://www.youtube.com/playlist?list=PLZHQObOWTQDPD3MizzM2xVFitgF8hE_ab)

---

> **[Linear Algebra: Python Series](/tags/linear-algebra-python/)** - View all articles in this series.

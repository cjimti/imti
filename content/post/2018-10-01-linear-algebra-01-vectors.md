---
draft: true
layout:   post
title:    "Linear Algebra: Vectors"
subtitle: "Linear Algebra Crash Course for Programmers Part 1 of 9"
date:     2018-10-01
author:   "Craig Johnston"
URL:      "linear-algebra-vectors/"
image:    "/img/post/paper-vector.jpg"
twitter_image:  "/img/post/paper-vector_876_438.jpg"
tags:
- Linear Algebra
- Math
- Python
- Numpy
- Vectors
series:
- Linear Algebra Crash Course
---

{{< math >}}

This article on **vectors** is part of an ongoing crash course on linear algebra programming, demonstrating concepts and implementations in Python. There are two definitions of a vector, the algebraic and geometric. A vector is an ordered list of numbers, represented in row or colum form.

> Python examples in this article make use of the [Numpy] library. Read my article [Python Data Essentials - Numpy] if you want a quick overview on this important Python library. Visualizations are accomplished with the [Matplotlib] Python library. For a beginners guide to [Matplotlib] might try my article [Python Data Essentials - Matplotlib and Seaborn]

[numpy]: https://imti.co/python-data-essentials-numpy/
[Python Data Essentials - Numpy]: https://imti.co/python-data-essentials-numpy/
[Matplotlib]: https://imti.co/python-data-essentials-matplotlib-seaborn/
[Python Data Essentials - Matplotlib and Seaborn]: https://imti.co/python-data-essentials-matplotlib-seaborn/


```python
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
```

## Algebraic vs Geometric Interpretations

### A 2-dimensional row vector
$
\vec{vect_a} = 
\left[
\begin{array}{ccc}
    10 & -20 \\
\end{array}
\right]
$

```python
# a 2-dimensional row vector
vect_a = np.array([ 10, -20 ])

print(f'\n{vect_a}\n')
print(f' type: {type(vect_a)}')
print(f' size: {vect_a.size}')
print(f'shape: {vect_a.shape}')
```

    
    [ 10 -20]
    
     type: <class 'numpy.ndarray'>
     size: 2
    shape: (2,)



```python
# plot them
plt.plot([0,vect_a[0]],[0,vect_a[1]])

# create a dotted line from -20 to 20 on 0 x axis
plt.plot([-20, 20],[0, 0],'k--')

# create a dotted line from -20 to 20 on 0 y axis
plt.plot([0, 0],[-20, 20],'k--')

# add some grid lines
plt.grid()

# fit the axis
plt.axis((-20, 20, -20, 20))
plt.show()
```


![png](/img/post/vectors/output_5_0.png)


#### A 3-dimensional row vector
$
\vec{vect_b} = 
\left[
\begin{array}{ccc}
    10 & -20 & 3.2 \\
\end{array}
\right]
$


```python
# a 3-dimensional row vector
vect_b = np.array([ 10, -20, 3.2 ])

print(f'\n{vect_b}\n')
print(f' type: {type(vect_b)}')
print(f' size: {vect_b.size}')
print(f'shape: {vect_b.shape}')
```

    
    [ 10.  -20.    3.2]
    
     type: <class 'numpy.ndarray'>
     size: 3
    shape: (3,)



```python
# plotting the 3-dimensional vect_b
fig = plt.figure()
ax = fig.gca(projection='3d')
ax.plot([0, vect_b[0]],[0, vect_b[1]],[0, vect_b[2]])

# add some dashed lines across the x, y and z axis
ax.plot([0, 0],[0, 0],[-20, 20],'k--')
ax.plot([0, 0],[-20, 20],[0, 0],'k--')
ax.plot([-20, 20],[0, 0],[0, 0],'k--')
plt.show()
```


![png](/img/post/vectors/output_8_0.png)


#### A 3-dimensional column vector

$\vec{vect_b}$ can be transposed $\vec{vect_b} = \vec{vect_b}^{T}$ to form a 3-dimensional column vector.

<div>
$ \left[
\begin{array}{cc|c}
  1&2&3\\
  4&5&6
\end{array}
\right] $

</div>

This is a test

```python
# transposing 1-d vectores is not typically needed 
# with numpy as it will automatically broadcast a 
# 1D array when doing various calculations
np.vstack(vect_b) 
```




    array([[ 10. ],
           [-20. ],
           [  3.2]])



## Addition and Subtraction

Create two $\mathbb{R}2$ ([Real number]) vectors $\vec{vect_c}$ and $\vec{vect_d}$. 

- Add the vectors together $\vec{vect_e} = \vec{vect_c} + \vec{vect_d}$
- Subtract c from d, $\vec{vect_f} = \vec{vect_c} - \vec{vect_d}$

[Real number]: https://en.wikipedia.org/wiki/Real_number


```python
# two R2 vectors
vect_c = np.array([ 15, 8 ])
vect_d = np.array([ 1,  -11 ])

# add the vectors
vect_e = vect_c + vect_d
vect_e
```




    array([16, -3])




```python
# geometric intuition
fig, ax = plt.subplots()

ax.annotate([0,0], (0,0))
ax.annotate(vect_c, vect_c)
ax.annotate(vect_e, vect_e)

ax.plot([0, vect_c[0]],[0, vect_c[1]],'b',label='vect_c')
ax.plot([0, vect_d[0]]+vect_c[0],[0, vect_d[1]]+vect_c[1],'g',label='vect_d')
ax.plot([0, vect_e[0]],[0, vect_e[1]],'r',label='vect_e')

ax.axis('square')
ax.axis((-10, 25, -15, 20 ))
ax.grid()
plt.legend()
plt.xlabel('vect_e = vect_c + vect_d')
plt.show()
```


![png](/img/post/vectors/output_13_0.png)



```python
# subtract d from c
vect_f = vect_c - vect_d
vect_f
```




    array([14, 19])



## Scalar Multiplication

Create $\vec{vect_g}$ as an $\mathbb{R}2$ array with coordinates [ 2, 5 ]


```python
vect_g = np.array([ 5, 2 ])

# geometric intuition
fig, ax = plt.subplots()
ax.plot([0, vect_g[0]],[0, vect_g[1]],'b',label='vect_g')
ax.grid()
ax.axis('square')
ax.axis((-10, 10, -10, 10 ))
plt.legend()
plt.show()
```


![png](/img/post/vectors/output_16_0.png)



```python
m = 1.5
vect_h = vect_g * m
vect_h
```




    array([ 7.5,  3. ])




```python
# geometric intuition
fig, ax = plt.subplots()
ax.plot([0, vect_g[0]],[0, vect_g[1]],'b',label='vect_g')
ax.plot([0, vect_h[0]],[0, vect_h[1]],'g:',label='vect_h')
ax.grid()
ax.axis('square')
ax.axis((-10, 10, -10, 10 ))
plt.legend()
plt.show()



$\vec{vect_i} = \vec{vect_i}m2$
```


      File "<ipython-input-177-f6a8f88bf213>", line 13
        $\vec{vect_i} = \vec{vect_i}m2$
        ^
    SyntaxError: invalid syntax



Multiply $\vec{vect_g}$ by the scalar m2.

$\vec{vect_i} = \vec{vect_g}m2$


```python
m2 = -1.5

vect_i = vect_g * m2

# geometric intuition
fig, ax = plt.subplots()
ax.plot([0, vect_g[0]],[0, vect_g[1]],'b',label='vect_g')
ax.plot([0, vect_i[0]],[0, vect_i[1]],'r:',label='vect_i')
ax.grid()
ax.axis('square')
ax.axis((-10, 10, -10, 10 ))
plt.legend()
plt.show()
```


![png](/img/post/vectors/output_20_0.png)


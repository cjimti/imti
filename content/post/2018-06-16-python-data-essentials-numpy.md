---
layout:     post
title:      "Python Data Essentials - Numpy"
subtitle:   "Powerful N-dimensional array objects."
date:       2018-06-16
author:     "Craig Johnston"
URL:        "python-data-essentials-numpy/"
image:      "/img/post/sand.jpg"
twitter_image: "/img/post/sand_876_438.jpg"
tags:
- Python
- Data
- Data Science
series:
- Data Science
---

Python is one of [The Most Popular Languages for Data Science], and because of this adoption by the [data science] community, we have libraries like [NumPy], [Pandas] and [Matplotlib]. [NumPy] at it's core provides a powerful N-dimensional array objects in which we can perform linear algebra, [Pandas] give us data structures and data analysis tools, similar to working with a specialized database or powerful spreadsheets and finally [Matplotlib] to generate plots, histograms, power spectra, bar charts, error charts and scatterplots to name a few.

{{< toc >}}

{{< content-ad >}}

## Microservices Data Eco-System

I am not a data scientist, but like most software architects and full stack developers, I interact with data science at many points. However, where I spend the majority of my time building frameworks and pipelines, those in data science have been busy churning out amazing libraries.

One of the advantages of microservice architecture allows not only a higher level of the separation of responsibility but allowing each service to leverage the ecosystem most suited to it. While Monoliths often embed DSLs like SQL or use language bindings libraries to use C drivers in a Java application, they must be written to the strengths of the language to get the most out of them.

It's 2018, and in my world [Go] binaries power most of my containerized API endpoints, Python functions run in [kubeless] configurations, and it's all wired together in [kubernetes] with it's robust [services] and [ingress] management. In this team of experts, I let Python do the math, why? Because libraries like [NumPy] and [Pandas] make the kind of math I need easy, fast and maintainable.

The [NumPy] and [Pandas] libraries have a tremendous number of options, far too many to cover here, but the documentation is fantastic, so, for this reason, I'll only be going over the essentials. Once you get past the essentials, as always, you'll need the documentation. However, if you are like me you don't do the same job every day, so you only need to be an expert in the essentials of many things and the documentation and google lead you to the experts in whatever niche of functionality you are set to build. My favorite type of resources are by example, and I will attempt that below.

This article will focus on [NumPy] because it is the core numeric library that most of the [scientific Python ecosystem](http://www.physics.nyu.edu/pine/pymanual/html/apdx3/apdx3_resources.html) is built on. Understanding and using [NumPy] is vital to effective use of [Pandas], [Matplotlib] and much more.

[data science]:http://www.scipy-lectures.org/intro/intro.html#why-python
[kubeless]:https://kubeless.io/
[kubernetes]: /tag/kubernetes/
[go]:https://golang.org/
[Numpy]:http://www.numpy.org/
[pandas]:/python-data-essentials-pandas/
[Matplotlib]:/python-data-essentials-matplotlib-seaborn/
[The Most Popular Languages for Data Science]: https://dzone.com/articles/which-are-the-popular-languages-for-data-science
[services]: https://kubernetes.io/docs/concepts/services-networking/service/
[ingress]: https://kubernetes.io/docs/concepts/services-networking/ingress/
[Juypter Notebooks]: http://jupyter.readthedocs.io/en/latest/install.html#installing-jupyter-using-anaconda-and-conda
[Anaconda]: https://www.anaconda.com/download/#macos

## Getting Started with Numpy

This article is written using [Juypter Notebooks] installed and running under [Anaconda]. If you don't already have this setup I highly recomend it, along with downloading this article itself as a notbook, executing and modifying the following examples. All the code below is executes here in [Juypter Notebooks].



```python
!conda list numpy
```

    # packages in environment at /Users/cjimti/anaconda3:
    #
    # Name                    Version                   Build  Channel
    numpy                     1.13.3           py36ha9ae307_4  
    numpy-base                1.14.3           py36ha9ae307_2  
    numpydoc                  0.8.0                    py36_0  


I am running numpy 1.13.3 for the following examples.

### Numpy 1.13 Resources

If you get stuck or interested in learning far more than the examples below, I suggest the following resources:

- [NumPy 1.13 Manual](https://docs.scipy.org/doc/numpy-1.13.0/contents.html)
- [NumPy 1.13 User Guide](https://docs.scipy.org/doc/numpy-1.13.0/user/index.html)
- [NumPy 1.13 Reference](https://docs.scipy.org/doc/numpy-1.13.0/reference/index.html#reference)
- [Cheat Sheet](https://www.dataquest.io/blog/numpy-cheat-sheet/)

For a deep dive on all things [NumPy] try [Scipy Lectures on Numpy](http://www.scipy-lectures.org/intro/numpy/index.html).

Why NumPy? Let's say we would like to find the mean of one hundred million random numbers:


```python
import numpy as np
```


```python
# create some random numbers
x = np.random.random(100000000)
```


```python
%%timeit -n1 -r1
sum(x) / len(x)
```

    6.52 s ± 0 ns per loop (mean ± std. dev. of 1 run, 1 loop each)



```python
%%timeit -n1 -r1
np.mean(x)
```

    65.7 ms ± 0 ns per loop (mean ± std. dev. of 1 run, 1 loop each)


We wrote less code, arguably more verbose code, and accomplished the same task over one hundred times faster. It's more code if you include the import statment, but that is long forgotton with the 100x speed increase.

Finding the mean of one hundred million random numbers is great use of NumPy, but it get's a lot more interesting with NumPy's powerful N-dimensional arrays. 

### Creating Arrays

NumPy's [array](https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.array.html) function creates n-dimentional arrays from any object exposing the array interface, an object whose __array__ method returns an array, or any (nested) sequence. 

- [Array Creation](https://docs.scipy.org/doc/numpy-1.13.0/user/basics.creation.html) Documentation


```python
x = np.array([1,2,3,4,5])

print(f'data:\n{x}')
print(f' type: {type(x)}')
print(f' size: {x.size}')
print(f'shape: {x.shape}')
```

    data:
    [1 2 3 4 5]
     type: <class 'numpy.ndarray'>
     size: 5
    shape: (5,)


Rank 2 arrays are just arrays within arrays. The outter array holds rows of column data (axis=0) arrays. Row (axis=1) index 0 is being set to [1,1,1].


```python
y = np.array([[1,1,1],[2,2,2],[3,3,3]])

print(f' data:\n{y}')
print(f' type: {type(y)}')
print(f' size: {y.size}')
print(f'shape: {y.shape}')
```

     data:
    [[1 1 1]
     [2 2 2]
     [3 3 3]]
     type: <class 'numpy.ndarray'>
     size: 9
    shape: (3, 3)


### Built-in Array Creation Functions

- [Array creation routines](https://docs.scipy.org/doc/numpy-1.13.0/reference/routines.array-creation.html) official documentation.

[np.zeros] (shape, dtype=float, order='C') returns an array or zeros in the shape specified as a [tuple].

[np.zeros]: https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.zeros.html
[tuple]:https://docs.python.org/3/tutorial/datastructures.html#tuples-and-sequences


```python
zros = np.zeros((10,12))
print(f' data:\n{zros}')
print(f' type: {type(zros)}')
print(f' size: {zros.size}')
print(f' size: {zros.dtype}')
print(f'shape: {zros.shape}')
```

     data:
    [[ 0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.]
     [ 0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.]
     [ 0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.]
     [ 0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.]
     [ 0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.]
     [ 0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.]
     [ 0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.]
     [ 0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.]
     [ 0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.]
     [ 0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.  0.]]
     type: <class 'numpy.ndarray'>
     size: 120
     size: float64
    shape: (10, 12)


[np.full] (shape, fill_value, dtype=None, order='C') will fill an array in the specified shape with the value provided. If not data type is specified one will be derrived by the input value.

[np.full]:https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.full.html


```python
f = np.full((5,5), 5)
print(f'5x5 of 5s:\n{f}\n')

print(f' size: {f.size}')
print(f'dtype: {f.dtype}')
print(f'shape: {f.shape}')
```

    5x5 of 5s:
    [[5 5 5 5 5]
     [5 5 5 5 5]
     [5 5 5 5 5]
     [5 5 5 5 5]
     [5 5 5 5 5]]
    
     size: 25
    dtype: int64
    shape: (5, 5)


Use the built in [np.eye] to create in identity matrix or build a custom diagonal with [np.diag].  

[np.eye]: https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.eye.html
[np.diag]: https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.diag.html


```python
# Identity and Diagonal Matrix
ident = np.eye(8)
print(f'Identity matrix:\n{ident}\n')

diag = np.diag([2,4,5,6,8,10,12])
print(f'Diagonal Matrix:\n{diag}\n')
```

    Identity matrix:
    [[ 1.  0.  0.  0.  0.  0.  0.  0.]
     [ 0.  1.  0.  0.  0.  0.  0.  0.]
     [ 0.  0.  1.  0.  0.  0.  0.  0.]
     [ 0.  0.  0.  1.  0.  0.  0.  0.]
     [ 0.  0.  0.  0.  1.  0.  0.  0.]
     [ 0.  0.  0.  0.  0.  1.  0.  0.]
     [ 0.  0.  0.  0.  0.  0.  1.  0.]
     [ 0.  0.  0.  0.  0.  0.  0.  1.]]
    
    Diagonal Matrix:
    [[ 2  0  0  0  0  0  0]
     [ 0  4  0  0  0  0  0]
     [ 0  0  5  0  0  0  0]
     [ 0  0  0  6  0  0  0]
     [ 0  0  0  0  8  0  0]
     [ 0  0  0  0  0 10  0]
     [ 0  0  0  0  0  0 12]]
    


### Ranges, Random and Reshaping

**Range Array Creation**
- [numpy.arange] - Returns evenly spaced values within a given interval.
- [numpy.linspace] - Returns evenly spaced numbers over a specified interval.
- [numpy.logspace] - Return numbers spaced evenly on a log scale.

**Random**
- [Random sampling] - documentation

**Reshaping Arrays**
- [numpy.reshape] - Documentation

[numpy.reshape]:https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.reshape.html
[Random sampling]:https://docs.scipy.org/doc/numpy-1.13.0/reference/routines.random.html
[numpy.arange]:https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.arange.html
[numpy.linspace]:https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.linspace.html#numpy.linspace
[numpy.logspace]:https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.logspace.html#numpy.logspace


```python
# arange rank 1 arrays
ar1 = np.arange(10)
ar2 = np.arange(50,60)
ar3 = np.arange(2,100,10)

print(f'Stop at 10:\n{ar1}\n')
print(f'Start at 50 and stop at 60:\n{ar2}\n')
print(f'Start at 2 and stop at 100 by 10:\n{ar3}\n')
```

    Stop at 10:
    [0 1 2 3 4 5 6 7 8 9]
    
    Start at 50 and stop at 60:
    [50 51 52 53 54 55 56 57 58 59]
    
    Start at 2 and stop at 100 by 10:
    [ 2 12 22 32 42 52 62 72 82 92]
    


Use [np.linspace] to return evenly spaced numbers over a specified interval. **endpoint=False** will exclude the stop value, and **retstep=True** is the spacing between samples.

[np.linspace]:https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.linspace.html


```python
lsp1 = np.linspace(0, 20, 15)
lsp2 = np.linspace(0, 20, 15, endpoint=False)

print(f'10 evenly spaced floats from .0-20.:\n{lsp1}\n')
print(f'excluding the endpoint:\n{lsp2}\n')
```

    10 evenly spaced floats from .0-20.:
    [  0.           1.42857143   2.85714286   4.28571429   5.71428571
       7.14285714   8.57142857  10.          11.42857143  12.85714286
      14.28571429  15.71428571  17.14285714  18.57142857  20.        ]
    
    excluding the endpoint:
    [  0.           1.33333333   2.66666667   4.           5.33333333
       6.66666667   8.           9.33333333  10.66666667  12.          13.33333333
      14.66666667  16.          17.33333333  18.66666667]
    


[np.reshape] gives a new shape to an array without changing its data.

[np.reshape]:https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.reshape.html


```python
r1 = np.arange(10)
r2 = np.reshape(r1, (2,5))

print(f'reshaped range of 10 to a 2x5:\n{r2}\n')
```

    reshaped range of 10 to a 2x5:
    [[0 1 2 3 4]
     [5 6 7 8 9]]
    


[NumPy Random] provides functions for simple random data, permutations and distributions. 

[NumPy Random]:https://docs.scipy.org/doc/numpy-1.13.0/reference/routines.random.html


```python
rnd1 = np.random.random((4,4))
rnd2 = np.random.randint(0,100,(5,5))

print(f'random 4x4.:\n{rnd1}\n')
print(f'random interger 5x5 between 0 and 99.:\n{rnd2}\n')
```

    random 4x4.:
    [[ 0.18782149  0.24735819  0.62014626  0.21425457]
     [ 0.99544511  0.50932097  0.25081655  0.87713039]
     [ 0.30737421  0.44161637  0.81432926  0.16024983]
     [ 0.95860737  0.35157861  0.8393971   0.25599258]]
    
    random interger 5x5 between 0 and 99.:
    [[37 65 16 31 40]
     [ 0 15 41 64 97]
     [50 79 58 37 37]
     [34 34 19 21 95]
     [84 35 86 56 37]]
    


[np.random.normal] draws random samples from a normal (Gaussian) distribution. 

Read the [Importance of data distribution in training machine learning models] to understand why we would need random numbers drawn from probability distributions.

[Importance of data distribution in training machine learning models]:https://tekmarathon.com/2015/11/13/importance-of-data-distribution-in-training-machine-learning-models/
[np.random.normal]:https://docs.scipy.org/doc/numpy-1.13.0/reference/generated/numpy.random.normal.html#numpy.random.normal


```python
# random numbers drawn from probability distributions
rn1 = np.random.normal(2,0.5, size=(10,4))
print(f'random normals with mean of 2\n and standard deviation of .5.:\n{rn1}\n')
print(f'mean: {rn1.mean()}')
print(f' std: {rn1.std()}')
```

    random normals with mean of 2
     and standard deviation of .5.:
    [[ 1.54646756  1.43589436  2.09875212  1.3974066 ]
     [ 1.08325865  2.0021442   1.47672472  2.85984543]
     [ 1.21980609  2.45491494  1.82050565  1.88821092]
     [ 1.94656678  2.0377511   2.29745424  1.84229137]
     [ 1.28723268  2.1499935   3.07733785  1.86075005]
     [ 2.32299782  2.28247921  2.19014796  1.89490517]
     [ 2.19440292  1.97758462  2.64923712  1.93849335]
     [ 2.58946891  1.7157246   2.46026935  1.95457179]
     [ 2.2315923   2.10719654  2.86608878  1.41678298]
     [ 2.04466755  1.00684125  2.36590025  2.88980114]]
    
    mean: 2.0220615601772067
     std: 0.49562922344472393


### Accessing, Deleting, and Inserting


```python
adi1 = np.arange(1,26).reshape(5,5)
print(adi1)
```

    [[ 1  2  3  4  5]
     [ 6  7  8  9 10]
     [11 12 13 14 15]
     [16 17 18 19 20]
     [21 22 23 24 25]]



```python
print(f'row 1, col 2: {adi1[0][1]}')
print(f'row 2, col 3: {adi1[2][2]}')
```

    row 1, col 2: 2
    row 2, col 3: 13



```python
# return matrix without rows 1-2
adi2 = np.delete(adi1, [1,2], axis=0)
print(f'with rows 1-2 removed:\n{adi2}')
```

    with rows 1-2 removed:
    [[ 1  2  3  4  5]
     [16 17 18 19 20]
     [21 22 23 24 25]]



```python
# return matrix without cols 1-2
adi3 = np.delete(adi1, [1,2], axis=1)
print(f'with cols 1-2 removed:\n{adi3}')
```

    with cols 1-2 removed:
    [[ 1  4  5]
     [ 6  9 10]
     [11 14 15]
     [16 19 20]
     [21 24 25]]



```python
# simple append
ap = np.arange(3)
ap = np.append(ap, [3,4])

print(f'append output: {ap}')
```

    append output: [0 1 2 3 4]



```python
print(adi1)
```

    [[ 1  2  3  4  5]
     [ 6  7  8  9 10]
     [11 12 13 14 15]
     [16 17 18 19 20]
     [21 22 23 24 25]]



```python
apnd1 = np.append(adi1, [[0,0,0,0,0]], axis=0)
apnd2 = np.append(adi1, [[0],[0],[0],[0],[0]], axis=1)

print(f'append row:\n{apnd1}\n')
print(f'append column:\n{apnd2}\n')
```

    append row:
    [[ 1  2  3  4  5]
     [ 6  7  8  9 10]
     [11 12 13 14 15]
     [16 17 18 19 20]
     [21 22 23 24 25]
     [ 0  0  0  0  0]]
    
    append column:
    [[ 1  2  3  4  5  0]
     [ 6  7  8  9 10  0]
     [11 12 13 14 15  0]
     [16 17 18 19 20  0]
     [21 22 23 24 25  0]]
    



```python
params = np.array([0,0,0,0])
params2 = np.insert(params, 2, [1,1,1])
print(f'inserting [1,1,1] at index 2:\n{params2}\n')
```

    inserting [1,1,1] at index 2:
    [0 0 1 1 1 0 0]
    



```python
ins = np.full((5,5), 0)
ins2 = np.insert(ins, 3, np.full(5, 4), axis=0)
ins3 = np.insert(ins, 3, np.full(5, 4), axis=1)

print(f'insert a row of 4s at row index 3:\n{ins2}\n')
print(f'insert a column of 4s at column index 3:\n{ins3}\n')
```

    insert a row of 4s at index 3:
    [[0 0 0 0 0]
     [0 0 0 0 0]
     [0 0 0 0 0]
     [4 4 4 4 4]
     [0 0 0 0 0]
     [0 0 0 0 0]]
    
    insert a column of 4s at index 3:
    [[0 0 0 4 0 0]
     [0 0 0 4 0 0]
     [0 0 0 4 0 0]
     [0 0 0 4 0 0]
     [0 0 0 4 0 0]]
    



```python
# stacking 
s1 = np.full((5,5), 0)
s2 = np.full((5,5), 1)
vs = np.vstack((s1, s2))
hs = np.hstack((s1, s2))

print(f'verticle stacking:\n{vs}\n')
print(f'horizontal stacking:\n{hs}\n')
```

    verticle stack:
    [[0 0 0 0 0]
     [0 0 0 0 0]
     [0 0 0 0 0]
     [0 0 0 0 0]
     [0 0 0 0 0]
     [1 1 1 1 1]
     [1 1 1 1 1]
     [1 1 1 1 1]
     [1 1 1 1 1]
     [1 1 1 1 1]]
    
    horizontal stack:
    [[0 0 0 0 0 1 1 1 1 1]
     [0 0 0 0 0 1 1 1 1 1]
     [0 0 0 0 0 1 1 1 1 1]
     [0 0 0 0 0 1 1 1 1 1]
     [0 0 0 0 0 1 1 1 1 1]]
    


### Slicing


```python
slc = np.arange(1, 21).reshape(4,5)
slc1 = slc[1:4, 2:5]
slc2 = slc[:, 1:2]
slc3 = slc[:, [0,3,4]]
cpy  = slc2.copy()

print(f'a 4x5 range:\n{slc}\n')
print(f'a slice from row 1 to 4 and cols 2 to 5:\n{slc1}\n')
print(f'a slice of all rows of column 2:\n{slc2}\n')
print(f'a slice of all rows of colums [0,3,4]:\n{slc3}\n')
print(f'a copy:\n{cpy}\n')
```

    a 4x5 range:
    [[ 1  2  3  4  5]
     [ 6  7  8  9 10]
     [11 12 13 14 15]
     [16 17 18 19 20]]
    
    a slice from row 1 to 4 and cols 2 to 5:
    [[ 8  9 10]
     [13 14 15]
     [18 19 20]]
    
    a slice all rows of column 2:
    [[ 2]
     [ 7]
     [12]
     [17]]
    
    a slice all rows of colums [0,3,4]:
    [[ 1  4  5]
     [ 6  9 10]
     [11 14 15]
     [16 19 20]]
    
    a copy:
    [[ 2]
     [ 7]
     [12]
     [17]]
    


### Boolean Indexing and Sorting


```python
seq = np.arange(25).reshape(5,5)
seq2 = seq|seq < 7
seq3 = seq[(seq > 7) & (seq < 12)]
seq4 = seq[seq % 2 < 1]

print(f'sequence from 0 to 24:\n{seq} \n')
print(f'less than 7:\n{seq2}\n')
print(f'even numbers:\n{seq4}\n')
```

    sequence from 0 to 24:
    [[ 0  1  2  3  4]
     [ 5  6  7  8  9]
     [10 11 12 13 14]
     [15 16 17 18 19]
     [20 21 22 23 24]] 
    
    less than 7:
    [[ True  True  True  True  True]
     [ True  True False False False]
     [False False False False False]
     [False False False False False]
     [False False False False False]]
    
    even numbers:
    [ 0  2  4  6  8 10 12 14 16 18 20 22 24]
    


### Arithmetic and Broadcasting

- [Mathematical functions] documentation
- [Broadcasting] documentation

[Broadcasting]:https://docs.scipy.org/doc/numpy/user/basics.broadcasting.html
[Mathematical functions]:https://docs.scipy.org/doc/numpy-1.13.0/reference/routines.math.html


```python
# rank 1 arrays
ax = np.array([1,2,3,4])
ay = np.array([5,6,7,8])

print(f'add two arrays:\n{ np.add(ax,ay) } \n')
print(f'      subtract:\n{ np.subtract(ax,ay) } \n')
print(f'      multiply:\n{ np.multiply(ax,ay) } \n')
print(f'        divide:\n{ np.divide(ax,ay) } \n')
```

    add two arrays:
    [ 6  8 10 12] 
    
          subtract:
    [-4 -4 -4 -4] 
    
          multiply:
    [ 5 12 21 32] 
    
            divide:
    [ 0.2         0.33333333  0.42857143  0.5       ] 
    



```python
# rank 2 arrays
aX = np.array([1,2,3,4]).reshape(2,2)
aY = np.array([5,6,7,8]).reshape(2,2)

print(f'add two arrays:\n{ np.add(aX,aY) } \n')
print(f'      subtract:\n{ np.subtract(aX,aY) } \n')
print(f'      multiply:\n{ np.multiply(aX,aY) } \n')
print(f'        divide:\n{ np.divide(aX,aY) } \n')
```

    add two arrays:
    [[ 6  8]
     [10 12]] 
    
          subtract:
    [[-4 -4]
     [-4 -4]] 
    
          multiply:
    [[ 5 12]
     [21 32]] 
    
            divide:
    [[ 0.2         0.33333333]
     [ 0.42857143  0.5       ]] 
    



```python
print(f'square roots:\n{ np.sqrt(aX) } \n')
print(f'exp (Euler\'s number):\n{ np.exp(aX) } \n')
print(f'average of all elements (mean):\n{ aX.mean() } \n')
print(f'average each column (mean):\n{ aX.mean(axis=0) } \n')
print(f'average each row (mean):\n{ aX.mean(axis=1) } \n')
```

    square roots:
    [[ 1.          1.41421356]
     [ 1.73205081  2.        ]] 
    
    exp (Euler's number):
    [[  2.71828183   7.3890561 ]
     [ 20.08553692  54.59815003]] 
    
    average of all elements (mean):
    2.5 
    
    average each column (mean):
    [ 2.  3.] 
    
    average each row (mean):
    [ 1.5  3.5] 
    



```python
aE = np.full((4,4), 1)
aF = np.array([1,2,3,4])
aG = np.add(aE, aF)

print(f' 4x4 of ones:\n{ aE } \n')
print(f' brodcasting sum of [1,2,3,4]:\n{ aG } \n')

```

     4x4 of ones:
    [[1 1 1 1]
     [1 1 1 1]
     [1 1 1 1]
     [1 1 1 1]] 
    
     brodcasting sum of [1,2,3,4]:
    [[2 3 4 5]
     [2 3 4 5]
     [2 3 4 5]
     [2 3 4 5]] 
    


### Mean normalization

Mean normalization scales data.

- [Normalizing inputs] - Improving Deep Neural Networks: Hyperparameter tuning, Regularization and Optimization
- [Mean Normalization] - Machine Learning
- [Feature scaling]
- [Statistics Normalization]

[Normalizing inputs]:https://www.coursera.org/learn/deep-neural-network/lecture/lXv6U/normalizing-inputs
[Mean Normalization]:https://www.coursera.org/learn/machine-learning/lecture/Adk8G/implementational-detail-mean-normalization
[Feature scaling]:https://en.wikipedia.org/wiki/Feature_scaling
[Statistics Normalization]: https://en.wikipedia.org/wiki/Normalization_(statistics)


```python
MN = np.random.randint(5000, size=(10,10))

print(f'a 10x10 of random integers 0-4999:\n{ MN } \n')
print(f'max value:\n{ MN.max() } \n')
print(f'min value:\n{ MN.min() } \n')
print(f'mean value:\n{ MN.mean() } \n')
```

    a 10x10 of random integers 0-4999:
    [[1363  941 2244 3740  131 2652 2374 2420  252 4859]
     [2902  275 4906 2677 3735 1955 2148 3565  792 2112]
     [1651 2195 1586 4975 1647  471  970  278 4116 4092]
     [1379 4697 2481 1421 3384 3528 4206 2108 2848 4494]
     [4047   43 2115 4063 3864 2261  128 2000 1633 2718]
     [ 393 2173 1442 2517 4527 3091  745  444 3053   61]
     [1145  653 3907  830  228 4055 3314 1010  936  676]
     [4846 2543 4079 2492 2817 1608  874 4627  672 3586]
     [4441 2559 3305 4077  964 4623 1594 3166 2136 4421]
     [2303  156 4824 1973  313 2170 3686 2381  342 1027]] 
    
    max value:
    4975 
    
    min value:
    43 
    
    mean value:
    2352.47 
    



```python
# average of each column
MN_ave_cols = MN.mean(axis=0, dtype=np.float64)

# standard Deviation of each column
MN_std_cols = MN.std(axis=0, dtype=np.float64)

print(f'average of each column:\n{ NM_ave_cols } \n')
print(f'standard Deviation of each column:\n{ NM_std_cols } \n')
```

    average of each column:
    [ 2369.9  2147.2  1968.4  2359.1  2340.   1867.4  2614.5  2289.4  2856.1
      2552. ] 
    
    standard Deviation of each column:
    [ 1273.86643334  1413.64400045  1386.22604217  1333.5585064   1390.563411
      1505.58043292  1436.11470642  1456.26400079  1253.61225664  1444.22394385] 
    



```python
# substract the mean from each column then divide by the standard deviation
MN_norm = (MN - MN_ave_cols) / MN_std_cols

print(f'scaled and normalized:\n{ MN_norm } \n')

print(f'old max value: { MN.max() }')
print(f'      new max: { MN_norm.max() }\n')

print(f'old min value: { MN.min() }')
print(f'      new max: { MN_norm.min() }\n')

```

    scaled and normalized:
    [[-0.51966084 -1.19801688  0.0295472   0.59720419 -1.55766063  0.57982528
       0.50089332 -0.28174638 -2.35596301  2.03185556]
     [ 0.56903781 -1.70761594  1.7431561  -0.32901124  1.04590533  0.07928253
       0.33885225  0.53620394 -1.91369783  0.13435183]
     [-0.31592776 -0.23850154 -0.39402705  1.67328703 -0.46248694 -0.98643548
      -0.50576889 -1.81192071  0.80869008  1.50204654]
     [-0.50834233  1.67593816  0.18211118 -1.42339184  0.79233938  1.20891489
       1.81442977 -0.50462892 -0.22981409  1.77973002]
     [ 1.37901829 -1.88513393 -0.05349395  0.87864124  1.13909623  0.299033
      -1.10947942 -0.58178056 -1.22491075  0.5529493 ]
     [-1.20584517 -0.25533514 -0.48672415 -0.46842278  1.61805412  0.89508822
      -0.66709297 -1.69333577 -0.06191713 -1.28238648]
     [-0.67387546 -1.41838404  1.10006996 -1.93834323 -1.48758685  1.58737405
       1.17486945 -1.28900399 -1.79576044 -0.85757222]
     [ 1.94423611  0.02777544  1.2107915  -0.49020583  0.38273286 -0.16991164
      -0.5746005   1.2948618  -2.01197898  1.15252456]
     [ 1.65773646  0.04001806  0.71254459  0.89083975 -0.95589303  1.9952769
      -0.05836346  0.25117147 -0.81294893  1.72930491]
     [ 0.1453013  -1.79867043  1.69037025 -0.94242202 -1.426182    0.23368237
       1.44159191 -0.3096067  -2.28225215 -0.61511724]] 
    
    old max value: 4975
          new max: 2.0318555579499042
    
    old min value: 43
          new max: -2.355963009127506
    


## Essential Python 3

A lot of data science in done in [Jupyter Notbooks] and libraries like [NumPy] make developing reports or documenting numerical processes. However if you a software developer like me, this code needs to run in a script on a server, in Amazon's [Lambda Function Handler] or even [kubeless] in a custom [kubernetes] cluster.

- Check out my article on [Essential Python 3] for a clean boilerplate script template to get you going.
- [Pandas] bring Python a data type equivalent to super-charged spreadsheets. Read [Python Data Essentials - Pandas][Pandas] to get a taste of this incredible library. 

[Pandas]:/python-data-essentials-pandas/
[Essential Python 3]: /essential-python3/
[kubernetes]: /hobby-cluster/
[kubeless]:https://kubeless.io/
[Jupyter Notbooks]:/golang-to-jupyter/
[Numpy]:https://docs.scipy.org/doc/numpy-1.13.0/reference/index.html
[Lambda Function Handler]:https://docs.aws.amazon.com/lambda/latest/dg/python-programming-model-handler-types.html

---
layout:     post
title:      "Python Data Essentials - Pandas"
subtitle:   "A data type equivalent to super-charged spreadsheets."
date:       2018-06-17
author:     "Craig Johnston"
URL:        "python-data-essentials-pandas/"
image:      "/img/post/columns.jpg"
twitter_image: "/img/post/columns_876_438.jpg"
tags:
- Python
- Data
- Data Science
series:
- Data Science
---

[Pandas] bring Python a data type equivalent to super-charged spreadsheets. Pandas add two highly expressive data structures to Python, [Series] and [DataFrame]. Pandas [Series] and [DataFrame]s provide a performant analysis and manipulation of “relational” or “labeled” data similar to relational database tables like MySQL or the rows and columns of Excel. [Pandas] are great for working with time series data as well as arbitrary matrix data, and unlabeled data.

<!--more-->

[Pandas] leverage [NumPy] and if you are not familiar with this fundamental library for working with numbers, then I suggest you take a look at [Python Data Essentials - NumPy][Numpy] to get a decent footing.

[Series]: https://pandas.pydata.org/pandas-docs/stable/generated/pandas.Series.html
[DataFrame]: https://pandas.pydata.org/pandas-docs/stable/generated/pandas.DataFrame.html
[NumPy]: /python-data-essentials-numpy/
[Pandas]:https://pandas.pydata.org/

{{< toc >}}

{{< content-ad >}}

If you want to go beyond this brief overview of [Pandas] I suggest the following resources:

- [10 Minutes to pandas] - Official
- [Official Tutorials]
- [Data Analysis with Python and Pandas Tutorial Introduction] - Video

[Data Analysis with Python and Pandas Tutorial Introduction]:https://www.youtube.com/watch?v=Iqjy9UqKKuo
[Official Tutorials]:http://pandas.pydata.org/pandas-docs/stable/tutorials.html
[10 Minutes to pandas]:http://pandas.pydata.org/pandas-docs/stable/10min.html

## Getting Started

In this article, I'll be working with [Pandas] version 0.22.0. If you are running a newer version, there is a possibility of interfaces changing or functionality being deprecated or replaced. I these cases a quick review of the official documentation should suffice.


```python
!conda list pandas
```

    # packages in environment at /Users/cjimti/anaconda3:
    #
    # Name                    Version                   Build  Channel
    pandas                    0.22.0           py36h0a44026_0  


## Series

[Series] data structures support integer and label based indexing. 

> One-dimensional ndarray with axis labels (including time series).

- [Series] official documentation

[Series]: https://pandas.pydata.org/pandas-docs/stable/generated/pandas.Series.html


```python
import pandas as pd

fields = ['Name','CPU', 'GHz', 'Cores','Ram','Own']
b1 = ['Orange Pi Plus','ARM Cortex-A7',1.536,4,1046,2]
board = pd.Series(data=b1, index = fields)

print(f'Series: \n{board}\n')
print(f'     Shape: {board.shape}')
print(f'Dimensions: {board.ndim}')
print(f'      Size: {board.size}')
```

    Series: 
    Name     Orange Pi Plus
    CPU       ARM Cortex-A7
    GHz               1.536
    Cores                 4
    Ram                1046
    Own                   2
    dtype: object
    
         Shape: (6,)
    Dimensions: 1
          Size: 6



```python
# check for label
print(f'Do we have GPU data? {"GPU" in board}')
print(f'Do we have CPU data? {"CPU" in board}')
```

    Do we have GPU data? False
    Do we have CPU data? True


### Accessing and Deleting Elements

- [pandas.DataFrame.iloc] - explicit selection by integer-index
- [pandas.DataFrame.loc] - explicit selection by label
- [pandas.Series.drop] - return Series with specified index labels removed.
- [Indexing and Selecting Data] official documentation.

[pandas.DataFrame.iloc]:http://pandas.pydata.org/pandas-docs/version/0.22/generated/pandas.DataFrame.iloc.html
[pandas.DataFrame.loc]: http://pandas.pydata.org/pandas-docs/version/0.22/generated/pandas.DataFrame.loc.html
[pandas.Series.drop]:https://pandas.pydata.org/pandas-docs/stable/generated/pandas.Series.drop.html
[Indexing and Selecting Data]:https://pandas.pydata.org/pandas-docs/stable/indexing.html


```python
print(f'The {board["Name"]} runs at {board["GHz"]} GHz.')
print(f'The {board[0]} has {board[3]} cores.')
print(f'The {board[0]} has {board[-1]:,} megabytes of ram.')
```

    The Orange Pi Plus runs at 1.536 GHz.
    The Orange Pi Plus has 4 cores.
    The Orange Pi Plus has 2 megabytes of ram.



```python
# select specific columns
cc = board[["CPU","Cores"]]

print(f'Series: \n{cc}\n')
print(f'     Shape: {cc.shape}')
print(f'Dimensions: {cc.ndim}')
print(f'      Size: {cc.size}')
```

    Series: 
    CPU      ARM Cortex-A7
    Cores                4
    dtype: object
    
         Shape: (2,)
    Dimensions: 1
          Size: 2



```python
# remove a column return or inplace=True
nb = board.drop("Cores")

print(f'Series: \n{nb}\n')
print(f'     Shape: {nb.shape}')
print(f'Dimensions: {nb.ndim}')
print(f'      Size: {nb.size}')
```

    Series: 
    Name    Orange Pi Plus
    CPU      ARM Cortex-A7
    GHz              1.536
    Ram               1046
    Own                  2
    dtype: object
    
         Shape: (5,)
    Dimensions: 1
          Size: 5



```python
inventory = pd.Series([1,3,2],['Orange Pi Plus', 'Raspberry Pi 3', 'Asus Tinker Board'])
print(f'Series: \n{inventory}\n')
```

    Series: 
    Orange Pi Plus       1
    Raspberry Pi 3       3
    Asus Tinker Board    2
    dtype: int64
    



```python
inventory = inventory.add(1)
print(f'Add 1 to all values: \n{inventory}\n')
```

    Add 1 to all values: 
    Orange Pi Plus       2
    Raspberry Pi 3       4
    Asus Tinker Board    3
    dtype: int64
    


#### [NumPy] on [Series] data.

[NumPy]: /python-data-essentials-numpy/
[Series]: https://pandas.pydata.org/pandas-docs/stable/generated/pandas.Series.html


```python
import numpy as np
```


```python
print(f'Square root of each item: \n{np.sqrt(inventory)}\n')
print(f'Each item to the power of 2: \n{np.power(inventory,2)}\n')
```

    Square root of each item: 
    Orange Pi Plus       1.414214
    Raspberry Pi 3       2.000000
    Asus Tinker Board    1.732051
    dtype: float64
    
    Each item to the power of 2: 
    Orange Pi Plus        4
    Raspberry Pi 3       16
    Asus Tinker Board     9
    dtype: int64
    



```python
# Orange Pi Plus and Asus Tinker Boards
inventory[['Orange Pi Plus', 'Asus Tinker Board']] * 2
```




    Orange Pi Plus       4
    Asus Tinker Board    6
    dtype: int64



### Arithmetic on Series Data


```python
containers = ['a','b','c']
items = [1,10,100]

item_containers = pd.Series(index=containers, data=items)

print(f'All: \n{item_containers}\n')
print(f'Greater than 1: \n{item_containers[item_containers > 1]}\n')
```

    All: 
    a      1
    b     10
    c    100
    dtype: int64
    
    Greater than 1: 
    b     10
    c    100
    dtype: int64
    



```python
# add 10 items to a
item_containers = item_containers.add([10,0,0])
print(f'All: \n{item_containers}\n')
```

    All: 
    a     11
    b     10
    c    100
    dtype: int64
    



```python
half_containers = item_containers / 2
print(f'Half: \n{half_containers}\n')
```

    Half: 
    a     5.5
    b     5.0
    c    50.0
    dtype: float64
    


## [DataFrames]

[DataFrames] are the central feature of [Pandas], a dictionary like data object. 

> Two-dimensional size-mutable, potentially heterogeneous tabular data structure with labeled axes (rows and columns). Arithmetic operations align on both row and column labels. Can be thought of as a dict-like container for Series objects. The primary pandas data structure.

- [pandas.DataFrame][DataFrames] official documentation.

[Pandas]:https://pandas.pydata.org/
[DataFrames]:https://pandas.pydata.org/pandas-docs/stable/generated/pandas.DataFrame.html


```python
import pandas as pd
```

### Creating

[Pandas] can create a [DataFrame] from a [NumPy] ndarray (structured or homogeneous), dict, or another DataFrame. A DataFrame with a Python [Dict] can contain [Series], arrays, constants, or list-like objects.

In the example below I create a [dictionary][Dict] that maps three indexes to three varied data sets. The fictional AI machines 'hal', 'johnny 5' and 'bender' all have different attributes with some overlap. Each of the dictionary keys contains a Pandas Series object. However, they may contain any list-like objects.

[Dict]:http://www.pythonforbeginners.com/dictionary/how-to-use-dictionaries-in-python


```python
ai = {'hal': pd.Series(data = [100, 90], index = ['intellect', 'dangerous']),
      'johnny 5': pd.Series(data = [12, 5, 2], index = ['dangerous','humor','bending']),
      'bender': pd.Series(data = [20, 50, 50, 100], index = ['intellect', 'dangerous', 'humor', 'bending'])}

df_ai = pd.DataFrame(ai)
df_ai
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>bender</th>
      <th>hal</th>
      <th>johnny 5</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>bending</th>
      <td>100</td>
      <td>NaN</td>
      <td>2.0</td>
    </tr>
    <tr>
      <th>dangerous</th>
      <td>50</td>
      <td>90.0</td>
      <td>12.0</td>
    </tr>
    <tr>
      <th>humor</th>
      <td>50</td>
      <td>NaN</td>
      <td>5.0</td>
    </tr>
    <tr>
      <th>intellect</th>
      <td>20</td>
      <td>100.0</td>
      <td>NaN</td>
    </tr>
  </tbody>
</table>
</div>




```python
print(f'     Shape: {df_ai.shape}')
print(f'Dimensions: {df_ai.ndim}')
print(f'      Size: {df_ai.size}')
print(f'Total NaNs: {df_ai.isnull().sum().sum()}')
print(f'NaN Counts: \n{df_ai.isnull().sum()}\n')

```

         Shape: (4, 3)
    Dimensions: 2
          Size: 12
    Total NaNs: 3
    NaN Counts: 
    bender      0
    hal         2
    johnny 5    1
    dtype: int64
    



```python
print(f'DataFrame Values: \n{df_ai.values}\n')
```

    DataFrame Values: 
    [[ 100.   nan    2.]
     [  50.   90.   12.]
     [  50.   nan    5.]
     [  20.  100.   nan]]
    


### Selecting

The methods [mask][pandas.DataFrame.mask] and [where][pandas.DataFrame.where] are provided by Panda's [Series] and [DataFrame] data types. See the examples below for some simple examples of value selection using basic arithmatic expressions.

- [pandas.DataFrame.mask]
- [pandas.DataFrame.where]
- [pandas.Series.mask]
- [pandas.Series.where]

[pandas.DataFrame.mask]:http://pandas.pydata.org/pandas-docs/stable/generated/pandas.DataFrame.mask.html
[pandas.Series.mask]:http://pandas.pydata.org/pandas-docs/stable/generated/pandas.Series.mask.html
[pandas.DataFrame.where]:http://pandas.pydata.org/pandas-docs/stable/generated/pandas.DataFrame.where.html
[pandas.Series.where]:http://pandas.pydata.org/pandas-docs/stable/generated/pandas.Series.where.html


```python
# mask out any data greater than 10
df_ai.mask(df_ai > 10)
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>bender</th>
      <th>hal</th>
      <th>johnny 5</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>bending</th>
      <td>NaN</td>
      <td>NaN</td>
      <td>2.0</td>
    </tr>
    <tr>
      <th>dangerous</th>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>humor</th>
      <td>NaN</td>
      <td>NaN</td>
      <td>5.0</td>
    </tr>
    <tr>
      <th>intellect</th>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
    </tr>
  </tbody>
</table>
</div>




```python
# only return data greater than 10, otherwise NaN
df_ai.where(df_ai > 10)
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>bender</th>
      <th>hal</th>
      <th>johnny 5</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>bending</th>
      <td>100</td>
      <td>NaN</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>dangerous</th>
      <td>50</td>
      <td>90.0</td>
      <td>12.0</td>
    </tr>
    <tr>
      <th>humor</th>
      <td>50</td>
      <td>NaN</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>intellect</th>
      <td>20</td>
      <td>100.0</td>
      <td>NaN</td>
    </tr>
  </tbody>
</table>
</div>




```python
# only return data greater than 10, otherwise 0
df_ai.where(df_ai > 10, 0)
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>bender</th>
      <th>hal</th>
      <th>johnny 5</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>bending</th>
      <td>100</td>
      <td>0.0</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>dangerous</th>
      <td>50</td>
      <td>90.0</td>
      <td>12.0</td>
    </tr>
    <tr>
      <th>humor</th>
      <td>50</td>
      <td>0.0</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>intellect</th>
      <td>20</td>
      <td>100.0</td>
      <td>0.0</td>
    </tr>
  </tbody>
</table>
</div>



### Modifying

The AI bots 'hal', 'johnny 5' and 'bender' share some common attributes, however where they do not, we get **nan** (not a number). Running the AI bot data through any math function would be problematic with the existence of non-numbers. Pandas give us quite a few options.

There are many options for cleaning this data. I'll start with removing any rows that contain **nan** values. We can make these adjustments with the optional parameter **inplace=True** if we wanted to modify the DataFrame in place, however for the sake of examples it is better to keep the original in-tact.


```python
# return a frame eliminating rows with NaN values
df_ai_common_rows = df_ai.dropna(axis=0)
df_ai_common_rows
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>bender</th>
      <th>hal</th>
      <th>johnny 5</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>dangerous</th>
      <td>50</td>
      <td>90.0</td>
      <td>12.0</td>
    </tr>
  </tbody>
</table>
</div>




```python
# return a frame eliminating rows with NaN values
df_ai_common_cols = df_ai.dropna(axis=1)
df_ai_common_cols
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>bender</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>bending</th>
      <td>100</td>
    </tr>
    <tr>
      <th>dangerous</th>
      <td>50</td>
    </tr>
    <tr>
      <th>humor</th>
      <td>50</td>
    </tr>
    <tr>
      <th>intellect</th>
      <td>20</td>
    </tr>
  </tbody>
</table>
</div>



Depending on requirements, no data could mean zero in our scale of 0-100. While zero is not a reasonable assumption for our AI bots, it's an easy data fix:


```python
# fill all NaNs with 0
df_ai.fillna(0)
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>bender</th>
      <th>hal</th>
      <th>johnny 5</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>bending</th>
      <td>100</td>
      <td>0.0</td>
      <td>2.0</td>
    </tr>
    <tr>
      <th>dangerous</th>
      <td>50</td>
      <td>90.0</td>
      <td>12.0</td>
    </tr>
    <tr>
      <th>humor</th>
      <td>50</td>
      <td>0.0</td>
      <td>5.0</td>
    </tr>
    <tr>
      <th>intellect</th>
      <td>20</td>
      <td>100.0</td>
      <td>0.0</td>
    </tr>
  </tbody>
</table>
</div>




```python
# forward fill rows with previous column (axis=0) data 
df_ai.fillna(method='ffill', axis=0)
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>bender</th>
      <th>hal</th>
      <th>johnny 5</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>bending</th>
      <td>100</td>
      <td>NaN</td>
      <td>2.0</td>
    </tr>
    <tr>
      <th>dangerous</th>
      <td>50</td>
      <td>90.0</td>
      <td>12.0</td>
    </tr>
    <tr>
      <th>humor</th>
      <td>50</td>
      <td>90.0</td>
      <td>5.0</td>
    </tr>
    <tr>
      <th>intellect</th>
      <td>20</td>
      <td>100.0</td>
      <td>5.0</td>
    </tr>
  </tbody>
</table>
</div>




```python
# forward fill rows with previous column (axis=0) data 
# then back fill
df_ai.fillna(method='ffill', axis=0).fillna(method='bfill', axis=0)
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>bender</th>
      <th>hal</th>
      <th>johnny 5</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>bending</th>
      <td>100</td>
      <td>90.0</td>
      <td>2.0</td>
    </tr>
    <tr>
      <th>dangerous</th>
      <td>50</td>
      <td>90.0</td>
      <td>12.0</td>
    </tr>
    <tr>
      <th>humor</th>
      <td>50</td>
      <td>90.0</td>
      <td>5.0</td>
    </tr>
    <tr>
      <th>intellect</th>
      <td>20</td>
      <td>100.0</td>
      <td>5.0</td>
    </tr>
  </tbody>
</table>
</div>



Forward (ffill) and backfilling (bfill) have far better uses in time-series data. In this case, `hal` having a danger rating of 90 should not assume that his bending ability would be 90 as well, but this example clearly illustrates the forward and backfilling capabilities of [DataFrame]'s [fillna] method.

[DataFrame]:https://pandas.pydata.org/pandas-docs/stable/generated/pandas.DataFrame.html
[fillna]:https://pandas.pydata.org/pandas-docs/version/0.22/generated/pandas.DataFrame.fillna.html

If we needed to make assumptions regarding the ability of this team of AI bots we could assume unknown data could start as an average of known data.


```python
# get the mean of data for each attribute row by column (axis=1)
df_ai.mean(axis=1)
```




    bending      51.000000
    dangerous    50.666667
    humor        27.500000
    intellect    60.000000
    dtype: float64



[pandas.DataFrame.apply] method applies the return value of a function along an axis of DataFrame, axis=1 in the example below. The function given to [pandas.DataFrame.apply] is passed the row or column depending the axis specified, the function below receives rows (because axis=1 is specified) and assigns each row to the variable "x" in which the method "mean" is called and resulting data returned from the function. 

We could have defied a named function; however this small opperation **x.fillna(x.mean())** is hardly worthy of such attention. Python's [lambda]s are one line, anonymous functions, and then used responsibly, can make the code more compact and readable at the same time. 

[pandas.DataFrame.apply]:http://pandas.pydata.org/pandas-docs/version/0.22/generated/pandas.DataFrame.apply.html
[lambda]:https://docs.python.org/3/tutorial/controlflow.html#lambda-expressions


```python
clean_df_ai = df_ai.apply(lambda x: x.fillna(x.mean()),axis=1)
clean_df_ai
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>bender</th>
      <th>hal</th>
      <th>johnny 5</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>bending</th>
      <td>100.0</td>
      <td>51.0</td>
      <td>2.0</td>
    </tr>
    <tr>
      <th>dangerous</th>
      <td>50.0</td>
      <td>90.0</td>
      <td>12.0</td>
    </tr>
    <tr>
      <th>humor</th>
      <td>50.0</td>
      <td>27.5</td>
      <td>5.0</td>
    </tr>
    <tr>
      <th>intellect</th>
      <td>20.0</td>
      <td>100.0</td>
      <td>60.0</td>
    </tr>
  </tbody>
</table>
</div>



### Sorting


```python
# order the columns by ai bot with the highest intellect
hii = clean_df_ai.sort_values(['intellect'], axis=1, ascending=False)
hii
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>hal</th>
      <th>johnny 5</th>
      <th>bender</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>bending</th>
      <td>51.0</td>
      <td>2.0</td>
      <td>100.0</td>
    </tr>
    <tr>
      <th>dangerous</th>
      <td>90.0</td>
      <td>12.0</td>
      <td>50.0</td>
    </tr>
    <tr>
      <th>humor</th>
      <td>27.5</td>
      <td>5.0</td>
      <td>50.0</td>
    </tr>
    <tr>
      <th>intellect</th>
      <td>100.0</td>
      <td>60.0</td>
      <td>20.0</td>
    </tr>
  </tbody>
</table>
</div>




```python
print(f'The bot with the highest intelligence is {hii.columns[0]}.')
print(f'The bot with the lowest intelligence is {hii.columns[-1]}.')
```

    The bot with the highest intelligence is hal.
    The bot with the lowest intelligence is bender.


I doubt that `johnny 5` is more intelligent than `bender` but his data was unknown and therefore derived by using a mean, so the score is mathematically correct.

I won't attempt even to scratch the surface of sorting functions and their parameters provided by [DataFrame]s. This article is only intended to give you a taste and get you going.

### Math

Use [NumPy] to perform any number of arithmetic operations on the values of a [DataFrames]. I suggest you take a look at my article [Python Data Essentials - Pandas][Numpy] for an overview of this compelling data science library.


## Essential Python 3

A lot of data science in done in [Jupyter Notbooks] and libraries like [NumPy] make developing reports or documenting numerical processes. However if you a software developer like me, this code needs to run in a script on a server, in Amazon's [Lambda Function Handler] or even [kubeless] in a custom [kubernetes] cluster.

Check out my article on [Essential Python 3] for a clean boilerplate script template to get you going.

[Essential Python 3]: /essential-python3/
[kubernetes]: /hobby-cluster/
[kubeless]:https://kubeless.io/
[Jupyter Notbooks]:/golang-to-jupyter/
[Numpy]:/python-data-essentials-numpy/
[Lambda Function Handler]:https://docs.aws.amazon.com/lambda/latest/dg/python-programming-model-handler-types.html
[DataFrame]:https://pandas.pydata.org/pandas-docs/stable/generated/pandas.DataFrame.html

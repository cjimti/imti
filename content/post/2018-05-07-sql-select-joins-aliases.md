---
layout:     post
title:      "SQL Foundations"
subtitle:   "Selects, joins and aliases."
date:       2018-04-02
author:     "Craig Johnston"
URL:        "sql-select-joins-aliases/"
image:      "/img/post/buckets.jpg"
twitter_image: "/img/post/buckets_876_438.jpg"
tags:
- SQL
- Data
- Database
---


The following is an attempt at explaining the basics of an SQL query, and more importantly how I believe you can best think through them. All queries can be broken down into the basics of this declarative language.

I recently helped a co-worker read through a large SQL query with a few dozen joins and left joins, alias, and recursions. He is mostly a front-end integrator and although he has been tinkering with SQL for years, he never really understood the basics. I realize that unless you have to write SQL, many front-end developers work from the API layer, where database interaction has been highly abstracted, and with only brief interactions, many do not realize how easy it is to know the fundamentals. I do not address subqueries, stored procedures or vendor-specific syntax. This example is just the foundation, yet everything builds up from it and can be broken down into it.

###  The Foundation

Declaring what you want by selecting, joining, and aliasing in the development of readable SQL queries.

```sql
SELECT [what] FROM [location] WHERE [a condition is true]
```

**[what]** is the columns you want back. The statement "SELECT *" litters hundreds of examples and is often scattered though sloppy code. "SELECT *" is generally an anti-pattern, it hides your dependencies, even if you genuinely want everything, it is not clear in that statement what everything is. SQL is declarative and so you should declare something, rather than being vague.

### Designing a Query

Start with the analog. A proper database schema is going to be as generic as possible, typically to accommodate a broader set of requirements than your specific query. Design the query to declare what you want from the database and use aliases to abstract the underlying implementation.

### The Analog
We are going to make a [Paleo Bowl](https://www.stupideasypaleo.com/2017/03/02/bitchin-bowl-recipe/) (I live on these things.) For this meal, we need meat, vegetable, and dressing.  So I might start my query like this.

```sql
SELECT meat, price
```

I know what it is that I want, so I declare it. I know I can get it at the grocery store in the meat aisle, so I declare that as well.

```sql
SELECT meat FROM meat_aisle
```

I have some preferences, so I declare a specific as a condition.

```sql
SELECT meat, price FROM meat_aisle WHERE meat_type = "tri-tip"
```

The example above is an analog, stores in my area do not take orders directly via SQL, although they nearly all do in their inventory and point-of-sale systems. I can take this abstract query and make it concrete. In fact, this is how I design all my queries.  I start with an abstract query based on my requirements, and refactor back to the physical entities. This use of abstraction is what makes aliases so great. However, I often see them used merely to make code smaller, and I think that is a shame. Today I saw a query on a [Drupal](https://www.drupal.org/) module use an alias to reduce a table called field_collection_field_data_value to fcfdv. That is like Mr. [Solzhenitsyn](https://amzn.to/2FSgfbq) asking you to call him slzhntsyn for short; it got shorter but not easier.

### The Implementation

Here is how I use aliases, I start with them, by keeping my straw query above but tying it to a real table. The database has a table called “product” however to my analog example it is a meat aisle, so I declare it as such with an alias.


```sql
SELECT meat, price FROM product AS meat_aisle
```

"product" does not have a column called meat. In this database, it is called type. I use meat to alias type, since that is the condition I will be putting on it.

```sql
SELECT meat_aisle.type AS meat, meat_aisle.price as price
FROM product AS meat_aisle
WHERE meat_aisle.type = "tri-tip"
```

**Output:**
```plain
meat, price
tri-tip, 699
```

It might seem strange at first to alias the beautifully generic product table to a specific like "meat." However, I know I need other ingredients and may be joining the same product table multiple times, and calling "product," "product2" is a terrible thing, but encountered too often. SQL is a declarative language for humans to interact with databases. The SQL should be readable by both.

My query should not be concerned about describing the underlying schema; the database does a great job at that.  My query is best understood by clearly representing what I am trying to accomplish with it.

### Mastery

If you are interested in really mastering SQL, I can highly recommend three books that got me through some of the most incredibly intricate database designs with challenging and unique requirements. Thanks to [Joe Celko](https://amzn.to/2rs09jC), I have successfully developed numerous queries that have been efficiently processing millions of records every day for over a decade.

- [Joe Celko's SQL for Smarties](https://amzn.to/2wn5232)
- [Joe Celko's Trees and Hierarchies in SQL for Smarties](https://amzn.to/2KFBL6J)
- [Joe Celko's Thinking in Sets: Auxiliary, Temporal, and Virtual Tables in SQL](https://amzn.to/2Im8NdT)

{{< content-ad >}}

[![celko](/images/content/celko.png)](https://amzn.to/2rs09jC)
ruby-object-table
=================

[![Gem Version](https://badge.fury.io/rb/object_table.svg)](http://badge.fury.io/rb/object_table)
[![Build Status](https://travis-ci.org/lincheney/ruby-object-table.svg?branch=master)](https://travis-ci.org/lincheney/ruby-object-table)
[![Code Climate](https://codeclimate.com/github/lincheney/ruby-object-table/badges/gpa.svg)](https://codeclimate.com/github/lincheney/ruby-object-table)
[![Coverage Status](https://coveralls.io/repos/lincheney/ruby-object-table/badge.svg?branch=master)](https://coveralls.io/r/lincheney/ruby-object-table?branch=master)

Simple data table/frame implementation in ruby.
Probably slow and extremely inefficient, but it works and that's all that matters.
Uses NArrays (https://github.com/masa16/narray) for storing data.

Be sure to check out the [release notes](https://github.com/lincheney/ruby-object-table/releases).

## Creating a table

Just pass a hash of columns into the constructor.
You can use vectors types (Array, NArray, Range) or scalars (basically anything else).

### Initialising with vector types

```ruby
>>> ObjectTable.new(array: [1, 2, 3], narray: NArray[4, 5, 6], range: 7..9)
 => ObjectTable(3, 3)
       array  narray  range
  0:       1       4      7
  1:       2       5      8
  2:       3       6      9
       array  narray  range 

# columns with uneven lengths gives an error
>>> ObjectTable.new(a: [1, 2, 3], b: [4, 5, 6, 7])
RuntimeError: Differing number of rows: [3, 4]
```

### With scalar types

With all scalar columns, a one-row table is assumed
```ruby
>>> ObjectTable.new(a: 1, b: 2)
 => ObjectTable(1, 2)
       a  b
  0:   1  2
       a  b 
```

Otherwise the scalars are extended to match the length of the vector columns
```ruby
>>> ObjectTable.new(a: [1, 2, 3], b: 100)
 => ObjectTable(3, 2)
       a    b
  0:   1  100
  1:   2  100
  2:   3  100
       a    b 
```

## Methods

- `#ncols` returns the number of columns
- `#nrows` returns the number of rows
- `#colnames` returns an array of the column names
- `#clone` make a copy of the table
- `#stack(table1, table2, ...)` appends the supplied tables
- `#apply(&block)` evaluates `block` in the context of the table
- `#where(&block)` filters the table
- `#group_by(&block)` splits the table into groups

For any methods taking a block, when passing a block which takes an argument, the block will be called with the table as the argument, otherwise (block with no arguments), the block is `#instance_eval`ed in the context of the block.

```ruby
>>> data = ObjectTable.new
# block with argument, binding is preserved
>>> data.apply{|tbl| self.class }
Object
>>> data.apply{ self.class }
ObjectTable
```

### Getting columns

You can get a column by using `#[]` or using the column name as a method.

```ruby
>>> data = ObjectTable.new(a: [1, 2, 3], b: 100, c: ['a', 'b', 'c'])

# using a method
>>> data.a
 => NArray.int(3): 
[ 1, 2, 3 ] 

# ... or using []
>>> data[:a]
 => NArray.int(3): 
[ 1, 2, 3 ] 
```

### Setting columns

You can set/add columns by using `#[]=`. This works for both vectors and scalars. Scalars are given a default type of object.

```ruby
>>> data = ObjectTable.new(a: [1, 2, 3], b: 100, c: ['a', 'b', 'c'])

# replace an old column with a vector
>>> data[:a] = [4, 5, 6]
>>> data
 => ObjectTable(3, 3)
       a    b    c
  0:   4  100  "a"
  1:   5  100  "b"
  2:   6  100  "c"
       a    b    c 

# ... or with a scalar
>>> data[:c] = "scalar string"
>>> data
 => ObjectTable(3, 3)
       a    b                c
  0:   4  100  "scalar string"
  1:   5  100  "scalar string"
  2:   6  100  "scalar string"
       a    b                c 

# ... and do the same for a new column
>>> data[:new_column] = 10...13
>>> data
 => ObjectTable(3, 4)
       a    b                c  new_column
  0:   4  100  "scalar string"          10
  1:   5  100  "scalar string"          11
  2:   6  100  "scalar string"          12
       a    b                c  new_column 

# ... but make sure they have the right length
>>> data[:a] = [1, 2, 3, 4]
IndexError: dst.shape[0]=3 != src.shape[0]=4
>>> data[:another_column] = [1, 2, 3, 4]
IndexError: dst.shape[0]=3 != src.shape[0]=4
```

#### `#set_column(name, value, typecode='object', shape...)`

`#[]=` really just calls `#set_column`, but you can have more control over the columns by calling `#set_column` yourself and adding additional arguments. Additional arguments control the shape and type of the column. They are the same as for `NArray.new`

```ruby
>>> data = ObjectTable.new(col0: [0]*3)
>>> data[:col1] = [1, 2, 3]
>>> data.col1
 => NArray.int(3): 
[ 1, 2, 3 ] 

# this time, let's make it a float instead
>>> data.set_column(:col2, [1, 2, 3], 'float')
>>> data.col2
 => NArray.float(3): 
[ 1.0, 2.0, 3.0 ] 

>>> data[:col3] = 4
>>> data.col3
 => NArray.object(3): 
[ 4, 4, 4 ] 

# this time, let's make it multi dimensional
>>> data.set_column(:col4, 4, 'int', 5)
>>> data.col4
 => NArray.int(5,3): 
[ [ 4, 4, 4, 4, 4 ], 
  [ 4, 4, 4, 4, 4 ], 
  [ 4, 4, 4, 4, 4 ] ] 
```

### Operating on columns

All standard NArray operations apply (addition, subtraction etc.)
Missing methods are vectorised over the column. (NOTE: this feature has been removed in v0.3.0)

```ruby
>>> data = ObjectTable.new(column: ['abc', 'bcd', 'cde'])
>>> data.column.match(/bc/)
 => NArray.object(3): 
[ #<MatchData "bc">, #<MatchData "bc">, nil ] 
```

### `#apply`

This is just a convenience method.

```ruby
>>> data = ObjectTable.new(a: [1, 2, 3], b: [4, 5, 6])

# this is exactly the same as (data.a + data.b)
>>> data.apply{ a + b }
 => NArray.int(3): 
[ 5, 7, 9 ] 

# you can use self to set/add columns
>>> data.apply{ self[:c] = a * b }
>>> data
 => ObjectTable(3, 3)
       a  b   c
  0:   1  4   4
  1:   2  5  10
  2:   3  6  18
       a  b   c

# if you don't want it to steal the binding (self), make the block take an argument
>>> data.apply{|tbl| tbl.a + tbl.c }
 => NArray.int(3): 
[ 5, 12, 21 ] 
```

If you return a grid (e.g. through the `@R` shortcut) it will be coerced to a table.

```ruby
>>> data = ObjectTable.new(a: [1, 2, 3], b: [4, 5, 6])
# let's make a new table but with a=a*3
>>> data.apply{ @R[a: a*3, b: b] }
 => ObjectTable(3, 2)
       a  b
  0:   3  4
  1:   6  5
  2:   9  6
       a  b 

# or if you called apply expecting an argument
>>> data.apply{|tbl| tbl.R[a: tbl.a*3, b: tbl.b] }
 => ObjectTable(3, 2)
       a  b
  0:   3  4
  1:   6  5
  2:   9  6
       a  b 
```

## Filtering

Use the `#where` method and pass a filtering block.
This creates a `View`, which syncs with the parent table.
This means any changes made to the parent also affect the view.

```ruby
>>> data = ObjectTable.new(a: 0...5, b: 5...10)
>>> a_lt_3 = data.where{ a < 3 }
 => ObjectTable::View(3, 2)
       a  b
  0:   0  5
  1:   1  6
  2:   2  7
       a  b 

# update the parent table
>>> data[:b] = data.b.reverse
# and the view gets updated too
>>> a_lt_3
 => ObjectTable::View(3, 2)
       a  b
  0:   0  9
  1:   1  8
  2:   2  7
       a  b 

# you can also chain #where calls
>>> data.where{ a < 3 }.where{ b > 7 }
 => ObjectTable::View(3, 2)
       a  b
  0:   0  9
  1:   1  8
       a  b 
# which is the same as
>>> data.where{ a < 3 && b > 7 }
```

Any changes made to the view also affect the parent.

```ruby
>>> data.where{ a < 3 }[:b] = 100
>>> data
 => ObjectTable(5, 2)
       a    b
  0:   4    5
  1:   3    6
  2:   2  100
  3:   1  100
  4:   0  100
       a    b 

# changes made to chained filters are propagated too
>>> data.where{ a > 3 }.where{ b < 100 }[:b] = -100
>>> data
 => ObjectTable(5, 2)
       a     b
  0:   4  -100
  1:   3     6
  2:   2   100
  3:   1   100
  4:   0   100
       a     b 
```

### Adding new columns

Added columns have a default value of `nil` outside the view.

```ruby
>>> data = ObjectTable.new(a: 0...5, b: 5...10)
# where a < 3, c will be 5, elsewhere it will be nil
>>> data.where{ a < 3 }[:c] = 5
>>> data
 => ObjectTable(5, 3)
       a  b    c
  0:   0  5    5
  1:   1  6    5
  2:   2  7    5
  3:   3  8  nil
  4:   4  9  nil
       a  b    c 
```

### `#apply`

Using `#apply` creates a `StaticView`. Any modifications made to the parent will not refresh the static view. Changes to the static view still affect the parent however.

```ruby
>>> data = ObjectTable.new(a: 0...5, b: 5...10)

>>> a_lt_3 = data.where{ a < 3 }
 => ObjectTable::View(3, 2)
       a  b
  0:   0  5
  1:   1  6
  2:   2  7
       a  b 
>>> a_lt_3[:a] = 5
# our view will refresh, so we can't see the changes!
>>> a_lt_3
 => ObjectTable::View(0, 2)
    a  b
    a  b 

# use apply instead
>>> data = ObjectTable.new(a: 0...5, b: 5...10)
>>> data.where{a < 3}.apply{ self[:a] = 5; p self; nil }
ObjectTable::StaticView(3, 2)
       a  b
  0:   5  5
  1:   5  6
  2:   5  7
       a  b
 => nil 
```

You should never try to use a static view outside of its `#apply` block.


### Other notes

If you want to filter a table and keep that data (i.e. without it syncing with the parent, propagating changes etc.) just `#clone` it.


## Grouping (and aggregating)

Use the `#group_by` method and pass column names or a block that returns grouping keys.

```ruby
# group by column_1
>>> data.group_by(:column_1)
# or group by a dynamically calculated value
# note the double braces is actually a hash inside a block 
>>> data.group_by{{ key: column_1.round }}
```

This gives you a `ObjectTable::Grouping`.
There are two ways to perform aggregation with a grouping: using `apply`/`each` or using `reduce`.

Using `apply`/`each` is the most flexible and powerful.
It iterates through each group and calls a supplied block for each group.

`reduce` instead iterates through each *row* and keeps track of which group the row belongs to.
It can only be used with (online algorithms)[http://en.wikipedia.org/wiki/Online_algorithm]
but can be much faster if there is a large number of groups (relative to the number of rows).

### Using `apply`/`each`

`each` enumerates through the groups.
`apply` is similar to doing `grouping.each.map` but instead of collecting results in an `Array`
the results are stacked into a new table.

```ruby
# let's create some data
>>> data = ObjectTable.new(col1: 1..10, col2: (1..20).step(2).to_a)
  => ObjectTable(10, 2)
       col1  col2
  0:      1     1
  1:      2     3
  2:      3     5
  3:      4     7
  4:      5     9
  5:      6    11
  6:      7    13
  7:      8    15
  8:      9    17
  9:     10    19
       col1  col2 

# print sum of col2 for col1 remainder 3
>>> data.group_by{{ rem: col1 % 3 }}.each{ p col2.sum }; nil
40
27
33

# which sum is which group?
# we can access the group keys through @K
>>> data.group_by{{ rem: col1 > 0 }}.each{ p [@K.rem, col2.sum] }; nil
[1, 40]
[2, 27]
[0, 33]

# collect results into an array
# note that we need an argument to the map block
>>> data.group_by{{ rem: col1 % 3 }}.each.map{|grp| [grp.K.rem, grp.col2.sum] }
 => [[1, 40], [2, 27], [0, 33]]

# collect the results into a new table using apply()
>>> data.group_by{{ rem: col1 % 3 }}.apply{ col2.sum }
 => ObjectTable(3, 2)
       rem  v_0
  0:     1   40
  1:     2   27
  2:     0   33
       rem  v_0 

# aggregated columns are given default names of v_0, v_1, etc.
# let's set the names ourselves
>>> data.group_by{{ rem: col1 % 3 }}.apply{ @R[sum: col2.sum] }
 => ObjectTable(3, 2)
       rem  sum
  0:     1   40
  1:     2   27
  2:     0   33
       rem  sum 
```

We can also assign new columns based on the group (you cannot do this with `reduce`).

```ruby
>>> data.group_by{{ rem: col1 % 3 }}.each{ self[:sum] = col2.sum }
>>> data
 => ObjectTable(10, 3)
       col1  col2  sum
  0:      1     1   40
  1:      2     3   27
  2:      3     5   33
  3:      4     7   40
  4:      5     9   27
  5:      6    11   33
  6:      7    13   40
  7:      8    15   27
  8:      9    17   33
  9:     10    19   40
       col1  col2  sum 
```

### Using `reduce`

`reduce` returns a new table like `apply`
(and there is no equivalent for `each`, i.e. iterating through groups).

Pass a block to `reduce`; you will have access to the `@R` variable
which is a group-specific hash where you can accumulate results.
See the examples below.

```ruby
# sum of column 2
>>> data.group_by{{ rem: col1 % 3 }}.reduce{ @R[:sum] += col2 }
 => ObjectTable(3, 2)
       rem  sum
  0:     1   40
  1:     2   27
  2:     0   33
       rem  sum

# we can supply initial values, e.g. if we wish to calculate product
>>> data.group_by{{ rem: col1 % 3 }}.reduce(prod: 1){ @R[:prod] *= col2 }
 => ObjectTable(3, 2)
       rem  prod
  0:     1  1729
  1:     2   405
  2:     0   935
       rem  prod 
```

You should avoid reduce unless your aggregating operation is simply
and you have a relatively large number of groups
(`reduce` is slower than `apply` with few groups).

### Comparison of `apply` and `reduce`

The `reduce` version is more complicated because we must implement the
online algorithm ourselves.

#### Sum 

```ruby
>>> data.group_by{{ rem: col1 % 3 }}.apply{ @R[sum: col2.sum] }
>>> data.group_by{{ rem: col1 % 3 }}.reduce{ @R[:sum] += col2 }
```

#### Product

```ruby
>>> data.group_by{{ rem: col1 % 3 }}.apply{ @R[prod: col2.prod] }
>>> data.group_by{{ rem: col1 % 3 }}.reduce(prod: 1){ @R[:prod] *= col2 }
```

#### Variance

Online algorithm for variance taken from: 
http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Online_algorithm

```ruby
>>> data.group_by{{ rem: col1 % 3 }}.apply{ @R[var: col2.stddev**2] }
>>> data.group_by{{ rem: col1 % 3 }}.reduce(n: 0, mean: 0.0, m2: 0) do
      @R[:n] += 1
      delta = col2 - @R[:mean]
      @R[:mean] += delta / @R[:n]
      @R[:m2] += delta * (col2 - @R[:mean])
    end.apply{ @R[rem: rem, variance: m2 / (n - 1)] }
```

## Joining

Note the current joining algorithm is quite slow.

```ruby
# let's create some data
>>> left = ObjectTable.new( key: [1, 2, 3, 5, 7], val_1: 1..5 )
>>> right = ObjectTable.new( key: [2, 3, 4, 5], val_2: 'a'..'d')

# inner join
>>> left.join(right, :key)
  => ObjectTable(3, 3)
       key  val_1  val_2
  0:     2      2    "a"
  1:     3      3    "b"
  2:     5      4    "d"
       key  val_1  val_2 

# left join
>>> left.join(right, :key, type: 'left')
 => ObjectTable(5, 3)
       key  val_1  val_2
  0:     1      1    nil
  1:     2      2    "a"
  2:     3      3    "b"
  3:     5      4    "d"
  4:     7      5    nil
       key  val_1  val_2 

# right join
>>> left.join(right, :key, type: 'right')
 => ObjectTable(4, 3)
       key  val_1  val_2
  0:     2      2    "a"
  1:     3      3    "b"
  2:     5      4    "d"
  3:     4      0    "c"
       key  val_1  val_2 

# outer join
>>> left.join(right, :key, type: 'outer')
 => ObjectTable(6, 3)
       key  val_1  val_2
  0:     1      1    nil
  1:     2      2    "a"
  2:     3      3    "b"
  3:     5      4    "d"
  4:     7      5    nil
  5:     4      0    "c"
       key  val_1  val_2 
```

## Subclassing ObjectTable

The act of subclassing itself is easy, but any methods you add won't be available to child views and groups.

```ruby
>>> class BrokenTable < ObjectTable
      def a_plus_b
        a + b
      end
    end
...

>>> data = BrokenTable.new(a: 1..3, b: 4..6)
>>> data.a_plus_b
 => NArray.int(3): 
[ 5, 7, 9 ] 

# this won't work!
>>> data.where{ a > 1 }.a_plus_b
NoMethodError: undefined method `a_plus_b' for #<ObjectTable::View:0x000000011d4dd0>
```

The easiest way to make it work is to put your methods into a mixin
and use the `fully_include` class method.

```ruby
>>> class WorkingTable < ObjectTable
      module Mixin
        def a_plus_b
          a + b
        end
      end

      fully_include Mixin
    end
...

>>> data = WorkingTable.new(a: 1..3, b: 4..6)
>>> data.a_plus_b
 => NArray.int(3): 
[ 5, 7, 9 ] 

# hurrah!
>>> data.where{ a > 1 }.a_plus_b
 => ObjectTable::MaskedColumn.int(2): 
[ 7, 9 ] 

```

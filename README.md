ruby-object-table
=================

Simple data table/frame implementation in ruby
Probably slow and extremely inefficient, but it works and that's all that matters.
Uses NArrays (https://github.com/masa16/narray) for storing data.

## Creating a table

Just pass a hash of columns into the constructor.
You can use vectors types (Array, NArray, Range) or scalars (basically anything else).

```ruby
>>> ObjectTable.new(a: [1, 2, 3], b: ['array', 'of', 'strings'], c: :a_repeated_scalar)
 => ObjectTable(3, 3)
       a          b                   c
  0:   1    "array"  :a_repeated_scalar
  1:   2       "of"  :a_repeated_scalar
  2:   3  "strings"  :a_repeated_scalar
       a          b                   c 
```

### With vector types

```ruby
# with data in arrays
>>> ObjectTable.new(a: [1, 2, 3], b: [4, 5, 6])
 => ObjectTable(3, 2)
       a  b
  0:   1  4
  1:   2  5
  2:   3  6
       a  b

# ... or narrays
>>> ObjectTable.new(a: NArray[1, 2, 3], b: NArray[4, 5, 6])

# ... or ranges
>>> ObjectTable.new(a: 1..3, b: 4..6)

# ... or a mixture
>>> ObjectTable.new(a: [1, 2, 3], b: NArray[4, 5, 6], c: 7..9)
 => ObjectTable(3, 3)
       a  b  c                                       
  0:   1  4  7                                       
  1:   2  5  8                                       
  2:   3  6  9                                       
       a  b  c

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

Otherwise the scalars are extended to match the lentgh of the vector columns
```ruby
>>> ObjectTable.new(a: [1, 2, 3], b: 100)
 => ObjectTable(3, 2)
       a    b
  0:   1  100
  1:   2  100
  2:   3  100
       a    b 
```

### Clone

You can also clone another object table.

## Columns

### Extracting columns

```ruby
>>> data = ObjectTable.new(a: [1, 2, 3], b: 100, c: ['a', 'b', 'c'])

# using a method
>>> data.a
 => ObjectTable::Column.int(3): 
[ 1, 2, 3 ] 

# ... or using []
>>> data[:a]
 => ObjectTable::Column.int(3): 
[ 1, 2, 3 ] 
```

### Setting columns

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

### Operating on columns

All standard NArray operations apply (addition, subtraction etc.)
Missing methods are vectorised over the column

```ruby
>>> data = ObjectTable.new(column: ['abc', 'bcd', 'cde'])
>>> data.column.match(/bc/)
 => ObjectTable::Column.object(3): 
[ #<MatchData "bc">, #<MatchData "bc">, nil ] 
```

### `#apply`

There is a convenience method `#apply` for operating on tables.
It basically `#instance_eval`s the block passed to it.

```ruby
>>> data = ObjectTable.new(a: [1, 2, 3], b: [4, 5, 6])
>>> data.apply{ a + b}
 => ObjectTable::Column.int(3): 
[ 5, 7, 9 ] 
>>> data.apply{ self[:c] = a * b }
>>> data
 => ObjectTable(3, 3)
       a  b   c
  0:   1  4   4
  1:   2  5  10
  2:   3  6  18
       a  b   c 
```

## Filtering

User the `#where` method and pass a block (as for `#apply`).
This creates a `TempView` which syncs with the parent table.

```ruby
>>> data = ObjectTable.new(a: 0...5, b: 5...10)
>>> a_lt_3 = data.where{ a < 3 }
 => ObjectTable::TempView(3, 2)
       a  b
  0:   0  5
  1:   1  6
  2:   2  7
       a  b 

# update the parent table
>>> data[:a] = data.a.reverse
>>> a_lt_3
 => ObjectTable::TempView(3, 2)
       a  b
  0:   2  7
  1:   1  8
  2:   0  9
       a  b 

# you can also chain #where calls
>>> data.where{ a < 3 }.where{ b > 5 }
 => ObjectTable::TempView(3, 2)
       a  b
  0:   2  7
  1:   1  8
  2:   0  9
       a  b 
# which is the same as
>>> data.where{ a < 3 && b > 5 }
```

Changes are propagated to the parent.

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

You can also use `#apply` on a view/filtered table.

```ruby
>>> data = ObjectTable.new(a: 0...5, b: 5...10)
>>> data.where{ a < 3 }.apply{ a + b }
 => ObjectTable::Column.int(3): 
[ 5, 7, 9 ] 

>>> data.where{ a < 3 }.apply{ self[:c] = a + b  }
>>> data
 => ObjectTable(5, 3)
       a  b    c
  0:   0  5    5
  1:   1  6    7
  2:   2  7    9
  3:   3  8  nil
  4:   4  9  nil
       a  b    c 
```

### Cloning

If you want to filter a table and keep that data (i.e. without it syncing with the parent, propagating changes etc.) just use the `#clone` method.

## Grouping (and aggregating)

Grouping is similar to filtering, but with the `#group` method.
You can then call `#each` to iterate through the groups or `#apply` if you want to aggregate the results into a table.

The argument to `#group` should be a hash mapping key name => key. See the below example.

```ruby
>>> data = ObjectTable.new(a: [1] * 4 + [0] * 4, b: 0...8)
 => ObjectTable(8, 2)
       a  b
  0:   1  0
  1:   1  1
  2:   1  2
  3:   1  3
  4:   0  4
  5:   0  5
  6:   0  6
  7:   0  7
       a  b 

>>> data.group{ {b_odd: b % 2} }.each{ p b }
ObjectTable::MaskedColumn.int(4): 
[ 0, 2, 4, 6 ]
ObjectTable::MaskedColumn.int(4): 
[ 1, 3, 5, 7 ]

>>> data.group{ {b_odd: b % 2} }.apply{ b.sum }
 => ObjectTable(2, 2)
       b_odd  v_0
  0:       0   12
  1:       1   16
       b_odd  v_0 
```

### Aggregation

Normally you can only have one aggregated column with a default name of v_0.
You can have more columns and set column names by making a `ObjectTable` or using the @R shortcut.

```ruby
>>> data = ObjectTable.new(a: [1] * 4 + [0] * 4, b: 0...8)

>>> data.group{ {b_odd: b % 2} }.apply{ @R[ b_sum: b.sum, b_mean: b.mean, count: nrows, a_sum: a.sum] }
 => ObjectTable(2, 5)
       b_odd  b_sum  b_mean  count  a_sum
  0:       0     12     3.0      4      2
  1:       1     16     4.0      4      2
       b_odd  b_sum  b_mean  count  a_sum 
```

### Assigning to columns

Assigning to columns will assign by group.

```ruby
>>> data = ObjectTable.new(a: [1] * 4 + [0] * 4, b: 0...8)

>>> data.group{ {b_odd: b % 2} }.each{ self[:b_sum] = b.sum }
>>> data
 => ObjectTable(8, 3)
       a  b  b_sum
  0:   1  0     12
  1:   1  1     16
  2:   1  2     12
  3:   1  3     16
  4:   0  4     12
  5:   0  5     16
  6:   0  6     12
  7:   0  7     16
       a  b  b_sum 
```

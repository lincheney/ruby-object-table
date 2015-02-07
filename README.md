ruby-object-table
=================

Simple data table/frame implementation in ruby
Probably slow and extremely inefficient, but it works and that's all that matters.
Uses NArrays (https://github.com/masa16/narray) for storing data.

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
- `#stack(table1, table2, ...)` appends then supplied tables
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
 => ObjectTable::Column.int(3): 
[ 1, 2, 3 ] 

# ... or using []
>>> data[:a]
 => ObjectTable::Column.int(3): 
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
 => ObjectTable::Column.int(3): 
[ 1, 2, 3 ] 

# this time, let's make it a float instead
>>> data.set_column(:col2, [1, 2, 3], 'float')
>>> data.col2
 => ObjectTable::Column.float(3): 
[ 1.0, 2.0, 3.0 ] 

>>> data[:col3] = 4
>>> data.col3
 => ObjectTable::Column.object(3): 
[ 4, 4, 4 ] 

# this time, let's make it multi dimensional
>>> data.set_column(:col4, 4, 'int', 5)
>>> data.col4
 => ObjectTable::Column.int(5,3): 
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
 => ObjectTable::Column.object(3): 
[ #<MatchData "bc">, #<MatchData "bc">, nil ] 
```

### `#apply`

This is just a convenience method.

```ruby
>>> data = ObjectTable.new(a: [1, 2, 3], b: [4, 5, 6])

# this is exactly the same as (data.a + data.b)
>>> data.apply{ a + b }
 => ObjectTable::Column.int(3): 
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
 => ObjectTable::Column.int(3): 
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
Then call `#each` to iterate through the groups or `#apply` to aggregate the results.

The argument to `#group_by` should be a hash mapping key name => key. See the below example.

```ruby
>>> data = ObjectTable.new(name: ['John', 'Tom', 'John', 'Tom', 'Jim'], value: 1..5)
 => ObjectTable(5, 2)
         name  value
  0:   "John"      1
  1:    "Tom"      2
  2:   "John"      3
  3:    "Tom"      4
  4:    "Jim"      5
         name  value

# group by the name and get the no. of rows in each group
>>> num_rows = []
>>> data.group_by(:name).each{ num_rows.push(nrows) }
>>> num_rows
 => [2, 2, 1]
 
# or group with a block
>>> num_rows = []
# let's group by initial letter of the name
>>> data.group_by{ {initial: name.map{|n| n[0]}} }.each{ num_rows.push(nrows) }
>>> num_rows
 => [3, 2]
```

The group keys are accessible through the `@K` shortcut

```ruby
>>> data = ObjectTable.new(name: ['John', 'Tom', 'John', 'Tom', 'Jim'], value: 1..5)
>>> data.group_by(:name).each{ p @K }
{:name=>"John"}
{:name=>"Tom"}
{:name=>"Jim"}

# or if you are using a block with args
>>> data.group_by(:name).each{|grp| p grp.K }
{:name=>"John"}
{:name=>"Tom"}
{:name=>"Jim"}
```


### Aggregation

Call `#apply` and the results are stored into a table.

```ruby
>>> data = ObjectTable.new(name: ['John', 'Tom', 'John', 'Tom', 'Jim'], value: 1..5)
>>> data.group_by(:name).apply{ value.mean }
 => ObjectTable(3, 2)
         name  v_0
  0:   "John"  2.0
  1:    "Tom"  3.0
  2:    "Jim"  5.0
         name  v_0 
```

Normally you can only have one aggregated column with a default name of v_0.
You can have more columns and set column names by making a `ObjectTable` or using the @R shortcut.

```ruby
>>> data.group_by(:name).apply{ @R[ mean: value.mean, sum: value.sum] }
 => ObjectTable(3, 3)
         name  mean  sum
  0:   "John"   2.0    4
  1:    "Tom"   3.0    6
  2:    "Jim"   5.0    5
         name  mean  sum 

# or if you are using a block with args
>>> data.group_by(:name).apply{|grp| grp.R[ mean: grp.value.mean, sum: grp.value.sum] }
 => ObjectTable(3, 3)
         name  mean  sum
  0:   "John"   2.0    4
  1:    "Tom"   3.0    6
  2:    "Jim"   5.0    5
         name  mean  sum 
```

### Assigning to columns

Assigning to columns will assign by group.

```ruby
# every row with the same name will get the same group_values
>>> data.group_by(:name).each{|grp| grp[:group_values] = grp.value.to_a.join(',') }
 => ObjectTable(5, 3)
         name  value  group_values
  0:   "John"      1         "1,3"
  1:    "Tom"      2         "2,4"
  2:   "John"      3         "1,3"
  3:    "Tom"      4         "2,4"
  4:    "Jim"      5           "5"
         name  value  group_values 
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
 => ObjectTable::Column.int(3): 
[ 5, 7, 9 ] 

# this won't work!
>>> data.where{ a > 1 }.a_plus_b
NoMethodError: undefined method `a_plus_b' for #<ObjectTable::View:0x000000011d4dd0>
```

To make it work, you'll need to subclass `View`, `StaticView` and `Group` too and assign those subclasses under your ObjectTable subclass.
The easiest way is just to include a module with your common methods.

```ruby
>>> class WorkingTable < ObjectTable
      module Mixin
        def a_plus_b
          a + b
        end
      end

      include Mixin

      # subclass each of these and include the Mixin too
      class StaticView < StaticView; include Mixin; end
      class View < View; include Mixin; end
      class Group < Group; include Mixin; end
    end
...

>>> data = WorkingTable.new(a: 1..3, b: 4..6)
>>> data.a_plus_b
 => ObjectTable::Column.int(3): 
[ 5, 7, 9 ] 

# hurrah!
>>> data.where{ a > 1 }.a_plus_b
 => ObjectTable::Column.int(2): 
[ 7, 9 ] 

# also works in groups!
>>> data.group_by{{odd: a % 2}}.each do
      p "when a % 2 == #{@K[:odd]}, a + b == #{a_plus_b.to_a}"
    end
...

"when a % 2 == 1, a + b == [5, 9]"
"when a % 2 == 0, a + b == [7]"
```

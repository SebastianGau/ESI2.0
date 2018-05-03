# esi-bucket

A collection of useful lua-hacks / tricks

## Changes

| version | date       | description                 |
| ------- | ---------- | --------------------------- |
| 0.1.1   | 2018-05-02 | GETREFERENCE function added |
| 1       | 2018-17-04 | Initial release             |

## Available functions

### INFO

This is a mandatory function for every ESI library.

### READONLYTABLE

Returns a readonly version of a lua table

```lua
  bucket = require 'esi-bucket'
  Directions = bucket.READONLYTABLE {
    LEFT   = 1,
    RIGHT  = 2,
    UP     = 3,
    DOWN   = 4,
  }
  Directions.Left = 5 --raises an error
```

### DEEPCOPY

Deep-Clones a lua table using recursion.

```lua
b = {{},{},{}}
c = bucket.DEEPCOPY(b)
```

### MEMO

Memoizes a function.

```lua
  function triangle(x)
    if x == 0 then 
      return 0 
    end
    return x+triangle(x-1)
  end

  print(triangle(40000)) -- stack overflow: too much recursion

  triangle = bucket.MEMO(triangle) -- make triangle function memoized, so it "remembers" previous results

  -- seed triangle's cache
  for i=0, 40000 do 
    triangle(i)
  end 

  print(triangle(40000)) -- 800020000, instantaneous result
```

### AUTOMAGICTABLE

Creates nested tables automatically.

```lua
  a = bucket.AUTOMAGICTABLE()
  a.b.c.d = "a.b and a.b.c are automatically created"
```

### REVERSETABLE

Creates nested tables automatically.

```lua
  a = bucket.REVERSETABLE({c = 1, d = 2})
  --a is {1 = c, 2 = d}
```

### EXTRACTKEYS

Returns an ordered (array) table with the keys of the passed table.

```lua
  a = bucket.EXTRACTKEYS({c = 1, d = 2})
  --a is {"c","d"}
```

### EXTRACTVALUES

Returns an ordered (array) table with the values of the passed table.

```lua
  a = bucket.EXTRACTVALUES({c = 1, d = 2})
  --a is {1, 2}
```

### COUNT

Returns the number of key-value-pairs in an unordered lua table (the count operator # only works for ordered tables, i.e. a = {"a","b","c"})

```lua
  a = bucket.COUNT{c = 1, d = 2}
  --a is 2
```

### GETREFERENCE

iterates through the given tableParts (hierarchical order: last part is the one we want (is the most specific)). Returns the target, which is a reference to the last item from tableParts.

```lua
local target = bucket:GETREFERENCE({ ["t1"] = {["t2"] = "text"}},{[1] = "t1",[2] = "t2"})
```

## Breaking changes

- Not Applicable
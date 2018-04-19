# esi-bucket

A collection of useful lua-hacks / tricks

## Changes

version | date | description
------- | ---- | -----------
1 | 2018-17-04 | Initial release

## Available functions

### INFO

This is a mandatory function for every ESI library.

### READONLYTABLE

Returns a readonly version of a lua table

```lua
  hackbox = require 'esi-hacks'
  Directions = hackbox.READONLYTABLE {
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
c = hackbox.DEEPCOPY(b)
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

  triangle = hackbox.MEMO(triangle) -- make triangle function memoized, so it "remembers" previous results

  -- seed triangle's cache
  for i=0, 40000 do 
    triangle(i)
  end 

  print(triangle(40000)) -- 800020000, instantaneous result
```

### AUTOMAGICTABLE

Creates nested tables automatically.

```lua
  a = hackbox.AUTOMAGICTABLE()
  a.b.c.d = "a.b and a.b.c are automatically created"
```

## Breaking changes

- Not Applicable
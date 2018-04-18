  bucket = require 'esi-bucket'
  -- bucket.readonlytable
  -- useage:
  Directions = bucket.readonlytable {
    LEFT   = 1,
    RIGHT  = 2,
    UP     = 3,
    DOWN   = 4,
  }
 
 local ok, err = pcall(function() Directions.Left = 5 end)
 if ok then
    error("This should have raised an error!")
 end


  -- bucket.deepcopy(table)
  -- deep-copy a table (e.g. for oop object initialization)
  -- useage:
  b = {{a = 1, b = "2"},{d = 5}, { e = 7}}
  c = bucket.deepcopy(b)
  if c==b then
    error("The table reference should have changed by deep cloning!")
  end


  --bucket.memo(function)
  --  ----useage example:
  function triangle(x)
    if x == 0 then 
      return 0 
    end
    return x+triangle(x-1)
  end

  pcall(print(triangle(40000))) -- stack overflow: too much recursion
  triangle = bucket.memo(triangle) -- make triangle function memoized, so it "remembers" previous results
  -- seed triangle's cache
  for i=0, 40000 do 
    triangle(i)
  end 
  print(triangle(40000)) -- 800020000, instantaneous result



  --bucket.AutomagicTable()
  --can be used to init a.b.c.d automatically
  a = bucket.AutomagicTable()
  a.b.c.d = "a.b and a.b.c are automatically created"


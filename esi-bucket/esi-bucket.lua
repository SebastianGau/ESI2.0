-- esi-bucket
local bucket = bucket or {}


bucket.INFO = function()
    return {
      version = {
        major = 0,
        minor = 1,
        revision = 1
      },
      contacts = {
        {
          name = "Florian Seidl",
          email = "florian.seidl@cts-gmbh.de"
        },
        {
          name = "Sebastian Gau",
          email = "sebastian.gau@basf.com"
        }
      },
      library = {
        -- Filename is always "lib-" .. modulename and the modulename must be used for the ScriptLibrary.LuaModuleName property.
        modulename = "esi-bucket"
      },
      dependencies = {
        {

        },
      }
    }
end


function bucket.READONLYTABLE(table)
  -- useage:
  -- Directions = bucket.READONLYTABLE {
  --   LEFT   = 1,
  --   RIGHT  = 2,
  --   UP     = 3,
  --   DOWN   = 4,
  --   otherstuff = {}
  -- }
  -- Directions.Left = 5 --raises an error

  return setmetatable({}, {
      __index = table,
      __newindex = function(table, key, value)
        error("Attempt to modify read-only table")
      end,
      __metatable = false
    });
end





local bucket = bucket or {}

function bucket.DEEPCOPY (t) 
  -- deep-copy a table (used for oop object initialization)
  -- useage:
  --  b = {{},{},{}}
  --  c = bucket.DEEPCOPY(b)
  if type(t) ~= "table" then return t end
  local meta = getmetatable(t)
  local target = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      target[k] = bucket.DEEPCOPY(v)
    else
      target[k] = v
    end
  end
  setmetatable(target, meta)
  return target
end


function bucket.DEEPCOPY2(t, seen) 
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end





local bucket = bucket or {}

bucket.MEMO = function(f)
  --  ----useage example:
  --  function triangle(x)
  --    if x == 0 then 
  --      return 0 
  --    end
  --    return x+triangle(x-1)
  --  end

  ----print(triangle(40000)) -- stack overflow: too much recursion

  --  triangle = bucket.MEMO(triangle) -- make triangle function memoized, so it "remembers" previous results

  ---- seed triangle's cache
  --  for i=0, 40000 do 
  --    triangle(i)
  --  end 

  --  print(triangle(40000)) -- 800020000, instantaneous result


  local unpack = unpack or table.unpack

  local globalCache = {}

  local function getCallMetamethod(f)
    if type(f) ~= 'table' then return nil end
    local mt = getmetatable(f)
    return type(mt)=='table' and mt.__call
  end

  local function resetCache(f, call)
    globalCache[f] = { results = {}, children = {}, call = call or getCallMetamethod(f) }
  end

  local function getCacheNode(cache, args)
    local node = cache
    for i=1, #args do
      node = node.children[args[i]]
      if not node then return nil end
    end
    return node
  end

  local function getOrBuildCacheNode(cache, args)
    local arg
    local node = cache
    for i=1, #args do
      arg = args[i]
      node.children[arg] = node.children[arg] or { children = {} }
      node = node.children[arg]
    end
    return node
  end

  local function getFromCache(cache, args)
    local node = getCacheNode(cache, args)
    return node and node.results or {}
  end

  local function insertInCache(cache, args, results)
    local node = getOrBuildCacheNode(cache, args)
    node.results = results
  end

  local function resetCacheIfMetamethodChanged(t)
    local call = getCallMetamethod(t)
    assert(type(call) == "function", "The __call metamethod must be a function") 
    if globalCache[t].call ~= call then
      resetCache(t, call)
    end
  end

  local function buildMemoizedFunction(f)
    local tf = type(f)
    return function (...)
      if tf == "table" then resetCacheIfMetamethodChanged(f) end

      local results = getFromCache( globalCache[f], {...} )

      if #results == 0 then
        results = { f(...) }
        insertInCache(globalCache[f], {...}, results)
      end

      return unpack(results)
    end
  end

  local function isCallable(f)
    local tf = type(f)
    if tf == 'function' then return true end
    if tf == 'table' then
      return type(getCallMetamethod(f))=="function"
    end
    return false
  end

  local function assertCallable(f)
    assert(isCallable(f), "Only functions and callable tables are admitted on memoize. Received " .. tostring(f))
  end

  local function memoize(f)
    assertCallable(f)
    resetCache(f)
    return buildMemoizedFunction(f)
  end

  return memoize(f)
end





local bucket = bucket or {}

function bucket.AUTOMAGICTABLE()
  --can be used to init a.b.c.d automatically
  --a = bucket.AUTOMAGICTABLE()
  --a.b.c.d = "a.b and a.b.c are automatically created"
  local auto, assign

  function auto(tab, key)
    return setmetatable({}, {
        __index = auto,
        __newindex = assign,
        parent = tab,
        key = key
      })
  end

  local meta = {__index = auto}

  -- The if statement below prevents the table from being
  -- created if the value assigned is nil. This is, I think,
  -- technically correct but it might be desirable to use
  -- assignment to nil to force a table into existence.

  function assign(tab, key, val)
    -- if val ~= nil then
    local oldmt = getmetatable(tab)
    oldmt.parent[oldmt.key] = tab
    setmetatable(tab, meta)
    tab[key] = val
    -- end
  end

  function CreateAutomagicTable()
    return setmetatable({}, meta)
  end

  return CreateAutomagicTable()
end

function bucket.REVERSETABLE(tab)
  if type(tab)~='table' then
    error("Invalid argument type: " .. type(tab))
  end
  local rev = {}
  for k, v in pairs(tab) do
    rev[v] = k
  end
end

function bucket.COUNT(tab)
  if type(tab)~='table' then
    error("Invalid argument type: " .. type(tab))
  end
  local c = 0
  for k, v in pairs(tab) do
    c = c + 1
  end
  return c
end

function bucket.EXTRACTKEYS(tab)
  if type(tab)~='table' then
    error("Invalid argument type: " .. type(tab))
  end
  local c = {}
  for k, v in pairs(tab) do
    table.insert(c, k)
  end
  return c
end

function bucket.EXTRACTVALUES(tab)
  if type(tab)~='table' then
    error("Invalid argument type: " .. type(tab))
  end
  local c = {}
  for k, v in pairs(tab) do
    table.insert(c, v)
  end
  return c
end

function bucket.GETREFERENCE(self, tbl, tableParts)
    local target = tbl
    if type(tbl) == "table" and type(tableParts) == "table" then
        for _, v in ipairs(tableParts) do
            target = target[v]
            if target == nil then
                return nil
            end
        end
        return target
    end
    return nil
end

return bucket
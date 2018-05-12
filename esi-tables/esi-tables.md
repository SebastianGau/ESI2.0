# esi-tables

A library for handling of tables / table holders.

## Changes

| version | date       | description                                                  |
| ------- | ---------- | ------------------------------------------------------------ |
| 0.1.2   | 2018.05.02 | added the functions ENSURETEMPLATE and SETCONFIGURATIONTABLE |
| 1       | 2018-04-17 | Initial release                                              |

## Available functions

### INFO

This is a mandatory function for every ESI library.

### NEW

Initializes the object based on an existing table holder. If it does not exist, upserts a new one.
If mode == "persistoncommand", the changes will only be written to the holder if SAVE() is called (this is the standard option). If mode == "persistimmediately", the changes will immediately be reflected to the table holder at the cost of performance loss.

```lua
local tab = require 'esi-tables'
local path = inmation.getself():parent():path()
local t, existedbefore = tab:NEW{path = path, objectname = "testtable", mode="persistimmediately"}
--this also works:
local t1 = tab:NEW{path = path .. "/testtable", mode="persistoncommand"} 
```

### SAVE

Persists the changes to the table holder. Is unnecessary if mode == "persistimmediately". Note that mode == "persistimmediately" results in a significant performance loss. You should try to work in-memory ("persistoncommand") as far as possible and persist by using the :SAVE() command afterwards.

```lua
t:SAVE()
```

### ADDROW / ADDCOLUMNS

Self-explaining.

```lua
t:ADDCOLUMNS{"Testnumber","col2", "col3", "col4"}
t:ADDROW{Testnumber = 1, col2 = "entry", col3="something", col4="toberemoved"}
t:ADDROW{Testnumber = 2, col2 = "entry1", col3="something1", col4="tobeupdated"}
t:ADDROW{Testnumber = 3, col2 = "entry2", col3="something2", col4="tobeselected"}
t:SAVE()
t:ADDROW{Testnumber = 4, col2 = "entry3", col3="something3", col4="anothertest"}
t:SAVE()
```

### UPDATE

Updates a row in a table holder.

```lua
t:UPDATE
{ 
    WHERE = {Testnumber = 2, col2 = "entry1"}, --a nonexistent column here will result in an error
    SET = {col3 = "somethingupdated", col4 = "wasupdated"}, 
}
t:SAVE()
--alternative function syntax (function/table syntax can also be mixed in WHERE and SET)
t:UPDATE
{ 
    WHERE = function(row) return row.Testnumber==2 and row.col2 == "entry1" end,
    SET = function(row) row.col3 = "somethingupdatedagain" row.col4 = "wasupdatedagain" end, 
}
t:SAVE()
```

### SELECT

Returns one or multiple rows of a table in a table holder

```lua
local selected = t:SELECT
{ 
    WHERE = {col4 = "wasupdated"} 
}
--alternatively:
local selected = t:SELECT
{ 
    WHERE = function(row) return row.col4=="wasupdated" end 
}
[[selected has the basic structure
{
    {col1 = "value1", col2 = "value2"},
    {col1 = "value12", col2 = "value22"},
}
]]
```



### REMOVECOLUMNS / COLUMNEXISTS

Removes the columns with the specified column names.

```lua
t:REMOVECOLUMNS{"col3"} --could also be {"col3","col4"}
t:SAVE()
if t:COLUMNEXISTS("col3")==true then 
    error("Column still exists but should have been deleted!")
end
```

### ROWCOUNT

Self-explanatory.

```lua
local count = t:ROWCOUNT()
```

### COLUMNCOUNT

Self-explanatory.

```lua
local count = t:COLUMNCOUNT()
```

### GETCOLUMN

Returns only the data of a single row as an ordered (indexed by number) table.

```lua
local selected = t:GETCOLUMN
{ 
    NAME = "col3",
    WHERE = {col4 = "wasupdated"} 
}
--alternatively:
local selected = t:GETCOLUMN
{ 
    NAME = "col3",
    WHERE = function(row) return row.col4 == "wasupdated" end 
}
[[selected has the structure {"valueforindex1", "valueforindex2"}]]
```

### DATA

Returns all the data in the table. This is equivalent to selecting all the table rows using :SELECT, and the returned lua table format is equivalent.

```lua
local data = t:DATA()
```

### INMATIONOBKECT

Returns the underlying inmation table holder. Attention: Direct Manipulation of this object can bring the esi-tables wrapper out of sync!

```lua
local obj= t:INMATIONOBJECT()
```

### SETSCHEMA / VALIDATESCHEMA

Enables to check the table against given schemes.

```lua
local path = inmation.getself():parent():path()
local mode = "persistoncommand"
local name = "schematable"
pcall(function() inmation.deleteobject(path .. "/" .. name) end)
local t, existedbefore = tab:NEW{path = path, objectname = name, mode=mode}

--build table
t:ADDCOLUMNS{"columnname1","columnname2","columnname3"}
t:ADDROW{columnname1 = 1, columnname2 = "entry", columnname3 = false}
t:ADDROW{columnname1 = 2, columnname2 = "entry1", columnname3 = true}
t:ADDROW{columnname1 = 3, columnname2= "entry2", columnname3 = true}
t:SAVE()

--try to pass an invalid schema
local schema =
{
    columns = 
    {
        {
            nameCAUSESFAIL = "columnname1", --this causes the check to fail
            required = true,
            unique = true,
            nonempty = true,
            valueset = {1, 2, 3},
        },
        {
            name = "columnname1", --this would not cause an error
            required = true, --the column is mandatory
            unique = true, --the column has to feature unique values
            nonempty = true, --all values in the column have to be nonempty
            valueset = {1, 2, 3}, --means that the values in the table have to be either 1, 2 or 3
        },
    },
    maxrows = 3,
}

local ok, err = pcall(t:SETSCHEMA(schema))
if ok then
    error("The schema structure was invalid and should have caused an error!")
end

--the schema always has to look like this
--non-existing columns in the schema.columns array will not be validated in the table (i.e. the table can have more columns than shown here)
local schema =
{
    columns = 
    {
        {
            name = "columnname1",
            required = true, --the column is mandatory
            unique = true, --the column has to feature unique values
            nonempty = true, --all values in the column have to be nonempty
            valueset = {1, 2, 3}, --means that the values in the table have to be either 1, 2 or 3
        },
        {
            name = "columnname2",
            required = true,
            unique = true,
            nonempty = true,
            valueset = {luatype="string"},
        },
        {
            name = "columnname3",
            required = true,
            unique = false,
            nonempty = true,
            valueset = {luatype="boolean"},
        },
    },
    maxrows = 3,
}

t:SETSCHEMA(schema)
--test whether the table is successfully validated
local res, err = t:VALIDATESCHEMA()
if not res then
    error("The check failed with " .. err .. " but should have passed!")
end
--test whether it is recognized if the table does not follow the schema
local updated = t:UPDATE{
    WHERE = function(row) return row.columnname1 == 3 end,
    SET = function(row) row.columnname3 = "asd" end, 
    --table now violates the schema since it is of type boolean
}
if updated~=1 then error("Invalid update count!") end
local updated = t:UPDATE{
    WHERE = function(row) return row.columnname2 == "entry1" end,
    SET = function(row) row.columnname2 = "entry" end, 
    --table now violates the schema since values are not unique within the column anymore
}
if updated~=1 then error("Invalid update count!") end
local updated = t:UPDATE{
    WHERE = function(row) return row.columnname1 == 3 end,
    SET = function(row) row.columnname1 = 4 end, 
    --table now violates the schema since only values 1,2,3 are allowed
}
if updated~=1 then error("Invalid update count!") end
t:SAVE()
local res, err = t:VALIDATESCHEMA()
if res then error("This test should have failed!") end
```

### ENSURETEMPLATE

Creates/Updates template.

```lua
O:ENSURETEMPLATE("Performance Counter Table", self.rootpath, "PERFORMANCECOUNTER", 'inmation.ESI.SystemMonitor.Defaults'["datapct"],  "typename", "ObjectAlias")
ENSURETEMPLATE = function(self, objectname, parentpath, default, tablename, systemalias, objectalias)
O:ENSURETEMPLATE{objectname="Performance Counter Table", parentpath=self.rootpath,default= require'inmation.ESI.SystemMonitor.Defaults'["PERFORMANCECOUNTER"], aliastree={"datapct",  "typename"}, objectalias="ObjectAlias"}
```

### SETCONFIGURATIONTABLE

Sets the configuration table.

```lua
O:SETCONFIGURATIONTABLE{tablename="healthcalculationstemplate",aliastree={"typename","ObjectAlias"},TableData=list}
setconfigurationtable = function(self, tablename, systemalias, objectalias, list)
```

## Breaking changes

- Not Applicable
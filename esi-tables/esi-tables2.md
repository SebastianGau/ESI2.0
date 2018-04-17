# esi-tables

A library for handling of tables / table holders.

## Changes

version | date | description
------- | ---- | -----------
1 | 2018-04-17 | Initial release

## Available functions

### INFO

This is a mandatory function for every ESI library.

### NEW

Initializes the object based on an existing table holder. If it does not exist, upserts a new one.
If mode == "persistoncommand", the changes will only be written to the holder if SAVE() is called.
Otherwise, all changes will immediately be reflected to the table holder at the cost of performance loss.

```lua
local path = inmation.getself():parent():path()
local t, existedbefore = tab:NEW{path = path, objectname = name, mode=mode}
--this also works:
local t1 = tab:NEW{path = path .. "/testtable", mode="persistoncommand"} 
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
```

### SELECT

Returns one or multiple rows of a table in a table holder

```lua
t:UPDATE
{ 
    WHERE = {Testnumber = 2, col2 = "entry1"}, --a nonexistent column here will result in an error
    SET = {col3 = "somethingupdated", col4 = "wasupdated"}, 
}
--alternative (function/table syntax can also be mixed in WHERE and SET)
t:UPDATE
{ 
    WHERE = function(row) return row.Testnumber==2 and row.col2 == "entry1" end,
    SET = function(row) row.col3 = "somethingupdatedagain" row.col4 = "wasupdatedagain" end, 
}
t:SAVE()
local selected = t:SELECT
{ 
    WHERE = {col4 = "wasupdated"} 
}
local selected = t:SELECT
{ 
    WHERE = function(row) return row.col4=="wasupdated" end 
}
[[selected has the structure
{
    {col1 = "value1", col2 = "value2"},
    {col1 = "value12", col2 = "value22"},
}
]]
```

### SAVE

### REMOVECOLUMNS

Removes the columns with the specified column names.

```lua
t:REMOVECOLUMNS{"col3"}
t:SAVE()
if t:COLUMNEXISTS("col3")==true then 
    error("Column still exists but should have been deleted!")
end
```

### ROWCOUNT

Self-explanatory.

### COLUMNCOUNT

Self-explanatory.

## Breaking changes

- Not Applicable
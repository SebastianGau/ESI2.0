local tab = require 'esi-tables'
local json = require 'dkjson'



local path = inmation.getself():parent():path()
local teststage = 7
local mode = "persistoncommand"
local name = "testtable"
pcall(function() inmation.deleteobject(path .. "/" .. name) end)

local t, existedbefore = tab:NEW{path = path, objectname = name, mode=mode}
if existedbefore then
    error("The table existed before, this is not possible!")
end
--command creates table if it is not existent or reads it if existent
--this also works:
-- local t1 = tab:NEW{path = path .. "/testtable", mode="persistoncommand"}
-- "persistoncommand" standard, "persistimmediately" resulsts in bad performance but immediate persistance

local save = function()
    if mode=="persistoncommand" then
        t:SAVE() --persists to core if mode is "persistoncommand", otherwise is useless
    end
end



--FILL A TABLE -passed
t:ADDCOLUMNS{"Testnumber","col2", "col3", "col4"}
t:ADDROW{Testnumber = 1, col2 = "entry", col3="something", col4="toberemoved"}
t:ADDROW{Testnumber = 2, col2 = "entry1", col3="something1", col4="tobeupdated"}
t:ADDROW{Testnumber = 3, col2 = "entry2", col3="something2", col4="tobeselected"}
save() 
t:ADDROW{Testnumber = 4, col2 = "entry3", col3="something3", col4="anothertest"}
save()
if teststage==1 then
    do return "done" end
end

--UPDATE/SELECT A SINGLE ROW
local updated = t:UPDATE
{ 
    WHERE = {Testnumber = 2, col2 = "entry1"}, --a nonexistent column here will result in an error
    SET = {col3 = "somethingupdated", col4 = "wasupdated"},
}
assert(updated==1, "should be 1, is " .. updated)
save()
local updated = t:UPDATE
{ 
    WHERE = function(row) return row.Testnumber == 2 and row.col2 == "entry1" end,
    SET = function(row) row.col4 = "wasupdatedagain" end
}
assert(updated==1, "should be 1, is " .. updated)
save()
local selected = t:SELECT
{ 
    WHERE = {col3 = "somethingupdated"} 
}
assert(#selected==1, "Invalid number of returned rows! Should be 1, is " .. #selected)
assert(selected[1].col3=='somethingupdated', "invalid table entry! is " .. tostring(selected[1].col3))
assert(selected[1].col4=="wasupdatedagain", "invalid table entry! is " .. tostring(selected[1].col4))
if teststage==1.5 then
    do return "updated and selected" end
end


--REMOVE EXISTING COLUMN
t:REMOVECOLUMNS{"col3"}
save()
if t:COLUMNEXISTS("col3")==true then 
    error("Column still exists but should have been deleted!")
end
if teststage==3 then
    do return "column was deleted" end
end


--returns existing columns
local ab = t:COLUMNS() 
if teststage==4 then
    do return "existing columns: " .. json.encode(ab) end
end


--clears the complete table
t:CLEAR()
save()
if t:COLUMNEXISTS("col3") or t:ROWCOUNT()>0 then
    error("Table was not cleared!")
end
if teststage==5 then
    do return "cleared table" end
end



-----------------------------SCHEMA TEST-----------------------------
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
            nonempty = true, --all values in the column have to be nonemoty
            valueset = {1, 2, 3}, --means that the values in the table have to be either 1, 2 or 3
        },
    },
    maxrows = 3,
}

local ok, err = pcall(function() t:SETSCHEMA(schema) end)
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
            nonempty = true, --all values in the column have to be nonemoty
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
if teststage == 6 then
    do return "result of schema test: success: " .. tostring(res) .. ", errors: " .. err or "none" end
end

local tab = require 'esi-tables'
local s = inmation.getself()
tab:SETTABLE{object = s, key = "key1", value = {{col1 = 1}, {col2 = 2}}}
tab:SETTABLE{object = s, key = "key2", value = {{col3 = 1}, {col4 = false}}}
tab:SETTABLE{object = s, key = "key3", value = {{col1 = 1}, {col2 = false}, {col3 = "a"}}}

local t1 = tab:GETTABLE{object = s, key = "key1"}
if t1[1].col1 ~= 1 then error("Invalid value!") end
local t2 = tab:GETTABLE{object = s, key = "key2"}
if t2[1].col3 ~= 1 then error("Invalid value!") end


--check schema validation
local t3 = tab:GETTABLE{object = s, key = "key3"}
local schema =
{
    columns = 
    {
        {
            name = "col1",
            required = true, --the column is mandatory
            unique = true, --the column has to feature unique values
            nonempty = false, --all values in the column have to be nonemoty
            valueset = {1, 2, 3}, --means that the values in the table have to be either 1, 2 or 3
        },
        {
            name = "col2",
            required = true,
            unique = true,
            nonempty = false,
            valueset = {luatype="boolean"},
        },
        {
            name = "col3",
            required = true,
            unique = false,
            nonempty = false,
            valueset = {luatype="string"},
        },
    },
    maxrows = 3,
}

local ok, err = tab:VALIDATETABLE(t3, schema)
if not ok then
    error("Schema validation should have passed but failed with error " .. err)
end



do return "passed all tests!" end



------------COOL IDEAS------------


--iterator use:
for _, row in t:SELECT{WHERE = {col1 = "asd"}} do 
    --row is e.g. {col1 = "asd", col2 = 37, col3="34636"}
end

--iterates over all rows
for _, row in t:SELECT{} do 

end


local tab = t:SELECT
{ 
    WHERE = {col1 = "asd"}, 
}:REMOVE() --would be cool, otherwise t:REMOVE{WHERE={col1 = "asd"}}



--UPDATE/SELECT A SINGLE ROW
t:UPDATE
{ 
    WHERE = {
        Testnumber = function(val) return val>2 end, 
        col2 = function(val) return val:find("ent") end
    },
    SET = {col3 = "somethingupdated", col4 = "wasupdated"}, 
    OR = true --or LIKE
}
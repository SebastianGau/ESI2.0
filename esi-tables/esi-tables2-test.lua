local tab = require 'esi-tables'
local path = inmation.getself():parent():path()
local json = require 'dkjson'




local teststage = 3
mode = "persistoncommand"
name = "testtable"
pcall(function() inmation.deleteobject(path .. "/" .. name) end)

local t, existedbefore = tab:NEW{path = path, objectname = name, mode=mode}
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
t:UPDATE
{ 
    WHERE = {Testnumber = 2, col2 = "entry1"}, --a nonexistent column here will result in an error
    SET = {col3 = "somethingupdated", col4 = "wasupdated"}
}
save()
local selected = t:SELECT
{ 
    WHERE = {col4 = "wasupdated"} 
}
assert(#selected~=1, "Invalid number of returned rows should be 1, is " .. #selected)
assert(selected[1].col3~='somethingupdated', "invalid table entry! is " .. tostring(selected[1].col3))
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
if teststage==5 then
    do return "cleared table" end
end


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
local tab = require 'esi-tables'

local tablepath = "asd"
local tab = tab:TABLE(tablepath)
tab:SCHEMA():ADDFIELD("columnname"):SETREQUIRED()

--TABLE()
:SCHEMA()
:LOADED() --whether table was loaded (bool)
:ROWS() --rowcount
:COLUMNS() --columncount
:FOREACHROW(scope, fnc) --func(scope, v)
:LOOKUP() = function(this, column, other_column, other_colum_value)


--TABLE():SCHEMA()
:ADDFIELD(name_string)
:INTEGRITYCHECK() --returns bool, details_string


local success, details = :INTEGRITYCHECK()


--TABLE():SCHEMA()
:SETREQUIRED()
:SETEXPECTEDTYPE(typename_string)
:SETDISCRETE()
:SETRANGE(low, high)
:SETVALUESET(table) --expects a table
:SETUNIQUE()
:SETNONEMPTY()
:ASTIMESPAN()
:ASDATASOURCEOBJECT()




local template =
{
    columns = {"col1","col2"},

}


local connector =
{

}


local t = tab:NEW{path = "asd", mode="persistoncommand"} 
-- persistoncommand standard, persistimmediately


local t, existedbefore = tab:NEW{path = "asd", objectname = "name", mode="persistimmediately"}
--command creates table if it is not existent or reads it if existent

t:SAVE() --persists to core if mode is "persistoncommand", otherwise is useless

t:ADDCOLUMNS{"col1","col2", "col3"}
t:REMOVECOLUMNS{"col4", "col5"}


t:ADDROW{col1 = "asd", col2 = 3, col3="fafd"}
t:ADDROW{col1 = "asd", col2 = 37, col3="34636"}
t:UPDATE
{ 
    WHERE = {col1 = "asd", col2 = "3"}, --a nonexistent column here will result in an error
    SET = {col2 = 4, col3 = "asdasd"}
} --returns number of modified rows
--IMPORTANT: check whether columns exist beforehand (from WHERE and SET)

local tab = t:SELECT
{ 
    WHERE = {col1 = "asd"}, 
}
[[tab holds 
{
    {col1 = "asd", col2 = 3, col3="fafd"},
    {col1 = "asd", col2 = 37, col3="34636"}
}
]]

local ab = t:COLUMNS() --returns {"col1","col2", "col3"}

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
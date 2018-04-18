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

local db = require 'esi-odbc'
local json = require 'dkjson'



--TODO:
--  Codepaging (Timo?)
--  Tests with different drivers (only MSSQL tested, oracle soon to come...)
--  what happens for invalid datatypes? (leads to nil in self.STATE.CURSOR:getcolnames())?
--      ->I implemented an exception (otherwise nothing is returned from the database and you think the table is empty...)

local data = 
  {
    ["dsn"] = "VKPI",
    ["user"] = "sa",
    ["password"] = "1877Mtk!1"
  }


local autoclose = false
--if no Name is provided, the connection will automatically be set to Autoclose
local dbobj = db:GETCONNECTION
{
    Name = "vkpi1", --can be set to standard value, is the identifier of the connection, internally the returned connection object is tracked in a table
    DSN = data.dsn, --has to be provided
    User = data.user, --has standard value empty string
    Password = data.password, --has standard value empty string
    Maxrecords = 100000, --has standard value 10000
    Autoclose = autoclose, --whether the connection is opened and closed on demand when executing a query, by default false
    Itermode = db.MODE.NUMBERINDEX 
    --also db.MODE.COLNAMEINDEX: determines whether the EXECUTE operatur rows 
    --as a lua table whose keys are numbers (0) or the column names (1)
}

--on autoclose, connection is automatically established on every query and closed afterwards
--otherwise, the connection has to be established and closed manually using :CONNECT() and :CLOSE()
if not autoclose then
    dbobj:CONNECT()
end

--test a execute
dbobj:EXECUTE("USE visualkpi")

--use numberindex
local q  = [[SELECT convert(nvarchar(50), ID) as ID, Name FROM VisualKPI.dbo.tableProfiles]]

--THIS LEADS TO AN ERROR:
--local q  = [[SELECT ID, Name FROM VisualKPI.dbo.tableProfiles]]
--problem: ID leads to an unknown datatype in the driver, I impmented that this throws an error

local profs1 = {}
for rownum, row in pairs(dbobj:EXECUTE(q)) do
    table.insert(profs1, {id = row[1], name = row[2]}) --db.MODE.NUMBERINDEX
end

--set mode to index the rows by column names
dbobj:SETITERMODE(db.MODE.COLNAMEINDEX)

local profs2 = dbobj:EXECUTE(q)



--this is also possible if a "Name" is passed in the GETCONNECTION argument table
db:GETCONNECTION{Name = "vkpi1"}:EXECUTE("USE visualkpi")
-- declarative syntax for high-level ESI Code also works:
db:GETCONNECTION("vkpi1"):EXECUTE("USE visualkpi")

local stats = dbobj:GETSTATISTICS()

dbobj:CLOSE()


do return "Profiles with numberindex: " .. json.encode(profs1) 
    .. "Profiles with column name index: " .. json.encode(profs2) ..
    ", Statistics: " .. json.encode(stats) end







# esi-odbc

A library for managing ODBC-Connections in lua

## Changes

version | date | description
------- | ---- | -----------
1 | 2018-04-16 | Initial release

## Available functions

### INFO

This is a mandatory function for every ESI library.

### GETCONNECTION

Returns a connection to an ODBC Source.

Useage

```lua
local db = require 'esi-odbc'
local data = 
{
    ["dsn"] = "asd",
    ["user"] = "asd",
    ["password"] = "asd"
}

local autoclose = false
--if no Name is provided, the connection will automatically be set to Autoclose
local dbobj = db:GETCONNECTION
{
    Name = "vkpi1", --can be set to standard value, is the identifier of the connection, 
    --internally the returned connection object is tracked in a table
    DSN = data.dsn, --has to be provided, DSN of the ODBC Source
    User = data.user, --has standard value empty string
    Password = data.password, --has standard value empty string
    Maxrecords = 100000, --maximum number of records to be fetched in one call, has standard value 10000
    Autoclose = autoclose, --whether the connection is opened and closed on demand when executing a query, by default false
    Itermode = db.MODE.NUMBERINDEX 
    --also db.MODE.COLNAMEINDEX: determines whether the EXECUTE operatur returns rows 
    --as a lua table whose keys are numbers (0) or the column names (1)
}

--this is also possible if a "Name" is passed in the GETCONNECTION argument table
local rowschanged = db:GETCONNECTION{Name = "vkpi1"}:EXECUTE("USE visualkpi")
-- declarative syntax for high-level ESI Code also works:
local rowschanged = db:GETCONNECTION("vkpi1"):EXECUTE("USE visualkpi")
```

### CONNECT

Establishes the connection to the database.

```lua
--on autoclose, connection is automatically established on every query and closed afterwards
--otherwise, the connection has to be established and closed manually using :CONNECT() and :CLOSE()
if not autoclose then
    dbobj:CONNECT()
end
```

### EXECUTE

Executes an SQL Query/Statement. Returns a table if the query returns a cursor.

Useage

```lua
--either this is possible
dbobj:EXECUTE("USE visualkpi")
--or this
local q  = [[SELECT convert(nvarchar(50), ID) as ID, Name FROM VisualKPI.dbo.tableProfiles]]
local profs1 = {}
for rownum, row in pairs(dbobj:EXECUTE(q)) do
    table.insert(profs1, {ID = row[1], Name = row[2]}) --db.MODE.NUMBERINDEX
end
--set mode to index the rows by column names
dbobj:SETITERMODE(db.MODE.COLNAMEINDEX)
local profs2 = dbobj:EXECUTE(q)
--returns:
```

returned lua tables as json (profs1 and profs2):

```json
[{
    "ID": "C52756A3-B3FE-4F55-A2EB-268FC1F60DC6",
    "Name": "Overview Dashboards"
}, {
    "ID": "737234DD-8238-4F5B-B482-97FB36D10029",
    "Name": "Default"
}, {
    "ID": "47033AB7-8D38-49B7-9363-CACE50505254",
    "Name": "Monitoring Models"
}]
```

### GETSTATISTICS

Returns statistical information about the performance and useage of the odbc source.

```lua
local stats = dbobj:GETSTATISTICS()
```
returned lua table as a json:

```json
{  
   "RECENT":{  
      "ENDTIME":1524569929680,
      "CONNECTION":{  
         "VENDORNAME":"Microsoft",
         "DRIVERNAME":"ODBC SQL Server Driver",
         "PRODUCTNAME":"SQL Server",
         "INIT":true
      },
      "STARTTIME":1524569929678,
      "STARTTIMELOCAL":"2018-04-24T13:38:49.678",
      "EXECUTE":{  
         "ROWS_AFFECTED":-1,
         "TIME":2
      },
      "ENDTIMELOCAL":"2018-04-24T13:38:49.680"
   },
   "PERFORMANCE":{  
      "WRITE":{  
         "OVERALLRECORDS":0,
         "CALLS":4,
         "AVGTIMEPEREXECUTE_MS":1.875
      },
      "READ":{  
         "MIN":0.048001607259115,
         "OVERALLMB":0.00028800964355469,
         "MAX":0.14400482177734,
         "UOM":"MB/s",
         "CALLS":2,
         "AVG":0.096003214518229,
         "OVERALLRECORDS":18
      }
   },
   "INITTIMELOCAL":"2018-04-24T13:38:49.649",
   "INITTIME":1524569929649,
   "CALLS":6
}
```

### CLOSE

Closes the ODBC connection. Leads to problems if forgotten.
After closing, no queries can be processed.

Useage

```lua
    dbobj:CLOSE()
```

## Breaking changes

- Not Applicable
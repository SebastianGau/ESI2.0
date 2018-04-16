# esi-variables

A library for upserting variables and variable groups

## Changes

version | date | description
------- | ---- | -----------
1 | 2018-04-16 | Initial release

## Available functions

### INFO

This is a mandatory function for every ESI library.

### CONNECT

Connects to an ODBC source. The odbc source has to be configured on the machine on 
which the command is executed.

Useage

```lua
    local ODBC = require 'esi-odbc'
    ODBC:CONNECT{dsn="dsname", user="user", password="pw"}
```

### EXECUTE

Executes an SQL Query/Statement. Returns an iterator if rows have to be iterated.
Throws an exception if the statement cannot be processed.

Useage

```lua
    local sql =  "SELECT      dbo.tableDashboards.ID, dbo.tableDashboards.Name"..
  "FROM        dbo.tableDashboards"..
  "WHERE       (dbo.tableDashboards.Description  LIKE 'asd')"
    local dashboards = {}
    for row in ODBC:EXECUTE(sql) do
      table.insert(dashboards, {id=row[1], name=row[2]})
    end

    --OR:
    local sql = "EXECUTE usp_DeleteProfile 'asd'"
    ODBC:EXECUTE(sql)
```

### CLOSE

Closes the ODBC connection. Leads to problems if forgotten.
After closing, no queries can be processed anymore.

Useage

```lua
    ODBC:CLOSE()
```

## Breaking changes

- Not Applicable
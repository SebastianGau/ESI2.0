# esi-variables

A library for upserting variables and variable groups

## Changes

| version | date       | description                                          |
| ------- | ---------- | ---------------------------------------------------- |
| 0.1.2   | 2018-04-24 | Bugfix SETVARIABLE, esi-object UPSERTOBJECT function |
| 0.1.1   | 2018-01-10 | Initial release                                      |

## dependencies

| library     | version | inmation core library |
| ----------- | ------- | --------------------- |
| dkjson      | 2.5     | yes                   |
| esi-objects | 0.1.1   | no                    |

## Available functions

### INFO

This is a mandatory function for every ESI library.

Usage

```lua
    local JSON = require('dkjson')
    local ESI = require('esi-example')
    local result = ESI:INFO()
    error(JSON.encode(result))
```

Example response

```lua
ommited for brevity
```

### SETVARIABLE

Upserts a variable object underneath the code-executing object and sets its value. Tables are automatically converted to json.

```lua
SETVARIABLE(path, v, q, t)
SETVARIABLE{path ="aas", v=1.4, q=1,t=2348763284767}
SETVARIABLE{path ="aas", v=1.4, q=1,t=2348763284767, json = {indent = true}}
SETVARIABLE({object = obj, path ="aas", v=1.4, q=1,t=2348763284767, json = {indent = true}})
```

### GETVARIABLE

Retrieves a variables from underneath the code-executing object.

```lua
local v,q,t = O:GETVARIABLE(variablepath)
local v,q,t = O:GETVARIABLE{ path ="aas"}
local v,q,t = O:GETVARIABLE{object = obj, path ="aas"}
```

## Breaking changes

- Not Applicable
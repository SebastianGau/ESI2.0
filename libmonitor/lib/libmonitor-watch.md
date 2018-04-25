# libmonitor-watch

Todo: description

## INFO

| version | date       | description                            |
| ------- | ---------- | -------------------------------------- |
| 0.0.2   | 17.04.2018 | add post and ctx to config TableHolder |
| 0.0.1   | 17.04.2018 | Initial release                        |

## dependencies

| library              | version | inmation core |
| -------------------- | ------- | ------------- |
| dkjson               | 2.5     | yes           |
| inmation.ESI.Objects | -       | no            |

## Available functions

### CHECKLIBVERSION

This function is used to monitor the libraries of one or multible cores using the webAPI function `http://localhost:8002/api/v2/execfunction/v2b?lib=libmonitor&func=getalllibs` to get the information from the libs. The script creates a TableHolder with the following fields that has to be filled in:

- **host** the webAPI host name or IP
- **name** the alias name for the core
- **user** the user name used for the webAPI authentication
- **password** the password used for the webAPI authentication
- **port** the port of the webAPI (when left blank, then the default port 8002 is used)
- **ctx** the context where the library ist stored (when left blank, then the default context of the webAPI is used)

lua example in a Generic Item

```lua
local lmw = require'libmonitor-watch'
return lmw:CHECKLIBVERSION()
```

### DEBUGGING

Enables debugging for the http calls.

lua example in a Generic Item

```lua
local lmw = require'libmonitor-watch'
lmw:DEBUGGING(true) -- enable debugging
return lmw:CHECKLIBVERSION()
```

## in upcoming version

- replace the inmation.ESI.Objects with esi-objects

## Breaking changes

- Not Applicable
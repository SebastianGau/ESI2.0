# libmonitor-updater

This library contains functions to automatically update inmation libraries from github.

## INFO

| version | date       | description     |
| ------- | ---------- | --------------- |
| 0.0.1   | 24.04.2018 | Initial release |

## dependencies

| library      | version | inmation core library |
| ------------ | ------- | --------------------- |
| dkjson       | 2.5     | yes                   |
| esi-objects  | 0.1.1   | no                    |
| esi-variable | 0.1.2   | no                    |

## Available functions

### CHECKFORUPDATES

This function is checking, if a new version of a library provided in the repository TableHolder is available and updates this library.
>**At the moment only support for git repositories without authentication!**

The function will automatically create a empty TableHolder for the repositories, this would be the libraries from the ESI2.0
| name          | url                                                                                            | scope  |
| ------------- | ---------------------------------------------------------------------------------------------- | ------ |
| esi-objects   | <https://raw.githubusercontent.com/SebastianGau/ESI2.0/master/esi-objects/esi-objects.lua>     | System |
| esi-variables | <https://raw.githubusercontent.com/SebastianGau/ESI2.0/master/esi-variables/esi-variables.lua> | System |
| esi-bucket    | <https://raw.githubusercontent.com/SebastianGau/ESI2.0/master/esi-bucket/esi-bucket.lua>       | System |
| esi-odbc      | <https://raw.githubusercontent.com/SebastianGau/ESI2.0/master/esi-odbc/esi-odbc.lua>           | System |
| esi-schema    | <https://raw.githubusercontent.com/SebastianGau/ESI2.0/master/esi-schema/esi-schema.lua>       | System |
| esi-tables    | <https://raw.githubusercontent.com/SebastianGau/ESI2.0/master/esi-tables/esi-tables.lua>       | System |
| esi-vkpi      | <https://raw.githubusercontent.com/SebastianGau/ESI2.0/master/esi-vkpi/esi-vkpi.lua>           | System |

lua example in a Generic Item

```lua
local lmu = require'libmonitor-updater'
lmu:CHECKFORUPDATES()
```

### DEBUGGING

Enables debugging for the https calls.

lua example in a Generic Item

```lua
local lmu = require'libmonitor-updater'
lmu:DEBUGGING(true)
lmu:CHECKFORUPDATES()
```

## in upcoming version

- Logging of all changes
- Report of the logging
- Selection automatic update or manual update
- Support authentication

## Breaking changes

- Not Applicable
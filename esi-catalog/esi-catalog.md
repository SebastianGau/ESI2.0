# esi-catalog

A library for finding inmation objects

## Changes

| version | date       | description                 |
| ------- | ---------- | --------------------------- |
| 1       | 2018-18-05 | Initial release             |

## Available functions

### :FIND(props, settings, operators)

Tries to find an inmation object according to property values.

```lua
  local CAT = require 'esi-catalog'
  CAT:FIND("PropertyName","PropertyValue") 
  --if no operator is given, equality is assumed, so the following is equivalent:
  CAT:FIND("PropertyName", "PropertyValue", "=")
  --this is also equivalent: tables are used if multiple properties have to be examined
  CAT:FIND({"PropertyName"}, {"PropertyValue"}, {"="})
  --examine multiple properties:
  CAT:FIND({"PropertyName1", "Propname2"}, {"PropertyValue1", 3}, {"=", "<"})
  --check whether a property exists at all
  CAT:FIND({"PropertyName"}, {"%%"}, {"LIKE"})
  --custom properties work as wall
  CAT:FIND({"BASF.UseCase"}, {"PredM"}, {"="})
```

### :FINDONE(props, settings, operators)

Works exactly like :FIND, but tries to find only one object (and returns the corresponding inmation object reference if one is found). If multiple objects are found, nil is returned.

## Breaking changes

- Not Applicable
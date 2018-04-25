# libmonitor

This library contains functions for monitoring and maintaining lua libraries over the inmation webAPI.

## INFO

| version | date       | description                                                     |
| ------- | ---------- | --------------------------------------------------------------- |
| 0.1.4   | 17.04.2018 | function checklibs: adding `runtime-dependencies` to the output |
| 0.1.2   | 17.04.2018 | function checklibs: change json part of  INFO to json array     |
| 0.1.1   | 17.04.2018 | Initial release                                                 |

## dependencies

| library          | version | inmation core |
| ---------------- | ------- | ------------- |
| dkjson           | 2.5     | yes           |
| inmation.Catalog | -       | no            |

## Available functions

### checklibs

A webAPI call to get the versions of the all lua libraries form the inmation system using inmation.Catalog.

```html
http://localhost:8002/api/v2/execfunction/v2b?lib=libmonitor&func=getalllibs
```

Example response:

```json
[
    {
        "name": "local Core",
        "host": "localhost",
        "libs": [
            {
                "LuaModuleName": "libmonitor",
                "path": "/System/Core/Core Logic/Use Cases/libmonitor",
                "INFO": [
                    {
                        "library": [
                            {
                                "modulename": "libmonitor",
                                "dependencies": [
                                    {
                                        "modulename": "dkjson",
                                        "dependencies-version": [
                                            {
                                                "major": 2,
                                                "minor": 5,
                                                "revision": 0
                                            }
                                        ]
                                    },
                                    {
                                        "modulename": "inmation.Catalog",
                                        "dependencies-version": [
                                            {
                                                "major": 0,
                                                "minor": 0,
                                                "revision": 0
                                            }
                                        ]
                                    }
                                ]
                            }
                        ],
                        "contacts": [
                            {
                                "name": "Florian Seidl",
                                "email": "florian.seidl@cts-gmbh.de"
                            }
                        ],
                        "version": [
                            {
                                "major": 0,
                                "minor": 1,
                                "revision": 3
                            }
                        ]
                    }
                ],
                "runtime-dependencies": [
                    "dkjson",
                    "inmation.Catalog"
                ],
                "VERSION": "0.1.3"
            }
        ]
    }
]
]
```

## in upcoming version

- replace the inmation.Catalog with esi-catalog

## Breaking changes

- Not Applicable
# esi-odbc

A library for managing ODBC-Connections in lua

## Changes

version | date | description
------- | ---- | -----------
1 | 2018-04-16 | Initial release

## Available functions

### INFO

This is a mandatory function for every ESI library.

### ADG:CONNECTDATABASE(name)

### ADG:SELECTDATABASE(databasename)

### ADG:DISCONNECTDATABASE()



### :SETDEFAULTPROFILE(ProfileName)

### :CLEARCURRENTDATABASE()

### :ENSUREPROFILE(ProfileName, ProfileDescription)

### :GETPROFILENAMES()

### :GETPROFILESBYDESCRIPTION(ProfileDescription)

### :DELETEPROFILE(ProfileName)

### :CLEARPROFILE(ProfileName)

### :GETDASHBOARDSINPROFILE(ProfileName)

### :GETDASHBOARDSBYDESCRIPTION(DashboardDescription)

### :ENSUREDASHBOARDINPARENTPROFILE(ParentProfileName, DashboardName, DashboardDescription)

### :CLEARDASHBOARD(DashboardName)

### :DELETEDASHBOARD(DashboardName)

### :SETDEFAULTDASHBOARD(DashboardName)

### :GETDASHBOARDSBYDESCRIPTION(DashboardDescription)

### :ENSUREEMBEDDEDCONTENTCHART(ContentName, URL)

### :SETCONTENTURL(ContentName, URL)

### :ENSUREBOOKMARKFORALLPROFILES(BookmarkedDashboardName)

### :ENSUREBOOKMARK(TargetProfileName, BookmarkedDashboardName)

### :CLEARALLBOOKMARKS()

### :ADDWIDGETTODASHBOARD(DashboardName, inmationobject, options, opts)

can also be used as ```lua 
function(self, DashboardName, Contentname, ContentURL, {width = 4, height = 8})
```
or
```lua
can also be used as function(self, TargetDashboardName, LinkedDashboardName, {width = 4, height = 8})
```

### :SETDASHBOARDLINK(alarmkpiobj, targetdashboardname)

### Breaking changes

- Not Applicable
# i2b2 r plugin

## Introduction

They was a strong need to provide a new export plugin to i2b2. This one is :

- based on open-source softwares
- securised (auth, audit table, i2b2 roles)
- fast (direct SQL calls to the i2b2 database)
- compressed export
- flexible, and modifiable

## Screenshot

### 1 Specify the export

![Screenshot1](./screenshot-i2b2rplugin.png/?raw=true "i2b2rplugin screenshot1")

### 2 Get the zip file

![Screenshot2](./screenshot-i2b2rplugin-2.png/?raw=true "i2b2rplugin screenshot2")

### 3 Open the zip file

![Screenshot3](./screenshot-i2b2rplugin-3.png/?raw=true "i2b2rplugin screenshot3")

## prerequired 

- i2b2 1.7 and higher
- postgresql database
- linux (debian/ubunu prefered)
- opencpu
- RPostgres R package
  - libpq (postgresql development library)
- data.table R package
- jsonlite R package
- the i2b2rplugin plugin installed & configured in the i2b2 webclient

## installation

- i2b2pm
  - create the audit table running the config/i2b2\_create\_postgresql.sql
- i2b2rplugin R package
  - clone this repository
  - configure the config/\*.csv in order to choose exported columns and roles
  - configure the config/\*.R in order to transform the data for users
  - rename the config/\*\_observation\_fact.R in order to map your concept\_mapping\_prefix
  - copy/edit the config file to a securized destination accessible to openCPU user
  - place some documentation files in it
  - edit the R/function.R#PATH\_CONFIG accordingly
  - compile the package
  - install the package as root on the OpenCPU server (in order openCPU access to it)
- ExportOCPU i2B2 web plugin
  - moove the plugins/ExportOCPU to /i2b2/js-i2b2/cells/plugins/standard/
  - edit the i2b2/default.htm add the javascript dependencies
```
<script type="text/javascript" src="//code.jquery.com/jquery-3.1.0.min.js"></script>
<script type="text/javascript" src="//cdn.opencpu.org/opencpu-0.5.js"></script>
```
  - /i2b2/js-i2b2/i2b2\_loader.js add the plugin to the list
```
{ code: "ExportOCPU",
        forceLoading: true,
        forceConfigMsg: { params: [] },
        roles: [ "DATA_DEID", "DATA_PROT" ],
        forceDir: "cells/plugins/standard"
}
```
  - /i2b2/js-i2b2/cells/plugins/standard/ExportOCPU/cell\_config\_data.js : replace with your host
```
ocpuUrl : "//<your-ip>/ocpu/library/i2b2rplugin/R",
ocpuHost :  "http://<your-ip>"
```


## to be done

- oracle/msql connectors
- statistical functions

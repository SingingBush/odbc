ODBC for D
==========

[![DUB Package](https://img.shields.io/dub/v/odbc.svg)](https://code.dlang.org/packages/odbc) [![CI](https://github.com/SingingBush/odbc/actions/workflows/dub.yml/badge.svg)](https://github.com/SingingBush/odbc/actions/workflows/dub.yml)

For many years odbc has been available in phobos under *etc.c.odbc* due to the [work of David L. Davis](https://spottedtiger.tripod.com/D_Language/D_Support_Projects_XP.html) in 2006.

 - etc/c/odbc/sql.d
 - etc/c/odbc/sqlext.d
 - etc/c/odbc/sqltypes.d
 - etc/c/odbc/sqlucode.d

Those modules are now deprecated (see [Mark etc.c.odbc as deprecated](https://github.com/dlang/phobos/commit/88fd21e7368e8e2158a6ac75d43587c77886d6dd)), and the functionality being moved to *core.sys.windows*. As this will cause issues in packages that need to use ODBC from non-windows environments I created this package to simply move the code as it was [prior to the change](https://github.com/dlang/phobos/tree/d548e8830aee86c024faf3279dd8d7e35d26aae8/etc/c/odbc), so that it can simply be used as a dub package. The imports are now:

 - odbc/sql.d
 - odbc/sqlext.d
 - odbc/sqltypes.d
 - odbc/sqlucode.d

## Installing a driver

You'll need to have an ODBC driver installed. For example to use SQL Server you can use _msodbcsql17_, _msodbcsql18_ or _FreeTDS_.

### Windows

On Windows you can use chocolatey to install the SQL Server ODBC driver:

```
choco install sqlserver-odbcdriver
```

### Linux

To install Microsoft's ODBC Driver (either 17 or 18), you can install the _msodbcsql17_ or _msodbcsql18_ package. 

#### Ubuntu

```
sudo curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

sudo curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list

sudo ACCEPT_EULA=Y apt-get install msodbcsql17 -y
```
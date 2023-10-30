ODBC for D
==========

[![DUB Package](https://img.shields.io/dub/v/odbc.svg)](https://code.dlang.org/packages/odbc) [![CI](https://github.com/SingingBush/odbc/actions/workflows/dub.yml/badge.svg)](https://github.com/SingingBush/odbc/actions/workflows/dub.yml)

Since 2015 odbc has been available in phobos under *etc.c.odbc* thanks to the earlier work of [David L. Davis](https://spottedtiger.tripod.com/D_Language/D_Support_Projects_XP.html) in 2006.

 - etc/c/odbc/sql.d
 - etc/c/odbc/sqlext.d
 - etc/c/odbc/sqltypes.d
 - etc/c/odbc/sqlucode.d

Those modules were marked as deprecated in Jan 2021 (see [Mark etc.c.odbc as deprecated](https://github.com/dlang/phobos/commit/88fd21e7368e8e2158a6ac75d43587c77886d6dd)), and the functionality being moved to *core.sys.windows*, despite the fact that ODBC is not windows specific.

As this will cause issues in cross-platform packages that require ODBC (such as [DDBC](https://github.com/buggins/ddbc)), this package was created to simply move the code as it was [prior to the change](https://github.com/dlang/phobos/tree/d548e8830aee86c024faf3279dd8d7e35d26aae8/etc/c/odbc), so that it can simply be used as a dub package. With the import paths insterad being:

 - odbc/sql.d
 - odbc/sqlext.d
 - odbc/sqltypes.d
 - odbc/sqlucode.d

More recently, in Aug 2023 the situation was reveresed by the odbc module being moved back to *etc.c.odbc* and use of *core.sys.windows.sql* being marked as a warning.

 - https://github.com/dlang/dmd/pull/15560
 - https://github.com/dlang/phobos/pull/8804

These changes should be released in 2.106

**So where does this leave the odbc dub package?**

The primary downstream project that uses this package is [DDBC](https://github.com/buggins/ddbc) which supports D compilers >= 2.097. These events affected D comilers 2.096 through to 2.105.* and there are good reasons for it to not be part of the main libraries or phobos. So, for now at least, DDBC will continue to use this dub package and reassess the situation at a later date. 

There does seem to be some interest in updating the code in *etc.c.odbc* to support ODBC 4 (currently it's ODBC 3 only) which defines extensions to support non-relational concepts and would be a good future enhancement. Moving forward, enhancements made to *etc.c.odbc* may be ported into this repository, but I'm also updating this project based on changes in [Microsoft's ODBC-Specification](https://github.com/microsoft/ODBC-Specification) and [unixODBC](https://github.com/lurcher/unixODBC) so there could be some divergence. Either way this project will continue to use semantic versioning and get released in a way that hopefully doesn't break any downstream code.

If you plan to use odbc with the latest D compiler (2.106 and above) then *etc.c.odbc* may be the best choice for you. If your project needs to support multiple compiler releases and you don't want your builds to fail on compiler updates, consider using this package. 

## Database support

ODBC (Open Database Connectivity) is a widley supported standard that is used by all the major RDBMS vendors such as Microsoft SQL Server, IBM Db2. SAP ASE (previously Sybase), Oracle, PostgreSQL, MySQL (and MariaDB), and possibly more. That said, vendors have differing capabilities so potentially ODBC drivers may not implement all features. Some may even have non-standard features. Therefore efforts are made to test the code using different combinations of drivers and databases. As some providers are not as convenient for CI builds as others the level of testing may vary.

 - **Microsoft SQL Server** : Supported. Tests are run against SQL Server during CI
 - **Oracle** : Limited Support. Some testing done locally using [Oracle's OCR database image](https://container-registry.oracle.com/ords/ocr/ba/database) (requires Oracle account)
 - **IBM Db2** : Limited Support. Some testing done locally using `ibmcom/db2:latest` (the newer `icr.io/db2_community/db2` image from [IBM Cloud® Container Registry](https://cloud.ibm.com/registry/) requires IBM account)
 - **Postgres** : Should work, not currently tested.
 - **MySQL / MariaDB** : Should work, not currently tested.
 - **SAP ASE (Adaptive Server Enterprise, formerly Sybase)** : Should work. Could do with testing using the [SAP ASE 90 day trial](https://www.sap.com/products/technology-platform/sybase-ase/trial.html) or their cloud offering.

## Installing a driver

You'll need to have an ODBC driver installed. For example to use SQL Server you can use _msodbcsql17_, _msodbcsql18_ or _FreeTDS_. For [IBM Db2](https://www.ibm.com/products/db2/database) (and possibly [SAP ASE](https://www.sap.com/uk/products/technology-platform/sybase-ase.html)) you'll likely need to download required libraries from the respective companies and install them manually. 

### Windows

On Windows you can use chocolatey to install the SQL Server ODBC driver:

```
choco install sqlserver-odbcdriver
```

### Linux

On Linux you can potentially use [FreeTDS](https://www.freetds.org/) as the ODBC driver when connecting to SQL Server. However, Using Microsoft's _msodbcsql17_ or _msodbcsql18_ driver is recommended.

To install Microsoft's ODBC Driver (either 17 or 18), you can install the _msodbcsql17_ or _msodbcsql18_ package. 

#### Fedora / Red Hat

On Fedora Linux you can find packages under [packages.microsoft.com/config/rhel/](https://packages.microsoft.com/config/rhel/). See the documentation [here](https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver16#redhat18) for more details.The basic steps are:

```
curl https://packages.microsoft.com/config/rhel/9/prod.repo > /etc/yum.repos.d/mssql-release.repo

sudo yum remove unixODBC-utf16 unixODBC-utf16-devel
sudo ACCEPT_EULA=Y dnf install -y unixODBC unixODBC-devel msodbcsql18 mssql-tools18
```

Then check that the driver is configured in `/etc/odbcinst.ini`


#### Ubuntu

```
sudo curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

sudo curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list

sudo ACCEPT_EULA=Y apt-get install msodbcsql18 -y
```

## Building and running tests

Build the library using `dub build`. To run the integration test package you'll need to `docker compose up -d` from the project root then do the following:


```
dub build --config=integration-test
cd test/
```

Then run one of the following (depending on your driver version. Also note that _TrustServerCertificate_ may be required):

```
./odbctest "Driver={ODBC Driver 17 for SQL Server};Server=127.0.0.1,1433;Uid=sa;Pwd=bbk4k77JKH88g54;"

or

./odbctest "Driver={ODBC Driver 18 for SQL Server};Server=127.0.0.1,1433;Uid=sa;Pwd=bbk4k77JKH88g54;TrustServerCertificate=Yes"
```

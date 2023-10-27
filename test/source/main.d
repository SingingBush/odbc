// module main;

import odbc; // relies on package.d being pushed
// import odbc.sql;
// import odbc.sqlext;
// import odbc.sqltypes;
// import odbc.sqlucode;

import core.stdc.stdio : printf;

// import std.algorithm;
// import std.conv : to;
// import std.datetime : Date, DateTime, TimeOfDay;
// import std.datetime.date;
// import std.datetime.systime;
// import std.exception;
// import std.file;
import std.stdio : stderr, writeln, writefln;
import std.string : fromStringz, toStringz;
// import std.variant;

version(Windows) {
    string connectionString = "Driver={SQL Server};Server=127.0.0.1;Uid=sa;Pwd=bbk4k77JKH88g54;"; // Windows
} else {
    string connectionString = "Driver={ODBC Driver 17 for SQL Server};Server=127.0.0.1,1433;Uid=sa;Pwd=bbk4k77JKH88g54;TrustServerCertificate=Yes;"; // Unix
    //string connectionString = "Driver=msodbc17;Server=127.0.0.1,1433;Uid=sa;Pwd=bbk4k77JKH88g54;"; // Unix
    //string connectionString = "Driver=FreeTDS;Server=127.0.0.1,1433;Uid=sa;Pwd=bbk4k77JKH88g54;"; // Unix with FreeTDS
}

SQLHENV env = SQL_NULL_HENV; // environment handle
SQLHDBC conn = SQL_NULL_HDBC; // connection handle

/*
 * The test code is based on:
 * https://www.easysoft.com/developer/languages/c/odbc_tutorial.html#odbc_api
 * as well as the Microsoft documentation found here:
 * https://learn.microsoft.com/en-us/sql/odbc/reference/odbc-programmer-s-reference
 * https://learn.microsoft.com/en-us/sql/connect/odbc/cpp-code-example-app-connect-access-sql-db
 */
int main(string[] argv) {
    if(argv.length > 1) {
        connectionString = argv[1];
    }

    char[256] driver;
    char[256] attr;
    SQLSMALLINT driver_ret;
    SQLSMALLINT attr_ret;
    SQLUSMALLINT direction;
    SQLRETURN ret;

    SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env); // Allocate an environment handle
    SQLSetEnvAttr(env, SQL_ATTR_ODBC_VERSION, cast(SQLPOINTER*) SQL_OV_ODBC3, 0); // We want ODBC v3 support

    writeln("Checking installed drivers...");

    direction = SQL_FETCH_FIRST;
    while(SQL_SUCCEEDED(ret = SQLDrivers(env, direction, cast(char*) driver, driver.sizeof, &driver_ret, cast(char*) attr, attr.sizeof, &attr_ret))) {
        direction = SQL_FETCH_NEXT;

        writefln(" - %s:\t%s", fromStringz(cast(char*) driver), fromStringz(cast(char*) attr));

        if (ret == SQL_SUCCESS_WITH_INFO) {
            writeln("\tdata truncation\n");
        }
    }

    SQLAllocHandle(SQL_HANDLE_DBC, env, &conn); // allocate db connection

    SQLSetConnectAttr(conn, SQL_LOGIN_TIMEOUT, cast(SQLPOINTER) 3, 0); // Set login timeout to 3 seconds


    writefln("Connecting to db with: %s", connectionString);

    if(SQL_SUCCEEDED(ret = SQLDriverConnect(conn, null, cast(char*) toStringz(connectionString), SQL_NTS, null, 0, null, SQL_DRIVER_COMPLETE))) {
        SQLCHAR[256] dbms_name, dbms_ver;

        writeln("Connected");

        /*
        *  Find something out about the driver.
        */
        SQLGetInfo(conn, SQL_DBMS_NAME, cast(SQLPOINTER)dbms_name, dbms_name.sizeof, null);
        SQLGetInfo(conn, SQL_DBMS_VER, cast(SQLPOINTER)dbms_ver, dbms_ver.sizeof, null);

        writefln(" - DBMS Name:\t%s", fromStringz(cast(char*) dbms_name));
        writefln(" - DBMS Version:\t%s", fromStringz(cast(char*) dbms_ver));

        SQLUSMALLINT max_concur_act;
        SQLGetInfo(conn, SQL_MAX_CONCURRENT_ACTIVITIES, cast(SQLPOINTER)max_concur_act, max_concur_act.sizeof, null);

        if (max_concur_act == 0) {
            writeln("SQLGetData - SQL_MAX_CONCURRENT_ACTIVITIES = no limit or undefined");
        } else {
            writefln("SQLGetData - SQL_MAX_CONCURRENT_ACTIVITIES = %u", max_concur_act);
        }

        SQLUINTEGER getdata_support;
        SQLGetInfo(conn, SQL_GETDATA_EXTENSIONS, cast(SQLPOINTER)getdata_support, getdata_support.sizeof, null);
        
        if (getdata_support & SQL_GD_ANY_ORDER) {
            writeln("SQLGetData - columns can be retrieved in any order");
        } else {
            writeln("SQLGetData - columns must be retrieved in order");
        }

        if (getdata_support & SQL_GD_ANY_COLUMN) {
            writeln("SQLGetData - can retrieve columns before last bound one");
        } else {
            writeln("SQLGetData - columns must be retrieved after last bound one");
        }



        // Set auto commit on
        if(SQL_SUCCEEDED(ret = SQLSetConnectAttr(conn, SQL_ATTR_AUTOCOMMIT, cast(SQLPOINTER*) SQL_AUTOCOMMIT_ON, SQL_IS_UINTEGER))) {
            writeln("SQLSetConnectAttr - AUTOCOMMIT set to ON");
        } else {
            stderr.writeln("SQLSetConnectAttr - unable to set AUTOCOMMIT to on");
        }


        execDirect(`SELECT [name] FROM master.dbo.sysdatabases`);

        execDirect("DROP TABLE IF EXISTS [odbc_tst_t1]");
        execDirect("CREATE TABLE [odbc_tst_t1] ([id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY, [name] VARCHAR(255) NOT NULL, description VARCHAR(max), created DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL)");

        // INSERT test data (requires IDENTITY_INSERT to be set to ON)
        execDirect("SET IDENTITY_INSERT [odbc_tst_t1] ON");
        execDirect("INSERT INTO [odbc_tst_t1] ([id], [name], [description]) VALUES
                    (1, 'Name 1', 'description 1'),
                    (2, 'Name 2', 'description 2'),
                    (3, 'Name 3', 'description 3'),
                    (4, 'Name 4', 'description 4'),
                    (5, 'Name 5', 'description 5')");

        execDirect("SET IDENTITY_INSERT [odbc_tst_t1] OFF");
        execDirect("INSERT INTO [odbc_tst_t1] ([name], [description], [created]) VALUES
                    ('rand 1', 'Specific Date in 2023', '2023/10/19 15:18:01')");

        // SELECT test data
        execDirect("SELECT [name] FROM [odbc_tst_t1]");

        // todo: create some select statements for different data types and ensure data can be retrieved + do prepared statements

        // Disconnect from db and free alloacted handles:
        SQLDisconnect(conn);
        SQLFreeHandle(SQL_HANDLE_DBC, conn);
        SQLFreeHandle(SQL_HANDLE_ENV, env);
    } else {
        stderr.writefln("Failed to connect to database. SQL return code: %d", ret);
        return 1;
    }

    return 0;
}

// If a call to SQL reurns -1 (SQL_ERROR) then this function can be called to get the error message
void writeErrorMessage(SQLHSTMT stmt) {
    SQLCHAR[6] sqlstate; // A string of 5 characters terminated by a null character. The first 2 characters indicate error class; the next 3 indicate subclass.
    SQLINTEGER nativeError;
    SQLCHAR[SQL_MAX_MESSAGE_LENGTH] messageText;
    SQLSMALLINT bufferLength = messageText.length;
    SQLSMALLINT textLength;

    SQLRETURN ret = SQLError(
        env,
        conn,
        stmt,
        &sqlstate[0],
        &nativeError,
        &messageText[0],
        bufferLength,
        &textLength
    );

    if(SQL_SUCCEEDED(ret)) {
        //writefln("SQL State %s, Error %d : %s", fromStringz(sqlstate.ptr), nativeError, fromStringz(messageText.ptr));
        writefln("SQL State %s, Error %d : %s", fromStringz(cast(char*) sqlstate), nativeError, fromStringz(cast(char*) messageText));
    }
}

void execDirect(string sql) {
    SQLHSTMT stmt;
    SQLRETURN ret;

    SQLAllocStmt(conn, &stmt);

    if(SQL_SUCCEEDED(ret = SQLExecDirect(stmt, cast(SQLCHAR*) toStringz(sql), SQL_NTS))) {
        writefln("SQLExecDirect succeeded : %s", sql);
    } else {
        stderr.writefln("SQLExecDirect failed. SQL return code: %d", ret);
        
        if(ret == SQL_ERROR) {
            writeErrorMessage(stmt);
        }
    }

    SQLINTEGER rowsAffected = 0; // SQLINTEGER is just an alias for int
    ret = SQLRowCount(stmt, &rowsAffected);
    if(rowsAffected > 0) {
        // if a UPDATE, INSERT, or DELETE has been done then we can expect number of rows affected
        writefln("%d rows affected", rowsAffected);
    }

    SQLSMALLINT num = 0; // SQLSMALLINT is just an alias for short
    ret = SQLNumResultCols(stmt, &num); // SQLNumResultCols should be called after statement excuted and if result > 0 there is a result set

    struct Column {
        SQLINTEGER index;
        SQLCHAR[32] stringVal;
    }

    if(num > 0) {
        writefln("We have a result set with %d columns:", num);

        Column col;

        ret = SQLBindCol(stmt, 1, SQL_C_CHAR, cast(SQLCHAR*) col.stringVal, col.stringVal.sizeof, null);

        while ((ret = SQLFetch(stmt)) == SQL_SUCCESS) {
            writefln(" - column %d : %s", col.index, fromStringz(cast(char*) col.stringVal));
        }
    }

    SQLFreeHandle(SQL_HANDLE_STMT, stmt);
}

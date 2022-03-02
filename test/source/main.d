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
    string connectionString = "Driver={ODBC Driver 17 for SQL Server};Server=127.0.0.1,1433;Uid=sa;Pwd=bbk4k77JKH88g54;"; // Unix
    //string connectionString = "Driver=msodbc17;Server=127.0.0.1,1433;Uid=sa;Pwd=bbk4k77JKH88g54;"; // Unix
    //string connectionString = "Driver=FreeTDS;Server=127.0.0.1,1433;Uid=sa;Pwd=bbk4k77JKH88g54;"; // Unix with FreeTDS
}


/*
 * The test code is based on:
 * https://www.easysoft.com/developer/languages/c/odbc_tutorial.html#odbc_api
 */
int main(string[] argv) {
    if(argv.length > 1) {
        connectionString = argv[1];
    }

    SQLHENV env = SQL_NULL_HENV; // environment handle
    SQLHDBC conn = SQL_NULL_HDBC; // connection handle
    // SQLHSTMT stmt; // statement handle
    // SQLHDESC desc; // descriptor handle

    char[256] driver;
    char[256] attr;
    SQLSMALLINT driver_ret;
    SQLSMALLINT attr_ret;
    SQLUSMALLINT direction;
    SQLRETURN ret;

    SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env); // Allocate an environment handle
    SQLSetEnvAttr(env, SQL_ATTR_ODBC_VERSION, cast(SQLPOINTER*) SQL_OV_ODBC3, 0); // We want ODBC v3 support

    direction = SQL_FETCH_FIRST;
    while(SQL_SUCCEEDED(ret = SQLDrivers(env, direction, cast(char*) driver, driver.sizeof, &driver_ret, cast(char*) attr, attr.sizeof, &attr_ret))) {
        direction = SQL_FETCH_NEXT;

        //printf("%s - %s\n", cast(char*) driver, cast(char*) attr); // todo: use D style syntax
        writefln("%s - %s", fromStringz(cast(char*) driver), fromStringz(cast(char*) attr));

        if (ret == SQL_SUCCESS_WITH_INFO) {
            writeln("\tdata truncation\n");
        }
    }

    SQLAllocHandle(SQL_HANDLE_DBC, env, &conn); // allocate db connection

    SQLSetConnectAttr(conn, SQL_LOGIN_TIMEOUT, cast(SQLPOINTER) 3, 0); // Set login timeout to 3 seconds


    writefln("Connecting to db with: %s", connectionString);

    if(SQL_SUCCEEDED(ret = SQLDriverConnect(conn, null, cast(char*) toStringz(connectionString), SQL_NTS, null, 0, null, SQL_DRIVER_COMPLETE))) {
        SQLCHAR[256] dbms_name, dbms_ver;
        SQLUINTEGER getdata_support;
        // SQLUSMALLINT max_concur_act;
        // SQLSMALLINT string_len;

        writeln("Connected");

        /*
        *  Find something out about the driver.
        */
        SQLGetInfo(conn, SQL_DBMS_NAME, cast(SQLPOINTER)dbms_name, dbms_name.sizeof, null);
        SQLGetInfo(conn, SQL_DBMS_VER, cast(SQLPOINTER)dbms_ver, dbms_ver.sizeof, null);
        // SQLGetInfo(conn, SQL_GETDATA_EXTENSIONS, cast(SQLPOINTER)&getdata_support, 0, 0);
        // SQLGetInfo(conn, SQL_MAX_CONCURRENT_ACTIVITIES, &max_concur_act, 0, 0);

        writefln("DBMS Name:\t%s", fromStringz(cast(char*) dbms_name));
        writefln("DBMS Version:\t%s", fromStringz(cast(char*) dbms_ver));

        // if (max_concur_act == 0) {
        //     printf("SQL_MAX_CONCURRENT_ACTIVITIES - no limit or undefined\n");
        // } else {
        //     printf("SQL_MAX_CONCURRENT_ACTIVITIES = %u\n", max_concur_act);
        // }

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

        SQLDisconnect(conn);
    } else {
        stderr.writefln("Failed to connect to database. SQL return code: %u", ret);
        return 1;
    }

    //SQLRETURN SQLPrepare(SQLHSTMT stmt, SQLCHAR *StatementText, SQLINTEGER TextLength);
    //SQLRETURN r = SQLAllocHandle(cast(short) SQL_HANDLE_STMT, conn, &stmt);

    return 0;
}
<?php


/*
 * you may need this line, depending on how you compile
 * this extension.
 */

dl('sqlite3.so');


/*
 * create a SQLite3 handle. 
 *
 * Note: in-memory database are created by the magic keyword ":memory:"
 *
 */

$db = sqlite3_open(":memory:");
if (!$db) die ("Could not create in-memory database..");

/*
 * create a simple test and insert some values..
 */

$ret = sqlite3_exec ($db, "CREATE TABLE test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER);");
if (!$ret) die (sqlite3_error($db));

sqlite3_exec($db, "INSERT INTO test (name,age) VALUES ('michael',32)");
echo "last rowid inserted : " . sqlite3_last_insert_rowid($db) ."\n";

sqlite3_exec($db, "INSERT INTO test (name,age) VALUES ('bob',27)");
echo "last rowid inserted : " . sqlite3_last_insert_rowid($db) ."\n";

sqlite3_exec($db, "INSERT INTO test (name,age) VALUES ('martin',12)");
echo "last rowid inserted : " . sqlite3_last_insert_rowid($db) ."\n";


sqlite3_close($db);


?>

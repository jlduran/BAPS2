<?php

/*
 * you may need this line, depending on how you compile
 * this extension.
 */

dl('sqlite3.so');


/*
 * create a callback function.
 *
 * It will be called by sqlite3_exec() for each row in the result
 * set.
 */

function my_callback($data, $columns)
{

	echo "my_callback called !\n";
  echo "1st argument: " . implode($data, ',')    ."\n";
  echo "2nd argument: " . implode($columns, ',') ."\n";
  
  return 0;
}


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
sqlite3_exec($db, "INSERT INTO test (name,age) VALUES ('bob',27)");
sqlite3_exec($db, "INSERT INTO test (name,age) VALUES ('martin',12)");


/*
 * Note the 3rd argument to this function ...
 *
 */

$res = sqlite3_exec($db, "SELECT * from test ORDER BY name", "my_callback");


sqlite3_close($db);

?>

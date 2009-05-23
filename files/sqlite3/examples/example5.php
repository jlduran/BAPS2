<?php

/*
 * you may need this line, depending on how you compile
 * this extension.
 */

dl('sqlite3.so');

/* column type<=>name map */

$col_types = array (
  SQLITE3_INTEGER => "integer",
  SQLITE3_FLOAT   => "float",
  SQLITE3_TEXT    => "text",
  SQLITE3_BLOB    => "blob",
  SQLITE3_NULL    => "null");
  


/*
 * create a SQLite3 handle. 
 *
 * Note: in-memory database are created by the magic keyword ":memory:"
 *
 */

$db = sqlite3_open(":memory:");
if (!$db) die ("Could not create in-memory database..");

if (! sqlite3_exec($db, "create table test (a int, b text, c double, d blob)"))
	die (sqlite3_error($db));


$res = sqlite3_query($db, "insert into test (a,b,c, d) VALUES (?, ?, ?, ?)");
if (!$res) die (sqlite3_error($db));

if (!sqlite3_bind_int   ($res, 1, 10))      die (sqlite3_error($db));
if (!sqlite3_bind_text  ($res, 2, "bob"))   die (sqlite3_error($db));
if (!sqlite3_bind_double($res, 3, 3.1415))  die (sqlite3_error($db));
if (!sqlite3_bind_blob  ($res, 4, file_get_contents("/bin/sh"))) die (sqlite3_error($db));

if (! sqlite3_query_exec($res, TRUE))	/* TRUE: delete the resource after the execution */
	die (sqlite3_error($db));

$res = sqlite3_query($db, "SELECT * from test");
if (!$res) 
	die (sqlite3_error($db));
  
$a_row = sqlite3_fetch_array($res);

for($n=0; $n < sqlite3_column_count($res); $n++)
{
	echo "column $n: type " . $col_types{sqlite3_column_type($res, $n)} ."\n";
}

sqlite3_query_close($res);


sqlite3_close($db);

?>

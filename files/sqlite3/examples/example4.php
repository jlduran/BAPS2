<?php

/*
 * you may need this line, depending on how you compile
 * this extension.
 */

dl('sqlite3.so');


/*
 * create a SQL function
 *
 * It will be called by sqlite3_exec() for each row in the result
 * set.
 */


function get_sha1($x)
{
	return sha1($x);
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
 * Define a new SQL function: sha1, which takes
 * only one argument.
 * SQLite3 library will call the PHP function get_sha1() 
 * to get the result.
 *
 */

if (!sqlite3_create_function($db, "sha1", 1, "get_sha1")) 
	die("sqlite3_create_function() failed.");
  
  

$res =  sqlite3_query($db, "select sha1('my password')");
if (!$res) die (sqlite3_error($db));

$row = sqlite3_fetch_array($res);

if (!$row) 
	echo "error: " . sqlite3_error($db);
else  
	var_dump($row);

sqlite3_query_close ($res);


sqlite3_close($db);

?>

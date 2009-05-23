<?php

/* Slightly modified php-5.2.5/ext/sqlite3/examples/example1.php */

/*
 * you may need this line, depending on how you compile
 * this extension.
 */

print "<html>\n";

if (! extension_loaded('sqlite3') ) {
       print("Loading sqlite3.so....<br>");
       dl('sqlite3.so');
}

/*
 * create a SQLite3 handle. 
 *
 * Note: in-memory database are created by the magic keyword ":memory:"
 *
 */

$db = sqlite3_open("/tmp/test.db");
if (!$db) die ("Could not create in-memory database..");

/*
 * create a simple test and insert some values..
 */

print "Creating table:<br>\n";
$ret = sqlite3_exec ($db, "CREATE TABLE test (id INTEGER, name TEXT, age INTEGER);");
if (!$ret) 
	print "\ttable already exists<br>\n";
else
	print "\ttable created<br>\n";

print "Inserting values:<br>\n";
sqlite3_exec($db, "INSERT INTO test (id,name,age) VALUES (1,'michael',32)");
sqlite3_exec($db, "INSERT INTO test (id,name,age) VALUES (2,'bob',27)");
sqlite3_exec($db, "INSERT INTO test (id,name,age) VALUES (3,'martin',12)");

/*
 * Create a query
 */

print "SQL query:<br>\n";
$query = sqlite3_query($db, "SELECT * FROM test ORDER BY age DESC");
if (!$query) die (sqlite3_error($db));

/*
 * sqlite3_fetch_array() returns an associative array 
 * for each row in the result set. Key indexes are 
 * the columns names.
 *
 */

while ( ($row = sqlite3_fetch_array($query)))
{
	printf("\t%-20s %u<br>\n", $row['name'], $row['age']);
}

/*
 * do not forget to release all handles !
 *
 */

print "Closing:<br>\n";
sqlite3_query_close($query);
sqlite3_close ($db);

print "</html>\n";

?>


PHP_ARG_WITH(sqlite3,  for sqlite3 support,
[  --with-sqlite3[=DIR]    Include sqlite3 support.])

if test "$PHP_SQLITE3" != "no"; 
then

  
  PHP_NEW_EXTENSION(sqlite3, php_sqlite3.c, $ext_shared)    
  PHP_SUBST(SQLITE3_SHARED_LIBADD)
  
  AC_DEFINE(HAVE_SQLITE3, 1, [Whether you have sqlite3])

	SQLITE3_INCDIR=$PHP_SQLITE3/include
  SQLITE3_LIBDIR=$PHP_SQLITE3/lib
  
  PHP_ADD_LIBRARY_WITH_PATH(sqlite3, $SQLITE3_LIBDIR, SQLITE3_SHARED_LIBADD)
  PHP_ADD_INCLUDE($SQLITE3_INCDIR)  
  
fi 

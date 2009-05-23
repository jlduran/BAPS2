#ifndef PHP_SQLITE3_H
#define PHP_SQLITE3_H 1

#define PHP_SQLITE3_VERSION "1.0"
#define PHP_SQLITE3_EXTNAME "SQLITE3"


#include <sqlite3.h>


PHP_MINIT_FUNCTION(sqlite3);
PHP_MINFO_FUNCTION(sqlite3);

PHP_FUNCTION(sqlite3_libversion);
PHP_FUNCTION(sqlite3_open);
PHP_FUNCTION(sqlite3_close);
PHP_FUNCTION(sqlite3_error);
PHP_FUNCTION(sqlite3_exec);
PHP_FUNCTION(sqlite3_query);
PHP_FUNCTION(sqlite3_changes);

PHP_FUNCTION(sqlite3_bind_int);
PHP_FUNCTION(sqlite3_bind_double);
PHP_FUNCTION(sqlite3_bind_text);
PHP_FUNCTION(sqlite3_bind_blob);
PHP_FUNCTION(sqlite3_bind_null);

PHP_FUNCTION(sqlite3_query_exec);

PHP_FUNCTION(sqlite3_fetch);
PHP_FUNCTION(sqlite3_fetch_array);
PHP_FUNCTION(sqlite3_column_count);
PHP_FUNCTION(sqlite3_column_name);
PHP_FUNCTION(sqlite3_column_type);

PHP_FUNCTION(sqlite3_query_close);

PHP_FUNCTION(sqlite3_last_insert_rowid);
PHP_FUNCTION(sqlite3_create_function);



#define PHP_SQLITE3_FETCH_ASSOC 1
#define PHP_SQLITE3_FETCH_INDEX 2




extern zend_module_entry sqlite3_module_entry;
#define phpext_sqlite3_ptr &sqlite3_module_entry

#endif

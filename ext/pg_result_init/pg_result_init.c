#include <libpq-fe.h>
#include <pg.h>
#include "pg_result_init.h"

VALUE rb_mPgResultInit;

static VALUE
pg_result_init_hello() {
  printf("kerk");

  return Qnil;
}

// TODO: always check the return value of malloc
// TODO: maybe check return value pg_new_result?
// TODO: do type checking on the VALUE variables
static VALUE
pg_result_init_create(VALUE self, VALUE rb_pgconn, VALUE rb_columns, VALUE rb_rows) {
	t_pg_connection *p_conn = pg_get_connection(rb_pgconn);
  PGconn *conn = p_conn->pgconn;

  /*
   * status 2 is for regular success
   * https://www.postgresql.org/docs/10/libpq-misc.html
   */
  int status = 2;

  PGresult *result = PQmakeEmptyPGresult(conn, status);
  VALUE rb_pgresult = pg_new_result(result, rb_pgconn);

  /* printf("%zu", sizeof(PGresAttDesc)); */

  int num_columns = RARRAY_LEN(rb_columns);
  PGresAttDesc *attDescs = malloc(num_columns * sizeof(PGresAttDesc));

  int index;
  VALUE rb_column;
  VALUE rb_column_name;
  char *column_name;

  for(index = 0; index < num_columns; index++) {
    rb_column = rb_ary_entry(rb_columns, index);
    rb_column_name = rb_funcall(rb_column, rb_intern("fetch"), 1, ID2SYM(rb_intern("name")));

    // Using StringValueCStr, if column contains null bytes it should raise Argument error
    // postgres does not handle null bytes.
    column_name = StringValueCStr(rb_column_name);

    rb_p(rb_column_name);

    // postgres/src/interfaces/libpq/libpq-fe.h:235
    attDescs[index].name = column_name; // TODO: do we need to copy the contents or can we use a reference?
    attDescs[index].tableid = 0;
    attDescs[index].columnid = 0;
    attDescs[index].format = 0; // 0 is text, 1 is binary https://www.postgresql.org/docs/10/libpq-exec.html
    attDescs[index].typid = 0;
    attDescs[index].typlen = 4;
    attDescs[index].atttypmod = -1; // -1 no type modifier
  }

  PQsetResultAttrs(result, num_columns, attDescs);

  free(attDescs);

  int num_rows = RARRAY_LEN(rb_rows);
  int row_index;
  int column_index;
  VALUE rb_row;
  VALUE rb_value;
  char *value;
  int value_len;

  for(row_index = 0; row_index < num_rows; row_index++) {
    for(column_index = 0; column_index < num_columns; column_index++) {
      rb_row = rb_ary_entry(rb_rows, row_index);
      rb_value = rb_ary_entry(rb_row, column_index);

      // TODO: maybe casting to string can be better?
      rb_value = rb_funcall(rb_value, rb_intern("to_s"), 0);

      // Using StringValueCStr, if column contains null bytes it should raise Argument error
      // postgres does not handle null bytes.
      value = StringValueCStr(rb_value);
      value_len = RSTRING_LEN(rb_value);

      PQsetvalue(result, row_index, column_index, value, value_len);
    }
  }

  return rb_pgresult;
}

void
Init_pg_result_init(void)
{
  rb_mPgResultInit = rb_define_module("PgResultInit");

  rb_define_module_function(rb_mPgResultInit, "hello", pg_result_init_hello, 0);

  /* `2` means that the method accepts 2 arguments */
  rb_define_module_function(rb_mPgResultInit, "create", pg_result_init_create, 3);
}

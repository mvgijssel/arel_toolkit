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
pg_result_init_create(VALUE self, VALUE rb_pgconn, VALUE rb_columns, VALUE rb_tuples) {
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

  int numAttributes = RARRAY_LEN(rb_columns);
  PGresAttDesc *attDescs = malloc(numAttributes * sizeof(PGresAttDesc));

  int index;
  VALUE rb_column;
  VALUE rb_column_name;
  char *column_name;

  for(index = 0; index < numAttributes; index++) {
    rb_column = rb_ary_entry(rb_columns, index);
    rb_column_name = rb_funcall(rb_column, rb_intern("fetch"), 1, ID2SYM(rb_intern("name")));

    // Using StringValueCStr, if column contains null bytes it should raise Argument error
    // postgres does not handle null bytes.
    column_name = StringValueCStr(rb_column_name);

    rb_p(rb_column_name);

    // TODO: do we need to copy the contents or can we use a reference?
    attDescs[index].name = column_name;
  }

  PQsetResultAttrs(result, numAttributes, attDescs);

  free(attDescs);

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

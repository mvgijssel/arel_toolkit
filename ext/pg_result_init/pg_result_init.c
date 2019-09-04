#include <libpq-fe.h>
#include <pg.h>
#include "pg_result_init.h"

VALUE rb_mPgResultInit;

static VALUE
pg_result_init_hello() {
  printf("kerk");

  return Qnil;
}

static VALUE
pg_result_init_create(VALUE self, VALUE rb_pgconn, VALUE columns) {
	t_pg_connection *p_conn = pg_get_connection(rb_pgconn);
  PGconn *conn = p_conn->pgconn;

  /*
   * status 2 is for regular success
   * https://www.postgresql.org/docs/10/libpq-misc.html
   */
  int status = 2;

  PGresult *result = PQmakeEmptyPGresult(conn, status);
  VALUE rb_pgresult = pg_new_result(result, rb_pgconn);

  column = rb_ary_entry(columns, 0);

  return rb_pgresult;
}

void
Init_pg_result_init(void)
{
  rb_mPgResultInit = rb_define_module("PgResultInit");

  rb_define_module_function(rb_mPgResultInit, "hello", pg_result_init_hello, 0);

  /* `2` means that the method accepts 2 arguments */
  rb_define_module_function(rb_mPgResultInit, "create", pg_result_init_create, 2);
}

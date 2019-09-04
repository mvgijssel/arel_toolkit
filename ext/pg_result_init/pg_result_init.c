#include "pg_result_init.h"

VALUE rb_mPgResultInit;

static VALUE
pg_result_init_hello() {
  printf("kerk");

  return Qnil;
}

void
Init_pg_result_init(void)
{
  rb_mPgResultInit = rb_define_module("PgResultInit");

  rb_define_module_function(rb_mPgResultInit, "hello", pg_result_init_hello, 0);
}

#include <libpq-fe.h>
#include "pg_result_init.h"

VALUE rb_mPgResultInit;

/* defined by ruby-pg */
PGresult* pgresult_get(VALUE);
VALUE pg_new_result _(( PGresult *, VALUE ));
VALUE rb_mPG;
VALUE rb_cPGresult;
VALUE rb_cPGconn;

static VALUE
pg_result_init_create(VALUE self, VALUE rb_pgconn, VALUE rb_result, VALUE rb_columns, VALUE rb_rows) {
  Check_Type(rb_columns, T_ARRAY);
  Check_Type(rb_rows, T_ARRAY);

	if (!rb_obj_is_kind_of(rb_result, rb_cPGresult)) {
	  rb_raise(
      rb_eTypeError,
      "wrong argument type %s (expected kind of PG::Result)",
      rb_obj_classname(rb_result)
    );
  }

  if (!rb_obj_is_kind_of(rb_pgconn, rb_cPGconn)) {
    rb_raise(
      rb_eTypeError,
      "wrong argument type %s (expected kind of PG::Connection)",
      rb_obj_classname(rb_pgconn)
    );
  }

  PGresult *result = pgresult_get(rb_result);
  PGresult *result_copy = PQcopyResult(result, PG_COPYRES_EVENTS | PG_COPYRES_NOTICEHOOKS);

  int num_columns = RARRAY_LEN(rb_columns);
  PGresAttDesc *attDescs = malloc(num_columns * sizeof(PGresAttDesc));

  if (attDescs == NULL)
    rb_raise(rb_eRuntimeError, "Cannot allocate memory");

  int index;
  VALUE rb_column;
  VALUE rb_column_name;
  VALUE rb_table_id;
  VALUE rb_column_id;
  VALUE rb_format;
  VALUE rb_typ_id;
  VALUE rb_typ_len;
  VALUE rb_att_typemod;

  char *column_name;

  for(index = 0; index < num_columns; index++) {
    rb_column = rb_ary_entry(rb_columns, index);
    Check_Type(rb_column, T_HASH);

    rb_column_name = rb_funcall(rb_column, rb_intern("fetch"), 1, ID2SYM(rb_intern("name")));

    // 0 means unknown tableid
    rb_table_id = rb_funcall(rb_column, rb_intern("fetch"), 2, ID2SYM(rb_intern("tableid")), INT2NUM(0));

    // 0 means unknown columnid
    rb_column_id = rb_funcall(rb_column, rb_intern("fetch"), 2, ID2SYM(rb_intern("columnid")), INT2NUM(0));

    // 0 is text, 1 is binary https://www.postgresql.org/docs/10/libpq-exec.html
    rb_format = rb_funcall(rb_column, rb_intern("fetch"), 2, ID2SYM(rb_intern("format")), INT2NUM(0));

    rb_typ_id = rb_funcall(rb_column, rb_intern("fetch"), 1, ID2SYM(rb_intern("typid")));
    rb_typ_len = rb_funcall(rb_column, rb_intern("fetch"), 1, ID2SYM(rb_intern("typlen")));

    // -1 means that there is no type modifier
    rb_att_typemod = rb_funcall(rb_column, rb_intern("fetch"), 2, ID2SYM(rb_intern("atttypmod")), INT2NUM(-1));

    // Using StringValueCStr, if column contains null bytes it should raise Argument error
    // postgres does not handle null bytes.
    column_name = StringValueCStr(rb_column_name);

    // postgres/src/interfaces/libpq/libpq-fe.h:235
    attDescs[index].name = column_name;
    attDescs[index].tableid = NUM2INT(rb_table_id);
    attDescs[index].columnid = NUM2INT(rb_column_id);
    attDescs[index].format = NUM2INT(rb_format);
    attDescs[index].typid = NUM2INT(rb_typ_id);
    attDescs[index].typlen = NUM2INT(rb_typ_len);
    attDescs[index].atttypmod = NUM2INT(rb_att_typemod);
  }

  int success;

  success = PQsetResultAttrs(result_copy, num_columns, attDescs);

  if (success == 0)
    rb_raise(rb_eRuntimeError, "PQsetResultAttrs failed: %d", success);

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

      if (NIL_P(rb_value)) {
        success = PQsetvalue(result_copy, row_index, column_index, NULL, -1);

        if (success == 0)
          rb_raise(rb_eRuntimeError, "PQsetvalue failed: %d", success);
      }
      else {
        rb_value = rb_funcall(rb_value, rb_intern("to_s"), 0);

        // Using StringValueCStr, if column contains null bytes it should raise Argument error
        // postgres does not handle null bytes.
        value = StringValueCStr(rb_value);
        value_len = RSTRING_LEN(rb_value);

        success = PQsetvalue(result_copy, row_index, column_index, value, value_len);

        if (success == 0)
          rb_raise(rb_eRuntimeError, "PQsetvalue failed: %d", success);
      }
    }
  }

  VALUE rb_pgresult = pg_new_result(result_copy, rb_pgconn);
  return rb_pgresult;
}

void
Init_pg_result_init(void)
{
  rb_mPG = rb_define_module( "PG" );
  rb_cPGresult = rb_define_class_under( rb_mPG, "Result", rb_cObject );
  rb_cPGconn = rb_define_class_under( rb_mPG, "Connection", rb_cObject );

  rb_mPgResultInit = rb_define_module("PgResultInit");
  rb_define_module_function(rb_mPgResultInit, "create", pg_result_init_create, 4);
}

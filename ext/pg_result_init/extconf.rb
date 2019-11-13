require 'mkmf'

CONFIG['debugflags'] = '-ggdb3'
CONFIG['optflags'] = '-O0'

# https://github.com/jeremyevans/sequel_pg/blob/master/ext/sequel_pg/extconf.rb

dir_config(
  'pg',
  '/Applications/Postgres.app/Contents/Versions/11/include',
  '/Applications/Postgres.app/Contents/Versions/11/lib',
)

if (
    have_library('pq') ||
    have_library('libpq') ||
    have_library('ms/libpq')
  ) &&
   have_header('libpq-fe.h') &&
   have_func('PQcopyResult') &&
   have_func('PQsetResultAttrs') &&
   have_func('PQsetvalue')

  create_makefile('arel_toolkit/pg_result_init')
else
  abort 'Could not find PostgreSQL build environment (libraries & headers): Makefile not created'
end

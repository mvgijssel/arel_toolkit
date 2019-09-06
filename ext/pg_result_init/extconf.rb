# read, write = IO.pipe

# pid = Process.fork do
#   require 'pg'
#   pg_ext = Gem.loaded_specs.fetch('pg')
#   pg_ext_inlude_dir = File.join(pg_ext.full_gem_path, 'ext')
#   pg_ext_lib_dir = pg_ext.extension_dir
#   write.puts("#{pg_ext_inlude_dir},#{pg_ext_lib_dir}")
#   puts "DONE PROCESS"
# end

# Process.wait(pid)
# write.close
# pg_ext_include_dir, pg_ext_lib_dir = read.read.chomp.split(",")
# read.close

# require 'pry'
# binding.pry

pg_ext_include_dir = "/Users/maarten/.anyenv/envs/rbenv/versions/2.5.3/lib/ruby/gems/2.5.0/gems/pg-1.1.4/ext"
pg_ext_lib_dir = '/Users/maarten/.anyenv/envs/rbenv/versions/2.5.3/lib/ruby/gems/2.5.0/extensions/x86_64-darwin-18/2.5.0-static/pg-1.1.4'

require 'mkmf'

CONFIG['debugflags'] = '-ggdb3'
CONFIG['optflags'] = '-O0'

# https://github.com/jeremyevans/sequel_pg/blob/master/ext/sequel_pg/extconf.rb

pg_include_dir = ENV['POSTGRES_INCLUDE'] ||
                 (begin
                    IO.popen('pg_config --includedir').readline.chomp
                  rescue StandardError
                    nil
                  end)
pg_lib_dir = ENV['POSTGRES_LIB'] ||
             (begin
                IO.popen('pg_config --libdir').readline.chomp
              rescue StandardError
                nil
              end)

dir_config(
  'pg',
  pg_include_dir,
  pg_lib_dir,
)

# require 'pry'
# binding.pry

dir_config(
  'pg_ext',
  pg_ext_include_dir,
  pg_ext_lib_dir,
)

if (
    have_library('pq') ||
    have_library('libpq') ||
    have_library('ms/libpq')
  ) &&
   have_header('libpq-fe.h') &&
   have_header('pg.h')

  # have_func 'PQsetSingleRowMode'
  # have_func 'timegm'

  # TODO: check pg_result_init.c for required enums / functions

  create_makefile('pg_result_init/pg_result_init')
else
  raise 'Could not find PostgreSQL build environment (libraries & headers): Makefile not created'
end

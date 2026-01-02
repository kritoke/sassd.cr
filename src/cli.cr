require "./sassd"

if ARGV.empty?
  puts "Usage: sassd [input_file]"
  exit 1
end

begin
  puts Sass.compile_file(ARGV[0])
rescue ex : Sass::CompilationError
  STDERR.puts ex.message
  exit 1
end

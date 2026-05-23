# Sass CLI Command Line Interface
#
# This module provides a command-line interface for the Sass compiler.
# It supports all the standard Sass compilation options and provides
# helpful usage information and error messages.
#
# ## Usage
#
# Basic usage:
# ```bash
# sassd input.scss
# sassd input.scss -o output.css
# ```
#
# With options:
# ```bash
# sassd --style compressed --source-map input.scss -o output.css
# ```
require "./sassd"

# CLI options structure
struct Sass::CLI::Options
  property input_file : String?
  property output_file : String?
  property style : String = "expanded"
  property source_map : Bool = false
  property source_map_embed : Bool = false
  property source_map_urls : String = "relative"
  property embed_sources : Bool = false
  property charset : Bool = true
  property error_css : Bool = true
  property quiet : Bool = false
  property quiet_deps : Bool = false
  property verbose : Bool = false
  property load_paths = [] of String
  property force : Bool = false

  def initialize
  end
end

# Simple CLI argument parser
class Sass::CLI
  def self.run(args : Array(String))
    if args.empty?
      show_help
      exit 0
    end

    options = parse_args(args)
    validate_and_execute(options)
  end

  private def self.parse_args(args : Array(String)) : Options
    options = Options.new
    i = 0

    while i < args.size
      arg = args[i]
      case arg
      when "--help", "-h"
        show_help
        exit 0
      when "--version", "-v"
        show_version
        exit 0
      when "--force", "-f"
        options.force = true
      else
        result = parse_option(arg, args, i)
        if result
          flag, value = result
          apply_option(options, flag, value)
          i += 1 if flag.has_value?
        else
          handle_positional_arg(options, arg)
        end
      end
      i += 1
    end

    options
  end

  private def self.parse_option(arg : String, args : Array(String), index : Int32)
    option = OPTIONMAP.find { |k, _| k == arg }
    return unless option

    flag = option[1]
    if flag.has_value?
      next_index = index + 1
      if next_index < args.size
        {flag, args[next_index]}
      end
    else
      {flag, nil}
    end
  end

  private def self.apply_option(options : Options, flag : Flag, value : String?)
    case flag.name
    when "style"            then options.style = value.as(String)
    when "source-map"       then options.source_map = true
    when "embed-source-map" then options.source_map_embed = true
    when "source-map-urls"  then options.source_map_urls = value.as(String)
    when "embed-sources"    then options.embed_sources = true
    when "no-charset"       then options.charset = false
    when "no-error-css"     then options.error_css = false
    when "quiet"            then options.quiet = true
    when "quiet-deps"       then options.quiet_deps = true
    when "verbose"          then options.verbose = true
    when "load-path"        then options.load_paths << value.as(String)
    when "output"           then options.output_file = value.as(String)
    end
  end

  private def self.handle_positional_arg(options : Options, arg : String)
    if arg.starts_with?("--")
      STDERR.puts "Unknown option: #{arg}"
      exit 1
    elsif options.input_file.nil?
      options.input_file = arg
    else
      STDERR.puts "Too many input files specified"
      exit 1
    end
  end

  private def self.validate_and_execute(options : Options)
    if options.input_file.nil?
      STDERR.puts "Error: Input file is required"
      exit 1
    end

    validate_paths(options)

    config = Sass.legacy_params_to_config(
      style: options.style,
      load_paths: options.load_paths,
      source_map: options.source_map,
      source_map_embed: options.source_map_embed,
      source_map_urls: options.source_map_urls,
      embed_sources: options.embed_sources,
      charset: options.charset,
      error_css: options.error_css,
      quiet: options.quiet,
      quiet_deps: options.quiet_deps,
      verbose: options.verbose,
      include_path: nil,
      is_indented_syntax_src: false
    )

    begin
      result = Sass.compile_file(options.input_file.as(String), config)
      if options.output_file
        if File.exists?(options.output_file.as(String)) && !options.force
          STDERR.puts "Error: Output file '#{options.output_file}' already exists. Use --force to overwrite."
          exit 1
        end
        File.write(options.output_file.as(String), result)
      else
        puts result
      end
    rescue ex : Sass::CompilationError
      STDERR.puts ex.message
      exit 1
    end
  end

  private def self.validate_paths(options : Options)
    begin
      Sass.validate_path!(options.input_file.as(String))
    rescue ex : Sass::InvalidSourceError
      STDERR.puts "Path validation error: #{ex.message}"
      exit 1
    end

    if options.output_file
      begin
        Sass.validate_path!(options.output_file.as(String))
      rescue ex : Sass::InvalidSourceError
        STDERR.puts "Output path validation error: #{ex.message}"
        exit 1
      end
    end
  end

  private def self.show_help
    puts <<-HELP
      Usage: sassd [options] <input_file> [-o <output_file>]

      Options:
        --help, -h            Show this help message
        --version, -v         Show version information
        --style <style>       Output style (expanded, compressed) [default: expanded]
        --source-map          Generate source map
        --embed-source-map    Embed source map in CSS output
        --source-map-urls <type> Source map URLs format (relative, absolute) [default: relative]
        --embed-sources       Embed original source files in source map
        --no-charset          Don't include charset declaration
        --no-error-css        Don't generate error CSS for debugging
        --quiet               Suppress warnings
        --quiet-deps          Suppress warnings from dependencies
        --verbose             Enable verbose output
        --load-path <path>    Add a load path for imports
        --output, -o <file>   Write output to file instead of stdout
        --force, -f            Overwrite output file without prompting

      Examples:
        sassd styles.scss
        sassd styles.scss -o styles.css
        sassd --style compressed --source-map --embed-source-map styles.scss -o styles.css
    HELP
  end

  private def self.show_version
    puts "sassd.cr version 0.3.0"

    begin
      output, _ = IO::Memory.new, IO::Memory.new
      status = Process.run("sass", args: ["--version"], output: output, error: Process::Redirect::Close)
      if status.success?
        puts "Dart Sass: #{output.to_s.strip}"
      end
    rescue
      # Ignore if sass is not available
    end
  end
end

struct Sass::CLI::Flag
  getter name : String
  getter has_value : Bool
end

module Sass::CLI::OPTIONMAP
  def self.[]=(key, value)
    @@map[key] = value
  end

  def self.[](key)
    @@map[key]?
  end

  def self.find(&block)
    @@map.find(&block)
  end

  def self.init
    @@map = {} of String => Flag
    @@map["--style"] = Flag.new("style", true)
    @@map["--source-map"] = Flag.new("source-map", false)
    @@map["--embed-source-map"] = Flag.new("embed-source-map", false)
    @@map["--source-map-urls"] = Flag.new("source-map-urls", true)
    @@map["--embed-sources"] = Flag.new("embed-sources", false)
    @@map["--no-charset"] = Flag.new("no-charset", false)
    @@map["--no-error-css"] = Flag.new("no-error-css", false)
    @@map["--quiet"] = Flag.new("quiet", false)
    @@map["--quiet-deps"] = Flag.new("quiet-deps", false)
    @@map["--verbose"] = Flag.new("verbose", false)
    @@map["--load-path"] = Flag.new("load-path", true)
    @@map["--output"] = Flag.new("output", true)
    @@map["-o"] = Flag.new("output", true)
  end
end

# Define version constant
module Sassd
  VERSION = "0.3.0"
end

# Initialize option map and run the CLI
Sass::CLI::OPTIONMAP.init
Sass::CLI.run(ARGV)

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

# Simple CLI argument parser
class Sass::CLI
  def self.run(args : Array(String))
    if args.empty?
      show_help
      exit 0
    end
    
    # Parse arguments
    input_file = nil
    output_file = nil
    style = "expanded"
    source_map = false
    source_map_embed = false
    source_map_urls = "relative"
    embed_sources = false
    charset = true
    error_css = true
    quiet = false
    quiet_deps = false
    verbose = false
    load_paths = [] of String
    
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
      when "--style"
        i += 1
        style = args[i] if i < args.size
      when "--source-map"
        source_map = true
      when "--embed-source-map"
        source_map_embed = true
      when "--source-map-urls"
        i += 1
        source_map_urls = args[i] if i < args.size
      when "--embed-sources"
        embed_sources = true
      when "--no-charset"
        charset = false
      when "--no-error-css"
        error_css = false
      when "--quiet"
        quiet = true
      when "--quiet-deps"
        quiet_deps = true
      when "--verbose"
        verbose = true
      when "--load-path"
        i += 1
        load_paths << args[i] if i < args.size
      when "--output", "-o"
        i += 1
        output_file = args[i] if i < args.size
      else
        # Assume it's the input file if it doesn't start with --
        if arg.starts_with?("--")
          STDERR.puts "Unknown option: #{arg}"
          exit 1
        elsif input_file.nil?
          input_file = arg
        else
          STDERR.puts "Too many input files specified"
          exit 1
        end
      end
      i += 1
    end
    
    if input_file.nil?
      STDERR.puts "Error: Input file is required"
      exit 1
    end
    
    # Create config from CLI arguments
    config = Sass::Config.new(
      style: style,
      source_map: source_map,
      source_map_embed: source_map_embed,
      source_map_urls: source_map_urls,
      embed_sources: embed_sources,
      charset: charset,
      error_css: error_css,
      quiet: quiet,
      quiet_deps: quiet_deps,
      verbose: verbose,
      load_paths: load_paths
    )
    
    begin
      result = Sass.compile_file(input_file, config)
      if output_file
        File.write(output_file, result)
      else
        # When outputting to stdout, ensure source maps are embedded if enabled
        puts result
      end
    rescue ex : Sass::CompilationError
      STDERR.puts ex.message
      exit 1
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

      Examples:
        sassd styles.scss
        sassd styles.scss -o styles.css
        sassd --style compressed --source-map --embed-source-map styles.scss -o styles.css
      HELP
  end
  
  private def self.show_version
    puts "sassd.cr version 0.3.0"
    
    # Try to get sass version
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

# Define version constant
module Sassd
  VERSION = "0.3.0"
end

# Run the CLI
Sass::CLI.run(ARGV)

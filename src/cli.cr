# Sass CLI Command Line Interface
require "./sassd"

# CLI options structure
struct Sass::CLI::Options
  property input_file : String = ""
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
  property fatal_deprecation : String?
  property silence_deprecation = [] of String
  property future_deprecation : String?
  property stdin : Bool = false
  property timeout : Int64?
end

struct Sass::CLI::Flag
  getter name : String
  getter needs_value : Bool

  def initialize(@name : String, @needs_value : Bool)
  end
end

module Sass::CLI::OPTIONMAP
  MAP = {
    "--style"               => Flag.new("style", true),
    "--source-map"          => Flag.new("source-map", false),
    "--embed-source-map"    => Flag.new("embed-source-map", false),
    "--source-map-urls"     => Flag.new("source-map-urls", true),
    "--embed-sources"       => Flag.new("embed-sources", false),
    "--no-charset"          => Flag.new("no-charset", false),
    "--no-error-css"        => Flag.new("no-error-css", false),
    "--quiet"               => Flag.new("quiet", false),
    "--quiet-deps"          => Flag.new("quiet-deps", false),
    "--verbose"             => Flag.new("verbose", false),
    "--load-path"           => Flag.new("load-path", true),
    "--output"              => Flag.new("output", true),
    "-o"                    => Flag.new("output", true),
    "--fatal-deprecation"   => Flag.new("fatal-deprecation", true),
    "--silence-deprecation" => Flag.new("silence-deprecation", true),
    "--future-deprecation"  => Flag.new("future-deprecation", true),
    "--stdin"               => Flag.new("stdin", false),
    "--force"               => Flag.new("force", false),
    "-f"                    => Flag.new("force", false),
  }

  def self.[]=(key, value)
    raise "OPTIONMAP is read-only"
  end

  def self.[](key)
    MAP[key]?
  end
end

module Sass::CLI
  def self.run(args : Array(String))
    if args.empty?
      show_help
      exit 0
    end

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
      when "--stdin"
        options.stdin = true
      when "--style"
        i += 1
        raise "Error: --style requires a value" unless i < args.size
        options.style = args[i]
      when "--timeout"
        i += 1
        raise "Error: --timeout requires a value" unless i < args.size
        options.timeout = args[i].to_i64
      when "--source-map"
        options.source_map = true
      when "--embed-source-map"
        options.source_map_embed = true
      when "--source-map-urls"
        i += 1
        raise "Error: --source-map-urls requires a value" unless i < args.size
        options.source_map_urls = args[i]
      when "--embed-sources"
        options.embed_sources = true
      when "--no-charset"
        options.charset = false
      when "--no-error-css"
        options.error_css = false
      when "--quiet"
        options.quiet = true
      when "--quiet-deps"
        options.quiet_deps = true
      when "--verbose"
        options.verbose = true
      when "--load-path"
        i += 1
        raise "Error: --load-path requires a value" unless i < args.size
        options.load_paths << args[i]
      when "--output", "-o"
        i += 1
        raise "Error: --output requires a value" unless i < args.size
        options.output_file = args[i]
      when "--force", "-f"
        options.force = true
      when "--fatal-deprecation"
        i += 1
        raise "Error: --fatal-deprecation requires a value" unless i < args.size
        options.fatal_deprecation = args[i]
      when "--silence-deprecation"
        i += 1
        raise "Error: --silence-deprecation requires a value" unless i < args.size
        options.silence_deprecation << args[i]
      when "--future-deprecation"
        i += 1
        raise "Error: --future-deprecation requires a value" unless i < args.size
        options.future_deprecation = args[i]
      else
        if arg.starts_with?("-")
          STDERR.puts "Unknown option: #{arg}"
          exit 1
        elsif options.input_file.empty?
          options.input_file = arg
        else
          STDERR.puts "Too many input files specified"
          exit 1
        end
      end
      i += 1
    end

    if options.input_file.empty? && !options.stdin
      STDERR.puts "Error: Input file is required (or use --stdin to read from stdin)"
      exit 1
    end

    sass_bin = File.join(__DIR__, "..", "bin", "sass")
    unless File.executable?(sass_bin)
      sass_bin = "sass"
    end
    Sass.bin_path = sass_bin

    config = Sass::Config.new(
      bin_path: sass_bin,
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
      fatal_deprecation: options.fatal_deprecation,
      silence_deprecation: options.silence_deprecation.empty? ? nil : options.silence_deprecation,
      future_deprecation: options.future_deprecation,
      timeout: options.timeout
    )

    result = if options.stdin
               content = STDIN.gets_to_end
               if content.empty?
                 STDERR.puts "Error: No input provided via stdin"
                 exit 1
               end
               Sass.compile(content, config)
             else
               Sass.compile_file(options.input_file, config)
             end

    if output_file = options.output_file
      if File.exists?(output_file) && !options.force
        STDERR.puts "Error: Output file '#{output_file}' already exists. Use --force to overwrite."
        exit 1
      end
      File.write(output_file, result)
    else
      puts result
    end
  end

  private def self.show_help
    puts <<-HELP
      Usage: sassd [options] <input_file> [-o <output_file>]
            sassd --stdin [-o <output_file>]

      Options:
        --help, -h            Show this help message
        --version, -v         Show version information
        --stdin                Read stylesheet from stdin
        --style <style>        Output style (expanded, compressed) [default: expanded]
        --source-map          Generate source map
        --embed-source-map    Embed source map in CSS output
        --source-map-urls <type> Source map URLs format (relative, absolute)
        --embed-sources       Embed original source files in source map
        --no-charset          Don't include charset declaration
        --no-error-css        Don't generate error CSS for debugging
        --quiet               Suppress warnings
        --quiet-deps          Suppress warnings from dependencies
        --verbose             Enable verbose output
        --load-path <path>    Add a load path for imports
        --output, -o <file>  Write output to file
        --force, -f           Overwrite output file without prompting
        --fatal-deprecation <version> Treat deprecations up to version as errors
        --silence-deprecation <name>  Suppress specific deprecation warning
        --future-deprecation <version> Opt-in to deprecations from future version
        --timeout <seconds>   Set compilation timeout

      Examples:
        sassd styles.scss
        sassd styles.scss -o styles.css
        cat styles.scss | sassd --stdin
      HELP
  end

  private def self.show_version
    puts "sassd.cr version 0.3.0"
  end
end

Sass::CLI.run(ARGV)

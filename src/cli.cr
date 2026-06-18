# Sass CLI Command Line Interface
require "./sassd"

# CLI options structure
class Sass::CLI::Options
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

module Sass::CLI
  # ---------------------------------------------------------------------------
  # Per-flag-group dispatch handlers
  #
  # Every handler shares the signature
  #   (Options, Array(String), Int32) -> Int32
  # and returns the *updated* argument index so the orchestration loop can
  # advance correctly. Value-consuming handlers increment the index, validate
  # that a value is present (raising the same message the original inline code
  # raised), and store the value. Boolean handlers simply flip a flag and
  # return the index unchanged.
  #
  # This decomposition replaces the monolithic ``case``/``when`` chain inside
  # ``run`` so that no single method exceeds the ameba cyclomatic-complexity
  # budget (sassd-refactor-002, design Decision 2).
  # ---------------------------------------------------------------------------

  # --- help / version (terminating handlers) ---

  private def self.show_help_and_exit(options : Options, args : Array(String), i : Int32) : Int32
    show_help
    exit 0
  end

  private def self.show_version_and_exit(options : Options, args : Array(String), i : Int32) : Int32
    show_version
    exit 0
  end

  # --- io group (--stdin, --output/-o, --force/-f) ---

  private def self.enable_stdin(options : Options, args : Array(String), i : Int32) : Int32
    options.stdin = true
    i
  end

  private def self.set_output(options : Options, args : Array(String), i : Int32) : Int32
    i += 1
    raise "Error: --output requires a value" unless i < args.size
    options.output_file = args[i]
    i
  end

  private def self.enable_force(options : Options, args : Array(String), i : Int32) : Int32
    options.force = true
    i
  end

  # --- style group ---

  private def self.set_style(options : Options, args : Array(String), i : Int32) : Int32
    i += 1
    raise "Error: --style requires a value" unless i < args.size
    options.style = args[i]
    i
  end

  # --- timeout group ---

  private def self.set_timeout(options : Options, args : Array(String), i : Int32) : Int32
    i += 1
    raise "Error: --timeout requires a value" unless i < args.size
    options.timeout = args[i].to_i64
    i
  end

  # --- source-map group ---

  private def self.enable_source_map(options : Options, args : Array(String), i : Int32) : Int32
    options.source_map = true
    i
  end

  private def self.enable_embed_source_map(options : Options, args : Array(String), i : Int32) : Int32
    options.source_map_embed = true
    i
  end

  private def self.set_source_map_urls(options : Options, args : Array(String), i : Int32) : Int32
    i += 1
    raise "Error: --source-map-urls requires a value" unless i < args.size
    options.source_map_urls = args[i]
    i
  end

  private def self.enable_embed_sources(options : Options, args : Array(String), i : Int32) : Int32
    options.embed_sources = true
    i
  end

  # --- output-control group (--no-charset, --no-error-css) ---

  private def self.disable_charset(options : Options, args : Array(String), i : Int32) : Int32
    options.charset = false
    i
  end

  private def self.disable_error_css(options : Options, args : Array(String), i : Int32) : Int32
    options.error_css = false
    i
  end

  # --- verbosity group (--quiet, --quiet-deps, --verbose) ---

  private def self.enable_quiet(options : Options, args : Array(String), i : Int32) : Int32
    options.quiet = true
    i
  end

  private def self.enable_quiet_deps(options : Options, args : Array(String), i : Int32) : Int32
    options.quiet_deps = true
    i
  end

  private def self.enable_verbose(options : Options, args : Array(String), i : Int32) : Int32
    options.verbose = true
    i
  end

  # --- load-path group ---

  private def self.add_load_path(options : Options, args : Array(String), i : Int32) : Int32
    i += 1
    raise "Error: --load-path requires a value" unless i < args.size
    options.load_paths << args[i]
    i
  end

  # --- deprecation group ---

  private def self.set_fatal_deprecation(options : Options, args : Array(String), i : Int32) : Int32
    i += 1
    raise "Error: --fatal-deprecation requires a value" unless i < args.size
    options.fatal_deprecation = args[i]
    i
  end

  private def self.add_silence_deprecation(options : Options, args : Array(String), i : Int32) : Int32
    i += 1
    raise "Error: --silence-deprecation requires a value" unless i < args.size
    options.silence_deprecation << args[i]
    i
  end

  private def self.set_future_deprecation(options : Options, args : Array(String), i : Int32) : Int32
    i += 1
    raise "Error: --future-deprecation requires a value" unless i < args.size
    options.future_deprecation = args[i]
    i
  end

  # ---------------------------------------------------------------------------
  # Dispatch registry
  #
  # Maps every recognised option string to its handler proc. The orchestration
  # loop in ``run`` looks up each argument here; anything not found falls
  # through to the unknown-option / positional-arg logic.
  # ---------------------------------------------------------------------------

  HANDLERS = {
    "--help"                => ->show_help_and_exit(Options, Array(String), Int32),
    "-h"                    => ->show_help_and_exit(Options, Array(String), Int32),
    "--version"             => ->show_version_and_exit(Options, Array(String), Int32),
    "-v"                    => ->show_version_and_exit(Options, Array(String), Int32),
    "--stdin"               => ->enable_stdin(Options, Array(String), Int32),
    "--style"               => ->set_style(Options, Array(String), Int32),
    "--timeout"             => ->set_timeout(Options, Array(String), Int32),
    "--source-map"          => ->enable_source_map(Options, Array(String), Int32),
    "--embed-source-map"    => ->enable_embed_source_map(Options, Array(String), Int32),
    "--source-map-urls"     => ->set_source_map_urls(Options, Array(String), Int32),
    "--embed-sources"       => ->enable_embed_sources(Options, Array(String), Int32),
    "--no-charset"          => ->disable_charset(Options, Array(String), Int32),
    "--no-error-css"        => ->disable_error_css(Options, Array(String), Int32),
    "--quiet"               => ->enable_quiet(Options, Array(String), Int32),
    "--quiet-deps"          => ->enable_quiet_deps(Options, Array(String), Int32),
    "--verbose"             => ->enable_verbose(Options, Array(String), Int32),
    "--load-path"           => ->add_load_path(Options, Array(String), Int32),
    "--output"              => ->set_output(Options, Array(String), Int32),
    "-o"                    => ->set_output(Options, Array(String), Int32),
    "--force"               => ->enable_force(Options, Array(String), Int32),
    "-f"                    => ->enable_force(Options, Array(String), Int32),
    "--fatal-deprecation"   => ->set_fatal_deprecation(Options, Array(String), Int32),
    "--silence-deprecation" => ->add_silence_deprecation(Options, Array(String), Int32),
    "--future-deprecation"  => ->set_future_deprecation(Options, Array(String), Int32),
  } of String => Proc(Options, Array(String), Int32, Int32)

  # ---------------------------------------------------------------------------
  # Orchestration entry point
  # ---------------------------------------------------------------------------

  def self.run(args : Array(String))
    if args.empty?
      show_help
      exit 0
    end

    options = Options.new

    i = 0
    while i < args.size
      arg = args[i]
      if handler = HANDLERS[arg]?
        i = handler.call(options, args, i)
      elsif arg.starts_with?("-")
        STDERR.puts "Unknown option: #{arg}"
        exit 1
      elsif options.input_file.empty?
        options.input_file = arg
      else
        STDERR.puts "Too many input files specified"
        exit 1
      end
      i += 1
    end

    validate_input(options)
    config = build_config(options)
    execute(options, config)
  end

  private def self.validate_input(options : Options) : Nil
    if options.input_file.empty? && !options.stdin
      STDERR.puts "Error: Input file is required (or use --stdin to read from stdin)"
      exit 1
    end
  end

  private def self.build_config(options : Options) : Sass::Config
    sass_bin = File.join(__DIR__, "..", "bin", "sass")
    sass_bin = "sass" unless File.executable?(sass_bin)
    Sass.bin_path = sass_bin

    Sass::Config.new(
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
      timeout: options.timeout,
    )
  end

  private def self.execute(options : Options, config : Sass::Config) : Nil
    result = begin
      if options.stdin
        content = STDIN.gets_to_end
        if content.empty?
          STDERR.puts "Error: No input provided via stdin"
          exit 1
        end
        Sass.compile(content, config)
      else
        Sass.compile_file(options.input_file, config)
      end
    rescue ex : Sass::CompilationError
      STDERR.puts "Error: #{ex.message}"
      exit 1
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
    puts "sassd.cr version #{Sass::VERSION}"
  end
end

Sass::CLI.run(ARGV)

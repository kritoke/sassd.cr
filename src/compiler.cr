# Sass wrapper for Dart Sass CLI
#
# This module provides a Crystal wrapper around the Dart Sass CLI,
# offering both backward compatibility with sass.cr and a modern,
# config-based API.
#
# ## Backward Compatibility
#
# The module maintains full API compatibility with sass.cr, supporting
# all the same method signatures and behaviors.
#
# ## Modern API
#
# A new Config-based API is available for cleaner, more maintainable code:
#
# ```
# config = Sass::Config.new(style: "compressed", source_map: true)
# result = Sass.compile(source, config)
# ```
#
# ## Error Handling
#
# Specific error types are provided for better error handling:
# - `Sass::CompilationError` - General compilation errors
# - `Sass::BinaryNotFoundError` - Sass binary not found
# - `Sass::VersionMismatchError` - Version requirements not met
# - `Sass::InvalidSourceError` - Invalid CSS/Sass source
# - `Sass::FileReadError` - File reading errors
# - `Sass::TemporaryFileError` - Temporary file handling errors
require "./compiler/args_builder"
require "./compiler/validator"
require "process"
require "io/memory"
require "semantic_version"

module Sass
  # YAML front matter delimiter count for split operation
  FRONT_MATTER_SPLIT_PARTS = 3
  # Executable permission bits (rwx for user/group/other)
  EXECUTABLE_PERMISSION_MASK = 0o111

  # Default configuration instance
  @@default_config : Config? = nil

  # The path to the sass executable. Defaults to "sass".
  @@bin_path : String = "sass"
  @@version_verified = false

  def self.bin_path
    @@bin_path
  end

  def self.bin_path=(path : String)
    @@bin_path = path
    @@version_verified = false
    # Update the default config with the new bin_path
    self.default_config = update_config(default_config, bin_path: path)
  end

  # The minimum required version of Dart Sass.
  def self.min_version
    default_config.min_version || "1.98.0"
  end

  def self.min_version=(version : String)
    # Update the default config with the new min_version
    self.default_config = update_config(default_config, min_version: version)
  end

  # Get the default configuration
  def self.default_config
    @@default_config ||= Config.default
  end

  # Set the default configuration
  def self.default_config=(config : Config)
    @@default_config = config
  end

  # A reusable compiler instance for API compatibility with sass.cr
  class Compiler
    include Sass

    # Backward compatibility properties
    property style : String
    property source_map : Bool
    property source_map_embed : Bool
    property source_map_urls : String # "relative" or "absolute"
    property embed_sources : Bool
    property charset : Bool
    property error_css : Bool
    property quiet : Bool
    property quiet_deps : Bool
    property verbose : Bool
    property load_paths : Array(String)
    property include_path : (Array(String) | String)?

    def initialize(@style : String = "expanded",
                   @source_map : Bool = false,
                   @source_map_embed : Bool = false,
                   @source_map_urls : String = "relative",
                   @embed_sources : Bool = false,
                   @charset : Bool = true,
                   @error_css : Bool = true,
                   @quiet : Bool = false,
                   @quiet_deps : Bool = false,
                   @verbose : Bool = false,
                   @load_paths : Array(String) = [] of String,
                   @include_path : (Array(String) | String)? = nil)
    end

    def compile(source : String,
                is_indented_syntax_src : Bool = false,
                source_path : String? = nil) : String
      config = Sass.compiler_instance_to_config(
        compiler_style: @style,
        compiler_source_map: @source_map,
        compiler_source_map_embed: @source_map_embed,
        compiler_source_map_urls: @source_map_urls,
        compiler_embed_sources: @embed_sources,
        compiler_charset: @charset,
        compiler_error_css: @error_css,
        compiler_quiet: @quiet,
        compiler_quiet_deps: @quiet_deps,
        compiler_verbose: @verbose,
        compiler_load_paths: @load_paths,
        compiler_include_path: @include_path,
        is_indented_syntax_src: is_indented_syntax_src
      )
      Sass.compile(source, config)
    end

    def compile_file(path : String,
                     is_indented_syntax_src : Bool = false) : String
      # Validate the input path for security
      Sass.validate_path!(path)

      config = Sass.compiler_instance_to_config(
        compiler_style: @style,
        compiler_source_map: @source_map,
        compiler_source_map_embed: @source_map_embed,
        compiler_source_map_urls: @source_map_urls,
        compiler_embed_sources: @embed_sources,
        compiler_charset: @charset,
        compiler_error_css: @error_css,
        compiler_quiet: @quiet,
        compiler_quiet_deps: @quiet_deps,
        compiler_verbose: @verbose,
        compiler_load_paths: @load_paths,
        compiler_include_path: @include_path,
        is_indented_syntax_src: is_indented_syntax_src
      )
      Sass.compile_file(path, config)
    end
  end

  # Backward compatibility: original sass.cr-style API
  def self.compile(source : String,
                   style : String = "expanded",
                   load_paths : Array(String)? = nil,
                   source_map : Bool = false,
                   source_map_embed : Bool = false,
                   source_map_urls : String = "relative",
                   embed_sources : Bool = false,
                   charset : Bool = true,
                   error_css : Bool = true,
                   quiet : Bool = false,
                   quiet_deps : Bool = false,
                   verbose : Bool = false,
                   source_path : String? = nil,
                   include_path : (Array(String) | String)? = nil,
                   is_indented_syntax_src : Bool = false) : String
    config = legacy_params_to_config(
      style: style,
      load_paths: load_paths,
      source_map: source_map,
      source_map_embed: source_map_embed,
      source_map_urls: source_map_urls,
      embed_sources: embed_sources,
      charset: charset,
      error_css: error_css,
      quiet: quiet,
      quiet_deps: quiet_deps,
      verbose: verbose,
      include_path: include_path,
      is_indented_syntax_src: is_indented_syntax_src
    )
    compile(source, config)
  end

  # New config-based API
  def self.compile(source : String,
                   config : Config = default_config) : String
    args = ["--stdin"]
    # Note: source_path is not supported in current Dart Sass, so we ignore it
    # Note: source_map with stdin requires embed_source_map
    effective_source_map_embed = config.source_map_embed || config.source_map
    args += common_args(config, effective_source_map_embed, for_stdin: true)

    execute_sass(args, config, input: IO::Memory.new(source))
  end

  # Backward compatibility: original sass.cr-style API
  def self.compile_file(path : String,
                        style : String = "expanded",
                        load_paths : Array(String)? = nil,
                        source_map : Bool = false,
                        source_map_embed : Bool = false,
                        source_map_urls : String = "relative",
                        embed_sources : Bool = false,
                        charset : Bool = true,
                        error_css : Bool = true,
                        quiet : Bool = false,
                        quiet_deps : Bool = false,
                        verbose : Bool = false,
                        include_path : (Array(String) | String)? = nil,
                        is_indented_syntax_src : Bool = false) : String
    # Validate the input path for security
    validate_path!(path)

    config = legacy_params_to_config(
      style: style,
      load_paths: load_paths,
      source_map: source_map,
      source_map_embed: source_map_embed,
      source_map_urls: source_map_urls,
      embed_sources: embed_sources,
      charset: charset,
      error_css: error_css,
      quiet: quiet,
      quiet_deps: quiet_deps,
      verbose: verbose,
      include_path: include_path,
      is_indented_syntax_src: is_indented_syntax_src
    )
    compile_file(path, config)
  end

  # New config-based API
  def self.compile_file(path : String,
                        config : Config = default_config) : String
    # Validate and resolve the input path to ensure it's safe
    resolved_path = validate_and_resolve_path!(path)

    # Handle Jekyll-style YAML front matter by stripping it before compilation
    if File.exists?(resolved_path)
      content = File.read(resolved_path)
      if content.starts_with?("---")
        parts = content.split("---", FRONT_MATTER_SPLIT_PARTS)
        if parts.size == FRONT_MATTER_SPLIT_PARTS
          # Process YAML front matter in-memory instead of using temporary files
          # Extract the Sass content after the YAML front matter
          sass_content = parts[2]

          # For stdin compilation with source maps, we need to embed source maps
          # Create a modified config that ensures source maps are embedded if enabled
          effective_config = if config.source_map && !config.source_map_embed
                               # Source maps with stdin require embedding
                               Config.new(
                                 style: config.style,
                                 source_map: config.source_map,
                                 source_map_embed: true, # Force embed for stdin
                                 source_map_urls: config.source_map_urls,
                                 embed_sources: config.embed_sources,
                                 charset: config.charset,
                                 error_css: config.error_css,
                                 quiet: config.quiet,
                                 quiet_deps: config.quiet_deps,
                                 verbose: config.verbose,
                                 load_paths: config.load_paths,
                                 include_path: config.include_path,
                                 is_indented_syntax_src: config.is_indented_syntax_src,
                                 min_version: config.min_version,
                                 bin_path: config.bin_path
                               )
                             else
                               config
                             end

          return compile(sass_content, effective_config)
        end
      end
    else
      raise Sass::FileReadError.new("Input file not found: #{path}")
    end

    compile_file_internal(
      path,
      config: config
    )
  end

  private def self.compile_file_internal(path : String,
                                         config : Config) : String
    args = [path]
    args += common_args(config, config.source_map_embed)

    execute_sass(args, config, error_prefix: "Sass Compilation Failed for #{path}")
  end

  # Backward compatibility: original sass.cr-style API
  def self.compile_directory(input_dir : String,
                             output_dir : String,
                             style : String = "expanded",
                             load_paths : Array(String)? = nil,
                             source_map : Bool = false,
                             source_map_embed : Bool = false,
                             source_map_urls : String = "relative",
                             embed_sources : Bool = false,
                             charset : Bool = true,
                             error_css : Bool = true,
                             quiet : Bool = false,
                             quiet_deps : Bool = false,
                             verbose : Bool = false,
                             include_path : (Array(String) | String)? = nil,
                             is_indented_syntax_src : Bool = false) : Nil
    # Validate input and output paths for security
    validate_path!(input_dir)
    validate_path!(output_dir)

    config = legacy_params_to_config(
      style: style,
      load_paths: load_paths,
      source_map: source_map,
      source_map_embed: source_map_embed,
      source_map_urls: source_map_urls,
      embed_sources: embed_sources,
      charset: charset,
      error_css: error_css,
      quiet: quiet,
      quiet_deps: quiet_deps,
      verbose: verbose,
      include_path: include_path,
      is_indented_syntax_src: is_indented_syntax_src
    )
    compile_directory(input_dir, output_dir, config)
  end

  # New config-based API
  def self.compile_directory(input_dir : String,
                             output_dir : String,
                             config : Config = default_config) : Nil
    # Validate input and output paths for security
    validate_path!(input_dir)
    validate_path!(output_dir)

    args = ["#{input_dir}:#{output_dir}"]
    args += common_args(config, config.source_map_embed)

    execute_sass(args, config, error_prefix: "Sass Batch Compilation Failed")
    nil
  end

  private def self.common_args(config : Config, source_map_embed : Bool, for_stdin = false) : Array(String)
    ArgsBuilder.build(config, source_map_embed, for_stdin)
  end

  private def self.execute_sass(args : Array(String), config : Config, input : IO? = nil, error_prefix : String = "Sass Compilation Failed") : String
    verify_bin_path!(config)
    # Use the resolved bin path from class variable if config doesn't specify one
    actual_bin_path = config.bin_path || @@bin_path
    output, error = IO::Memory.new, IO::Memory.new
    status = Process.run(actual_bin_path, args: args, input: input || Process::Redirect::Close, output: output, error: error)

    if status.success?
      output.to_s
    else
      # Provide more specific error messages based on the error content
      error_output = error.to_s
      if error_output.includes?("Invalid CSS")
        raise Sass::InvalidSourceError.new("#{error_prefix}:\n#{error_output}")
      elsif error_output.includes?("File to import not found")
        raise Sass::FileReadError.new("#{error_prefix}:\n#{error_output}")
      else
        raise Sass::CompilationError.new("#{error_prefix}:\nSTDOUT: #{output}\nSTDERR: #{error}")
      end
    end
  end

  private def self.resolve_load_paths(load_paths, include_path)
    paths = [] of String
    if load_paths
      load_paths.each do |p|
        validate_path!(p)
        paths << p
      end
    end
    if include_path
      include_path.each do |p|
        validate_path!(p)
        paths << p
      end
    end
    paths
  end

  private def self.verify_bin_path!(config : Config)
    bin_path = config.bin_path || @@bin_path

    # Validate the bin path to ensure it's safe before use
    if bin_path != "sass"
      # For non-default paths, validate and resolve to absolute path
      validated_path = validate_bin_path!(bin_path)
      path = Process.find_executable(validated_path) || validated_path
    else
      # For default "sass", try to find it in bin directory first
      path = Process.find_executable(File.expand_path("./bin/sass")) || Process.find_executable("sass")
    end

    raise Sass::BinaryNotFoundError.new("Sass binary not found at '#{bin_path}'.") unless path

    # Update the config with the resolved path if using default
    if config.bin_path.nil?
      @@bin_path = path
      @@version_verified = true
    end

    check_version!(path, config.min_version || min_version)
  end

  # Validate a file path for security concerns
  def self.validate_path!(path : String)
    Validator.validate_path!(path)
  end

  # Validate and resolve a file path to prevent path traversal
  def self.validate_and_resolve_path!(path : String, base_dir : String? = nil) : String
    Validator.validate_and_resolve_path!(path, base_dir)
  end

  # Validate a binary path for command execution
  def self.validate_bin_path!(bin_path : String) : String
    Validator.validate_bin_path!(bin_path)
  end

  # Validate the output style parameter
  private def self.validate_style!(style : String) : String
    Validator.validate_style!(style)
  end

  # Validate the source map URLs parameter
  private def self.validate_source_map_urls!(urls : String) : String
    Validator.validate_source_map_urls!(urls)
  end

  # Convert legacy API parameters to Config object
  def self.legacy_params_to_config(
    style : String = "expanded",
    load_paths : Array(String)? = nil,
    source_map : Bool = false,
    source_map_embed : Bool = false,
    source_map_urls : String = "relative",
    embed_sources : Bool = false,
    charset : Bool = true,
    error_css : Bool = true,
    quiet : Bool = false,
    quiet_deps : Bool = false,
    verbose : Bool = false,
    include_path : (Array(String) | String)? = nil,
    is_indented_syntax_src : Bool = false,
  ) : Config
    Config.new(
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
      load_paths: load_paths || [] of String,
      include_path: include_path,
      is_indented_syntax_src: is_indented_syntax_src
    )
  end

  # Update specific fields in a config while preserving others
  def self.update_config(
    config : Config,
    style : String? = nil,
    load_paths : Array(String)? = nil,
    source_map : Bool? = nil,
    source_map_embed : Bool? = nil,
    source_map_urls : String? = nil,
    embed_sources : Bool? = nil,
    charset : Bool? = nil,
    error_css : Bool? = nil,
    quiet : Bool? = nil,
    quiet_deps : Bool? = nil,
    verbose : Bool? = nil,
    include_path : (Array(String) | String)? = nil,
    is_indented_syntax_src : Bool? = nil,
    min_version : String? = nil,
    bin_path : String? = nil,
  ) : Config
    Config.new(
      style: style || config.style,
      source_map: source_map || config.source_map,
      source_map_embed: source_map_embed || config.source_map_embed,
      source_map_urls: source_map_urls || config.source_map_urls,
      embed_sources: embed_sources || config.embed_sources,
      charset: charset || config.charset,
      error_css: error_css || config.error_css,
      quiet: quiet || config.quiet,
      quiet_deps: quiet_deps || config.quiet_deps,
      verbose: verbose || config.verbose,
      load_paths: load_paths || config.load_paths,
      include_path: include_path.nil? ? config.include_path : include_path,
      is_indented_syntax_src: is_indented_syntax_src || config.is_indented_syntax_src,
      min_version: min_version.nil? ? config.min_version : min_version,
      bin_path: bin_path.nil? ? config.bin_path : bin_path
    )
  end

  # Convert Compiler instance variables to Config object
  def self.compiler_instance_to_config(
    compiler_style : String,
    compiler_source_map : Bool,
    compiler_source_map_embed : Bool,
    compiler_source_map_urls : String,
    compiler_embed_sources : Bool,
    compiler_charset : Bool,
    compiler_error_css : Bool,
    compiler_quiet : Bool,
    compiler_quiet_deps : Bool,
    compiler_verbose : Bool,
    compiler_load_paths : Array(String),
    compiler_include_path : (Array(String) | String)?,
    is_indented_syntax_src : Bool = false,
  ) : Config
    Config.new(
      style: compiler_style,
      source_map: compiler_source_map,
      source_map_embed: compiler_source_map_embed,
      source_map_urls: compiler_source_map_urls,
      embed_sources: compiler_embed_sources,
      charset: compiler_charset,
      error_css: compiler_error_css,
      quiet: compiler_quiet,
      quiet_deps: compiler_quiet_deps,
      verbose: compiler_verbose,
      load_paths: compiler_load_paths,
      include_path: compiler_include_path,
      is_indented_syntax_src: is_indented_syntax_src
    )
  end

  private def self.check_version!(path, required_version_str)
    # Validate the path is safe before executing
    validate_path!(path)
    
    # Ensure the path is an absolute path and exists as a file
    absolute_path = File.expand_path(path)
    unless File.file?(absolute_path)
      raise Sass::BinaryNotFoundError.new("Version check failed - path is not a file: #{path}")
    end
    
    stdout, stderr = IO::Memory.new, IO::Memory.new
    status = Process.run(absolute_path, args: ["--version"], output: stdout, error: stderr)
    if status.success?
      version_str = stdout.to_s.strip.split(' ').first
      begin
        current_version = SemanticVersion.parse(version_str)
        required_version = SemanticVersion.parse(required_version_str)
        if current_version < required_version
          raise Sass::VersionMismatchError.new("Sass version mismatch at '#{path}': Found #{current_version}, but version >= #{required_version} is required.")
        end
      rescue ex : ArgumentError
        raise Sass::CompilationError.new("Could not parse Sass version string '#{version_str}': #{ex.message}")
      end
    else
      raise Sass::BinaryNotFoundError.new("Failed to determine Sass version from '#{path}':\n#{stderr}")
    end
  end
end

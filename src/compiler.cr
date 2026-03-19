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
# ```crystal
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
require "process"
require "io/memory"
require "semantic_version"

module Sass
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
    # Also update the default config
    default_config = self.default_config
    self.default_config = Config.new(
      style: default_config.style,
      source_map: default_config.source_map,
      source_map_embed: default_config.source_map_embed,
      source_map_urls: default_config.source_map_urls,
      embed_sources: default_config.embed_sources,
      charset: default_config.charset,
      error_css: default_config.error_css,
      quiet: default_config.quiet,
      quiet_deps: default_config.quiet_deps,
      verbose: default_config.verbose,
      load_paths: default_config.load_paths,
      include_path: default_config.include_path,
      is_indented_syntax_src: default_config.is_indented_syntax_src,
      min_version: default_config.min_version,
      bin_path: path
    )
  end

  # The minimum required version of Dart Sass.
  def self.min_version
    default_config.min_version || "1.98.0"
  end

  def self.min_version=(version : String)
    default_config = self.default_config
    self.default_config = Config.new(
      style: default_config.style,
      source_map: default_config.source_map,
      source_map_embed: default_config.source_map_embed,
      source_map_urls: default_config.source_map_urls,
      embed_sources: default_config.embed_sources,
      charset: default_config.charset,
      error_css: default_config.error_css,
      quiet: default_config.quiet,
      quiet_deps: default_config.quiet_deps,
      verbose: default_config.verbose,
      load_paths: default_config.load_paths,
      include_path: default_config.include_path,
      is_indented_syntax_src: default_config.is_indented_syntax_src,
      min_version: version,
      bin_path: default_config.bin_path
    )
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
      config = Config.new(
        style: @style,
        source_map: @source_map,
        source_map_embed: @source_map_embed,
        source_map_urls: @source_map_urls,
        embed_sources: @embed_sources,
        charset: @charset,
        error_css: @error_css,
        quiet: @quiet,
        quiet_deps: @quiet_deps,
        verbose: @verbose,
        load_paths: @load_paths,
        include_path: @include_path,
        is_indented_syntax_src: is_indented_syntax_src
      )
      Sass.compile(source, config)
    end

    def compile_file(path : String,
                     is_indented_syntax_src : Bool = false) : String
      config = Config.new(
        style: @style,
        source_map: @source_map,
        source_map_embed: @source_map_embed,
        source_map_urls: @source_map_urls,
        embed_sources: @embed_sources,
        charset: @charset,
        error_css: @error_css,
        quiet: @quiet,
        quiet_deps: @quiet_deps,
        verbose: @verbose,
        load_paths: @load_paths,
        include_path: @include_path,
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
    config = Config.new(
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
    config = Config.new(
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
    compile_file(path, config)
  end

  # New config-based API
  def self.compile_file(path : String,
                        config : Config = default_config) : String
    # Handle Jekyll-style YAML front matter by stripping it before compilation
    if File.exists?(path)
      content = File.read(path)
      if content.starts_with?("---")
        parts = content.split("---", 3)
        if parts.size == 3
          # Use file compilation for better source map support
          # The YAML front matter is already stripped, so just write temp file
          temp_file_path = nil
          begin
            temp_file = File.tempfile(".scss")
            temp_file_path = temp_file.path
            temp_file.close
            File.write(temp_file_path, parts[2])
            return compile_file_internal(
              temp_file_path,
              config: config
            )
          rescue ex : File::Error
            raise Sass::TemporaryFileError.new("Failed to create or write temporary file for YAML front matter processing: #{ex.message}")
          ensure
            if temp_file_path && File.exists?(temp_file_path)
              begin
                File.delete(temp_file_path)
              rescue ex : File::Error
                # Log warning but don't fail - temporary file cleanup is best-effort
                STDERR.puts "Warning: Failed to clean up temporary file #{temp_file_path}: #{ex.message}"
              end
            end
          end
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
    config = Config.new(
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
    compile_directory(input_dir, output_dir, config)
  end

  # New config-based API
  def self.compile_directory(input_dir : String,
                            output_dir : String,
                            config : Config = default_config) : Nil
    args = ["#{input_dir}:#{output_dir}"]
    args += common_args(config, config.source_map_embed)

    execute_sass(args, config, error_prefix: "Sass Batch Compilation Failed")
    nil
  end

  private def self.common_args(config : Config, source_map_embed : Bool, for_stdin = false)
    args = ["--style=#{config.style}"]
    if source_map_embed
      args << "--embed-source-map"
    elsif config.source_map && !for_stdin
      # Don't generate source maps for stdin without embedding (not supported)
      args << "--source-map"
    else
      args << "--no-source-map"
    end

    # Source map options
    args << "--source-map-urls=#{config.source_map_urls}" if config.source_map_urls != "relative"
    args << "--embed-sources" if config.embed_sources

    # Charset control
    args << "--no-charset" unless config.charset

    # Error CSS generation
    args << "--no-error-css" unless config.error_css

    # Warning/deprecation options
    args << "--quiet" if config.quiet
    args << "--quiet-deps" if config.quiet_deps
    args << "--verbose" if config.verbose

    # Syntax and load paths
    args << "--indented" if config.is_indented_syntax_src
    resolve_load_paths(config.load_paths, config.include_path).each { |path| args << "--load-path=#{path}" }
    args
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
    paths.concat(load_paths) if load_paths
    paths.concat(include_path) if include_path
    paths
  end

  private def self.verify_bin_path!(config : Config)
    bin_path = config.bin_path || @@bin_path
    path = if bin_path == "sass"
             Process.find_executable(File.expand_path("./bin/sass")) || Process.find_executable("sass")
           else
             Process.find_executable(bin_path)
           end
    raise Sass::BinaryNotFoundError.new("Sass binary not found at '#{bin_path}'.") unless path
    
    # Update the config with the resolved path if using default
    if config.bin_path.nil?
      @@bin_path = path
      @@version_verified = true
    end
    
    check_version!(path, config.min_version || min_version)
  end

  private def self.check_version!(path, required_version_str)
    stdout, stderr = IO::Memory.new, IO::Memory.new
    status = Process.run(path, args: ["--version"], output: stdout, error: stderr)
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

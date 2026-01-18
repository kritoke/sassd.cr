require "process"
require "io/memory"
require "semantic_version"

module Sass
  # The path to the sass executable. Defaults to "sass".
  @@bin_path : String = "sass"
  @@version_verified = false

  def self.bin_path
    @@bin_path
  end

  def self.bin_path=(path : String)
    @@bin_path = path
    @@version_verified = false
  end

  # The minimum required version of Dart Sass.
  class_property min_version : String = "1.97.1"

  # A reusable compiler instance for API compatibility with sass.cr
  class Compiler
    include Sass

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
    property include_path : String?

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
                   @include_path : String? = nil)
    end

    def compile(source : String,
                is_indented_syntax_src : Bool = false,
                source_path : String? = nil) : String
      Sass.compile(
        source: source,
        style: @style,
        load_paths: @load_paths.empty? ? nil : @load_paths,
        source_map: @source_map,
        source_map_embed: @source_map_embed,
        source_map_urls: @source_map_urls,
        embed_sources: @embed_sources,
        charset: @charset,
        error_css: @error_css,
        quiet: @quiet,
        quiet_deps: @quiet_deps,
        verbose: @verbose,
        source_path: source_path,
        include_path: @include_path,
        is_indented_syntax_src: is_indented_syntax_src
      )
    end

    def compile_file(path : String,
                     is_indented_syntax_src : Bool = false) : String
      Sass.compile_file(
        path: path,
        style: @style,
        load_paths: @load_paths.empty? ? nil : @load_paths,
        source_map: @source_map,
        source_map_embed: @source_map_embed,
        source_map_urls: @source_map_urls,
        embed_sources: @embed_sources,
        charset: @charset,
        error_css: @error_css,
        quiet: @quiet,
        quiet_deps: @quiet_deps,
        verbose: @verbose,
        include_path: @include_path,
        is_indented_syntax_src: is_indented_syntax_src
      )
    end
  end

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
    args = ["--stdin"]
    # Note: source_path is not supported in current Dart Sass, so we ignore it
    # Note: source_map with stdin requires embed_source_map
    effective_source_map_embed = source_map_embed || source_map
    args += common_args(style, source_map, effective_source_map_embed, source_map_urls, embed_sources, charset, error_css, quiet, quiet_deps, verbose, load_paths, include_path, is_indented_syntax_src, for_stdin: true)

    execute_sass(args, input: IO::Memory.new(source))
  end

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
    # Handle Jekyll-style YAML front matter by stripping it before compilation
    if File.exists?(path)
      content = File.read(path)
      if content.starts_with?("---")
        parts = content.split("---", 3)
        if parts.size == 3
          # Use file compilation for better source map support
          # The YAML front matter is already stripped, so just write temp file
          temp_file = File.tempfile(".scss")
          begin
            File.write(temp_file.path, parts[2])
            return compile_file_internal(
              temp_file.path,
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
          ensure
            File.delete(temp_file.path) if File.exists?(temp_file.path)
          end
        end
      end
    end

    compile_file_internal(
      path,
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
  end

  private def self.compile_file_internal(path : String,
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
    args = [path]
    args += common_args(style, source_map, source_map_embed, source_map_urls, embed_sources, charset, error_css, quiet, quiet_deps, verbose, load_paths, include_path, is_indented_syntax_src)

    execute_sass(args, error_prefix: "Sass Compilation Failed for #{path}")
  end

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
    args = ["#{input_dir}:#{output_dir}"]
    args += common_args(style, source_map, source_map_embed, source_map_urls, embed_sources, charset, error_css, quiet, quiet_deps, verbose, load_paths, include_path, is_indented_syntax_src)

    execute_sass(args, error_prefix: "Sass Batch Compilation Failed")
    nil
  end

  private def self.common_args(style, source_map, source_map_embed, source_map_urls, embed_sources, charset, error_css, quiet, quiet_deps, verbose, load_paths, include_path, is_indented_syntax_src, for_stdin = false)
    args = ["--style=#{style}"]
    if source_map_embed
      args << "--embed-source-map"
    elsif source_map && !for_stdin
      # Don't generate source maps for stdin without embedding (not supported)
      args << "--source-map"
    else
      args << "--no-source-map"
    end

    # Source map options
    args << "--source-map-urls=#{source_map_urls}" if source_map_urls != "relative"
    args << "--embed-sources" if embed_sources

    # Charset control
    args << "--no-charset" unless charset

    # Error CSS generation
    args << "--no-error-css" unless error_css

    # Warning/deprecation options
    args << "--quiet" if quiet
    args << "--quiet-deps" if quiet_deps
    args << "--verbose" if verbose

    # Syntax and load paths
    args << "--indented" if is_indented_syntax_src
    resolve_load_paths(load_paths, include_path).each { |path| args << "--load-path=#{path}" }
    args
  end

  private def self.execute_sass(args : Array(String), input : IO? = nil, error_prefix : String = "Sass Compilation Failed") : String
    verify_bin_path!
    output, error = IO::Memory.new, IO::Memory.new
    status = Process.run(@@bin_path, args: args, input: input || Process::Redirect::Close, output: output, error: error)

    if status.success?
      output.to_s
    else
      raise Sass::CompilationError.new("#{error_prefix}:\nSTDOUT: #{output}\nSTDERR: #{error}")
    end
  end

  private def self.resolve_load_paths(load_paths, include_path)
    paths = [] of String
    paths.concat(load_paths) if load_paths
    case include_path
    when String        then paths << include_path
    when Array(String) then paths.concat(include_path)
    end
    paths
  end

  private def self.verify_bin_path!
    return if @@version_verified
    path = if @@bin_path == "sass"
             Process.find_executable(File.expand_path("./bin/sass")) || Process.find_executable("sass")
           else
             Process.find_executable(@@bin_path)
           end
    raise Sass::CompilationError.new("Sass binary not found.") unless path
    @@bin_path = path
    check_version!(@@bin_path)
    @@version_verified = true
  end

  private def self.check_version!(path)
    stdout, stderr = IO::Memory.new, IO::Memory.new
    status = Process.run(path, args: ["--version"], output: stdout, error: stderr)
    if status.success?
      version_str = stdout.to_s.strip.split(' ').first
      begin
        current_version = SemanticVersion.parse(version_str)
        required_version = SemanticVersion.parse(@@min_version)
        if current_version < required_version
          raise Sass::CompilationError.new("Sass version mismatch at '#{path}': Found #{current_version}, but version >= #{required_version} is required.")
        end
      rescue ex : ArgumentError
        raise Sass::CompilationError.new("Could not parse Sass version string '#{version_str}': #{ex.message}")
      end
    else
      raise Sass::CompilationError.new("Failed to determine Sass version from '#{path}':\n#{stderr}")
    end
  end
end

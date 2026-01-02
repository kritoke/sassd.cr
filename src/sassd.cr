require "process"
require "io/memory"
require "semantic_version"

module Sass
  class CompilationError < Exception; end

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

  # API compatible with sass.cr
  def self.compile(source : String,
                   style : String = "expanded",
                   load_paths : Array(String)? = nil,
                   source_map : Bool = false,
                   source_map_embed : Bool = false,
                   source_path : String? = nil,
                   include_path : Array(String) | String | Nil = nil,
                   is_indented_syntax_src : Bool = false) : String
    verify_bin_path!

    args = ["--stdin", "--style=#{style}"]
    args << "--indented" if is_indented_syntax_src

    if source_map_embed
      args << "--embed-source-map"
    else
      args << (source_map ? "--source-map" : "--no-source-map")
    end

    # Ensures the source map points to the correct original file path
    args << "--stdin-file-path=#{source_path}" if source_path

    # Combine load_paths and include_path for API compatibility
    all_paths = [] of String
    all_paths.concat(load_paths) if load_paths
    case include_path
    when String        then all_paths << include_path
    when Array(String) then all_paths.concat(include_path)
    end

    all_paths.each do |lp|
      args << "--load-path=#{lp}"
    end

    input = IO::Memory.new(source)
    output = IO::Memory.new
    error = IO::Memory.new

    status = Process.run(@@bin_path, args: args, input: input, output: output, error: error)

    if status.success?
      output.to_s
    else
      raise CompilationError.new("Sass Compilation Failed:\nSTDOUT: #{output}\nSTDERR: #{error}")
    end
  end

  # Compiles a file directly, which is faster for Jekyll-style workflows
  def self.compile_file(path : String,
                        style : String = "expanded",
                        load_paths : Array(String)? = nil,
                        source_map : Bool = false,
                        source_map_embed : Bool = false,
                        include_path : Array(String) | String | Nil = nil,
                        is_indented_syntax_src : Bool = false) : String
    verify_bin_path!

    args = [path, "--style=#{style}"]
    if source_map_embed
      args << "--embed-source-map"
    else
      args << (source_map ? "--source-map" : "--no-source-map")
    end

    all_paths = [] of String
    all_paths.concat(load_paths) if load_paths
    case include_path
    when String        then all_paths << include_path
    when Array(String) then all_paths.concat(include_path)
    end

    all_paths.each do |lp|
      args << "--load-path=#{lp}"
    end

    output = IO::Memory.new
    error = IO::Memory.new

    status = Process.run(@@bin_path, args: args, output: output, error: error)

    if status.success?
      output.to_s
    else
      raise CompilationError.new("Sass Compilation Failed for #{path}:\nSTDOUT: #{output}\nSTDERR: #{error}")
    end
  end

  # Compiles an entire directory. Ideal for Static Site Generators.
  # Maps all files in input_dir to output_dir in a single process.
  def self.compile_directory(input_dir : String,
                             output_dir : String,
                             style : String = "expanded",
                             load_paths : Array(String)? = nil,
                             source_map : Bool = false,
                             source_map_embed : Bool = false,
                             include_path : Array(String) | String | Nil = nil,
                             is_indented_syntax_src : Bool = false) : Nil
    verify_bin_path!

    args = ["#{input_dir}:#{output_dir}", "--style=#{style}"]

    if source_map_embed
      args << "--embed-source-map"
    else
      args << (source_map ? "--source-map" : "--no-source-map")
    end

    all_paths = [] of String
    all_paths.concat(load_paths) if load_paths
    case include_path
    when String        then all_paths << include_path
    when Array(String) then all_paths.concat(include_path)
    end

    all_paths.each do |lp|
      args << "--load-path=#{lp}"
    end

    error = IO::Memory.new
    status = Process.run(@@bin_path, args: args, error: error)

    unless status.success?
      raise CompilationError.new("Sass Batch Compilation Failed:\n#{error}")
    end
  end

  private def self.verify_bin_path!
    return if @@version_verified

    # Favor the local ./bin/sass installation (from 'make sass') 
    # over the system PATH to avoid version mismatches.
    path = if @@bin_path == "sass"
             Process.find_executable(File.expand_path("./bin/sass")) || Process.find_executable("sass")
           else
             Process.find_executable(@@bin_path)
           end

    unless path
      raise CompilationError.new("Sass binary not found. Please ensure Dart Sass is installed in PATH or at './bin/sass', or set Sass.bin_path manually.")
    end

    @@bin_path = path
    check_version!(@@bin_path)
    @@version_verified = true
  end

  private def self.check_version!(path)
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    status = Process.run(path, args: ["--version"], output: stdout, error: stderr)

    if status.success?
      # Dart Sass usually outputs the version number first (e.g., "1.69.5")
      version_str = stdout.to_s.strip.split(' ').first

      begin
        current_version = SemanticVersion.parse(version_str)
        required_version = SemanticVersion.parse(@@min_version)

        if current_version < required_version
          raise CompilationError.new("Sass version mismatch at '#{path}': Found #{current_version}, but version >= #{required_version} is required.")
        end
      rescue ex : ArgumentError
        raise CompilationError.new("Could not parse Sass version string '#{version_str}': #{ex.message}")
      end
    else
      raise CompilationError.new("Failed to determine Sass version from '#{path}':\n#{stderr}")
    end
  end
end

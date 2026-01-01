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
  class_property min_version : String = "1.33.0"

  # API compatible with sass.cr
  def self.compile(source : String,
                   style : String = "expanded",
                   load_paths : Array(String)? = nil,
                   source_map : Bool = false,
                   source_map_embed : Bool = false,
                   source_path : String? = nil) : String
    verify_bin_path!

    args = ["--stdin", "--style=#{style}"]
    args << (source_map ? "--source-map" : "--no-source-map")
    args << "--embed-source-map" if source_map_embed

    # Ensures the source map points to the correct original file path
    args << "--stdin-file-path=#{source_path}" if source_path

    load_paths.try &.each do |path|
      args << "--load-path=#{path}"
    end

    input = IO::Memory.new(source)
    output = IO::Memory.new
    error = IO::Memory.new

    status = Process.run(@@bin_path, args: args, input: input, output: output, error: error)

    if status.success?
      output.to_s
    else
      raise CompilationError.new("Sass Compilation Failed:\n#{error}")
    end
  end

  # Compiles a file directly, which is faster for Jekyll-style workflows
  def self.compile_file(path : String,
                        style : String = "expanded",
                        load_paths : Array(String)? = nil,
                        source_map : Bool = false,
                        source_map_embed : Bool = false) : String
    verify_bin_path!

    args = [path, "--style=#{style}"]
    args << (source_map ? "--source-map" : "--no-source-map")
    args << "--embed-source-map" if source_map_embed

    load_paths.try &.each do |load_path|
      args << "--load-path=#{load_path}"
    end

    output = IO::Memory.new
    error = IO::Memory.new

    status = Process.run(@@bin_path, args: args, output: output, error: error)

    if status.success?
      output.to_s
    else
      raise CompilationError.new("Sass Compilation Failed for #{path}:\n#{error}")
    end
  end

  # Compiles an entire directory. Ideal for Static Site Generators.
  # Maps all files in input_dir to output_dir in a single process.
  def self.compile_directory(input_dir : String,
                             output_dir : String,
                             style : String = "expanded",
                             load_paths : Array(String)? = nil,
                             source_map : Bool = false) : Nil
    verify_bin_path!

    args = ["#{input_dir}:#{output_dir}", "--style=#{style}"]
    args << (source_map ? "--source-map" : "--no-source-map")

    load_paths.try &.each do |path|
      args << "--load-path=#{path}"
    end

    error = IO::Memory.new
    status = Process.run(@@bin_path, args: args, error: error)

    unless status.success?
      raise CompilationError.new("Sass Batch Compilation Failed:\n#{error}")
    end
  end

  private def self.verify_bin_path!
    return if @@version_verified

    path = Process.find_executable(@@bin_path)
    unless path
      raise CompilationError.new("Sass binary not found at: '#{@@bin_path}'. Please ensure Dart Sass is installed and in your PATH, or set Sass.bin_path manually.")
    end

    check_version!(path)
    @@version_verified = true
  end

  private def self.check_version!(path)
    stdout = IO::Memory.new
    status = Process.run(path, args: ["--version"], output: stdout)

    if status.success?
      # Dart Sass usually outputs the version number first (e.g., "1.69.5")
      version_str = stdout.to_s.strip.split(' ').first

      begin
        current_version = SemanticVersion.parse(version_str)
        required_version = SemanticVersion.parse(@@min_version)

        if current_version < required_version
          raise CompilationError.new("Installed Sass version #{current_version} is lower than the required minimum version #{required_version}.")
        end
      rescue ex : ArgumentError
        raise CompilationError.new("Could not parse Sass version string '#{version_str}': #{ex.message}")
      end
    else
      raise CompilationError.new("Failed to determine Sass version from '#{path}'.")
    end
  end
end

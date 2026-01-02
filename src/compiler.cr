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

    args = ["--stdin"]
    args += common_args(style, source_map, source_map_embed, load_paths, include_path)
    args << "--indented" if is_indented_syntax_src
    args << "--stdin-file-path=#{source_path}" if source_path

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

  def self.compile_file(path : String,
                        style : String = "expanded",
                        load_paths : Array(String)? = nil,
                        source_map : Bool = false,
                        source_map_embed : Bool = false,
                        include_path : Array(String) | String | Nil = nil,
                        is_indented_syntax_src : Bool = false) : String
    verify_bin_path!

    # Handle Jekyll-style YAML front matter by stripping it before compilation
    if File.exists?(path)
      content = File.read(path)
      if content.starts_with?("---")
        parts = content.split("---", 3)
        if parts.size == 3
          return compile(
            source: parts[2],
            style: style,
            load_paths: load_paths,
            source_map: source_map,
            source_map_embed: source_map_embed,
            source_path: path,
            include_path: include_path,
            is_indented_syntax_src: is_indented_syntax_src
          )
        end
      end
    end

    args = [path]
    args += common_args(style, source_map, source_map_embed, load_paths, include_path)
    args << "--indented" if is_indented_syntax_src

    output = IO::Memory.new
    error = IO::Memory.new

    status = Process.run(@@bin_path, args: args, output: output, error: error)

    if status.success?
      output.to_s
    else
      raise CompilationError.new("Sass Compilation Failed for #{path}:\nSTDOUT: #{output}\nSTDERR: #{error}")
    end
  end

  def self.compile_directory(input_dir : String,
                             output_dir : String,
                             style : String = "expanded",
                             load_paths : Array(String)? = nil,
                             source_map : Bool = false,
                             source_map_embed : Bool = false,
                             include_path : Array(String) | String | Nil = nil,
                             is_indented_syntax_src : Bool = false) : Nil
    verify_bin_path!

    args = ["#{input_dir}:#{output_dir}"]
    args += common_args(style, source_map, source_map_embed, load_paths, include_path)
    args << "--indented" if is_indented_syntax_src

    error = IO::Memory.new
    status = Process.run(@@bin_path, args: args, error: error)

    unless status.success?
      raise CompilationError.new("Sass Batch Compilation Failed:\n#{error}")
    end
  end

  private def self.common_args(style, source_map, source_map_embed, load_paths, include_path)
    args = ["--style=#{style}"]
    if source_map_embed
      args << "--embed-source-map"
    else
      args << (source_map ? "--source-map" : "--no-source-map")
    end
    resolve_load_paths(load_paths, include_path).each { |path| args << "--load-path=#{path}" }
    args
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
    raise CompilationError.new("Sass binary not found.") unless path
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
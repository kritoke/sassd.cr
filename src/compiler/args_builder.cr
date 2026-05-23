# CLI Argument Builder for Sass compilation
#
# Builds CLI arguments for Dart Sass from Config objects.
module Sass
  module ArgsBuilder
    # Build all common arguments for Sass execution
    def self.build(config : Config, source_map_embed : Bool, for_stdin = false) : Array(String)
      style_args(config) +
        source_map_args(config, source_map_embed, for_stdin) +
        output_args(config) +
        warning_args(config) +
        syntax_args(config) +
        load_path_args(config)
    end

    private def self.style_args(config : Config) : Array(String)
      style = config.style
      return ["--style=#{style}"] if ALLOWED_STYLES.includes?(style)
      raise Sass::CompilationError.new("Invalid style '#{style}'. Allowed: #{ALLOWED_STYLES.join(", ")}")
    end

    private def self.output_args(config : Config) : Array(String)
      args = [] of String
      source_map_urls = config.source_map_urls
      unless ALLOWED_SOURCE_MAP_URLS.includes?(source_map_urls)
        raise Sass::CompilationError.new("Invalid source-map-urls '#{source_map_urls}'. Allowed values: #{ALLOWED_SOURCE_MAP_URLS.join(", ")}")
      end
      args << "--source-map-urls=#{source_map_urls}" if source_map_urls != "relative"
      args << "--embed-sources" if config.embed_sources
      args << "--no-charset" unless config.charset
      args << "--no-error-css" unless config.error_css
      args
    end

    private def self.warning_args(config : Config) : Array(String)
      args = [] of String
      args << "--quiet" if config.quiet
      args << "--quiet-deps" if config.quiet_deps
      args << "--verbose" if config.verbose
      args
    end

    private def self.syntax_args(config : Config) : Array(String)
      config.is_indented_syntax_src ? ["--indented"] : [] of String
    end

    private def self.load_path_args(config : Config) : Array(String)
      paths = [] of String
      config.load_paths.try &.each do |p|
        next if p.nil? || p.empty?
        Sass.validate_path!(p)
        paths << p
      end
      config.include_path.try &.each do |p|
        next if p.nil? || p.empty?
        Sass.validate_path!(p)
        paths << p
      end
      paths.map { |path| "--load-path=#{path}" }
    end

    private def self.source_map_args(config : Config, source_map_embed : Bool, for_stdin : Bool) : Array(String)
      return ["--no-source-map"] unless source_map_embed || config.source_map
      return ["--no-source-map"] if for_stdin && !source_map_embed
      source_map_embed ? ["--embed-source-map"] : ["--source-map"]
    end
  end
end
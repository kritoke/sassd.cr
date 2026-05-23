# CLI Argument Builder for Sass compilation
#
# This module is responsible for building the command-line arguments
# passed to the Dart Sass executable. It encapsulates all argument
# construction logic for better maintainability and testing.
module Sass
  module ArgsBuilder
    # Allowed output styles for Dart Sass
    ALLOWED_STYLES = {"expanded", "compressed"}
    # Allowed source map URL types
    ALLOWED_SOURCE_MAP_URLS = {"relative", "absolute"}

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
      unless ALLOWED_STYLES.includes?(style)
        raise Sass::CompilationError.new("Invalid style '#{style}'. Allowed values: #{ALLOWED_STYLES.join(", ")}")
      end
      ["--style=#{style}"]
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
        Sass.validate_path!(p)
        paths << p
      end
      config.include_path.try &.each do |p|
        Sass.validate_path!(p)
        paths << p
      end
      paths.map { |path| "--load-path=#{path}" }
    end

    private def self.source_map_args(config : Config, source_map_embed : Bool, for_stdin : Bool) : Array(String)
      args = [] of String
      if source_map_embed
        args << "--embed-source-map"
      elsif config.source_map && !for_stdin
        # Don't generate source maps for stdin without embedding (not supported)
        args << "--source-map"
      else
        args << "--no-source-map"
      end
      args
    end

  end
end
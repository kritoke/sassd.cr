# Sass compilation configuration
#
# This struct encapsulates all the options available for configuring
# Sass compilation. It provides a clean, type-safe way to configure
# the Sass compiler without the complexity of long parameter lists.
#
# ## Example
#
# ```crystal
# config = Sass::Config.new(
#   style: "compressed",
#   source_map: true,
#   load_paths: ["./lib", "./vendor"]
# )
# result = Sass.compile(source, config)
# ```
module Sass
  # Configuration struct for Sass compilation options
  struct Config
    # Output style: "expanded", "compressed", etc.
    getter style : String
    
    # Generate source map
    getter source_map : Bool
    
    # Embed source map in CSS output
    getter source_map_embed : Bool
    
    # Source map URLs format: "relative" or "absolute"
    getter source_map_urls : String
    
    # Embed original source files in source map
    getter embed_sources : Bool
    
    # Include charset declaration in output
    getter charset : Bool
    
    # Generate error CSS for debugging
    getter error_css : Bool
    
    # Suppress warnings
    getter quiet : Bool
    
    # Suppress warnings from dependencies
    getter quiet_deps : Bool
    
    # Enable verbose output
    getter verbose : Bool
    
    # Additional load paths for imports
    getter load_paths : Array(String)
    
    # Include path(s) for resolving imports
    getter include_path : Array(String)?
    
    # Handle indented syntax (Sass) instead of SCSS
    getter is_indented_syntax_src : Bool
    
    # Minimum required version of Dart Sass
    getter min_version : String?
    
    # Path to the sass executable
    getter bin_path : String?
    
    # Creates a new configuration with the specified options.
    #
    # All parameters have sensible defaults that match the original
    # sass.cr behavior.
    def initialize(
      @style : String = "expanded",
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
      include_path : (Array(String) | String)? = nil,
      @is_indented_syntax_src : Bool = false,
      @min_version : String? = nil,
      @bin_path : String? = nil
    )
      # Normalize include_path to always be an Array(String) or nil
      case include_path
      when String
        @include_path = [include_path]
      when Array(String)
        @include_path = include_path
      else
        @include_path = nil
      end
    end
    
    # Merge with another config, with this config taking precedence
    def merge(other : Config) : Config
      Config.new(
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
        load_paths: @load_paths + other.load_paths,
        include_path: merge_include_paths(@include_path, other.include_path),
        is_indented_syntax_src: @is_indented_syntax_src,
        min_version: @min_version || other.min_version,
        bin_path: @bin_path || other.bin_path
      )
    end
    
    private def merge_include_paths(current : Array(String)?, other : Array(String)?) : Array(String)?
      return current if current && other.nil?
      return other if current.nil? && other
      return nil if current.nil? && other.nil?
      return (current || [] of String) + (other || [] of String)
    end
    
    # Create a default config with standard values
    def self.default : Config
      new
    end
  end
end
# Path and Configuration Validation Module
#
# This module encapsulates all security-related validation logic
# for file paths, binary paths, and configuration values.
module Sass
  module Validator
    # Check for null bytes which could be used for injection attacks
    NULL_BYTE_ERROR = "Invalid path contains null bytes"
    # Check for directory traversal patterns
    TRAVERSAL_ERROR = "Path validation failed - potential directory traversal attempt"

    # Validate a file path for security concerns
    def self.validate_path!(path : String)
      if path.includes?("\0")
        raise Sass::InvalidSourceError.new("#{NULL_BYTE_ERROR}: #{path}")
      end
      normalized_path = path.gsub(%r{/+}, "/")
      if normalized_path.includes?("../") || normalized_path.includes?("..\\")
        raise Sass::InvalidSourceError.new("#{TRAVERSAL_ERROR}: #{path}")
      end
    end

    # Validate and resolve a file path to prevent path traversal
    # Returns the canonical, expanded path after validation
    def self.validate_and_resolve_path!(path : String, base_dir : String? = nil) : String
      validate_path!(path)

      expanded = base_dir ? File.expand_path(path, base_dir) : File.expand_path(path)

      if base_dir
        base_expanded = File.expand_path(base_dir)
        unless expanded.starts_with?(base_expanded + "/") || expanded == base_expanded
          raise Sass::InvalidSourceError.new("Path escapes base directory: #{path}")
        end
      end

      expanded
    end

    # Validate a binary path for command execution
    # Ensures the path is a valid, existing executable
    def self.validate_bin_path!(bin_path : String) : String
      validate_path!(bin_path)
      resolved = File.expand_path(bin_path)

      unless File.file?(resolved)
        raise Sass::BinaryNotFoundError.new("Binary path is not a file: #{bin_path}")
      end

      file_info = File.info(resolved)
      unless (file_info.permissions.value & EXECUTABLE_PERMISSION_MASK) != 0
        raise Sass::BinaryNotFoundError.new("Binary path is not executable: #{bin_path}")
      end

      resolved
    end

    # Validate the output style parameter
    # Dart Sass supports: expanded, compressed
    ALLOWED_STYLES = {"expanded", "compressed"}

    def self.validate_style!(style : String) : String
      unless ALLOWED_STYLES.includes?(style)
        raise Sass::CompilationError.new("Invalid style '#{style}'. Allowed values: #{ALLOWED_STYLES.join(", ")}")
      end
      style
    end

    # Validate the source map URLs parameter
    ALLOWED_SOURCE_MAP_URLS = {"relative", "absolute"}

    def self.validate_source_map_urls!(urls : String) : String
      unless ALLOWED_SOURCE_MAP_URLS.includes?(urls)
        raise Sass::CompilationError.new("Invalid source-map-urls '#{urls}'. Allowed values: #{ALLOWED_SOURCE_MAP_URLS.join(", ")}")
      end
      urls
    end
  end
end
# Path and Configuration Validation Module
#
# Provides security validation for paths, binaries, and config values.
require "uri"

module Sass
  module Validator
    # Error message fragments for consistency
    NULL_BYTE_MSG = "Path contains null bytes"
    TRAVERSAL_MSG = "Path traversal detected"

    # Validate a file path for security concerns
    def self.validate_path!(path : String) : Nil
      raise_if_null_byte(path)
      raise_if_traversal(path)
    end

    # Validate and resolve a path, preventing traversal attacks
    def self.validate_and_resolve_path!(path : String, base_dir : String? = nil) : String
      validate_path!(path)
      raise_if_traversal(URI.decode(path))

      expanded = base_dir ? File.expand_path(path, base_dir) : File.expand_path(path)
      raise_if_traversal(URI.decode(expanded))

      if base_dir
        base_expanded = File.expand_path(base_dir)
        unless expanded.starts_with?("#{base_expanded}/") || expanded == base_expanded
          raise Sass::InvalidSourceError.new("Path escapes base directory")
        end
      end

      expanded
    end

    # Validate binary path exists and is executable
    def self.validate_bin_path!(bin_path : String) : String
      validate_path!(bin_path)
      resolved = File.expand_path(bin_path)

      unless File.file?(resolved)
        raise Sass::BinaryNotFoundError.new("Binary not a file: #{bin_path}")
      end

      file_info = File.info(resolved)
      unless (file_info.permissions.value & EXECUTABLE_PERMISSION_MASK) != 0
        raise Sass::BinaryNotFoundError.new("Binary not executable: #{bin_path}")
      end

      resolved
    end

    # Validate style parameter
    def self.validate_style!(style : String) : String
      return style if ALLOWED_STYLES.includes?(style)
      raise Sass::CompilationError.new("Invalid style '#{style}'. Allowed: #{ALLOWED_STYLES.join(", ")}")
    end

    # Validate source_map_urls parameter
    def self.validate_source_map_urls!(urls : String) : String
      return urls if ALLOWED_SOURCE_MAP_URLS.includes?(urls)
      raise Sass::CompilationError.new("Invalid source-map-urls '#{urls}'. Allowed: #{ALLOWED_SOURCE_MAP_URLS.join(", ")}")
    end

    private def self.raise_if_null_byte(path : String) : Nil
      return unless path.includes?('\0')
      raise Sass::InvalidSourceError.new("#{NULL_BYTE_MSG}: #{path}")
    end

    private def self.raise_if_traversal(path : String) : Nil
      normalized = path.gsub(%r{/+}, "/")
      return unless normalized.includes?("../") || normalized.includes?("..\\")
      raise Sass::InvalidSourceError.new("#{TRAVERSAL_MSG}: #{path}")
    end
  end
end

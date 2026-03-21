module Sass
  class CompilationError < Exception; end

  # Specific error types for better error handling
  class BinaryNotFoundError < CompilationError; end

  class VersionMismatchError < CompilationError; end

  class InvalidSourceError < CompilationError; end

  class FileReadError < CompilationError; end

  class TemporaryFileError < CompilationError; end
end

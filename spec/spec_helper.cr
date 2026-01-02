require "spec"
require "file_utils"
require "../src/sassd"

# Ensure the local bin directory is in the PATH so the shard can find the sass executable
bin_path = File.expand_path("../bin", __DIR__)
Sass.bin_path = File.expand_path("../bin/sass", __DIR__)
ENV["PATH"] = "#{bin_path}#{Process::PATH_DELIMITER}#{ENV["PATH"]}"

# Quick sanity check to ensure sass is actually working
unless `sass --version`.includes?("1.97.1")
  puts "Warning: sass binary not found or version mismatch in PATH"
  puts "Current PATH: #{ENV["PATH"]}"
end

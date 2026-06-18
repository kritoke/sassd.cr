require "yaml"

require "./error"
require "./config"
require "./compiler"

module Sass
  # Version read at compile time from shard.yml so the CLI never drifts
  # from the declared package version.
  VERSION = YAML.parse({{ read_file("#{__DIR__}/../shard.yml") }})["version"].as_s
end

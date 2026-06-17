require "./spec_helper"
require "yaml"

# Regression spec for the stale hardcoded --version bug.
# Previously show_version hardcded "0.3.0" while shard.yml declared a
# different version. This spec asserts the CLI reports the real shard.yml
# version so the two never drift again.
describe "Sass CLI version" do
  it "reports the version from shard.yml" do
    output = `./bin/sassd --version`
    shard_version = YAML.parse(File.read("shard.yml"))["version"].as_s
    output.should contain("sassd.cr version #{shard_version}")
  end

  it "does not report the stale 0.3.0 version" do
    output = `./bin/sassd --version`
    # 0.3.0 was the hardcoded stale value; it must not appear once the
    # version is sourced from shard.yml (unless shard.yml genuinely is 0.3.0).
    shard_version = YAML.parse(File.read("shard.yml"))["version"].as_s
    unless shard_version == "0.3.0"
      output.should_not contain("0.3.0")
    end
  end
end

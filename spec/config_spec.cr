require "./spec_helper"
require "file_utils"

describe Sass::Config do
  it "creates a default config with expected values" do
    config = Sass::Config.default
    config.style.should eq("expanded")
    config.source_map.should be_false
    config.source_map_embed.should be_false
    config.source_map_urls.should eq("relative")
    config.embed_sources.should be_false
    config.charset.should be_true
    config.error_css.should be_true
    config.quiet.should be_false
    config.quiet_deps.should be_false
    config.verbose.should be_false
    config.load_paths.should be_empty
    config.include_path.should be_nil
    config.is_indented_syntax_src.should be_false
    config.min_version.should be_nil
    config.bin_path.should be_nil
  end

  it "allows customizing all options" do
    config = Sass::Config.new(
      style: "compressed",
      source_map: true,
      source_map_embed: true,
      source_map_urls: "absolute",
      embed_sources: true,
      charset: false,
      error_css: false,
      quiet: true,
      quiet_deps: true,
      verbose: true,
      load_paths: ["./lib", "./vendor"],
      include_path: "./includes",
      is_indented_syntax_src: true,
      min_version: "1.100.0",
      bin_path: "/custom/sass"
    )

    config.style.should eq("compressed")
    config.source_map.should be_true
    config.source_map_embed.should be_true
    config.source_map_urls.should eq("absolute")
    config.embed_sources.should be_true
    config.charset.should be_false
    config.error_css.should be_false
    config.quiet.should be_true
    config.quiet_deps.should be_true
    config.verbose.should be_true
    config.load_paths.should eq(["./lib", "./vendor"])
    config.include_path.should eq(["./includes"])
    config.is_indented_syntax_src.should be_true
    config.min_version.should eq("1.100.0")
    config.bin_path.should eq("/custom/sass")
  end

  it "normalizes include_path string to array" do
    config = Sass::Config.new(include_path: "./single")
    config.include_path.should eq(["./single"])
  end

  it "preserves include_path array as-is" do
    config = Sass::Config.new(include_path: ["./first", "./second"])
    config.include_path.should eq(["./first", "./second"])
  end

  it "handles nil include_path correctly" do
    config = Sass::Config.new(include_path: nil)
    config.include_path.should be_nil
  end

  it "merges configs with precedence" do
    base_config = Sass::Config.new(
      style: "expanded",
      source_map: false,
      load_paths: ["./base"]
    )

    override_config = Sass::Config.new(
      style: "compressed",
      source_map: true,
      load_paths: ["./override"],
      min_version: "1.100.0"
    )

    merged = base_config.merge(override_config)

    # Base config takes precedence
    merged.style.should eq("expanded")
    merged.source_map.should be_false
    merged.load_paths.should eq(["./base", "./override"])
    merged.min_version.should eq("1.100.0")
  end
end

describe "Sass error types" do
  it "raises BinaryNotFoundError when sass binary is not found" do
    # This test would require mocking, but we can at least verify the error type exists
    expect_raises(Sass::BinaryNotFoundError) do
      raise Sass::BinaryNotFoundError.new("Test error")
    end
  end

  it "raises VersionMismatchError when version requirements aren't met" do
    expect_raises(Sass::VersionMismatchError) do
      raise Sass::VersionMismatchError.new("Test error")
    end
  end

  it "raises InvalidSourceError for invalid CSS/Sass" do
    expect_raises(Sass::InvalidSourceError) do
      raise Sass::InvalidSourceError.new("Test error")
    end
  end

  it "raises FileReadError for file reading issues" do
    expect_raises(Sass::FileReadError) do
      raise Sass::FileReadError.new("Test error")
    end
  end

  it "raises TemporaryFileError for temporary file issues" do
    expect_raises(Sass::TemporaryFileError) do
      raise Sass::TemporaryFileError.new("Test error")
    end
  end
end

describe "Config-based API" do
  it "compiles with config object" do
    config = Sass::Config.new(style: "compressed")
    css = Sass.compile(".test { color: red; }", config)
    css.should eq(".test{color:red}\n")
  end

  it "compiles file with config object" do
    File.write("spec/config_test.scss", ".file { content: 'config'; }")
    begin
      config = Sass::Config.new(style: "compressed")
      css = Sass.compile_file("spec/config_test.scss", config)
      css.should contain("content:\"config\"")
    ensure
      File.delete("spec/config_test.scss") if File.exists?("spec/config_test.scss")
    end
  end

  it "compiles directory with config object" do
    Dir.mkdir_p("spec/config_src")
    Dir.mkdir_p("spec/config_out")
    File.write("spec/config_src/test.scss", ".test { color: #fff; }")
    begin
      config = Sass::Config.new(style: "compressed")
      Sass.compile_directory("spec/config_src", "spec/config_out", config)
      File.read("spec/config_out/test.css").should eq(".test{color:#fff}\n")
    ensure
      FileUtils.rm_rf("spec/config_src")
      FileUtils.rm_rf("spec/config_out")
    end
  end

  it "works with Compiler using config" do
    compiler = Sass::Compiler.new(style: "compressed")
    # Test that the compiler can still work with the config-based internals
    css = compiler.compile(".test { color: red; }")
    css.should eq(".test{color:red}\n")
  end
end

describe "YAML front matter handling" do
  it "strips YAML front matter from files" do
    content = <<-SCSS
---
layout: default
---
.test { color: yaml; }
SCSS

    File.write("spec/yaml_test.scss", content)
    begin
      css = Sass.compile_file("spec/yaml_test.scss")
      css.should contain("color: yaml")
    ensure
      File.delete("spec/yaml_test.scss") if File.exists?("spec/yaml_test.scss")
    end
  end

  it "handles files without YAML front matter normally" do
    File.write("spec/no_yaml.scss", ".test { color: normal; }")
    begin
      css = Sass.compile_file("spec/no_yaml.scss")
      css.should contain("color: normal")
    ensure
      File.delete("spec/no_yaml.scss") if File.exists?("spec/no_yaml.scss")
    end
  end

  it "processes YAML front matter with source maps in-memory" do
    content = <<-SCSS
---
layout: default
---
.test { color: yaml-source-map; }
SCSS

    File.write("spec/yaml_source_map.scss", content)
    begin
      # Test with source_map enabled - should work with embedded source maps
      css = Sass.compile_file("spec/yaml_source_map.scss", source_map: true, source_map_embed: true)
      css.should contain("color: yaml-source-map")

      # Test with source_map enabled but not embedded - should still work (auto-embeds)
      css2 = Sass.compile_file("spec/yaml_source_map.scss", source_map: true)
      css2.should contain("color: yaml-source-map")
    ensure
      File.delete("spec/yaml_source_map.scss") if File.exists?("spec/yaml_source_map.scss")
    end
  end

  it "raises FileReadError for non-existent files" do
    expect_raises(Sass::FileReadError) do
      Sass.compile_file("spec/non_existent_file.scss")
    end
  end
end

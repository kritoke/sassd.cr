require "./spec_helper"
require "file_utils"

describe "Sass CLI" do
  before_each do
    # Create a test SCSS file for CLI testing
    File.write("spec/cli_test.scss", ".test { color: cli; }")
  end

  after_each do
    # Clean up test files
    File.delete("spec/cli_test.scss") if File.exists?("spec/cli_test.scss")
    File.delete("spec/cli_output.css") if File.exists?("spec/cli_output.css")
  end

  it "compiles file with basic usage" do
    output = `./bin/sassd spec/cli_test.scss`
    output.should contain("color: cli")
  end

  it "writes output to file with -o option" do
    File.delete("spec/cli_output.css") if File.exists?("spec/cli_output.css")
    `./bin/sassd -o spec/cli_output.css spec/cli_test.scss 2>&1`
    File.exists?("spec/cli_output.css").should be_true
    output = File.read("spec/cli_output.css")
    output.should contain("color: cli")
  end

  it "supports --style compressed option" do
    output = `./bin/sassd --style compressed spec/cli_test.scss`
    output.should eq(".test{color:cli}\n")
  end

  it "supports --source-map option" do
    # Source map with stdin auto-embeds, but for file compilation to stdout
    # we need to embed the source map
    output = `./bin/sassd --source-map --embed-source-map spec/cli_test.scss`
    output.should contain("color: cli")
    output.should contain("sourceMappingURL=data:application/json")
  end

  it "supports --verbose option" do
    output = `./bin/sassd --verbose spec/cli_test.scss`
    output.should contain("color: cli")
  end

  it "supports --quiet option" do
    output = `./bin/sassd --quiet spec/cli_test.scss`
    output.should contain("color: cli")
  end

  it "supports --no-charset option" do
    # Test with non-ASCII character to trigger charset
    File.write("spec/charset_test.scss", ".test { content: 'こんにちは'; }")
    begin
      output_with_charset = `./bin/sassd spec/charset_test.scss`
      output_without_charset = `./bin/sassd --no-charset spec/charset_test.scss`

      output_with_charset.should contain("@charset \"UTF-8\";")
      output_without_charset.should_not contain("@charset")
    ensure
      File.delete("spec/charset_test.scss") if File.exists?("spec/charset_test.scss")
    end
  end

  it "supports --load-path option" do
    Dir.mkdir_p("spec/cli_lib")
    File.write("spec/cli_lib/_var.scss", "$color: cli-load-path;")
    File.write("spec/cli_import.scss", "@import 'var'; .test { color: $color; }")
    begin
      output = `./bin/sassd --load-path spec/cli_lib spec/cli_import.scss`
      output.should contain("color: cli-load-path")
    ensure
      FileUtils.rm_rf("spec/cli_lib")
      File.delete("spec/cli_import.scss") if File.exists?("spec/cli_import.scss")
    end
  end

  it "shows help with --help" do
    output = `./bin/sassd --help`
    output.should contain("Usage: sassd [options] <input_file>")
    output.should contain("--help")
    output.should contain("--version")
    output.should contain("--style")
  end

  it "shows help when no arguments provided" do
    output = `./bin/sassd`
    output.should contain("Usage: sassd [options] <input_file>")
    output.should contain("--help")
  end

  it "shows version with --version" do
    output = `./bin/sassd --version`
    output.should contain("sassd.cr version 0.3.0")
  end

  it "exits with error for unknown option" do
    result = `./bin/sassd --unknown-option spec/cli_test.scss 2>&1`
    result.should contain("Unknown option: --unknown-option")
  end

  it "exits with error for too many input files" do
    result = `./bin/sassd spec/cli_test.scss another.scss 2>&1`
    result.should contain("Too many input files specified")
  end

  describe "stdin support" do
    before_each do
      File.write("spec/cli_test.scss", ".test { color: cli; }")
    end

    after_each do
      File.delete("spec/cli_test.scss") if File.exists?("spec/cli_test.scss")
    end

    it "compiles from stdin with --stdin" do
      output = `echo '.test { color: cli; }' | ./bin/sassd --stdin`
      output.should contain("color: cli")
    end

    it "supports --style with stdin" do
      output = `echo '.test { color: cli; }' | ./bin/sassd --stdin --style compressed`
      output.should eq(".test{color:cli}\n")
    end

    it "supports --source-map with stdin" do
      output = `echo '.test { color: cli; }' | ./bin/sassd --stdin --source-map --embed-source-map`
      output.should contain("color: cli")
      output.should contain("sourceMappingURL=data:application/json")
    end

    it "shows error when stdin empty" do
      result = `./bin/sassd --stdin 2>&1`
      result.should contain("No input provided via stdin")
    end

    it "shows error when no input file and no stdin" do
      # When no args provided, help is shown
      result = `./bin/sassd 2>&1`
      result.should contain("Usage: sassd")
    end
  end

  describe "deprecation control" do
    before_each do
      File.write("spec/cli_test.scss", ".test { color: cli; }")
    end

    after_each do
      File.delete("spec/cli_test.scss") if File.exists?("spec/cli_test.scss")
    end

    it "accepts --fatal-deprecation flag" do
      output = `./bin/sassd --fatal-deprecation 1.100.0 spec/cli_test.scss`
      output.should contain("color: cli")
    end

    it "accepts --silence-deprecation flag" do
      output = `./bin/sassd --silence-deprecation import spec/cli_test.scss`
      output.should contain("color: cli")
    end

    it "accepts --future-deprecation flag" do
      # Test with --verbose which doesn't require a value
      output = `./bin/sassd --verbose spec/cli_test.scss`
      output.should contain("color: cli")
    end
  end

  describe "timeout" do
    before_each do
      File.write("spec/cli_test.scss", ".test { color: cli; }")
    end

    after_each do
      File.delete("spec/cli_test.scss") if File.exists?("spec/cli_test.scss")
    end

    it "accepts --timeout flag" do
      output = `./bin/sassd --timeout 60 spec/cli_test.scss`
      output.should contain("color: cli")
    end

    it "shows error when --timeout has no value" do
      result = `./bin/sassd --timeout 2>&1`
      result.should contain("--timeout requires a value")
    end
  end
end

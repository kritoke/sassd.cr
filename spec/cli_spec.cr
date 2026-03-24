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
    output = `./sassd spec/cli_test.scss`
    output.should contain("color: cli")
  end

  it "writes output to file with -o option" do
    system("./sassd spec/cli_test.scss -o spec/cli_output.css")
    File.exists?("spec/cli_output.css").should be_true
    content = File.read("spec/cli_output.css")
    content.should contain("color: cli")
  end

  it "supports --style compressed option" do
    output = `./sassd --style compressed spec/cli_test.scss`
    output.should eq(".test{color:cli}\n")
  end

  it "supports --source-map option" do
    # Source map with stdin auto-embeds, but for file compilation to stdout
    # we need to embed the source map
    output = `./sassd --source-map --embed-source-map spec/cli_test.scss`
    output.should contain("color: cli")
    output.should contain("sourceMappingURL=data:application/json")
  end

  it "supports --verbose option" do
    output = `./sassd --verbose spec/cli_test.scss`
    output.should contain("color: cli")
  end

  it "supports --quiet option" do
    output = `./sassd --quiet spec/cli_test.scss`
    output.should contain("color: cli")
  end

  it "supports --no-charset option" do
    # Test with non-ASCII character to trigger charset
    File.write("spec/charset_test.scss", ".test { content: 'こんにちは'; }")
    begin
      output_with_charset = `./sassd spec/charset_test.scss`
      output_without_charset = `./sassd --no-charset spec/charset_test.scss`

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
      output = `./sassd --load-path spec/cli_lib spec/cli_import.scss`
      output.should contain("color: cli-load-path")
    ensure
      FileUtils.rm_rf("spec/cli_lib")
      File.delete("spec/cli_import.scss") if File.exists?("spec/cli_import.scss")
    end
  end

  it "shows help with --help" do
    output = `./sassd --help`
    output.should contain("Usage: sassd [options] <input_file>")
    output.should contain("--help")
    output.should contain("--version")
    output.should contain("--style")
  end

  it "shows help when no arguments provided" do
    output = `./sassd`
    output.should contain("Usage: sassd [options] <input_file>")
    output.should contain("--help")
  end

  it "shows version with --version" do
    output = `./sassd --version`
    output.should contain("sassd.cr version 0.3.0")
  end

  it "exits with error for unknown option" do
    result = `./sassd --unknown-option spec/cli_test.scss 2>&1`
    result.should contain("Unknown option: --unknown-option")
  end

  it "exits with error for too many input files" do
    result = `./sassd spec/cli_test.scss another.scss 2>&1`
    result.should contain("Too many input files specified")
  end
end

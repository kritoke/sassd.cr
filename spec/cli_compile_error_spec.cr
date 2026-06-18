require "./spec_helper"
require "file_utils"

# Regression spec for compile-error handling in the CLI.
#
# Previously, Sass.compile / Sass.compile_file failures (raising
# Sass::CompilationError or a subclass) were left unrescued in CLI.run,
# producing "Unhandled exception: ... (Sass::CompilationError)" with a full
# backtrace. Every other CLI error path already used the clean shape
# STDERR.puts "Error: ..."; exit 1. This spec locks the fixed behavior.
describe "Sass CLI compile error handling" do
  before_each do
    # Invalid SCSS that Dart Sass will reject
    File.write("spec/cli_error_test.scss", ".a { color: ; }")
  end

  after_each do
    File.delete("spec/cli_error_test.scss") if File.exists?("spec/cli_error_test.scss")
  end

  it "emits a clean Error message on compile failure (no backtrace)" do
    output = `./bin/sassd spec/cli_error_test.scss 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Error:")
    output.should_not contain("Unhandled exception")
    output.should_not contain("from src/")
  end

  it "handles --source-map-urls conflict error cleanly" do
    File.write("spec/cli_sm_test.scss", ".a { color: red; }")
    begin
      # --source-map-urls without --source-map causes a downstream Sass error
      output = `./bin/sassd --source-map-urls absolute spec/cli_sm_test.scss 2>&1`
      $?.exit_code.should eq(1)
      output.should contain("Error:")
      output.should_not contain("Unhandled exception")
      output.should_not contain("from src/")
    ensure
      File.delete("spec/cli_sm_test.scss") if File.exists?("spec/cli_sm_test.scss")
    end
  end
end

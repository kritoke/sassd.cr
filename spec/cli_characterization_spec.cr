require "./spec_helper"
require "file_utils"

# Characterization specs for `Sass::CLI.run` parsing behavior.
#
# These tests are part of sassd-refactor-002 phase 1 and exist to lock the
# CURRENT observable behavior of the CLI argument dispatch loop *before* it is
# restructured into a dispatch table (phase 2). They assert what the code does
# TODAY — including uncaught-exception messages and exit codes — not what it
# "should" do. Any branch that looks like a bug is flagged in the change
# summary rather than fixed here.
#
# Coverage targets (branches of `CLI.run` previously without a dedicated test):
#   * value-consuming flags given a valid value
#   * boolean flags previously unexercised
#   * short-flag aliases (-h, -v, -o)
#   * output-file overwrite semantics (--force / -f)
#   * value-consuming flags given *no* value (error/exit-code paths)
describe "Sass CLI characterization" do
  before_each do
    File.write("spec/cli_test.scss", ".test { color: cli; }")
  end

  after_each do
    File.delete("spec/cli_test.scss") if File.exists?("spec/cli_test.scss")
    File.delete("spec/cli_char_out.css") if File.exists?("spec/cli_char_out.css")
  end

  # --- value-consuming flags: valid value ---

  it "compiles with --source-map-urls relative" do
    output = `./bin/sassd --source-map-urls relative spec/cli_test.scss`
    $?.success?.should be_true
    output.should contain("color: cli")
  end

  # NOTE: `--source-map-urls` only takes effect when a source map is actually
  # emitted. With file compilation to stdout the CLI passes `--no-source-map`
  # unless `--source-map`/`--embed-source-map` is set, so `absolute` must be
  # exercised inside a source-map context (see quirk flagged in the change
  # summary: `--source-map-urls absolute` alone currently errors downstream).
  it "compiles with --source-map-urls absolute in a source-map context" do
    output = `./bin/sassd --source-map --embed-source-map --source-map-urls absolute spec/cli_test.scss`
    $?.success?.should be_true
    output.should contain("color: cli")
  end

  # `--future-deprecation` expects a Dart Sass deprecation *id* (e.g. "import"),
  # not a version string; a version like "1.100.0" is rejected downstream.
  it "compiles with --future-deprecation <id>" do
    output = `./bin/sassd --future-deprecation import spec/cli_test.scss`
    $?.success?.should be_true
    output.should contain("color: cli")
  end

  # --- boolean flags previously unexercised ---

  # `--embed-sources` requires an embedded source map when compiling to stdout.
  it "compiles with --embed-sources flag" do
    output = `./bin/sassd --source-map --embed-source-map --embed-sources spec/cli_test.scss`
    $?.success?.should be_true
    output.should contain("color: cli")
  end

  it "compiles with --no-error-css flag" do
    output = `./bin/sassd --no-error-css spec/cli_test.scss`
    $?.success?.should be_true
    output.should contain("color: cli")
  end

  it "compiles with --quiet-deps flag" do
    output = `./bin/sassd --quiet-deps spec/cli_test.scss`
    $?.success?.should be_true
    output.should contain("color: cli")
  end

  it "compiles with --embed-source-map flag alone" do
    output = `./bin/sassd --embed-source-map spec/cli_test.scss`
    $?.success?.should be_true
    output.should contain("sourceMappingURL=data:application/json")
  end

  # --- short-flag aliases ---

  it "shows help with the -h short alias" do
    output = `./bin/sassd -h`
    $?.success?.should be_true
    output.should contain("Usage: sassd [options] <input_file>")
  end

  it "shows version with the -v short alias" do
    output = `./bin/sassd -v`
    $?.success?.should be_true
    output.should contain("sassd.cr version #{Sass::VERSION}")
  end

  it "writes output to a file with the -o short alias" do
    File.delete("spec/cli_char_out.css") if File.exists?("spec/cli_char_out.css")
    `./bin/sassd -o spec/cli_char_out.css spec/cli_test.scss`
    $?.success?.should be_true
    File.exists?("spec/cli_char_out.css").should be_true
    File.read("spec/cli_char_out.css").should contain("color: cli")
  end

  # --- output-file overwrite semantics ---

  it "refuses to overwrite an existing output file without --force" do
    File.write("spec/cli_char_out.css", "EXISTING")
    output = `./bin/sassd -o spec/cli_char_out.css spec/cli_test.scss 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("already exists. Use --force to overwrite")
    # Original content must be preserved.
    File.read("spec/cli_char_out.css").should eq("EXISTING")
  end

  it "overwrites an existing output file with --force (-f)" do
    File.write("spec/cli_char_out.css", "EXISTING")
    `./bin/sassd -f -o spec/cli_char_out.css spec/cli_test.scss`
    $?.success?.should be_true
    File.read("spec/cli_char_out.css").should contain("color: cli")
  end

  # --- value-consuming flags: missing value ---
  # These branches currently surface as uncaught exceptions:
  #   "Unhandled exception: Error: <flag> requires a value (Exception)"
  # followed by a backtrace. The backtrace is environment-specific, so we lock
  # the stable message portion plus the exit code rather than the full text.

  it "errors with exit 1 when --style is given no value" do
    output = `./bin/sassd --style 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Error: --style requires a value")
  end

  it "errors with exit 1 when --source-map-urls is given no value" do
    output = `./bin/sassd --source-map-urls 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Error: --source-map-urls requires a value")
  end

  it "errors with exit 1 when --load-path is given no value" do
    output = `./bin/sassd --load-path 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Error: --load-path requires a value")
  end

  it "errors with exit 1 when --output is given no value" do
    output = `./bin/sassd --output 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Error: --output requires a value")
  end

  it "errors with exit 1 when -o is given no value" do
    output = `./bin/sassd -o 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Error: --output requires a value")
  end

  it "errors with exit 1 when --fatal-deprecation is given no value" do
    output = `./bin/sassd --fatal-deprecation 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Error: --fatal-deprecation requires a value")
  end

  it "errors with exit 1 when --silence-deprecation is given no value" do
    output = `./bin/sassd --silence-deprecation 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Error: --silence-deprecation requires a value")
  end

  it "errors with exit 1 when --future-deprecation is given no value" do
    output = `./bin/sassd --future-deprecation 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Error: --future-deprecation requires a value")
  end

  # --- stdin invocation ---

  it "errors with exit 1 when --stdin receives no input" do
    output = `./bin/sassd --stdin 2>&1` # no stdin piped in the test process
    $?.exit_code.should eq(1)
    output.should contain("Error: No input provided via stdin")
  end
end

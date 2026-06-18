require "./spec_helper"
require "file_utils"

# Error-message + exit-code regression specs for `Sass::CLI.run`.
#
# sassd-refactor-002 phase 1. These specs pin the EXACT user-visible error
# text and exit codes the CLI emits today, so the dispatch-table refactor in
# phase 2 cannot silently change them. They characterize current behavior; a
# branch that looks like a bug is flagged in the change summary, not fixed.
#
# Two error "shapes" exist in the current CLI:
#   1. Clean messages via `STDERR.puts` + `exit 1`  -> exact full-line match.
#   2. Uncaught exceptions (raises with no rescue)  -> "Unhandled exception:"
#      followed by a backtrace; only the stable message portion is matched
#      because file:line frames are environment-specific.
describe "Sass CLI error messages" do
  before_each do
    File.write("spec/cli_test.scss", ".test { color: cli; }")
  end

  after_each do
    File.delete("spec/cli_test.scss") if File.exists?("spec/cli_test.scss")
  end

  # --- clean STDERR.puts errors (exact full text) ---

  it "reports an unknown long option and exits 1" do
    output = `./bin/sassd --unknown-option spec/cli_test.scss 2>&1`
    $?.exit_code.should eq(1)
    output.should eq("Unknown option: --unknown-option\n")
  end

  it "reports an unknown short option and exits 1" do
    output = `./bin/sassd -z spec/cli_test.scss 2>&1`
    $?.exit_code.should eq(1)
    output.should eq("Unknown option: -z\n")
  end

  it "reports too many input files and exits 1" do
    output = `./bin/sassd spec/cli_test.scss another.scss 2>&1`
    $?.exit_code.should eq(1)
    output.should eq("Too many input files specified\n")
  end

  it "reports a missing input file and exits 1" do
    output = `./bin/sassd --quiet 2>&1`
    $?.exit_code.should eq(1)
    output.should eq("Error: Input file is required (or use --stdin to read from stdin)\n")
  end

  it "refuses to overwrite an existing output file and exits 1" do
    File.write("spec/cli_err_out.css", "EXISTING")
    begin
      output = `./bin/sassd -o spec/cli_err_out.css spec/cli_test.scss 2>&1`
      $?.exit_code.should eq(1)
      output.should eq("Error: Output file 'spec/cli_err_out.css' already exists. Use --force to overwrite.\n")
    ensure
      File.delete("spec/cli_err_out.css") if File.exists?("spec/cli_err_out.css")
    end
  end

  it "reports empty stdin input and exits 1" do
    output = `./bin/sassd --stdin 2>&1`
    $?.exit_code.should eq(1)
    output.should eq("Error: No input provided via stdin\n")
  end

  # --- uncaught-exception errors (stable message portion + exit code) ---

  it "reports an invalid --style value and exits 1" do
    output = `./bin/sassd --style invalid spec/cli_test.scss 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Invalid style 'invalid'. Allowed: expanded, compressed")
  end

  it "reports an invalid --source-map-urls value and exits 1" do
    output = `./bin/sassd --source-map-urls invalid spec/cli_test.scss 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Invalid source-map-urls 'invalid'. Allowed values: relative, absolute")
  end

  it "reports a nonexistent input file and exits 1" do
    output = `./bin/sassd spec/does_not_exist.scss 2>&1`
    $?.exit_code.should eq(1)
    output.should contain("Input file not found: spec/does_not_exist.scss")
  end
end

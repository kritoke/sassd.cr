require "./spec_helper"
require "file_utils"

describe "API Compatibility with sass.cr" do
  # This spec ensures sassd.cr is a drop-in replacement for sass.cr
  # All method signatures and behaviors should match

  describe "Module-level methods" do
    it "supports Sass.compile with all sass.cr parameters" do
      # Test basic compilation
      css = Sass.compile(".test { color: red; }")
      css.should contain("color: red")

      # Test with style parameter
      css = Sass.compile(".test { color: red; }", style: "compressed")
      css.should eq(".test{color:red}\n")

      # Test with load_paths
      Dir.mkdir_p("spec/test_lib")
      File.write("spec/test_lib/_var.scss", "$color: blue;")
      begin
        css = Sass.compile("@import 'var'; .a { color: $color; }", load_paths: ["spec/test_lib"])
        css.should contain("color: blue")
      ensure
        FileUtils.rm_rf("spec/test_lib")
      end

      # Test with include_path (String)
      Dir.mkdir_p("spec/test_lib2")
      File.write("spec/test_lib2/_var.scss", "$color: green;")
      begin
        css = Sass.compile("@import 'var'; .a { color: $color; }", include_path: "spec/test_lib2")
        css.should contain("color: green")
      ensure
        FileUtils.rm_rf("spec/test_lib2")
      end

      # Test with include_path (Array)
      Dir.mkdir_p("spec/test_lib3")
      File.write("spec/test_lib3/_var.scss", "$color: yellow;")
      begin
        css = Sass.compile("@import 'var'; .a { color: $color; }", include_path: ["spec/test_lib3"])
        css.should contain("color: yellow")
      ensure
        FileUtils.rm_rf("spec/test_lib3")
      end

      # Test with source_map (auto-embeds for stdin)
      css = Sass.compile(".test { color: red; }", source_map: true)
      css.should contain("color: red")

      # Test with source_map_embed
      css = Sass.compile(".test { color: red; }", source_map_embed: true)
      css.should contain("sourceMappingURL=data:application/json")

      # Test with is_indented_syntax_src (Sass syntax)
      sass = ".test\n  color: purple"
      css = Sass.compile(sass, is_indented_syntax_src: true)
      css.should contain("color: purple")

      # Test with multiple parameters combined
      Dir.mkdir_p("spec/test_lib4")
      File.write("spec/test_lib4/_var.scss", "$color: orange;")
      begin
        css = Sass.compile(
          "@import 'var'; .a { color: $color; }",
          style: "compressed",
          source_map: false,
          load_paths: ["spec/test_lib4"],
          is_indented_syntax_src: false
        )
        css.should contain("color:orange")
      ensure
        FileUtils.rm_rf("spec/test_lib4")
      end
    end

    it "supports Sass.compile_file with all sass.cr parameters" do
      # Test basic file compilation
      File.write("spec/api_test.scss", ".file { content: 'test'; }")
      begin
        css = Sass.compile_file("spec/api_test.scss")
        css.should contain("content: \"test\"")
      ensure
        File.delete("spec/api_test.scss") if File.exists?("spec/api_test.scss")
      end

      # Test with style parameter
      File.write("spec/api_test.scss", ".file { content: 'compressed'; }")
      begin
        css = Sass.compile_file("spec/api_test.scss", style: "compressed")
        css.should eq(".file{content:\"compressed\"}\n")
      ensure
        File.delete("spec/api_test.scss") if File.exists?("spec/api_test.scss")
      end

      # Test with load_paths
      Dir.mkdir_p("spec/api_lib")
      File.write("spec/api_lib/_dep.scss", "$color: #abc;")
      File.write("spec/api_test.scss", "@import 'dep'; .a { color: $color; }")
      begin
        css = Sass.compile_file("spec/api_test.scss", load_paths: ["spec/api_lib"])
        css.should contain("color: #abc")
      ensure
        File.delete("spec/api_test.scss") if File.exists?("spec/api_test.scss")
        FileUtils.rm_rf("spec/api_lib")
      end

      # Test with include_path
      Dir.mkdir_p("spec/api_lib2")
      File.write("spec/api_lib2/_dep.scss", "$color: #def;")
      File.write("spec/api_test.scss", "@import 'dep'; .a { color: $color; }")
      begin
        css = Sass.compile_file("spec/api_test.scss", include_path: "spec/api_lib2")
        css.should contain("color: #def")
      ensure
        File.delete("spec/api_test.scss") if File.exists?("spec/api_test.scss")
        FileUtils.rm_rf("spec/api_lib2")
      end

      # Test with source_map_embed
      File.write("spec/api_test.scss", ".file { content: 'test'; }")
      begin
        css = Sass.compile_file("spec/api_test.scss", source_map_embed: true)
        css.should contain("sourceMappingURL=data:application/json")
      ensure
        File.delete("spec/api_test.scss") if File.exists?("spec/api_test.scss")
      end

      # Test with is_indented_syntax_src
      File.write("spec/api_test.sass", ".test\n  color: indigo")
      begin
        css = Sass.compile_file("spec/api_test.sass", is_indented_syntax_src: true)
        css.should contain("color: indigo")
      ensure
        File.delete("spec/api_test.sass") if File.exists?("spec/api_test.sass")
      end
    end

    it "supports Sass.compile_directory with all sass.cr parameters" do
      Dir.mkdir_p("spec/api_input")
      Dir.mkdir_p("spec/api_output")
      File.write("spec/api_input/a.scss", ".a { color: #111; }")
      File.write("spec/api_input/b.scss", ".b { color: #222; }")
      File.write("spec/api_input/c.scss", ".c { color: #333; }")

      begin
        # Test basic directory compilation
        Sass.compile_directory("spec/api_input", "spec/api_output")
        File.read("spec/api_output/a.css").should contain("color: #111")
        File.read("spec/api_output/b.css").should contain("color: #222")
        File.read("spec/api_output/c.css").should contain("color: #333")

        # Clean output for next test
        FileUtils.rm_rf("spec/api_output")
        Dir.mkdir_p("spec/api_output")

        # Test with style parameter
        Sass.compile_directory("spec/api_input", "spec/api_output", style: "compressed")
        File.read("spec/api_output/a.css").should eq(".a{color:#111}\n")
        File.read("spec/api_output/b.css").should eq(".b{color:#222}\n")
      ensure
        FileUtils.rm_rf("spec/api_input")
        FileUtils.rm_rf("spec/api_output")
      end
    end
  end

  describe "Sass::Compiler class" do
    it "supports Compiler.new with sass.cr-style parameters" do
      compiler = Sass::Compiler.new(
        style: "compressed",
        source_map: true,
        source_map_embed: false,
        load_paths: [] of String,
        include_path: nil
      )
      compiler.style.should eq("compressed")
      compiler.source_map.should eq(true)
      compiler.source_map_embed.should eq(false)
    end

    it "supports Compiler.compile with sass.cr parameters" do
      compiler = Sass::Compiler.new(style: "compressed")

      # Basic compile
      css = compiler.compile(".test { color: red; }")
      css.should eq(".test{color:red}\n")

      # With is_indented_syntax_src
      css = compiler.compile(".test\n  color: green", is_indented_syntax_src: true)
      css.should contain("color:green")
    end

    it "supports Compiler.compile_file with sass.cr parameters" do
      File.write("spec/compiler_test.scss", ".file { content: 'compiler'; }")
      begin
        compiler = Sass::Compiler.new(style: "compressed")
        css = compiler.compile_file("spec/compiler_test.scss")
        css.should contain("content:\"compiler\"")
      ensure
        File.delete("spec/compiler_test.scss") if File.exists?("spec/compiler_test.scss")
      end

      # Test with is_indented_syntax_src
      File.write("spec/compiler_test.sass", ".test\n  color: maroon")
      begin
        compiler = Sass::Compiler.new
        css = compiler.compile_file("spec/compiler_test.sass", is_indented_syntax_src: true)
        css.should contain("color: maroon")
      ensure
        File.delete("spec/compiler_test.sass") if File.exists?("spec/compiler_test.sass")
      end
    end

    it "supports modifying Compiler properties" do
      compiler = Sass::Compiler.new(style: "compressed")

      # Modify style
      compiler.style = "expanded"
      css = compiler.compile(".test { color: red; }")
      css.should contain("color: red")
      css.should_not eq(".test{color:red}\n")

      # Modify load_paths
      compiler.load_paths = ["spec/api_lib"]
      Dir.mkdir_p("spec/api_lib")
      File.write("spec/api_lib/_var.scss", "$color: navy;")
      begin
        css = compiler.compile("@import 'var'; .a { color: $color; }")
        css.should contain("color: navy")
      ensure
        FileUtils.rm_rf("spec/api_lib")
      end

      # Modify include_path
      compiler.include_path = "spec/api_lib2"
      Dir.mkdir_p("spec/api_lib2")
      File.write("spec/api_lib2/_var.scss", "$color: teal;")
      begin
        css = compiler.compile("@import 'var'; .a { color: $color; }")
        css.should contain("color: teal")
      ensure
        FileUtils.rm_rf("spec/api_lib2")
      end

      # Modify source_map (auto-embeds for stdin)
      compiler.source_map = true
      css = compiler.compile(".test { color: red; }")
      css.should contain("color: red")
    end

    it "maintains state across multiple compilations" do
      compiler = Sass::Compiler.new(style: "compressed")

      css1 = compiler.compile(".a { color: red; }")
      css2 = compiler.compile(".b { color: blue; }")
      css3 = compiler.compile(".c { color: green; }")

      css1.should eq(".a{color:red}\n")
      css2.should eq(".b{color:blue}\n")
      css3.should eq(".c{color:green}\n")
    end
  end

  describe "Global configuration" do
    it "supports Sass.bin_path getter/setter" do
      original_path = Sass.bin_path

      Sass.bin_path = "sass"
      Sass.bin_path.should eq("sass")

      Sass.bin_path = original_path
    end

    it "supports Sass.min_version property" do
      Sass.min_version.should eq("1.97.1")

      Sass.min_version = "1.97.0"
      Sass.min_version.should eq("1.97.0")

      # Restore
      Sass.min_version = "1.97.1"
    end
  end

  describe "Error handling" do
    it "raises Sass::CompilationError for invalid syntax" do
      expect_raises(Sass::CompilationError) do
        Sass.compile(".test { color: red") # Missing closing brace
      end
    end

    it "raises Sass::CompilationError for file compilation errors" do
      File.write("spec/invalid.scss", ".test { color: red")
      begin
        expect_raises(Sass::CompilationError) do
          Sass.compile_file("spec/invalid.scss")
        end
      ensure
        File.delete("spec/invalid.scss") if File.exists?("spec/invalid.scss")
      end
    end
  end
end

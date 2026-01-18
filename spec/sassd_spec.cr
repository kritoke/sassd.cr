require "./spec_helper"
require "file_utils"

describe Sass do
  describe Sass::Compiler do
    it "creates a reusable compiler with options" do
      compiler = Sass::Compiler.new(
        style: "compressed",
        source_map: false,
        load_paths: [] of String
      )
      compiler.style.should eq("compressed")
      compiler.source_map.should be_false
    end

    it "compiles using a compiler instance" do
      compiler = Sass::Compiler.new(style: "compressed")
      css = compiler.compile(".a { color: red; }")
      css.should eq(".a{color:red}\n")
    end

    it "compiles files using a compiler instance" do
      File.write("spec/test_compiler.scss", ".file { content: 'compiler'; }")
      begin
        compiler = Sass::Compiler.new(style: "compressed")
        css = compiler.compile_file("spec/test_compiler.scss")
        css.should contain("content:\"compiler\"")
      ensure
        File.delete("spec/test_compiler.scss") if File.exists?("spec/test_compiler.scss")
      end
    end

    it "maintains consistent options across compilations" do
      compiler = Sass::Compiler.new(style: "compressed")
      css1 = compiler.compile(".a { color: red; }")
      css2 = compiler.compile(".b { color: blue; }")
      css1.should eq(".a{color:red}\n")
      css2.should eq(".b{color:blue}\n")
    end

    it "allows modifying options after creation" do
      compiler = Sass::Compiler.new(style: "compressed")
      css_compressed = compiler.compile(".a { color: red; }")
      css_compressed.should eq(".a{color:red}\n")

      compiler.style = "expanded"
      css_expanded = compiler.compile(".a { color: red; }")
      css_expanded.should contain("color: red")
      css_expanded.should_not eq(css_compressed)
    end
  end

  describe ".compile" do
    it "compiles basic SCSS" do
      css = Sass.compile(".a { color: red; }")
      css.should contain("color: red")
    end

    it "respects compressed style" do
      css = Sass.compile(".a { color: red; }", style: "compressed")
      css.should eq(".a{color:red}\n")
    end

    it "handles indented syntax (.sass)" do
      sass = ".a\n  color: blue"
      css = Sass.compile(sass, is_indented_syntax_src: true)
      css.should contain("color: blue")
    end

    it "embeds source maps" do
      css = Sass.compile(".a { color: red; }", source_map_embed: true)
      css.should contain("sourceMappingURL=data:application/json")
    end

    it "raises CompilationError with STDOUT and STDERR on failure" do
      ex = expect_raises(Sass::CompilationError) do
        Sass.compile("invalid { syntax")
      end
      message = ex.message
      message.should_not be_nil
      if message
        message.should contain("STDOUT:")
        message.should contain("STDERR:")
      end
    end
  end

  describe ".compile_file" do
    it "compiles a file from disk" do
      File.write("spec/test.scss", ".file { content: 'ok'; }")
      begin
        css = Sass.compile_file("spec/test.scss")
        css.should contain("content: \"ok\"")
      ensure
        File.delete("spec/test.scss") if File.exists?("spec/test.scss")
      end
    end
  end

  describe "load paths and include paths" do
    it "resolves imports via include_path (String)" do
      Dir.mkdir_p("spec/lib")
      File.write("spec/lib/_dep.scss", "$color: #abc;")
      begin
        css = Sass.compile("@import 'dep'; .test { color: $color; }", include_path: "spec/lib")
        css.should contain("color: #abc")
      ensure
        FileUtils.rm_rf("spec/lib")
      end
    end

    it "resolves imports via load_paths (Array)" do
      Dir.mkdir_p("spec/lib2")
      File.write("spec/lib2/_dep.scss", "$color: #def;")
      begin
        css = Sass.compile("@import 'dep'; .test { color: $color; }", load_paths: ["spec/lib2"])
        css.should contain("color: #def")
      ensure
        FileUtils.rm_rf("spec/lib2")
      end
    end
  end

  describe ".compile_directory" do
    it "compiles multiple files in a single process" do
      Dir.mkdir_p("spec/src_dir")
      Dir.mkdir_p("spec/out_dir")
      File.write("spec/src_dir/one.scss", ".one { color: #111; }")
      File.write("spec/src_dir/two.scss", ".two { color: #222; }")
      begin
        Sass.compile_directory("spec/src_dir", "spec/out_dir")
        File.read("spec/out_dir/one.css").should contain("color: #111")
        File.read("spec/out_dir/two.css").should contain("color: #222")
      ensure
        FileUtils.rm_rf("spec/src_dir")
        FileUtils.rm_rf("spec/out_dir")
      end
    end
  end
end

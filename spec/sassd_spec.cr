require "./spec_helper"

describe Sass do
  describe ".compile" do
    it "compiles a basic SCSS string" do
      scss = "$color: #00aabb; body { color: $color; }"
      css = Sass.compile(scss)
      css.should contain("color: #00aabb")
    end

    it "respects the style option" do
      scss = "body { margin: 0; }"
      compressed = Sass.compile(scss, style: "compressed")
      compressed.should contain("body{margin:0}")
    end

    it "raises CompilationError for invalid syntax" do
      expect_raises(Sass::CompilationError) do
        Sass.compile("body { color: $non-existent-var; }")
      end
    end

    it "embeds source maps when requested" do
      scss = "body { color: red; }"
      css = Sass.compile(scss, source_map: true, source_map_embed: true)
      css.should contain("sourceMappingURL=data:application/json")
    end
  end

  describe ".compile_file" do
    it "compiles a .scss file from disk" do
      path = "spec/test_file.scss"
      File.write(path, "div { p { font-size: 12px; } }")

      begin
        css = Sass.compile_file(path)
        css.should contain("div p")
        css.should contain("font-size: 12px")
      ensure
        File.delete(path) if File.exists?(path)
      end
    end
  end

  describe ".compile_directory" do
    it "compiles multiple files in a directory" do
      in_dir = "spec/fixtures/scss"
      out_dir = "spec/fixtures/css"

      FileUtils.mkdir_p(in_dir)
      FileUtils.mkdir_p(out_dir)

      File.write("#{in_dir}/a.scss", "body { background: white; }")
      File.write("#{in_dir}/b.scss", "header { display: flex; }")

      begin
        Sass.compile_directory(in_dir, out_dir)

        File.exists?("#{out_dir}/a.css").should be_true
        File.exists?("#{out_dir}/b.css").should be_true
        File.read("#{out_dir}/a.css").should contain("background: white")
      ensure
        FileUtils.rm_rf("spec/fixtures")
      end
    end
  end
end

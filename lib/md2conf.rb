require 'md2conf/version'
require 'redcarpet'

module Md2conf

  def self.parse_markdown(filename)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(), tables: true, fenced_code_blocks: true, autolink: true)
    markdown.render(File.read(filename))
  end

end

require 'md2conf/version'
require 'redcarpet'

module Md2conf
  class SubMagic
    # @param [String] html
    # @return [String]
    def code_blocks(html)
      html.scan(%r{<pre><code.*?>.*?</code></pre>}m).each do |codeblock|
        confluence_code = '<ac:structured-macro ac:name="code">'\
          '<ac:parameter ac:name="theme">Midnight</ac:parameter>'\
          '<ac:parameter ac:name="linenumbers">true</ac:parameter>'\
          '<ac:parameter ac:name="language">'
        lang            = codeblock.scan(/code class="(.*)"/)[0][0].gsub('puppet', 'ruby')
        lang            = 'none' if lang.nil?
        confluence_code = confluence_code + lang + '</ac:parameter>'
        content         = codeblock.scan(%r{<pre><code.*?>(.*?)</code></pre>}m)[0][0]
        content         = '<ac:plain-text-body><![CDATA[' + content + ']]></ac:plain-text-body>'
        confluence_code = confluence_code + content + '</ac:structured-macro>'
        confluence_code = confluence_code.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;', '"').gsub('&amp;', '&')
        html            = html.gsub(codeblock, confluence_code)
      end
      html
    end
  end

  def self.parse_markdown(filename)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new, tables: true, fenced_code_blocks: true, autolink: true)
    html     = markdown.render(File.read(filename))
    confl    = SubMagic.new
    confl.code_blocks(html)
  end
end

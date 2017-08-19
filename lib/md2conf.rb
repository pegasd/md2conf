require 'md2conf/version'
require 'redcarpet'
require 'cgi'

module Md2conf
  class ConfluenceUtil
    def initialize(html)
      @html = html
    end

    def parse(max_toc_level)
      process_mentions
      convert_info_macros
      process_code_blocks
      add_toc max_toc_level

      @html
    end

    def process_code_blocks
      @html.scan(%r{<pre><code.*?>.*?</code></pre>}m).each do |codeblock|
        content = codeblock.match(%r{<pre><code.*?>(.*?)</code></pre>}m)[1]
        lang    = codeblock.match(/code class="(.*)"/)
        lang    = if lang.nil?
          'none'
        else
          lang[1].sub('puppet', 'ruby')
        end

        confluence_code = <<~HTML
          <ac:structured-macro ac:name="code">
            <ac:parameter ac:name="theme">RDark</ac:parameter>
            <ac:parameter ac:name="linenumbers">true</ac:parameter>
            <ac:parameter ac:name="language">#{lang}</ac:parameter>
            <ac:plain-text-body><![CDATA[#{CGI.unescape_html content}]]></ac:plain-text-body>
          </ac:structured-macro>
        HTML

        @html.sub! codeblock, confluence_code
      end
    end

    def process_mentions
      clean_html = @html.gsub(%r{<code.*?>.*?</code>}m, '')
      clean_html.scan(/@(\w+)/m).each do |mention|
        mention         = mention.first
        confluence_code = "<ac:link><ri:user ri:username=\"#{mention}\"/></ac:link>"
        @html.gsub! "@#{mention}", confluence_code
      end
    end

    def convert_info_macros
      confluence_code = <<~HTML
        <ac:structured-macro ac:name="%{macro_name}">
          <ac:rich-text-body>
            %{quote}
          </ac:rich-text-body>
        </ac:structured-macro>
      HTML

      @html.scan(%r{<blockquote>(.*?)</blockquote>}m).each do |quote|
        quote = quote.first
        if quote.include? 'Note: '
          quote_new  = quote.strip.sub 'Note: ', ''
          macro_name = 'note'
        elsif quote.include? 'Warning: '
          quote_new  = quote.strip.sub 'Warning: ', ''
          macro_name = 'warning'
        else
          quote_new  = quote.strip
          macro_name = 'info'
        end
        @html.sub! %r{<blockquote>#{quote}</blockquote>}m, confluence_code % { macro_name: macro_name, quote: quote_new }
      end
    end

    def add_toc(max_toc_level)
      @html = <<~HTML
        <ac:structured-macro ac:name="toc">
          <ac:parameter ac:name="maxLevel">#{max_toc_level}</ac:parameter>
        </ac:structured-macro>
        #{@html}
      HTML
    end
  end

  def self.parse_markdown(markdown, cut_header: true, max_toc_level: 7)
    if cut_header && markdown.start_with?('# ')
      markdown = markdown.lines.drop(1).join
    end

    md         = Redcarpet::Markdown.new(Redcarpet::Render::XHTML.new, tables: true, fenced_code_blocks: true, autolink: true)
    html       = md.render(markdown)
    confluence = ConfluenceUtil.new(html)
    confluence.parse(max_toc_level)
  end
end

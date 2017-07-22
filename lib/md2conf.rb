require 'md2conf/version'
require 'redcarpet'
require 'cgi'

module Md2conf
  class SubMagic
    # @param [String] html
    # @return [String]
    def process_code_blocks(html)
      html.scan(%r{<pre><code.*?>.*?</code></pre>}m).each do |codeblock|
        content = codeblock.match(%r{<pre><code.*?>(.*?)</code></pre>}m)[1]
        lang    = codeblock.match(/code class="(.*)"/)
        if lang.nil?
          lang = 'none'
        else
          lang = lang[1].sub('puppet', 'ruby')
        end
        confluence_code = <<~HTML
          <ac:structured-macro ac:name="code">
            <ac:parameter ac:name="theme">RDark</ac:parameter>
            <ac:parameter ac:name="linenumbers">true</ac:parameter>
            <ac:parameter ac:name="language">#{lang}</ac:parameter>
            <ac:plain-text-body><![CDATA[#{CGI.unescape_html content}]]></ac:plain-text-body>
          </ac:structured-macro>
        HTML

        html = html.gsub(codeblock, confluence_code)
      end
      html
    end

    def process_mentions(html)
      html.scan(%r{@(\w+)}m).each do |mention|
        mention         = mention.first
        confluence_code = "<ac:link><ri:user ri:username=\"#{mention}\"/></ac:link>"
        html            = html.gsub("@#{mention}", confluence_code)
      end
      html
    end

    def convert_info_macros(html)
      info_tag    = '<p><ac:structured-macro ac:name="info"><ac:rich-text-body><p>'
      note_tag    = info_tag.gsub('info', 'note')
      warning_tag = info_tag.gsub('info', 'warning')
      close_tag   = '</p></ac:rich-text-body></ac:structured-macro></p>'
      html        = html.gsub('<p>~?', info_tag).gsub('?~</p>', close_tag)
      html        = html.gsub('<p>~!', note_tag).gsub('!~</p>', close_tag)
      html        = html.gsub('<p>~%', warning_tag).gsub('%~</p>', close_tag)
      html.scan(%r{<blockquote>(.*?)</blockquote>}m).each do |quote|
        quote   = quote.first
        note    = quote.match(%r{^<.*>Note}m)
        warning = quote.match(%r{^<.*>Warning}m)
        if note
          clean_tag = strip_type(quote, 'Note')
          macro_tag = clean_tag.gsub(/<p>/i, warning_tag).gsub(%r{</p>}, close_tag).strip
        elsif warning
          clean_tag = strip_type(quote, 'Warning')
          macro_tag = clean_tag.gsub(/<p>/i, warning_tag).gsub(%r{</p>}, close_tag).strip
        else
          macro_tag = quote.gsub(/<p>/i, info_tag).gsub(%r{</p>}, close_tag).strip
        end
        html = html.gsub(%r{<blockquote>#{quote}</blockquote>}i, macro_tag)
      end
      html
    end

    def strip_type(tag, type)
      tag
        .sub(/#{type}:\s/i, '')
        .sub(/#{type}:\s:\s/i, '')
        .sub(/<.*?>#{type}:\s<.*?>/i, '')
        .sub(/<.*?>#{type}\s:\s<.*?>/i, '')
        .sub(/<(em|strong)>#{type}:<.*?>\s/i, '')
        .sub(/<(em|strong)>#{type}\s:<.*?>\s/i, '')
        .sub(/<(em|strong)>#{type}<.*?>:\s/i, '')
        .sub(/<(em|strong)>#{type}\s<.*?>:\s/i, '')
    end

    def add_toc(html)
      <<~HTML
        <ac:structured-macro ac:name="toc" />
        #{html}
      HTML
    end
  end

  def self.parse_markdown(markdown)
    md    = Redcarpet::Markdown.new(Redcarpet::Render::XHTML.new, tables: true, fenced_code_blocks: true, autolink: true)
    html  = md.render(markdown)
    confl = SubMagic.new
    html  = confl.convert_info_macros(html)
    html  = confl.process_code_blocks(html)
    html  = confl.process_mentions(html)
    confl.add_toc(html)
  end
end

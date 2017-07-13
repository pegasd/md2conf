require 'md2conf/version'
require 'redcarpet'

module Md2conf
  class SubMagic
    # @param [String] html
    # @return [String]
    def process_code_blocks(html)
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

    def process_mentions(html)
      html.scan(%r{@\w+}m).each do |mention|
        confluence_code = "<ac:link><ri:user ri:username=\"#{mention}\"/></ac:link>"
        html            = html.gsub(mention, confluence_code)
      end
      html
    end

    def process_refs(html)
      html.scan(%r{\n(\[\^(\d)\].*)|<p>(\[\^(\d)\].*)}m).each do |ref|
        if ref[0]
          full_ref = ref[0].gsub('</p>', '').gsub('<p>', '')
          ref_id   = ref[1]
        else
          full_ref = ref[2]
          ref_id   = ref[3]
        end
        full_ref = full_ref.gsub('</p>', '').gsub('<p>', '')
        html.gsub(full_ref, '')
        href        = full_ref.scan(%r{href="(.*?)"}m)[0][0]
        superscript = "<a id=\"test\" href=\"#{href}\"><sup>#{ref_id}</sup></a>"
        html        = html.gsub(/[^#{ref_id}]/, superscript)
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
        note    = quote.scan(%r{^<.*>Note}m)[0][0]
        warning = quote.scan(%r{^<.*>Warning}m)[0][0]
        if note
          clean_tag = strip_type(quote, 'Note')
          macro_tag = clean_tag.gsub('<p>', warning_tag).gsub('</p>', close_tag).strip
        elsif warning
          clean_tag = strip_type(quote, 'Warning')
          macro_tag = clean_tag.gsub('<p>', warning_tag).gsub('</p>', close_tag).strip
        else
          macro_tag = quote.gsub('<p>', info_tag).gsub('</p>', close_tag).strip
        end
        html = html.gsub("<blockquote>#{quote}</blockquote>", macro_tag)
      end
      html
    end

    def strip_type(tag, type)
      tag = tag.strip.sub(/#{type}:\s/i, '')
      tag = tag.strip.sub(/#{type}:\s:\s/i, '')
      tag = tag.strip.sub(/<.*?>#{type}:\s<.*?>/i, '')
      tag = tag.strip.sub(/<.*?>#{type}\s:\s<.*?>/i, '')
      tag = tag.strip.sub(/<(em|strong)>#{type}:<.*?>\s/i, '')
      tag = tag.strip.sub(/<(em|strong)>#{type}\s:<.*?>\s/i, '')
      tag = tag.strip.sub(/<(em|strong)>#{type}<.*?>:\s/i, '')
      tag = tag.strip.sub(/<(em|strong)>#{type}\s<.*?>:\s/i, '')
      tag.upcase
    end

    def add_toc(html)
      contents_markup = '<ac:structured-macro ac:name="toc">'\
'<ac:parameter ac:name="printable">true</ac:parameter>'\
'<ac:parameter ac:name="style">disc</ac:parameter>'\
'<ac:parameter ac:name="maxLevel">2</ac:parameter>'\
'<ac:parameter ac:name="minLevel">1</ac:parameter>'\
'<ac:parameter ac:name="class">rm-contents</ac:parameter>'\
'<ac:parameter ac:name="exclude"></ac:parameter>'\
'<ac:parameter ac:name="type">list</ac:parameter>'\
'<ac:parameter ac:name="outline">false</ac:parameter>'\
'<ac:parameter ac:name="include"></ac:parameter>'\
'</ac:structured-macro>'
      "#{contents_markup}\n#{html}"
    end
  end

  def self.parse_markdown(filename)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new, tables: true, fenced_code_blocks: true, autolink: true)
    html     = markdown.render(File.read(filename))
    confl    = SubMagic.new
    html     = confl.convert_info_macros(html)
    html     = confl.process_code_blocks(html)
    html     = confl.process_mentions(html)
    html     = confl.process_refs(html)
    confl.add_toc(html)
  end
end

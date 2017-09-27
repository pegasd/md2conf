require 'md2conf/version'
require 'redcarpet'
require 'cgi'
require 'yaml'

# Processes markdown and converts it to Confluence Storage Format.
#
# The main workload is done by redcarpet gem, which generates an almost ready-to-use
# XHTML output. But there's some more magic performed by ConfluenceUtil class afterwards.
module Md2conf
  # ConfluenceUtil class contains various helpers for processing XHTML generated by redcarpet gem.
  class ConfluenceUtil
    # @param [String] html XHTML rendered by redcarpet gem (must have fenced code blocks).
    # @param [Integer] max_toc_level Table of Contents maximum header depth.
    def initialize(html, max_toc_level, config_file)
      @html          = html
      @max_toc_level = max_toc_level
      return unless File.file?(File.expand_path(config_file))
      @config = YAML.load_file(File.expand_path(config_file))
      return unless @config.key? 'macros'
      @macros = @config['macros']
    end

    # Launch all internal parsers.
    def parse
      process_macros if @macros
      process_mentions
      convert_info_macros
      process_code_blocks
      add_toc

      @html
    end

    # Process custom macros. Macro definitions should be placed in `~/.md2conf.yaml`.
    # Format is described in the README.
    #
    # Macros are blocks that are contained in curly braces like this: `{JIRA:52837}`.
    def process_macros
      html_new      = ''
      last_position = 0
      @html.scan(/{(.*?)}/) do |macro|
        next if inside_code_block Regexp.last_match.pre_match
        macro_name = macro.first.split(':')[0]
        macro_arg  = macro.first.split(':')[1]

        confluence_code = if @macros.include? macro_name
          @macros[macro_name] % { arg: macro_arg }
        else
          "<code>#{macro.first}</code>"
        end

        since_last_match = @html[last_position..Regexp.last_match.begin(0) - 1]
        html_new << "#{since_last_match}#{confluence_code}"
        last_position = Regexp.last_match.end(0)
      end

      # Did we have at least one match?
      return unless Regexp.last_match
      @html = html_new << if inside_code_block Regexp.last_match.pre_match
        @html[last_position..-1]
      else
        Regexp.last_match.post_match
      end
    end

    # Process username mentions.
    #
    # Everything that starts with an `@` and is not enclosed in a code block will be converted
    # to a valid Confluence username.
    def process_mentions
      html_new      = ''
      last_position = 0
      @html.scan(/@(\w+)/) do |mention|
        next if inside_code_block Regexp.last_match.pre_match

        confluence_code  = "<ac:link><ri:user ri:username=\"#{mention.first}\"/></ac:link>"
        since_last_match = @html[last_position..Regexp.last_match.begin(0) - 1]
        html_new << "#{since_last_match}#{confluence_code}"
        last_position = Regexp.last_match.end(1)
      end

      # Did we have at least one match?
      return unless Regexp.last_match
      @html = html_new << if inside_code_block Regexp.last_match.pre_match
        @html[last_position..-1]
      else
        Regexp.last_match.post_match
      end
    end

    # Convert Info macros to Confluence-friendly format:
    #
    # @example Regular informational message
    #   > My info message
    #
    # @example A Note (`Note: ` will be removed from the message)
    #   > Note: An important note
    #
    # @example A Warning (`Warning: ` will be removed from the message)
    #   > Warning: An extremely important warning
    def convert_info_macros
      confluence_code = <<~HTML
        <ac:structured-macro ac:name="%<macro_name>s">
          <ac:rich-text-body>
            %<quote>s
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
        @html.sub! "<blockquote>#{quote}</blockquote>", format(confluence_code, macro_name: macro_name, quote: quote_new)
      end
    end

    # Convert regular code blocks to Confluence code blocks.
    # Language type is also supported.
    #
    # `puppet` is currently replaced by `ruby` language type.
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

    # Add Table of Contents Confluence tag at the beginning.
    #
    # Use @max_toc_level class variable to specify maximum header depth.
    def add_toc
      return if @max_toc_level == 0
      @html = <<~HTML
        <ac:structured-macro ac:name="toc">
          <ac:parameter ac:name="maxLevel">#{@max_toc_level}</ac:parameter>
        </ac:structured-macro>
        #{@html}
      HTML
    end

    private

    # Check whether we're inside a code block based on pre_match variable.
    def inside_code_block(pre_match)
      # *
      return false unless pre_match.include? '<code'

      # <code> *
      return true unless pre_match.include? '</code>'

      # <code></code> *
      # <code></code><code> *
      pre_match.rindex('<code') > pre_match.rindex('</code>')
    end
  end

  # @example Just read a Markdown file and parse it
  #   Md2conf.parse_markdown File.read './README.md'
  #
  # @param [String] markdown Markdown contents to convert to Confluence format.
  # @param [Boolean] cut_header Whether to cut off initial header (must start with `/^# /`).
  # @param [Integer] max_toc_level Table of Contents maximum header depth.
  #
  # @return [String] Confluence Storage Format document.
  def self.parse_markdown(markdown, cut_header: true, max_toc_level: 7, config_file: '~/.md2conf.yaml')
    if cut_header && markdown.start_with?('# ')
      markdown = markdown.lines.drop(1).join
    end

    md         = Redcarpet::Markdown.new(Redcarpet::Render::XHTML.new, tables: true, fenced_code_blocks: true, autolink: true)
    html       = md.render(markdown)
    confluence = ConfluenceUtil.new(html, max_toc_level, config_file)
    confluence.parse
  end
end

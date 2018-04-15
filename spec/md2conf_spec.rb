require 'spec_helper'

RSpec.describe Md2conf do
  it 'has a version number' do
    expect(Md2conf::VERSION).not_to be nil
  end

  it 'cuts the header properly' do
    expect(Md2conf.parse_markdown("# hello\n## there"))
      .not_to match(/hello/)
  end

  it 'works without cutting the header' do
    expect(Md2conf.parse_markdown('# hello', cut_header: false))
      .to match(%r{^<h1>hello</h1>$})
  end

  it 'sets custom maxLevel in ToC' do
    expect(Md2conf.parse_markdown('# hello', max_toc_level: 2))
      .to match(%r{^\s*<ac:parameter ac:name="maxLevel">2</ac:parameter>$})
  end

  it 'only processes usernames outside of code blocks' do
    md = <<~MARKDOWN
      # users

      @user

      `@dontparseme`

      ```
      @meneither

      # I'll stay unparsed even though there's a @user outside
      @user
      ```
    MARKDOWN
    md_parsed = Md2conf.parse_markdown(md)

    expect(md_parsed).to match(/ri:username="user"/)
    expect(md_parsed).to match(%r{^<p><code>@dontparseme</code></p>$})
    expect(md_parsed).to match(/@meneither/)
    expect(md_parsed).to match(/^@user$/)
  end

  it 'converts macros with arguments' do
    md = '{RT:12345}'
    expect(
      Md2conf.parse_markdown(md, config_file: 'spec/fixtures/config.yaml')
    ).to match(
      %r{https://mycompany\.org/rt/Display\.html\?id=12345}
    )
  end

  it 'converts macros without arguments' do
    md = '{HEY}'
    expect(
      Md2conf.parse_markdown(md, config_file: 'spec/fixtures/config.yaml')
    ).to match(
      /hello/
    )
  end

  it 'supports markdown strikethrough' do
    md = '~~woot~~'
    expect(
      Md2conf.parse_markdown(md, config_file: 'spec/fixtures/config.yaml')
    ).to match(%r{<del>woot</del>})
  end
end

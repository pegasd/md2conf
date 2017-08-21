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
    expect(md_parsed).to match(%r{@meneither})
    expect(md_parsed).to match(%r{^@user$})
  end
end

require 'spec_helper'

RSpec.describe Md2conf do
  it 'has a version number' do
    expect(Md2conf::VERSION).not_to be nil
  end

  it 'cuts the header properly' do
    expect(Md2conf.parse_markdown("# hello\n## there"))
      .not_to match(/hello/)
  end

  it 'works without ' do
    expect(Md2conf.parse_markdown('# hello', cut_header: false))
      .to match(%r{^<h1>hello</h1>$})
  end
end

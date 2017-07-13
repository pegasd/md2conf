require 'spec_helper'

RSpec.describe Md2conf do
  it 'has a version number' do
    expect(Md2conf::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(Md2conf.parse_markdown(<<~MARKDOWN
      # hello
    MARKDOWN
    )).to match(%r{^<h1>hello</h1>$})
  end
end

# Md2conf

Confverts Markdown to Confluence storage format

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'md2conf'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install md2conf
```

## Usage

```ruby
require 'md2conf'

conf_xhtml = Md2conf.parse_markdown(File.read('./README.md'))
```

Contents of `conf_xhtml` is now ready to be pushed to Confluence.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pegasd/md2conf.

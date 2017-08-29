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

### Basic usage

```ruby
require 'md2conf'

conf_xhtml = Md2conf.parse_markdown(File.read('./README.md'))
```

Contents of `conf_xhtml` is now ready to be pushed to Confluence.

### Custom macros

It is possible to set up custom macros to be processed inside your Markdown files.

Macros must be specified in the format `{MACRO_NAME:MACRO_ARG}` and reside outside of code blocks.

Macro definition are read from the file `~/.md2conf.yaml` inside a `macros` key:

```yaml
macros:
  PUP: <a href="https://tickets.puppetlabs.com/browse/PUP-%<arg>s"><img src="https://img.shields.io/badge/PUP-%<arg>s-blue.svg" /></a>
  PUPTEXT: <a href="https://tickets.puppetlabs.com/browse/PUP-%<arg>s">PUP-%<arg>s</a>
```

Having these definitions, the following macros:

```markdown
{PUP:7123} Fixed a bug

{PUPTEXT:7885} Work in progress
```

will be converted to this:

```html
<a href="https://tickets.puppetlabs.com/browse/PUP-7123"><img src="https://img.shields.io/badge/PUP-7123-blue.svg" /></a> Fixed a bug

<a href="https://tickets.puppetlabs.com/browse/PUP-7885">PUP-7885</a> Work in progress
```

Note the usage of `%<arg>s` - these will be replaced by the `MACRO_ARG` part that is specified inside each macro.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports, feature and pull requests are welcome at the official GitHub [repo](https://github.com/pegasd/md2conf).

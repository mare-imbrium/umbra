# Umbra

Stripped version of canis gem (ncurses ruby). Create ncurses applications using a simple small library.
The source is small and simple, so easy to hack if need be. 

 - Minimal functionality
 - Very close to ncurses, should not try to wrap everything
 - load only what you need
 - not necessarily object oriented, that is not a goal
 - should be able to use a file or widget from here without having to copy too much
 - should be able to understand one file without having to understand entire library
 - should be easy for others to change as per their needs, or copy parts.
 - 

## Gem name
  `umbra` was taken, so had to change the gem name to `ncumbra` but the packages and structure etc remain umbra.

## Motivation for yet another ncurses library

 rbcurse and canis are very large. Too many dependencies on other parts of system. This aims to be small and minimal, 
 keeping parts as independent as possible. 

## Future versions
 - Ampersand in Label and Button to signify shortcut/mnemonic.
 - table
 - combo list
 - 256 colors
 - tree (maybe)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'umbra'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install umbra

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mare-imbrium/umbra.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

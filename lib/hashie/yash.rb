require 'yaml'
require 'erb'
require 'hashie/mash'

module Hashie
  # Yash allows you to transform files into Mash objects
  # This is useful for instance when you'll have to load config files.
  #
  # == Example ( the good part)
  #
  #   if you have a config file like the following:
  #   #/etc/config/settings/database.yml
  #   development:
  #     host: 'localhost'
  #     port: 1234
  #   production:
  #     host: <%= ENV['HOST'] %> #let's say that ENV['host'] is set to '1.2.3.4'
  #     port: <%= ENV['PORT'] %>
  #
  #   .file_to_mash will transform a file into Mash:
  #   config = Yash.file_to_mash('settings/database.yml')
  #   config.development.host # => 'localhost'
  #
  #
  #   .load will do the same as file_to_mash and:
  #     - freeze keys so that it'll be readable only
  #     - add some magic for pretty inspect the hash
  #   config = Yash.load('settings/database.yml')
  #   config.development.host # => 'localhost'
  #   config.development.host = "foo" # => <# RuntimeError can't modify frozen ...>
  #
  #   .[] will cache the results of load(file) into memory
  #   config = Yash['settings/database.yml']
  #   config2 = Yash['settings/database.yml']
  #   config.object_id == config2.object_id
  #   config.development.host # => 'localhost'
  #
  #
  #   Cool stuffs:
  #
  #   - You can extend a Yash to mimic the settings behaviour to another class
  #   This will define a `settings` method for easier global access in your code to specific configs:
  #   #/etc/config/settings/twitter.yml
  #   production:
  #     api_key: <%= ENV['twitter_api_key'] %> #let's say that ENV['twitter_api_key'] is set to 'twitter_foo'
  #   #/etc/config/settings/facebook.yml
  #   production:
  #     api_key: <%= ENV['facebook_api_key'] %> #let's say that ENV['facebook_api_key'] is set to 'facebook_foo'
  #
  #   Twitter.extend Yash.new('settings/twitter.yml')
  #   Facebook.extend Yash.new('settings/facebook.yml')
  #   Twitter.settings[ENV['RACK_ENV']].api_key # => 'twitter_foo'
  #   Facebook.settings.production.api_key # =>'facebook_foo'
  #
  #   If you dont like `settings`, you can overwrite it:
  #   Twitter.extend Yash.new('settings/twitter.yml', settings_method_name: 'config')
  #   Twitter.config.api_key # => 'twitter_foo'
  #
  class Yash < Module
    attr_reader :settings_method_name

    class<<self
      attr_reader :_mashes
    end

    def initialize(filename, options = {})
      @settings_method_name  = options.fetch(:settings_method_name) { 'settings' }
      @filename = filename
    end

    def self.[](filename)
      @_mashes ||= Hash.new { |h, key| h[key] = load(key) }

      @_mashes[filename]
    end

    def self.load(path, parser = Extensions::Yash::YamlErbParser)
      fail ArgumentError, "The following file doesn't exist: #{path}" unless File.file?(path)
      hash = parser.perform(path)
      Hashie::Mash.new(hash).freeze
    end

    def extended(klass)
      yash = self
      klass.send :define_singleton_method, settings_method_name.to_sym do
        Yash[yash.instance_variable_get('@filename')]
      end
    end
  end
end

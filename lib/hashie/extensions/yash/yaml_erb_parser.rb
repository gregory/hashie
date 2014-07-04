module Hashie
  module Extensions
    module Yash
      class YamlErbParser
        def initialize(file_path)
          @content = File.read(file_path)
        end

        def perform
          YAML.load ERB.new(@content).result
        end

        def self.perform(file_path)
          new(file_path).perform
        end
      end
    end
  end
end

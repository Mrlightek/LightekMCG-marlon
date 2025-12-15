# lib/marlon/docs/playground_generator.rb
require "json"

module Marlon
  module Docs
    class PlaygroundGenerator
      def self.generate(docs)
        collection = {
          info: {
            name: "Marlon API Playground",
            schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
          },
          item: docs.map { |doc| build_item(doc) }
        }

        path = File.join(Dir.pwd, "docs", "api_playground.json")
        File.write(path, JSON.pretty_generate(collection))
      end

      def self.build_item(doc)
        {
          name: "#{doc[:type]}: #{doc[:name]}",
          request: {
            method: "POST",
            header: [
              { key: "Content-Type", value: "application/json" },
              { key: "X-MARLON-TOKEN", value: "change_me" }
            ],
            body: {
              mode: "raw",
              raw: JSON.pretty_generate({
                service: doc[:type] == "service" ? doc[:name] : nil,
                command: doc[:type] == "command" ? doc[:name] : nil,
                args: doc[:params].map { |p| [p[:name], ""] }.to_h
              })
            },
            url: { raw: "http://localhost:3000/" }
          }
        }
      end
    end
  end
end

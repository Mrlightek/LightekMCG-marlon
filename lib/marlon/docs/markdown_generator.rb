# lib/marlon/docs/markdown_generator.rb
module Marlon
  module Docs
    class MarkdownGenerator
      def self.generate(docs)
        docs.each do |doc|
          file_name = "#{doc[:type]}_#{doc[:name]}.md"
          path = File.join(Dir.pwd, "docs", file_name)

          content = render_markdown(doc)
          File.write(path, content)
        end
      end

      def self.render_markdown(doc)
        <<~MD
        # #{doc[:type].capitalize}: #{doc[:name]}

        **File:** `#{doc[:path]}`

        #{doc[:description]}

        ## Parameters
        #{render_params(doc[:params])}

        ## Returns
        #{render_returns(doc[:returns])}

        ## Examples
        #{render_examples(doc[:examples])}
        MD
      end

      def self.render_params(params)
        return "_None_" if params.empty?
        params.map { |p| "- **#{p[:name]}** (#{p[:types].join(', ')}): #{p[:text]}" }.join("\n")
      end

      def self.render_returns(ret)
        return "_None_" unless ret
        "#{ret[:types].join(', ')} — #{ret[:text]}"
      end

      def self.render_examples(ex)
        return "_None_" if ex.empty?
        ex.map { |e| "```ruby\n#{e}\n```" }.join("\n\n")
      end
    end
  end
end

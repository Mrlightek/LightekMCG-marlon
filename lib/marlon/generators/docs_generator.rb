# lib/marlon/generators/docs_generator.rb
require "fileutils"
require "json"
require "erb"

module Marlon
  module Generators
    class DocsGenerator
      OUTPUT_DIR = File.join(Dir.pwd, "public", "docs")
      PLAYGROUND_DIR = File.join(OUTPUT_DIR, "playground")

      def initialize(opts = {})
        @opts = opts
        @gatekeeper_token = (Marlon.config.dig("gatekeeper", "token") rescue nil) || "<PASTE_GATEKEEPER_TOKEN>"
      end

      def generate
        prepare_output
        load_project_files
        collect_items
        build_markdown_docs
        build_json_index
        build_postman_collection
        build_html_site
        build_docs_service_stub
        puts "✅ Docs generated at #{OUTPUT_DIR}"
      end

      private

      def prepare_output
        FileUtils.rm_rf(OUTPUT_DIR) if Dir.exist?(OUTPUT_DIR)
        FileUtils.mkdir_p(OUTPUT_DIR)
        FileUtils.mkdir_p(File.join(OUTPUT_DIR, "services"))
        FileUtils.mkdir_p(File.join(OUTPUT_DIR, "commands"))
        FileUtils.mkdir_p(File.join(OUTPUT_DIR, "generators"))
        FileUtils.mkdir_p(PLAYGROUND_DIR)
      end

      # Attempt to require service & module files so constants exist for introspection.
      def load_project_files
        # load top-level service files
        Dir[File.join(Dir.pwd, "lib", "marlon", "services", "**", "*.rb")].each { |f| safe_require(f) }
        # load module services
        Dir[File.join(Dir.pwd, "lib", "marlon", "modules", "**", "services", "**", "*.rb")].each { |f| safe_require(f) }
        # load CLI commands
        Dir[File.join(Dir.pwd, "lib", "marlon", "cli", "commands", "**", "*.rb")].each { |f| safe_require(f) }
        # load generators
        Dir[File.join(Dir.pwd, "lib", "marlon", "generators", "**", "*.rb")].each { |f| safe_require(f) }
      end

      def safe_require(path)
        require path.sub("#{Dir.pwd}/", "") rescue begin
          load path rescue nil
        end
      end

      # Collect services, their actions and commands/generators
      def collect_items
        @services = collect_services
        @commands = collect_commands
        @generators = collect_generators
      end

      def collect_services
        services = []

        # Top-level Marlon::Services
        if defined?(Marlon::Services)
          Marlon::Services.constants.each do |c|
            klass = Marlon::Services.const_get(c) rescue nil
            next unless klass.is_a?(Class)
            methods = instance_public_methods(klass)
            services << service_entry("Marlon::Services::#{c}", klass, methods)
          end
        end

        # Module services (Marlon::Modules::<Module>::...::Service)
        if defined?(Marlon::Modules)
          Marlon::Modules.constants.each do |mod|
            modconst = Marlon::Modules.const_get(mod) rescue nil
            next unless modconst.is_a?(Module)
            modconst.constants.each do |inner|
              candidate = modconst.const_get(inner) rescue nil
              # if it's a module namespace that contains classes:
              if candidate.is_a?(Module)
                candidate.constants.each do |c|
                  klass = candidate.const_get(c) rescue nil
                  next unless klass.is_a?(Class)
                  methods = instance_public_methods(klass)
                  name = "Marlon::Modules::#{mod}::#{c}"
                  services << service_entry(name, klass, methods)
                end
              elsif candidate.is_a?(Class)
                # direct class
                klass = candidate
                methods = instance_public_methods(klass)
                name = "Marlon::Modules::#{mod}::#{inner}"
                services << service_entry(name, klass, methods)
              end
            end
          end
        end

        services
      end

      def collect_commands
        commands = []
        if defined?(Marlon::CLI::Commands)
          Marlon::CLI::Commands.constants.each do |c|
            klass = Marlon::CLI::Commands.const_get(c) rescue nil
            next unless klass
            commands << { name: c.to_s, doc: extract_docstring(klass) }
          end
        end
        commands
      end

      def collect_generators
        gens = []
        if defined?(Marlon::Generators)
          Marlon::Generators.constants.each do |c|
            klass = Marlon::Generators.const_get(c) rescue nil
            next unless klass.is_a?(Class)
            gens << { name: c.to_s, doc: extract_docstring(klass) }
          end
        end
        gens
      end

      # collect public instance methods (excluding inherited ones)
      def instance_public_methods(klass)
        klass.instance_methods(false).map do |m|
          mobj = klass.instance_method(m)
          {
            name: m.to_s,
            params: format_parameters(mobj.parameters),
            doc: extract_method_comment(klass, m)
          }
        end
      end

      def format_parameters(params)
        params.map do |ptype, pname|
          case ptype
          when :req then "#{pname}"
          when :opt then "#{pname} (optional)"
          when :rest then "*#{pname}"
          when :keyreq then "#{pname}:"
          when :key then "#{pname}: (optional)"
          when :keyrest then "**#{pname}"
          when :block then "&#{pname}"
          else "#{ptype}:#{pname}"
          end
        end
      end

      # Attempt to extract rudimentary docstrings from class source if available.
      def extract_docstring(klass)
        if klass.respond_to?(:name)
          file = source_file_for_constant(klass) rescue nil
          return "" unless file && File.exist?(file)
          lines = File.read(file).lines
          # naive: read first block comment at top of class def
          idx = lines.index { |l| l =~ /\bclass\b.*\b#{klass.name.split("::").last}\b/ } || 0
          snippet = lines[[0, idx-10].max..idx+2].join
          snippet.strip
        else
          ""
        end
      rescue
        ""
      end

      def extract_method_comment(klass, method_name)
        file = source_file_for_constant(klass) rescue nil
        return "" unless file && File.exist?(file)
        lines = File.read(file).lines
        method_line = lines.index { |l| l =~ /\bdef\s+#{method_name}\b/ }
        return "" unless method_line
        # collect comments immediately preceding method line
        i = method_line - 1
        comments = []
        while i >= 0 && lines[i] =~ /^\s*#/
          comments.unshift(lines[i].sub(/^\s*#\s?/, "").strip)
          i -= 1
        end
        comments.join(" ")
      rescue
        ""
      end

      # Find source file that defines the constant by scanning likely files
      def source_file_for_constant(klass)
        short = klass.name.split("::").last
        patterns = [
          File.join(Dir.pwd, "lib", "marlon", "**", "#{underscore(short)}.rb"),
          File.join(Dir.pwd, "lib", "marlon", "**", "#{short.downcase}.rb")
        ]
        patterns.each do |pat|
          found = Dir[pat].first
          return found if found
        end
        nil
      end

      def underscore(str)
        str.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end

      # ---------------------
      # BUILD DOCS
      # ---------------------
      def build_markdown_docs
        index = { services: [], commands: [], generators: [] }

        @services.each do |s|
          id = s[:name].gsub("::", "_")
          path = File.join(OUTPUT_DIR, "services", "#{id}.md")
          File.write(path, render_markdown_service(s))
          index[:services] << { id: id, name: s[:name], file: "services/#{id}.md" }
        end

        @commands.each do |c|
          id = "cmd_#{c[:name].downcase}"
          path = File.join(OUTPUT_DIR, "commands", "#{id}.md")
          File.write(path, render_markdown_command(c))
          index[:commands] << { id: id, name: c[:name], file: "commands/#{id}.md" }
        end

        @generators.each do |g|
          id = "gen_#{g[:name].downcase}"
          path = File.join(OUTPUT_DIR, "generators", "#{id}.md")
          File.write(path, render_markdown_generator(g))
          index[:generators] << { id: id, name: g[:name], file: "generators/#{id}.md" }
        end

        # Top-level index
        File.write(File.join(OUTPUT_DIR, "index.md"), render_markdown_index(index))
      end

      def render_markdown_service(s)
        <<~MD
        # #{s[:name]}

        #{s[:doc]}

        ## Actions

        #{s[:methods].map { |m|
          <<~ACTION
          ### #{m[:name]}

          #{m[:doc].to_s}

          **Parameters:** #{m[:params].join(", ")}

          **Examples**

          **curl**
          ```bash
          curl -X POST http://127.0.0.1:3000/marlon/gatekeeper \\
            -H "Content-Type: application/json" \\
            -H "X-Marlon-Token: #{@gatekeeper_token}" \\
            -d '{
              "service": "#{extract_service_short_name(s[:name])}",
              "action": "#{m[:name]}",
              "payload": {}
            }'
          ```

          **Ruby**
          ```ruby
          payload = {
            service: "#{extract_service_short_name(s[:name])}",
            action: "#{m[:name]}",
            payload: {}
          }
          res = Net::HTTP.post(URI("http://127.0.0.1:3000/marlon/gatekeeper"), payload.to_json, "Content-Type" => "application/json", "X-Marlon-Token" => "#{@gatekeeper_token}")
          puts res.body
          ```

          **JavaScript (fetch)**
          ```js
          fetch("/marlon/gatekeeper", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "X-Marlon-Token": "#{@gatekeeper_token}"
            },
            body: JSON.stringify({
              service: "#{extract_service_short_name(s[:name])}",
              action: "#{m[:name]}",
              payload: {}
            })
          }).then(r => r.json()).then(console.log)
          ```
          ACTION
        }.join("\n\n")}

        MD
      end

      def extract_service_short_name(full_name)
        # Examples:
        # "Marlon::Services::UserCreator" -> "UserCreator"
        # "Marlon::Modules::Cloud::Main" -> "Cloud::Main" (we'll let payloads use "Cloud::Main")
        parts = full_name.split("::")
        if parts[1] == "Services"
          parts.last
        else
          parts[2..-1].join("::")
        end
      end

      def render_markdown_command(c)
        <<~MD
        # Command #{c[:name]}

        #{c[:doc].to_s}

        Usage:

        ```
        marlon #{c[:name].downcase}
        ```
        MD
      end

      def render_markdown_generator(g)
        <<~MD
        # Generator #{g[:name]}

        #{g[:doc].to_s}

        Usage:

        ```
        marlon g #{g[:name].downcase}
        ```
        MD
      end

      def render_markdown_index(index)
        <<~MD
        # Marlon Documentation Index

        ## Services
        #{index[:services].map { |s| "- [#{s[:name]}](#{s[:file]})" }.join("\n")}

        ## Commands
        #{index[:commands].map { |c| "- [#{c[:name]}](#{c[:file]})" }.join("\n")}

        ## Generators
        #{index[:generators].map { |g| "- [#{g[:name]}](#{g[:file]})" }.join("\n")}
        MD
      end

      # ---------------------
      # JSON Index
      # ---------------------
      def build_json_index
        out = {
          marlon_version: Marlon::VERSION,
          generated_at: Time.now.utc.iso8601,
          services: @services,
          commands: @commands,
          generators: @generators
        }
        File.write(File.join(OUTPUT_DIR, "index.json"), JSON.pretty_generate(out))
      end

      # ---------------------
      # Postman collection (very basic)
      # ---------------------
      def build_postman_collection
        collection = {
          info: {
            name: "Marlon API Collection",
            schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
          },
          item: []
        }

        @services.each do |s|
          s[:methods].each do |m|
            body = {
              service: extract_service_short_name(s[:name]),
              action: m[:name],
              payload: {}
            }
            collection[:item] << {
              name: "#{extract_service_short_name(s[:name])}.#{m[:name]}",
              request: {
                method: "POST",
                header: [
                  { key: "Content-Type", value: "application/json" },
                  { key: "X-Marlon-Token", value: @gatekeeper_token }
                ],
                body: {
                  mode: "raw",
                  raw: JSON.pretty_generate(body)
                },
                url: { raw: "http://127.0.0.1:3000/marlon/gatekeeper", protocol: "http", host: ["127.0.0.1"], port: "3000", path: ["marlon","gatekeeper"] }
              }
            }
          end
        end

        File.write(File.join(PLAYGROUND_DIR, "marlon_postman_collection.json"), JSON.pretty_generate(collection))
      end

      # ---------------------
      # HTML site & interactive tester
      # ---------------------
      def build_html_site
        tpl = html_template
        File.write(File.join(OUTPUT_DIR, "index.html"), tpl)
        # simple service pages redirect to index.html anchors (the index lists everything)
      end

      def html_template
        services_html = @services.map do |s|
          <<~HTML
          <section class="service">
            <h2>#{s[:name]}</h2>
            <p>#{ERB::Util.html_escape(s[:doc].to_s)}</p>
            <ul>
              #{s[:methods].map { |m|
                <<~M
                <li>
                  <h3 id="#{anchor_for(s[:name], m[:name])}">#{m[:name]}</h3>
                  <p>#{ERB::Util.html_escape(m[:doc].to_s)}</p>
                  <p><strong>Params:</strong> #{ERB::Util.html_escape(m[:params].join(", "))}</p>
                  <pre><code>curl -X POST /marlon/gatekeeper -H "Content-Type: application/json" -H "X-Marlon-Token: #{@gatekeeper_token}" -d '{"service":"#{extract_service_short_name(s[:name])}","action":"#{m[:name]}","payload":{}}'</code></pre>

                  <div class="tester">
                    <label>Payload JSON</label>
                    <textarea data-service="#{extract_service_short_name(s[:name])}" data-action="#{m[:name]}" rows="5" cols="60">{}</textarea><br/>
                    <button class="run-btn" data-service="#{extract_service_short_name(s[:name])}" data-action="#{m[:name]}">Run</button>
                    <pre class="result" id="result_#{anchor_for(s[:name], m[:name])}"></pre>
                  </div>
                </li>
                M
              }.join("\n")}
            </ul>
          </section>
          HTML
        end.join("\n")

        <<~HTML
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>Marlon Docs</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial; padding: 24px; }
            pre { background:#f7f7f7; padding:12px; border-radius:6px; overflow:auto }
            textarea { width:100%; font-family: monospace; }
            .tester { margin-top:8px; }
            .service { border-bottom:1px solid #eee; padding-bottom:16px; margin-bottom:16px; }
            .run-btn { margin-top:8px; padding:8px 12px; }
          </style>
        </head>
        <body>
          <h1>Marlon Docs</h1>
          <p>Interactive docs + playground. Paste your Gatekeeper token below or keep the placeholder.</p>
          <label>Gatekeeper Token: <input id="token" value="#{@gatekeeper_token}" style="width:400px"/></label>
          #{services_html}
          <hr/>
          <h3>Postman Collection</h3>
          <p>Download the collection and import to Postman/Insomnia:</p>
          <a href="/docs/playground/marlon_postman_collection.json" download>Download Postman Collection</a>

          <script>
            async function run(service, action, body, token, resultEl) {
              try {
                const res = await fetch('/marlon/gatekeeper', {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json',
                    'X-Marlon-Token': token
                  },
                  body: JSON.stringify({ service: service, action: action, payload: JSON.parse(body) })
                });
                const text = await res.text();
                document.getElementById(resultEl).textContent = text;
              } catch (err) {
                document.getElementById(resultEl).textContent = 'ERROR: ' + err.message;
              }
            }

            document.addEventListener('click', function(e){
              if(e.target && e.target.classList.contains('run-btn')){
                const service = e.target.dataset.service;
                const action = e.target.dataset.action;
                const textArea = e.target.previousElementSibling;
                const body = textArea.value;
                const token = document.getElementById('token').value;
                const resultEl = 'result_' + service.replace(/[^a-z0-9]/gi,'_') + '_' + action;
                run(service, action, body, token, resultEl);
              }
            });

            // assign ids for results
            document.querySelectorAll('.service h3').forEach(function(h){
              const id = h.id;
              const resEl = document.getElementById('result_' + id);
              if(!resEl){
                const pre = document.createElement('pre');
                pre.id = 'result_' + id;
                h.parentNode.appendChild(pre);
              }
            });
          </script>
        </body>
        </html>
        HTML
      end

      def anchor_for(service, method)
        "#{service.gsub("::","_")}_#{method}"
      end

      # ---------------------
      # Provide a DocsService so docs can be fetched via Gatekeeper payloads too
      # ---------------------
      def build_docs_service_stub
        svc_path = File.join(Dir.pwd, "lib", "marlon", "services", "docs_service.rb")
        File.write(svc_path, <<~RUBY)
          module Marlon
            module Services
              class DocsService
                def initialize(params = {})
                  @params = params
                end

                # call this via Gatekeeper payload: { service: "DocsService", action: "index" }
                def index
                  path = File.join(Dir.pwd, "public", "docs", "index.json")
                  if File.exist?(path)
                    JSON.parse(File.read(path))
                  else
                    { error: "docs_not_found" }
                  end
                end

                def get(service_name, action_name = nil)
                  idx = index()
                  if action_name
                    # try to locate specific action under service
                    svc = idx['services'].find { |s| s['name'] == service_name }
                    return { error: "service_not_found" } unless svc
                    acts = svc['methods'].select { |m| m['name'] == action_name }
                    return { service: svc, actions: acts }
                  else
                    svc = idx['services'].find { |s| s['name'] == service_name }
                    svc || { error: "service_not_found" }
                  end
                end
              end
            end
          end
        RUBY
      end
    end
  end
end

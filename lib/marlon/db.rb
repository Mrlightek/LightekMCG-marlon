# lib/marlon/db.rb
require "sqlite3"
require "pg"
require "json"

module Marlon
  module DB
    @connections = {}
    @adapter = nil

    class << self
      attr_reader :adapter

      def connect(name, adapter:, **opts)
        case adapter
        when :sqlite
          conn = SQLite3::Database.new(opts[:file] || "#{name}.db")
          conn.results_as_hash = true
        when :postgres
          conn = PG.connect(
            dbname: opts[:db] || "marlon",
            host: opts[:host] || "localhost",
            user: opts[:user] || ENV["USER"],
            password: opts[:password] || ""
          )
        else
          raise "Adapter #{adapter} not implemented"
        end

        @connections[name] = conn
        @adapter = adapter
      end

      def connection(name = :main)
        @connections[name] || raise("No DB connection named #{name}")
      end

      # Ensure table exists with provided columns (simple types)
      def ensure_table(table, columns)
        case @adapter
        when :sqlite
          conn = connection
          cols_sql = columns.map { |k, t| "#{k} #{sql_type_sqlite(t)}" }.join(", ")
          conn.execute("CREATE TABLE IF NOT EXISTS #{table} (#{cols_sql}, PRIMARY KEY(id))")
        when :postgres
          conn = connection
          cols_sql = columns.map { |k, t| %("#{k}" #{sql_type_postgres(t)}) }.join(", ")
          conn.exec("CREATE TABLE IF NOT EXISTS \"#{table}\" (#{cols_sql}, PRIMARY KEY(id))")
        end
      end

      def sql_type_sqlite(type)
        case type
        when :string then "TEXT"
        when :integer then "INTEGER"
        when :float then "REAL"
        when :boolean then "BOOLEAN"
        when :json then "JSON"
        else "TEXT"
        end
      end

      def sql_type_postgres(type)
        case type
        when :string then "TEXT"
        when :integer then "INTEGER"
        when :float then "REAL"
        when :boolean then "BOOLEAN"
        when :json then "JSONB"
        else "TEXT"
        end
      end

      # Upsert/save record
      def save(table, data, conn_name = :main)
        case @adapter
        when :sqlite
          conn = connection(conn_name)
          # Ensure table columns exist for keys
          cols = data.keys.map { |k| [k.to_s, :string] }.to_h
          ensure_table(table, cols)

          columns = data.keys.join(", ")
          placeholders = (["?"] * data.keys.length).join(", ")
          # Use INSERT OR REPLACE to upsert by primary key
          sql = "INSERT OR REPLACE INTO #{table} (#{columns}) VALUES (#{placeholders})"
          conn.execute(sql, data.values)
        when :postgres
          conn = connection(conn_name)
          # Ensure table exists — caller should ensure but keep simple
          columns = data.keys.map { |k| %("#{k}") }.join(", ")
          placeholders = data.keys.each_with_index.map { |_, i| "$#{i + 1}" }.join(", ")
          update_clause = data.keys.map { |k| %("#{k}" = EXCLUDED."#{k}") }.join(", ")
          sql = <<~SQL
            INSERT INTO "#{table}" (#{columns})
            VALUES (#{placeholders})
            ON CONFLICT (id) DO UPDATE SET #{update_clause}
          SQL
          conn.exec_params(sql, data.values)
        end
      end

      # Find by id
      def find(table, id, conn_name = :main)
        case @adapter
        when :sqlite
          conn = connection(conn_name)
          rows = conn.execute("SELECT * FROM #{table} WHERE id = ?", [id])
          rows.empty? ? nil : rows.first
        when :postgres
          conn = connection(conn_name)
          res = conn.exec_params("SELECT * FROM \"#{table}\" WHERE id = $1 LIMIT 1", [id])
          res.ntuples.zero? ? nil : res[0]
        end
      end

      # Simple where (AND conditions only)
      def where(table, conditions = {}, conn_name = :main)
        case @adapter
        when :sqlite
          conn = connection(conn_name)
          if conditions.empty?
            conn.execute("SELECT * FROM #{table}")
          else
            keys = conditions.keys
            clause = keys.map { |k| "#{k} = ?" }.join(" AND ")
            conn.execute("SELECT * FROM #{table} WHERE #{clause}", conditions.values)
          end
        when :postgres
          conn = connection(conn_name)
          if conditions.empty?
            res = conn.exec("SELECT * FROM \"#{table}\"")
            res.to_a
          else
            keys = conditions.keys
            clause = keys.each_with_index.map { |k, i| %("#{k}" = $#{i + 1}) }.join(" AND ")
            res = conn.exec_params("SELECT * FROM \"#{table}\" WHERE #{clause}", conditions.values)
            res.to_a
          end
        end
      end

      def update(table, id, data, conn_name = :main)
        case @adapter
        when :sqlite
          conn = connection(conn_name)
          set_clause = data.keys.map { |k| "#{k} = ?" }.join(", ")
          conn.execute("UPDATE #{table} SET #{set_clause} WHERE id = ?", data.values + [id])
        when :postgres
          conn = connection(conn_name)
          set_clause = data.keys.each_with_index.map { |k, i| %("#{k}" = $#{i + 2}) }.join(", ")
          sql = "UPDATE \"#{table}\" SET #{set_clause} WHERE id = $1"
          conn.exec_params(sql, [id] + data.values)
        end
      end

      def delete(table, id, conn_name = :main)
        case @adapter
        when :sqlite
          conn = connection(conn_name)
          conn.execute("DELETE FROM #{table} WHERE id = ?", [id])
        when :postgres
          conn = connection(conn_name)
          conn.exec_params("DELETE FROM \"#{table}\" WHERE id = $1", [id])
        end
      end
    end
  end
end

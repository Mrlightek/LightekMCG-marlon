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

      def connect(name = :main, adapter:, **opts)
        case adapter.to_sym
        when :sqlite
          conn = SQLite3::Database.new(opts[:file] || "#{name}.db")
          conn.results_as_hash = true
          @connections[name] = conn
          @adapter = :sqlite
        when :postgres, :pg
          conn = PG.connect(dbname: opts[:db] || "marlon", host: opts[:host], user: opts[:user], password: opts[:password])
          @connections[name] = conn
          @adapter = :postgres
        else
          raise "Unknown adapter #{adapter}"
        end
      end

      def connection(name = :main)
        @connections[name] || raise("No DB connection named #{name}")
      end

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
        else
          raise "No adapter connected"
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

      # Upsert/save
      def save(table, data, conn_name = :main)
        case @adapter
        when :sqlite
          conn = connection(conn_name)
          # ensure columns exist - simple, may be expanded to ALTER TABLE
          ensure_table(table, data.keys.map { |k| [k, :string] }.to_h)
          columns = data.keys.join(", ")
          placeholders = (["?"] * data.keys.length).join(", ")
          sql = "INSERT OR REPLACE INTO #{table} (#{columns}) VALUES (#{placeholders})"
          conn.execute(sql, data.values)
        when :postgres
          conn = connection(conn_name)
          columns = data.keys.map { |k| %("#{k}") }.join(", ")
          placeholders = data.keys.each_with_index.map { |_, i| "$#{i + 1}" }.join(", ")
          update_clause = data.keys.map { |k| %("#{k}" = EXCLUDED."#{k}") }.join(", ")
          sql = <<~SQL
            INSERT INTO "#{table}" (#{columns})
            VALUES (#{placeholders})
            ON CONFLICT (id) DO UPDATE SET #{update_clause}
          SQL
          conn.exec_params(sql, data.values)
        else
          raise "No adapter"
        end
      end

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
          conn.exec_params("UPDATE \"#{table}\" SET #{set_clause} WHERE id = $1", [id] + data.values)
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

# Pure Marlon migration (no Rails)
module Marlon
  module Migrate
    class CloudTables
      def self.up
        Marlon::DB.ensure_table(
          "marlon_tenants",
          id: :string,
          slug: :string,
          ip: :string,
          ovh_id: :string,
          plan: :string,
          created_at: :string,
          updated_at: :string
        )
      end

      def self.down
        # optional: drop table
        conn = Marlon::DB.connection
        conn.execute("DROP TABLE IF EXISTS marlon_tenants")
      end
    end
  end
end

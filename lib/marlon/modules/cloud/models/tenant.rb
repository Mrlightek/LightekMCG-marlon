module Marlon
  module Modules
    module Cloud
      class Tenant
        TABLE = "marlon_tenants"

        # Ensure table exists on load
        def self.ensure_table!
          Marlon::DB.ensure_table(
            TABLE,
            id: :string,
            slug: :string,
            ip: :string,
            ovh_id: :string,
            plan: :string,
            created_at: :string,
            updated_at: :string
          )
        end

        def self.create(attrs)
          id = SecureRandom.uuid
          now = Time.now.utc.iso8601
          data = attrs.merge(
            id: id,
            created_at: now,
            updated_at: now
          )
          Marlon::DB.save(TABLE, data)
          data
        end

        def self.find(id)
          Marlon::DB.find(TABLE, id)
        end

        def self.where(cond = {})
          Marlon::DB.where(TABLE, cond)
        end

        def self.update(id, attrs)
          attrs[:updated_at] = Time.now.utc.iso8601
          Marlon::DB.update(TABLE, id, attrs)
        end

        def self.delete(id)
          Marlon::DB.delete(TABLE, id)
        end
      end
    end
  end
end

Marlon::Modules::Cloud::Tenant.ensure_table!

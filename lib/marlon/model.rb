# lib/marlon/model.rb
require "securerandom"
require "json"
require_relative "db"
require_relative "inflector"

module Marlon
  class Model
    ############################################################
    #                       CLASS API
    ############################################################

    def self.attributes
      @attributes ||= {}
    end

    def self.references_defs
      @references_defs ||= {}
    end

    def self.attachments_enabled?
      true
    end

    # -------------------------------------------------------------------
    # ATTRIBUTE
    # -------------------------------------------------------------------
    def self.attribute(name, type: :string, default: nil)
      attributes[name] = { type: type, default: default }

      define_method(name) do
        @values ||= {}
        @values.key?(name) ? @values[name] : default
      end

      define_method("#{name}=") do |val|
        @values ||= {}
        @values[name] = type_cast(val, type)
      end
    end

    # -------------------------------------------------------------------
    # REFERENCES (belongs_to)
    # -------------------------------------------------------------------
    def self.references(name)
      fk = "#{name}_id".to_sym
      references_defs[name] = fk
      attribute fk, type: :string, default: nil

      define_method(name) do
        ref_id = public_send(fk)
        return nil unless ref_id
        Object.const_get(name.to_s.capitalize).find(ref_id)
      end

      define_method("#{name}=") do |model|
        public_send("#{fk}=", model&.id)
      end
    end


    def self.reference(name)
  attributes["#{name}_id".to_sym] = { type: :string, default: nil }

  define_method(name) do
    fk = public_send("#{name}_id")
    return nil unless fk
    Object.const_get(name.to_s.capitalize).find(fk)
  end

  define_method("#{name}=") do |obj|
    public_send("#{name}_id=", obj.id)
  end
end


    # -------------------------------------------------------------------
    # HAS MANY (reverse relation)
    # -------------------------------------------------------------------
    def self.has_many(name, class_name:, foreign_key:)
      define_method(name) do
        klass = Object.const_get(class_name)
        klass.where(foreign_key => id)
      end
    end

    ############################################################
    #                       AUTO TABLE CREATION
    ############################################################

    def self.ensure_table!
      return if @table_created

      cols = attributes.map do |name, opts|
        sql_type = case opts[:type]
                   when :string then "TEXT"
                   when :integer then "INTEGER"
                   when :float then "REAL"
                   when :boolean then "BOOLEAN"
                   when :json then "JSON"
                   else "TEXT"
                   end
        "#{name} #{sql_type}"
      end

      sql = case Marlon::DB.adapter
            when :sqlite
              "CREATE TABLE IF NOT EXISTS #{name} (#{cols.join(",")}, PRIMARY KEY(id))"
            when :postgres
              "CREATE TABLE IF NOT EXISTS \"#{name}\" (#{cols.join(",")}, PRIMARY KEY(id))"
            end

      conn = Marlon::DB.connection
      Marlon::DB.adapter == :postgres ? conn.exec(sql) : conn.execute(sql)

      @table_created = true
    end

    ############################################################
    #                       INSTANCE API
    ############################################################

    def initialize(params = {})
      @values = {}
      params.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
      @values[:id] ||= SecureRandom.uuid
    end

    def id
      @values[:id]
    end

    # -------------------------------------------------------------------
    # SAVE
    # -------------------------------------------------------------------
    def save
      now = Time.now.utc.to_s
      @values[:created_at] ||= now
      @values[:updated_at] = now

      self.class.ensure_table!
      Marlon::DB.save(self.class.name, to_h)

      persist_attributes_to_file
      self
    end

    # -------------------------------------------------------------------
    # DELETE
    # -------------------------------------------------------------------
    def delete
      Marlon::DB.delete(self.class.name, id)
    end

    # -------------------------------------------------------------------
    # TO HASH
    # -------------------------------------------------------------------
    def to_h
      self.class.attributes.keys.index_with do |key|
        public_send(key)
      end.merge(id: id)
    end

    ############################################################
    #                       CLASS QUERY API
    ############################################################

    def self.find(id)
      ensure_table!
      row = Marlon::DB.find(name, id)
      row ? new(row) : nil
    end

    def self.where(conditions)
      ensure_table!
      rows = Marlon::DB.where(name, conditions)
      rows.map { |row| new(row) }
    end

    ############################################################
    #                       ATTACHMENTS
    ############################################################

    def attach(file_path)
      FileUtils.mkdir_p("storage/#{self.class.name}/#{id}")
      dest = "storage/#{self.class.name}/#{id}/#{File.basename(file_path)}"
      FileUtils.cp(file_path, dest)
    end

    def attachments
      path = "storage/#{self.class.name}/#{id}"
      return [] unless Dir.exist?(path)
      Dir.children(path).map { |f| "#{path}/#{f}" }
    end

    def self.attachment(name)
  attributes["#{name}_blob_id".to_sym] = { type: :string, default: nil }

  define_method(name) do
    blob_id = public_send("#{name}_blob_id")
    return nil unless blob_id
    Marlon::Blob.find(blob_id)
  end

  define_method("#{name}=") do |file|
    blob = Marlon::Blob.create_from_file(file)
    public_send("#{name}_blob_id=", blob.id)
  end
end

def self.attachments(name)
  define_method(name) do
    Marlon::Blob.where(record_type: self.class.name, record_id: id, name: name)
  end

  define_method("#{name}=") do |files|
    Array(files).each do |file|
      Marlon::Blob.create_from_file(
        file,
        record_type: self.class.name,
        record_id: id,
        name: name
      )
    end
  end
end


    ############################################################
    #                       INTERNAL
    ############################################################

    private

    def type_cast(value, type)
      return nil if value.nil?
      case type
      when :string  then value.to_s
      when :integer then value.to_i
      when :float   then value.to_f
      when :boolean then !!value
      when :json    then JSON.parse(value.to_s) rescue value
      else value
      end
    end

    # -------------------------------------------------------------------
    # PERSIST ATTRIBUTES BACK INTO MODEL FILE
    # -------------------------------------------------------------------
    def persist_attributes_to_file
      model_file = File.join(Dir.pwd, "lib", "marlon", "models", "#{self.class.name.downcase}.rb")
      return unless File.exist?(model_file)

      content = File.read(model_file)
      lines = self.class.attributes.map do |name, opts|
        "  attribute :#{name}, type: :#{opts[:type]}, default: #{opts[:default].inspect}"
      end

      new_block = "# ATTRIBUTES START\n#{lines.join("\n")}\n  # ATTRIBUTES END"

      new_content =
        if content =~ /# ATTRIBUTES START(.+?)# ATTRIBUTES END/m
          content.sub(/# ATTRIBUTES START(.+?)# ATTRIBUTES END/m, new_block)
        else
          content.sub(/class #{self.class.name} < Marlon::Model/) do |match|
            "#{match}\n#{new_block}"
          end
        end

      File.write(model_file, new_content)
    end
  end
end

# lib/marlon/model.rb
require "securerandom"
require "json"
require "fileutils"
require "time"
require_relative "db"
require_relative "inflector"
require_relative "blob" rescue nil # optional if blob exists

module Marlon
  class ValidationError < StandardError; end

  class Model
    class << self
      # core attributes
      def attributes
        @attributes ||= {
          id:         { type: :string, default: nil },
          created_at: { type: :string, default: nil },
          updated_at: { type: :string, default: nil }
        }
      end

      def validations
        @validations ||= []
      end

      def add_validation(attr, rules)
        validations << { attr: attr.to_sym, rules: rules }
      end

      # DSL: validates :name, presence: true, numericality: true
      def validates(attr, rules)
        add_validation(attr, rules)
      end

      # Define attribute; defaults to :auto if not provided (type inference)
      def attribute(name, type: :auto, default: nil)
        name = name.to_sym
        attributes[name] = { type: type, default: default }
        define_attribute_accessors(name, type, default)
      end

      # belongs_to style
      def reference(name)
        fk = "#{name}_id".to_sym
        attribute(fk, type: :string, default: nil)
        define_method(name) do
          ref_id = public_send(fk)
          return nil unless ref_id
          Object.const_get(name.to_s.capitalize).find(ref_id)
        end

        define_method("#{name}=") do |obj|
          public_send("#{fk}=", obj&.id)
        end
      end

      # has_many reverse
      def has_many(name, class_name:, foreign_key:)
        define_method(name) do
          klass = Object.const_get(class_name)
          klass.where(foreign_key => id)
        end
      end

      # attachments / single & multiple
      def attachment(name)
        attribute("#{name}_blob_id".to_sym, type: :string)
        define_method(name) do
          blob_id = public_send("#{name}_blob_id")
          blob_id ? Blob.find(blob_id) : nil
        end
        define_method("#{name}=") do |file|
          blob = Blob.create_from_file(file, record_type: self.class.name, record_id: id, name: name.to_s)
          public_send("#{name}_blob_id=", blob.id)
        end
      end

      def attachments(name)
        define_method(name) do
          Blob.where(record_type: self.class.name, record_id: id, name: name.to_s)
        end
        define_method("#{name}=") do |files|
          Array(files).each do |f|
            Blob.create_from_file(f, record_type: self.class.name, record_id: id, name: name.to_s)
          end
        end
      end

      # Naming helpers
      def table_name
        Inflector.pluralize(Inflector.underscore(name))
      end

      # Ensure DB table exists
      def ensure_table!
        return if @table_created
        Marlon::DB.ensure_table(table_name, attributes.transform_values { |v| v[:type] })
        @table_created = true
      end

      # Simple caching (in-memory) for find()
      def cache
        @cache ||= {}
      end

      def cache_enabled?
        !!@use_cache
      end

      def enable_cache!
        @use_cache = true
      end

      def disable_cache!
        @use_cache = false
        @cache = {}
      end

      # find / where
      def find(id)
        ensure_table!
        if cache_enabled? && cache[id]
          return cache[id]
        end
        row = Marlon::DB.find(table_name, id)
        model = row ? new(symbolize_row(row)) : nil
        cache[id] = model if cache_enabled? && model
        model
      end

      def where(conds = {})
        ensure_table!
        rows = Marlon::DB.where(table_name, conds)
        rows.map { |r| new(symbolize_row(r)) }
      end

      private

      def define_attribute_accessors(name, type, default)
        define_method(name) do
          @values ||= {}
          if @values.key?(name.to_sym)
            @values[name.to_sym]
          else
            default
          end
        end

        define_method("#{name}=") do |val|
          @values ||= {}
          @values[name.to_sym] = self.class.infer_and_cast(val, type)
        end
      end

      def symbolize_row(row)
        # support sqlite (Hash) and PG row (Hash-like)
        row.each_with_object({}) do |(k, v), memo|
          memo[k.to_sym] = v
        end
      end

      # Called by instances to coerce value
      def infer_and_cast(value, declared_type)
        t = declared_type || :auto
        if t == :auto
          inferred = infer_type(value)
          return cast_by_type(value, inferred)
        else
          return cast_by_type(value, t)
        end
      end

      # naive type inference
      def infer_type(value)
        return :json if value.is_a?(Hash) || value.is_a?(Array)
        s = value.to_s.strip
        return :boolean if s == "true" || s == "false" || value == true || value == false
        return :integer if s.match?(/\A-?\d+\z/)
        return :float if s.match?(/\A-?\d+\.\d+\z/)
        return :json if s.start_with?("{") && s.end_with?("}") || s.start_with?("[") && s.end_with?("]")
        :string
      end

      def cast_by_type(value, type)
        return nil if value.nil?
        case type
        when :string  then value.to_s
        when :integer then value.to_i
        when :float   then value.to_f
        when :boolean then !!value && value != "false"
        when :json    then JSON.parse(value.to_s) rescue value
        else value
        end
      end
    end

    # instance API ----------------------------------------------------
    def initialize(params = {})
      @values = {}
      params.each do |k, v|
        setter = "#{k}="
        public_send(setter, v) if respond_to?(setter)
      end
      @values[:id] ||= SecureRandom.uuid
    end

    def id
      @values[:id]
    end

    def to_h
      # freeze shape: string keys to match DB expectations
      self.class.attributes.keys.map { |k| [k.to_s, public_send(k)] }.to_h
    end

    # validations runner returns boolean, fills errors
    def valid?
      @errors = []
      self.class.validations.each do |v|
        val = public_send(v[:attr])
        rules = v[:rules]
        if rules[:presence] && (val.nil? || (val.respond_to?(:to_s) && val.to_s.strip.empty?))
          @errors << "#{v[:attr]} must be present"
        end
        if rules[:numericality] && !(val.to_s =~ /\A-?\d+(\.\d+)?\z/)
          @errors << "#{v[:attr]} must be numeric"
        end
        if rules[:format] && !(val.to_s =~ rules[:format])
          @errors << "#{v[:attr]} is invalid"
        end
        if rules[:inclusion] && !rules[:inclusion].include?(val)
          @errors << "#{v[:attr]} is not included in list"
        end
      end
      @errors.empty?
    end

    def errors
      @errors || []
    end

    # Save with validation
    def save(validate: true)
      if validate && !valid?
        raise ValidationError, errors.join("; ")
      end

      now = Time.now.utc.iso8601
      @values[:created_at] ||= now
      @values[:updated_at] = now

      self.class.ensure_table!

      data = to_h
      Marlon::DB.save(self.class.table_name, data)

      # cache invalidate/update
      if self.class.cache_enabled?
        self.class.cache[id] = self
      end

      persist_attributes_to_file
      self
    end

    def delete
      Marlon::DB.delete(self.class.table_name, id)
      self.class.cache.delete(id) if self.class.cache_enabled?
      true
    end

    private

    # write attribute list into model file (markers)
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
            "#{match}\n  #{new_block}\n"
          end
        end

      File.write(model_file, new_content)
    end
  end
end

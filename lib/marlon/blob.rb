# lib/marlon/blob.rb
require "securerandom"
require "fileutils"
require_relative "model"

module Marlon
  class Blob < Model
    attribute :filename, type: :string
    attribute :content_type, type: :string
    attribute :size, type: :integer
    attribute :record_type, type: :string
    attribute :record_id, type: :string
    attribute :name, type: :string
    attribute :path, type: :string

    def self.storage_dir
      File.join(Dir.pwd, "storage", "blobs")
    end

    def self.create_from_file(src_path, opts = {})
      raise "file not found: #{src_path}" unless File.exist?(src_path)
      id = SecureRandom.uuid
      ext = File.extname(src_path)
      filename = opts[:filename] || File.basename(src_path)
      dest_dir = File.join(storage_dir, id)
      FileUtils.mkdir_p(dest_dir)
      dest = File.join(dest_dir, filename)
      FileUtils.cp(src_path, dest)
      blob = new(
        id: id,
        filename: filename,
        content_type: opts[:content_type] || "application/octet-stream",
        size: File.size(dest),
        record_type: opts[:record_type],
        record_id: opts[:record_id],
        name: opts[:name],
        path: dest
      )
      blob.save
      blob
    end

    def self.find(id)
      super(id)
    end

    def url
      path
    end

    def self.where(conds = {})
      super(conds)
    end
  end
end

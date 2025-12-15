#!/usr/bin/env ruby

# Set the root directory to the first argument, or current directory by default
root_dir = ARGV[0] || "."

def print_tree(path, prefix = "")
  entries = Dir.entries(path).reject { |e| e.start_with?(".") }.sort
  entries.each_with_index do |entry, index|
    full_path = File.join(path, entry)
    is_last = index == entries.size - 1
    connector = is_last ? "└── " : "├── "
    puts "#{prefix}#{connector}#{entry}"

    if File.directory?(full_path)
      new_prefix = prefix + (is_last ? "    " : "│   ")
      print_tree(full_path, new_prefix)
    end
  end
end

puts root_dir
print_tree(root_dir)

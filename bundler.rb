require 'set'
require 'fileutils'

def main
  processed_files = Set.new
  output = []

  process_script("install.sh", processed_files, output)
  File.write("install.sh", output.join("\n"))
end

def process_script(file_path, processed_files, output)
  return if processed_files.include?(file_path)

  processed_files.add(file_path)
  content = File.read(file_path)

  parent_path = File.dirname(file_path)

  content.each_line do |line|
    next if line.start_with?("#")

    if line.start_with?("source ") || line.start_with?(". ")
      imported_file = line.split[1]

      unless imported_file.start_with?("$HOME")
        full_path = File.join(parent_path, imported_file)
        process_script(full_path, processed_files, output)
      else
        output << line.chomp
      end
    else
      output << line.chomp
    end
  end
end

main if __FILE__ == $PROGRAM_NAME

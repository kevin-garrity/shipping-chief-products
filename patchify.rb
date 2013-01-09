#! /usr/bin/env ruby
# for each file in the patchify dir we will upload the file

puts "applying patch"
ENV['PATCHIFY_DIR'] = "patchify"

Dir.glob(File.join("patchify", "*/*")).reverse.each do |file|
  puts `shoifydev upload #{file}`
end

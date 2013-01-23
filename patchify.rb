#! /usr/bin/env ruby
# for each file in the patchify dir we will upload the file

puts "applying patch"
ENV['PATCHIFY_DIR'] = "shopify_theme_modifications"

Dir.glob(File.join(ENV['PATCHIFY_DIR'], "*/*")).reverse.each do |file|
  puts `shopifydev upload #{file[file.index("/") + 1, file.length - 1]}`
end

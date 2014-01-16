require "erb"

# Yoinked from Github
class String
	def console_red; colorize(self, "\e[31m"); end
	def console_green; colorize(self, "\e[32m"); end

	def console_bold; colorize(self, "\e[1m"); end
	def console_underline; colorize(self, "\e[4m"); end

	def colorize(text, color_code)  "#{color_code}#{text}\e[0m" end
end

# Compile source_dir/filename to destination_dir/filename
def ext_copy_file(filename, source_dir, destination_dir, with_erb: false)
	source_file = File.join(source_dir, filename)
	destination_file = File.join(destination_dir, filename)

	mkdir_p destination_dir
	destination_file.sub(/\.erb(\.[a-z]+)$/) {with_erb = true; "#{$1}"}

	if with_erb
		File.open(destination_file, "w") do |f|
			f.puts ERB.new(IO.read(source_file)).result(binding)
			puts "✔ Copied #{filename.console_bold} (ERB)"
		end
	else
		cp source_file, destination_dir
		puts "✔ Copied #{filename.console_bold} (no ERB)"
	end

	return destination_file
end
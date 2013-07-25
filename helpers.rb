# Yoinked from Github
class String
	def console_red; colorize(self, "\e[1m\e[31m"); end
	def console_green; colorize(self, "\e[1m\e[32m"); end
	def console_bold; colorize(self, "\e[1m"); end
	def console_underline; colorize(self, "\e[4m"); end

	def colorize(text, color_code)  "#{color_code}#{text}\e[0m" end
end

# Compile source_dir/filename to destination_dir/filename
def erb_crunch(filename, source_dir, destination_dir)
	source_file = File.join(source_dir, filename)
	destination_file = File.join(destination_dir, filename)

	File.open(destination_file, "w") do |f|
		f.puts ERB.new(IO.read(source_file)).result(binding)
		puts '✔ Crunched '+filename.console_bold
	end

	return destination_file
end
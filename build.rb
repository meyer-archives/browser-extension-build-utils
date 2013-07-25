require 'erb'

PWD = File.expand_path(File.dirname(__FILE__))
EXT_SRC = "#{EXT_NAME}.safariextension"
EXT_SRC_PATH = File.join(TEMP_DIR, EXT_SRC)

@ext_files = []

EXT_FILES.each do |filename|
	@ext_files.push filename.sub('.coffee','.js')
end

task :default => 'build:release'

namespace :build do
	desc "Build browser extensions for #{EXT_DISPLAY_NAME}"
	task :release => [:start, :crunch, :copy_icons, :build, :finish]

	desc "Build browser extension folder for #{EXT_DISPLAY_NAME}"
	task :dev => [:start, :set_dev_timestamp, :crunch, :copy_icons, :finish]

	task :set_dev_timestamp do
		@ext_version = [
			'0',
			# Chrome requires: max of four digits per section, no initial zero.
			Time.now.to_i.to_s[-9,4].sub(%r{^0},''),
			Time.now.to_i.to_s[-5,4].sub(%r{^0},'')
		].join('.')
	end

	task :start do
		name = "#{EXT_DISPLAY_NAME} #{@ext_version}"
		puts '', name.console_green.console_underline

		# Make sure the destination directory exists
		system "mkdir -p #{RELEASE_DIR}"

		# Remove parent temp directory
		system "rm -rf #{EXT_SRC_PATH}"
		system "mkdir -p #{EXT_SRC_PATH}"
		puts "✔ Reset build folder"
	end

	task :crunch do
		EXT_FILES.each do |filename|
			if filename.include? '.coffee'
				cs_file = erb_crunch(filename, BUILD_SRC, EXT_SRC_PATH)
				if `coffee -c #{cs_file}`
					puts "✔ Compiled " + filename.console_bold + " to " + filename.sub('.coffee','.js').console_bold
				end
			else
				js_file = erb_crunch(filename, BUILD_SRC, EXT_SRC_PATH)
			end
		end

		erb_crunch('Info.plist', PWD, EXT_SRC_PATH)
		erb_crunch('manifest.json', PWD, EXT_SRC_PATH)
	end

	task :copy_icons do
		EXT_ICONS.each do |icon_size|
			if `cp #{BUILD_SRC}/Icon-#{icon_size}.png #{EXT_SRC_PATH}`
				puts "✔ Copied "+"Icon-#{icon_size}.png".console_bold
			end
		end
	end

	task :build do
		# Using absolute paths because of the directory change
		# TODO: better fix
		build_options = [
			File.join(RELEASE_DIR, BUILD_PREFIX),
			CERT_DIR,
			File.expand_path(TEMP_DIR),
			EXT_SRC
		].join(' ')

		if `#{PWD}/build-safari-ext.sh #{build_options}`
			puts "✔ Built Safari extension to #{RELEASE_DIR}".console_green
		end
		if `#{PWD}/build-chrome-ext.sh #{build_options}`
			puts "✔ Built Chrome extension to #{RELEASE_DIR}".console_green
		end
	end

	task :finish do
		# TODO: something more inspiring here.
		puts ''
	end
end
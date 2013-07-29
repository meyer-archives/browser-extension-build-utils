require 'erb'

PWD = File.expand_path(File.dirname(__FILE__))
EXT_DEST_DIR = "#{EXT_NAME}.safariextension"
EXT_DEST_PATH = File.join(TEMP_DIR, EXT_DEST_DIR)

@ext_version = EXT_VERSION

@ext_files = []
@js_files = []
@cs_files = []

EXT_FILES.each do |filename|
	if filename.include? '.coffee'
		@cs_files.push filename
	else
		@js_files.push filename
	end
	@ext_files.push filename.sub('.coffee','.js')
end

@ext_icons = []

EXT_ICONS.each do |icon_size|
	@ext_icons.push "Icon-#{icon_size}.png"
end

namespace :extension do
	desc "Build browser extensions for #{EXT_DISPLAY_NAME}"
	task :build_release => [:preflight, :release_header, :compile_extension, :finish]

	desc "Build browser extension folder for #{EXT_DISPLAY_NAME}"
	task :build_dev => [:preflight, :dev_header, :reset_build, :copy_files, :finish]

	task :preflight do
		puts '','Preflight checks'.console_underline.console_bold

		pf_errors = []
		pf_success = []

		# Conditionally check for CoffeeScript
		if @cs_files.length and not `which coffee`.strip!
			pf_errors.push 'CoffeeScript is not installed, but required by '+@cs_files.join(', ')
		else
			pf_success.push `coffee --version`.strip+' is installed'
		end

		# TODO: Ensure EXT_SOURCE_DIR exists

		# TODO: Create folders, check permissions
		# [TEMP_DIR, EXT_SOURCE_DIR, EXT_DEST_PATH, EXT_RELEASE_DIR].each do |folder|
		# end

		# TODO: Check for certificates in EXT_CERT_DIR

		if @ext_icons.length > 0
			@ext_icons.each do |filename|
				if File.exists? File.join(EXT_SOURCE_DIR, filename)
					pf_success.push filename+' exists'
				else
					pf_errors.push filename+' does not exist in '+EXT_SOURCE_DIR
				end
			end
		end

		if pf_success.length > 0
			puts ('✔ '+pf_success.join("\n✔ ")).console_green
		end

		if pf_errors.length > 0
			puts ('✗ '+pf_errors.join("\n✗ ")).console_red
			puts '','Corrent the errors to continue.',''
			exit 1
		end
	end

	task :dev_header do
		# Add build number for dev versions
		@ext_version = [
			EXT_VERSION,
			(Time.now.to_i/60).to_s[-4,4].sub(%r{^0},'')
		].join('.')

		title = "Build #{EXT_DISPLAY_NAME} #{@ext_version}"
		puts '', title.console_underline.console_bold
	end

	task :release_header do
		title = "Build #{EXT_DISPLAY_NAME} #{@ext_version}"
		puts '', title.console_underline.console_bold
		puts 'Browser extensions will be built in '+EXT_RELEASE_DIR.console_bold+'.',''
		print 'Is that ok? (y/n): '

		once = false
		too_far = 0

		begin
			until %w( k ok y yes n no ).include?(answer = $stdin.gets.chomp.downcase)
				exit 1 if too_far < 3
				++too_far # += 1

				if !once
					print 'Please type y/yes or n/no. '
					once = true
				end
				print 'Build extensions? (y/n): '
			end
		rescue Interrupt
			exit 1
		end

		exit 1 if answer =~ /n/
		puts ''
	end

	task :reset_build do
		# Make ./bin
		mkdir_p EXT_RELEASE_DIR

		# Reset ./temp/demo.safariextension
		rm_rf EXT_DEST_PATH
		mkdir_p EXT_DEST_PATH

		puts "✔ Reset build folder"

	end

	task :copy_files do
		# CoffeeScript files
		@cs_files.each do |filename|
			cs_file = erb_crunch(filename, EXT_SOURCE_DIR, EXT_DEST_PATH)
			if `coffee -c #{cs_file}`
				puts "✔ Compiled " + filename.console_bold + " to " + filename.sub('.coffee','.js').console_bold
			end
		end

		# Javascript files
		@js_files.each do |filename|
			erb_crunch(filename, EXT_SOURCE_DIR, EXT_DEST_PATH)
		end

		# Extension metadata
		erb_crunch('Info.plist', PWD, EXT_DEST_PATH)
		erb_crunch('manifest.json', PWD, EXT_DEST_PATH)

		# Icons
		@ext_icons.each do |filename|
			if cp File.join(EXT_SOURCE_DIR,filename), EXT_DEST_PATH
				puts "✔ Copied "+filename.console_bold
			end
		end
	end

	task :compile_extension => [:reset_build, :copy_files] do
		# Using absolute paths because of the directory change
		# TODO: better fix
		build_options = [
			File.join(EXT_RELEASE_DIR, EXT_BUILD_PREFIX),
			EXT_CERT_DIR,
			File.expand_path(TEMP_DIR),
			EXT_DEST_DIR
		].join(' ')

		if `#{PWD}/build-safari-ext.sh #{build_options}`
			puts "✔ Built Safari extension to #{EXT_RELEASE_DIR}".console_bold
		end
		if `#{PWD}/build-chrome-ext.sh #{build_options}`
			puts "✔ Built Chrome extension to #{EXT_RELEASE_DIR}".console_bold
		end
	end

	task :finish do
		# TODO: something more inspiring here.
		puts ''
	end
end
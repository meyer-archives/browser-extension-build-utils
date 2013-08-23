PWD = File.expand_path(File.dirname(__FILE__))
EXT_DEST_DIR = "#{EXT_NAME}.safariextension"
EXT_DEST_PATH = File.join(TEMP_DIR, EXT_DEST_DIR)

@ext_version = EXT_VERSION

@content_scripts = []
@cs_files = []
@text_files = []
@binary_files = []

EXT_CONTENT_SCRIPTS.each do |filename|
	if filename.include? '.coffee'
		@cs_files.push filename
	else
		@text_files.push filename
	end
	@content_scripts.push filename.sub('.coffee','.js')
end

EXT_EXTRA_RESOURCES.each do |filename|
	if filename.include? '.coffee'
		@cs_files.push filename
	elsif filename.include? '.js'
		@text_files.push filename
	else
		@binary_files.push filename
	end
end

namespace :extension do
	desc "Build browser extensions for #{EXT_DISPLAY_NAME}"
	task :build_release => [:preflight, :confirm_build, :compile_extension, :finish]

	desc "Build browser extension folder for #{EXT_DISPLAY_NAME}"
	task :build_dev => [:set_dev_version, :preflight, :reset_build, :copy_files, :finish]

	task :build_arrays do
		EXT_ICONS.each do |icon_size|
			@binary_files.push "Icon-#{icon_size}.png"
		end

		if EXT_BACKGROUND_PAGE
			@text_files.push 'background.html'
			@cs_files.push 'background.coffee'
		end

		if EXT_POPOVER_MENU
			@binary_files.push 'toolbar-button-icon-safari.png'
			@binary_files.push 'toolbar-button-icon-safari@2x.png'
			@binary_files.push 'toolbar-button-icon-chrome.png'
			@binary_files.push 'toolbar-button-icon-chrome@2x.png'
			@text_files.push 'popover.css'
			@text_files.push 'popover.html'
			@cs_files.push 'popover.coffee'
		end
	end

	task :preflight => [:build_arrays] do
		puts '', "#{EXT_DISPLAY_NAME} #{@ext_version}"

		puts '','Preflight checks'.console_underline

		pf_errors = []
		pf_success = []

		if EXT_BACKGROUND_PAGE
			# TODO: check for background page/scripts
			pf_success.push 'TODO: check for background page/scripts'
		end

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

		((@cs_files + @text_files).sort + @binary_files).each do |filename|
			if File.exists? File.join(EXT_SOURCE_DIR, filename)
				pf_success.push filename+' exists'
			else
				pf_errors.push filename+' does not exist in '+EXT_SOURCE_DIR
			end
		end

		if pf_errors.length > 0
			puts ('✗ '+pf_errors.join("\n✗ ")).console_red
			puts '','Corrent the errors to continue.',''
			exit 1
		else
			puts '✔ Everything looks good from here'
		end
	end

	task :set_dev_version do
		@ext_version = [
			EXT_VERSION,
			(Time.now.to_i/60).to_s[-4,4].sub(%r{^0},'9')
		].join('.')
	end

	task :confirm_build do
		puts "Browser extensions will be built in #{EXT_RELEASE_DIR}",''
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

		# Reset ./build/demo.safariextension
		rm_rf EXT_DEST_PATH
		mkdir_p EXT_DEST_PATH

		puts "✔ Reset build folder"

	end

	task :copy_files do
		puts '','Crunch extension metadata'.console_underline
		erb_crunch('Info.plist', PWD, EXT_DEST_PATH)
		erb_crunch('manifest.json', PWD, EXT_DEST_PATH)

		puts '','Crunch CoffeeScript files'.console_underline
		@cs_files.each do |filename|
			cs_file = erb_crunch(filename, EXT_SOURCE_DIR, EXT_DEST_PATH)
			if `coffee -c #{cs_file}`
				puts "✔ Compiled #{filename} to #{filename.sub('.coffee','.js')}"
			end
		end

		puts '','Crunch text files'.console_underline
		@text_files.each do |filename|
			erb_crunch(filename, EXT_SOURCE_DIR, EXT_DEST_PATH)
		end

		puts '','Copy binary resources'.console_underline
		@binary_files.each do |filename|
			cp File.join(EXT_SOURCE_DIR, filename), EXT_DEST_PATH
			puts "✔ Copied #{filename}"
		end
	end

	task :compile_extension => [:reset_build, :copy_files] do
		# Using absolute paths because of the directory change
		# TODO: better fix
		build_options = [
			File.join(EXT_RELEASE_DIR, "#{EXT_NAME}-#{@ext_version}"),
			EXT_CERT_DIR,
			File.expand_path(TEMP_DIR),
			EXT_DEST_DIR
		].join(' ')

		if `#{PWD}/build-safari-ext.sh #{build_options}`
			puts "✔ Built Safari extension to #{EXT_RELEASE_DIR}"
		end
		if `#{PWD}/build-chrome-ext.sh #{build_options}`
			puts "✔ Built Chrome extension to #{EXT_RELEASE_DIR}"
		end
		erb_crunch('safari-update-manifest.plist', SERVER_SOURCE_DIR, EXT_RELEASE_DIR)
	end

	task :finish do
		# TODO: something more inspiring here.
		puts ''
	end
end
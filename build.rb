require 'erb'

PWD = File.expand_path(File.dirname(__FILE__))
EXT_DEST_DIR = "#{EXT_NAME}.safariextension"
EXT_DEST_PATH = File.join(TEMP_DIR, EXT_DEST_DIR)

@ext_files = []

EXT_FILES.each do |filename|
	@ext_files.push filename.sub('.coffee','.js')
end

namespace :extension do
	desc "Build browser extensions for #{EXT_DISPLAY_NAME}"
	task :build_release => [:release_header, :start, :crunch, :copy_icons, :build, :finish]

	desc "Build browser extension folder for #{EXT_DISPLAY_NAME}"
	task :build_dev => [:dev_header, :start, :crunch, :copy_icons, :finish]

	task :dev_header do
		@ext_version = [
			'0',
			# Chrome requires: max of four digits per section, no initial zero.
			Time.now.to_i.to_s[-9,4].sub(%r{^0},''),
			Time.now.to_i.to_s[-5,4].sub(%r{^0},'')
		].join('.')

		title = "Build #{EXT_DISPLAY_NAME} #{@ext_version}"
		puts '', title.console_green_underline
	end

	task :release_header do
		title = "Build #{EXT_DISPLAY_NAME} #{@ext_version}"
		puts '', title.console_green_underline
		puts 'Browser extensions will be built in '+EXT_RELEASE_DIR.console_bold+'.',''
		print 'Is that ok? (y/n): '

		once = false
		too_far = 0

		begin
			until %w( k ok y yes n no ).include?(answer = $stdin.gets.chomp.downcase)
				if too_far < 3
					too_far += 1
				else
					exit 1
				end

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

	task :start do
		# Make ./bin
		system "mkdir -p #{EXT_RELEASE_DIR}"

		# Reset ./temp/demo.safariextension
		system "rm -rf #{EXT_DEST_PATH}"
		system "mkdir -p #{EXT_DEST_PATH}"

		puts "✔ Reset build folder"
	end

	task :crunch do
		EXT_FILES.each do |filename|
			if filename.include? '.coffee'
				cs_file = erb_crunch(filename, EXT_SOURCE_DIR, EXT_DEST_PATH)
				if `coffee -c #{cs_file}`
					puts "✔ Compiled " + filename.console_bold + " to " + filename.sub('.coffee','.js').console_bold
				end
			else
				js_file = erb_crunch(filename, EXT_SOURCE_DIR, EXT_DEST_PATH)
			end
		end

		erb_crunch('Info.plist', PWD, EXT_DEST_PATH)
		erb_crunch('manifest.json', PWD, EXT_DEST_PATH)
	end

	task :copy_icons do
		EXT_ICONS.each do |icon_size|
			if `cp #{EXT_SOURCE_DIR}/Icon-#{icon_size}.png #{EXT_DEST_PATH}`
				puts "✔ Copied "+"Icon-#{icon_size}.png".console_bold
			end
		end
	end

	task :build do
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
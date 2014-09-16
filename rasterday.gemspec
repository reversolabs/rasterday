Gem::Specification.new { |s|
	s.platform = Gem::Platform::RUBY

	s.author = "Pete Elmore"
	s.email = "pete@reverso.be"
	s.files = Dir["{lib,doc,bin,ext}/**/*"].delete_if {|f|
		/\/rdoc(\/|$)/i.match f
	} + %w(Rakefile)
	s.require_path = 'lib'
	s.has_rdoc = true
	s.extra_rdoc_files = (Dir['doc/*'] << 'README').select(&File.method(:file?))
	s.extensions << 'ext/extconf.rb' if File.exist? 'ext/extconf.rb'
	Dir['bin/*'].map(&File.method(:basename)).map(&s.executables.method(:<<))

	s.name = 'rasterday'
	s.summary = "Rack middleware to convert SVGs to raster images"
	s.homepage = "http://github.com/reversolabs/#{s.name}"
	%w(
		rmagick
		rack
	).each &s.method(:add_dependency)
	s.version = '0.1.0'
}


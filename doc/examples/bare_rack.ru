# This example just serves up any SVGs that you put into this directory.

require 'rasterday'

b = Rack::Builder.new {
	use Rasterday
	use Rack::Static,
		urls: [/.*\.svg$/],
		root: File.dirname(__FILE__)
	run lambda { |*|
		Rack::Response.new("You'll want to navigate to an SVG instead of the root.")
	}
}.to_app
run b


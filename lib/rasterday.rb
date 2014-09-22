require 'RMagick'
require 'logger'

# Rasterday is a piece of Rack Middleware that automatically converts SVG images
# to raster images.
class Rasterday
	# Specifies default values for Rasterday#initialize's +opts+.
	DefaultOpts = {
		trigger: :bad_browsers,
		format: 'GIF',
		content_type: nil, # See FormatToContent
		logger: nil,
		stamp_responses: true, # Helps with debugging, performance.
		# TODO:  Caching.
	}

	FormatToContent = {
		'GIF' => 'image/gif',
		'PNG' => 'image/png',
		'JPEG' => 'image/jpeg',
	}

	attr_reader :app, :outf, :content_type, :trigger

	def initialize app, opts = {}
		@app = app
		opts = DefaultOpts.merge opts

		@stamp_responses = opts[:stamp_responses]
		@outf = opts[:format]
		@content_type = opts[:content_type] || FormatToContent[@outf]

		m = opts[:trigger]
		case m
		when Method, Proc
			@trigger = m
		when Symbol, String
			@trigger = method(m)
		end

		if trigger.nil?
			raise ArgumentError, "Apparently invalid trigger:  #{opts[:trigger].inspect}"
		end
	end
	
	def call env
		r = @app.call env

		begin
			r = r.to_a
			# We only touch 2xx-class messages:
			return r unless (200...300).include?(r[0])
			# We don't touch HEAD requests:
			return r if env['REQUEST_METHOD'] == 'HEAD'
			# The reason for this is that we can't generate the appropriate headers
			# unless we get a body back.

			# We only care about SVGs:
			ctk, ct = r[1].find { |k,v| k.downcase == 'content-type' }
			return r if ct != "image/svg+xml"
			# Run the trigger last (most likely to be expensive):
			return r if !trigger[env, r]
			svg = ''
			r[2].each { |chunk| svg << chunk }
			of = @outf
			i, * = Magick::Image.from_blob(svg) { |info|
				info.background_color = 'none'
			}
			i.format = @outf
			r[1][ctk] = content_type
			blob = i.to_blob
			clk, cl = r[1].find { |k,v| k.downcase == 'content-length' }
			r[1][clk] = blob.bytesize.to_s
			r[2] = [i.to_blob]
			r[1]['Rasterday'] = '1'
		rescue StandardError => e
			logger.error { "Failed to convert:  #{e} #{e.backtrace.join("\n")}" }
		end
		r
	end

	def logger
		@logger ||= Logger.new($stderr)
	end

	def stamp_responses?
		@stamp_responses
	end

	def always(*)
		true
	end

	def bad_browsers(env, *)
		ua = env['HTTP_USER_AGENT']
		# IE hates SVGs:
		return true if ua.include?('MSIE') || ua.include?('Trident/')
		# Older versions of Firefox:
		ff = /Firefox\/(\d+(\.\d+))/.match(ua)
		if ff != nil
			return ff[1].to_i <= 3
		end
		# The rest of this chunk is TODO.  See ../doc/TODO .
		false
	end
end

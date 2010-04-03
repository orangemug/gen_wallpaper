require 'rubygems'
require 'RMagick'
require "wordnet"

# INSTALL:
#   rwordnet

module GenWallpaper
	module DailyWord
		class Star
		    def initialize(w, h)
			@angle_inc = 10
			@width     = w
			@height    = h

			# Max distance form the center.
			@radius = Math.sqrt(@width*@width + @height*@height)

			# Stripe colors
			@color_a = "#FF4500"
			@color_b = "#FFA500"

			@color_a = "#4A8AB9"
			@color_b = "#869EAF"
		    end

		    def draw(img)
			cen_x = @width/2.0
			cen_y = @height/2.0
			5.step(355, @angle_inc) do |n|
			    a1=(n*Math::PI)/180.0
			    x1 = (Math.cos(a1) * @radius) + cen_x
			    y1 = (Math.sin(a1) * @radius) + cen_y

			    a2=((n+@angle_inc)*Math::PI)/180.0
			    x2 = (Math.cos(a2) * @radius) + cen_x
			    y2 = (Math.sin(a2) * @radius) + cen_y

			    # Get color
			    color = ( ((n-5)%20) > 0  ? @color_a : @color_b)

			    line = Magick::Draw.new
			    line.fill(color)
			    line.polygon(cen_x,cen_y, x1,y1, x2,y2)

			    # Output
			    line.draw(img)
			end

			return img
		    end
		end
	end
end

module GenWallpaper
	module DailyWord
		class Definition
		    def initialize(w, h)
			@color_a = "white"
			@color_b = "black"
			@color_shadow = "#000000"

			@width  = w
			@height = h
		    end

		    def get_definition()
			definition = nil
			while(!definition) do
				# Soooo inefficient
				line = IO.readlines('/usr/share/dict/words')
				c = rand*line.length.to_i
				word = line[c-1].gsub(/\'s$/, '')

				word.chomp!
				lemmas = WordNet::WordNetDB.find(word)

				# Print out each lemma with a list of possible meanings.
				lemmas.each do |lemma|
					lemma.synsets.each_with_index do |synset,i|
						definition = synset.gloss.capitalize
						break
					end
					break if  definition
				end
			end
			return {:word => word, :definition => definition}
		    end

		    def draw_word(orig_img)
			img = Magick::ImageList.new
			img.new_image(@width, @height) {
			    self.background_color = "#0000FF00"
			}

			color = @color_b
			25.step(0,-5) do |n|
			    text = Magick::Draw.new
			    text.annotate(img, 0, 0, -10, -10, @word) do
				self.font = "resources/fonts/Candice.ttf"
				self.gravity = Magick::CenterGravity
				self.pointsize = 72
				self.fill = "white"
				self.stroke_width = n
				self.stroke = color
			    end
			    color = (color == @color_a ? @color_b : @color_a)
			end

			# Add the shadow.
			shadow = img.shadow(1,0,5.0)
			shadow = shadow.colorize(1, 1, 1, "black")
			img = shadow.composite(img, 6, 6, Magick::OverCompositeOp)
			return orig_img.composite(img, 7, 7, Magick::OverCompositeOp)
		    end

		    def draw_definition(img_orig)
			img = Magick::ImageList.new
			img.new_image(@width, @height) {
			    # Image with a transparant background.
			    self.background_color = "#0000FF00"
			}


			defin_new = ""
			# Split def
			num_lines = 0;
			cnt = 1
			@definition.split(/\s+/).each { |n|
			    cnt += n.length
			    if cnt > 50 then
				cnt = n.length
				defin_new << "\n"
				num_lines += 1
			    end
			    defin_new << n << " "
			}

			text = Magick::Draw.new
			text.annotate(img, 0,0,0,10+(@height/2)+(80/2), defin_new.to_s) do
			    self.font = "resources/fonts/Candice.ttf"
			    self.gravity = Magick::NorthGravity
			    self.pointsize = 30
			    self.fill = "white"
			    self.stroke_width = 1
			    self.stroke = "black"
			end

			img_orig = img_orig.composite(img, 7, 7, Magick::OverCompositeOp)
			return img_orig
		    end

		    def draw(img)
			word_hash = get_definition
			@word       = word_hash[:word].capitalize
			@definition = word_hash[:definition]

			img = draw_word(img)
			return draw_definition(img)
		    end
		end
	end
end




#
# THE APP
#


#
# Initalize and run the script.
#
screen_width=1680
screen_height=1050

# Image.
img = Magick::ImageList.new
img.new_image(screen_width, screen_height) {
    self.background_color = "#0000FF00"
}

# Draw background
s=GenWallpaper::DailyWord::Star.new(screen_width, screen_height)
img = s.draw(img)

# Print random word + definition.
d=GenWallpaper::DailyWord::Definition.new(screen_width, screen_height)
img = d.draw(img)

# Write the image!
img.write("daily_word.png")


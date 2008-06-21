require 'helpers'
require 'rubygame'

class Tile

	attr_reader :x, :y, :item

	def initialize(x, y, item)
		@x, @y = x, y
		@item = item
		@hexagon = make_hexagon_coordinates(@x, @y)
		@color = GAME_COLORS::NEUTRAL_LAND
	end

	def draw(surface)
		surface.draw_polygon_s(@hexagon, @color)
		surface.draw_polygon_a(@hexagon, [0, 0, 0])
	end

end

class Board
	
	attr_reader :tiles, :surface, :sprites

	BOARD_DIR = File.join('boards')

	def initialize(filename, players)
		unless File.exist?( full_filename = File.join(BOARD_DIR, filename))
			raise "Map not found"
		end
		@tiles = []
		@tiles.acts_as_indexable_board
		
		@surface = Rubygame::Surface.new([640, 480])
		@surface.fill(GAME_COLORS::SEA)

		@sprites = Sprites::Group.new

		File.readlines(full_filename).each_with_index do |row, yindex|
			row.strip.split('').each_with_index do |repr, xindex|
				unless repr == '-'
					tile = yield xindex, yindex, repr
					@tiles[yindex][xindex] = tile
					@sprites << tile.item if tile.item
					tile.draw(@surface)
				end
			end
		end


	end

	def [](x, y)
		return @tiles[y][x]
	end

	def update
		@sprites.update
	end

	def draw(screen)
		@surface.blit(screen, [0,0])
		@sprites.draw(screen)
	end

end

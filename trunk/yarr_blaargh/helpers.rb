class String
	def to_color_array
		[self[1,2], self[3,2], self[5,2]].map{|e| e.to_i(16) }
	end
	alias to_array to_color_array
end

class Integer
	def even?
		self[0].zero?
	end
  def odd?
    not even?
  end
end

class Object

	def acts_as_indexable_board
		class << self
			alias old_at []
			def [](index)
				if not (row = self.old_at(index))
					row = (self[index] = [])
				end
				row
			end

			alias old_each each
			def each(&block)
				self.old_each{|row| row.each{|tile| yield tile if tile} }
			end
		end
	end

end

module GAME_COLORS
	NEUTRAL_LAND = "#C1C1F7".to_color_array
	PLAYERS = {1 => "#155094".to_color_array, 2 => "#A82222".to_color_array }
	SEA = "#66BBFF".to_color_array
	HP_BAR = "#00FF00".to_color_array
	MENU_BG = "#000044".to_color_array
	MENU_BG_HIGHLIGHTED = "#000077".to_color_array
	INFO_TEXT = "white"
	ACTIONS_TEXT = "#FFFF66".to_color_array
	HIGHLIGHTED_TEXT = "red"
end

HEXAGON_DELTAS = [[0, 0], [0, 30], [30, 40], [60, 30], [60, 0], [30, -10], [0, 0]]

# Returns the coordinates of the hexagon
def make_hexagon_coordinates(x, y)
	start_point = calculate_startpoint(x, y)
	HEXAGON_DELTAS.map do |delta| 
		[start_point[0] + delta[0], start_point[1] + delta[1]]
	end
end

# Returns the coordinates of the TOP LEFT VERTEX of the hexagon. It is located +10 in y
# of the rectangle bound to it.
def calculate_startpoint(x, y)
	start_point = [x*60, y*40+10]
	start_point[0] += 30 if y.even?
	start_point
end

def pos_to_coords(position)
	y = position[1] / 40
	if y.even?
		x = (position[0] - 30) / 60
	else
		x = position[0] / 60
	end
	[x, y]
end

def display(message)
	puts "#TODO: " + message
end


def temporary_menu(options)
  n_items = options.size
  puts "Select an option:"
  options.each_with_index{|opt, i| puts "\t#{i}: #{opt}"}
  selected = Integer(gets) rescue nil
  until selected and options[selected]
    puts "Please select a valid option"
    selected = Integer(gets) rescue nil
  end
  return selected
end

class HexVector
  
  attr_accessor :x, :y
  
  def self.[](x, y)
    return HexaVector.new(x, y)
  end
  
  def initialize(x, y)
    @x, @y = x, y
  end
  
  def +(other)
    # TODO
  end
  
end

H = HexVector #Alias for class name
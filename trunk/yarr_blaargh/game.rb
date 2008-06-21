require 'cards'
require 'board'
require 'helpers'

Surface.autoload_dirs << [File.join(File.dirname(__FILE__), 'images')]
MOVE_DELTAS = [[0, -1], [1, 0], [0, 1], [-1, 1], [-1, 0], [-1, -1]]

class GameSprite
	attr_accessor :player
	attr_accessor :hp
	include Sprites::Sprite
	HP_FONT = TTF.new('times_new_yorker.ttf', 12)
	HP_FONT.bold = true
	def initialize(x, y, player, char_name, initial_hp)
		super()
		@x, @y, @player = x, y, player
		@max_hp = initial_hp
		@hp = initial_hp
		@original_image = Surface[char_name + '.bmp']
		@original_image.set_colorkey(@original_image.get_at([0,0]))
		@image = @original_image
		@rect = @image.make_rect
		sp = calculate_startpoint(x, y)
		@rect.bottomleft = [sp[0], sp[1] + 30]

		@hp_bar_tl = @rect.bottomleft
		@hp_bar_br = [@rect.right, @rect.bottom + 3]
		@hp_bar_width = 30
		@hp_legend = GameSprite::HP_FONT.render(@hp.to_s, true, GAME_COLORS::PLAYERS[@player.number])
		@hp_legend_rect = @hp_legend.make_rect
		@hp_legend_rect.top = @rect.bottom + 3
		@hp_legend_rect.left = @rect.left
	end

	def draw(surface)
		super(surface)
		surface.draw_box_s(@hp_bar_tl, [@hp_bar_tl[0] + @hp_bar_width, @hp_bar_br[1]], GAME_COLORS::HP_BAR)
		surface.draw_box(@hp_bar_tl, @hp_bar_br, "black")
		@hp_legend.blit(surface, @hp_legend_rect)
	end

	def update
		# Override in child classes
	end

	def collide_point?(point)
		@rect.collide_point?(*point)
	end
end

class Fighter < GameSprite
	attr_accessor :player, :char_name, :used, :action
	def initialize(x, y, player, char_name, initial_hp)
		super(x, y, player, char_name, initial_hp)
		@char_name = char_name
		@flipped = false
		if player.number == 2
			flip
			@rect.move!(30, 0)
			@hp_bar_tl[0] += 30
			@hp_bar_br[0] += 30
			@hp_legend_rect.left += 30
		end
		@jumping = false
		@jump = 0
		@jump_direction = :up
    @used = false
	end

	def update
		if @jumping
			if @jump_direction == :up
				@rect.move!(0, -1)
				@jump += 1
				@jump_direction = :down if @jump == 15
			else
				@rect.move!(0, 1)
				@jump -= 1
				@jump_direction = :up if @jump == 0
			end
		end
	end

  def move(where)
    next_pos = MOVE_DELTAS[where]
    # Correction for displacement
    if @y.even? and next_pos[1].odd?
      next_pos[0] += 1
    end
    @action = lambda do |current_position|
      move_to(current_position[0] + next_pos[0], current_position[1] + next_pos[1])
    end
    use
  end

  def move_to(new_x, new_y)
    target = $board[new_x, new_y]
    puts "Target: #{target}"
    if target and target.item #and target.item.player == self.player #TODO: Only one unit per tile
      display "Ooops. Units have just crashed. It cannot move..."
      return
    end
    old_sp = calculate_startpoint(@x, @y)
    new_sp = calculate_startpoint(new_x, new_y)
    delta_x, delta_y = new_sp[0] - old_sp[0], new_sp[1] - old_sp[1]
    @x, @y = new_x, new_y
		@rect.move!(delta_x, delta_y)
    @hp_legend_rect.move!(delta_x, delta_y)
    @hp_bar_tl[0] += delta_x
    @hp_bar_tl[1] += delta_y
    @hp_bar_br[0] += delta_x
    @hp_bar_br[1] += delta_y
    @remember_pos = @rect.topleft
  end

  def charge
    @action = lambda do |current_position|
      self.player.energy = [self.player.energy + 50, 200].min
    end
    use
  end

  def card(c)
    @action = lambda do |current_position|
      puts "POW! from #{c.name}"
    end
    use
  end

	def flip
		@flipped = !@flipped
		@image = @image.flip(true, false)
	end
	
	def select
		@jumping = true
		@remember_pos = @rect.topleft
	end

	def unselect
		@jumping = false
		@jump = 0
		@jump_direction = :up
		@rect.topleft = @remember_pos
	end

  def use
    @used = true
    unselect
  end

  def draw(surface)
    super(surface)
    if @used
      surface.draw_line_a(@rect.tl, @rect.br, GAME_COLORS::PLAYERS[@player.number])
      surface.draw_line_a(@rect.tr, @rect.bl, GAME_COLORS::PLAYERS[@player.number])
    end
  end

  def end_turn
    @action.call([@x, @y]) if @action
  end

end

class Base < GameSprite
	def initialize(x, y, player, char_name, initial_hp)
		super(x, y, player, char_name, initial_hp)
		@rect.move!(15, 0)
		@hp_bar_tl[0] += 15
		@hp_bar_br[0] += 15
		@hp_legend_rect.left += 15
	end
end




class Player

	attr_accessor :number
	attr_accessor :energy, :fighters
	attr_accessor :base
	attr_accessor :deck
	attr_accessor :available_moves, :available_charges
	
	def initialize(type, number)
		@type = type
		@number = number
		@energy = 200
		@deck = Deck.new(type, number)
		@available_moves = 3
    @available_charges = 2
	end

end

class Game

	attr_accessor :p1, :p2
	attr_accessor :board

	def initialize(players, board_filename)
		@p1 = Player.new(players[0], 1)
		@p2 = Player.new(players[1], 2)		

		characters = [['zombie', 'ghoul', 'cementery'], ['pirate', 'captain', 'ship']]
		characters.reverse! if players[0] == :pirates
		
		
		@board = Board.new(board_filename, players) do |x, y, repr|
			item = case repr
				when '#' then nil
				when 'o' then Fighter.new(x, y, @p1, characters[0][0], 100)
				when 'O' then Fighter.new(x, y, @p1, characters[0][1], 200)
				when '@' then Base.new(x, y, @p1, characters[0][2], 100)
				when 'x' then Fighter.new(x, y, @p2, characters[1][0], 100)
				when 'X' then Fighter.new(x, y, @p2, characters[1][1], 200)
				when '$' then Base.new(x, y, @p2, characters[1][2], 100)
			end
			Tile.new(x, y, item)
		end
	end

	def [](player)
		case player
			when 1 then @p1
			when 2 then @p2
		end
	end

  def end_turn
    @board.tiles.each do |t|
      if t.item and t.item.kind_of?(Fighter)
        t.item.end_turn
      end
    end
  end

end

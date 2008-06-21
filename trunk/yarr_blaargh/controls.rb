require 'helpers'

class Controls

	attr_accessor :menu_color

	Surface.autoload_dirs << File.join(File.dirname(__FILE__), 'cards', 'pirates')
	Surface.autoload_dirs << File.join(File.dirname(__FILE__), 'cards', 'zombies')

	Actions = ['move', 'charge', 'card', 'end turn']
	Actions_font = TTF.new('times_new_yorker.ttf', 26)
	Info_font = TTF.new('times_new_yorker.ttf', 15)

  Moves = ['up right', 'right', 'down right', 'down left', 'left', 'up left']

	def initialize(game)
		
		
		@game = game

		@menu_surface = Rubygame::Surface.new([200, 480])
		@menu_surface.fill(GAME_COLORS::MENU_BG)

		@info_text = Controls::Info_font.render("Select action", true, GAME_COLORS::INFO_TEXT)
		rect = @info_text.make_rect
		rect.centerx = @menu_surface.width / 2
		rect.y = 10
		@info_text.blit(@menu_surface, rect)

		@actions_surface = Rubygame::Surface.new([200, 120])
		@actions_surface.fill(GAME_COLORS::MENU_BG)
		@ac_rect = @actions_surface.make_rect
		@ac_rect.centerx = @menu_surface.width / 2
		@ac_rect.y = 30

		@menu_actions = {}
		0.upto(3) do |i|
			action = Controls::Actions[i]
			text = Controls::Actions_font.render(action.upcase, true, GAME_COLORS::ACTIONS_TEXT)
			rect = text.make_rect
			rect.centerx = @actions_surface.width / 2
			rect.y = 30*i
			text.blit(@actions_surface, rect)
			@menu_actions[action] = text
		end

		@actions_surface.blit(@menu_surface, @ac_rect)

		@current_selected_fighter = nil
		@turn = 0

	end
	
	def draw(screen)
		@menu_surface.blit(screen, [640, 0])
	end

	def turn_of(turn)
		@turn = turn
	end

	def option=(opt)
		if @current_selected and @current_selected != opt
			text = menu_font.render("Yay, rendered!", true, MENU_COLOR)
		end
		if opt
			@current_selected = opt
			menu_font.render("Yay, rendered!", true, MENU_COLOR_H)
		end
	end

	def select(fighter)
    if fighter.used
      display("The character is already used")
      return
    end
    @current_selected_fighter.unselect if @current_selected_fighter
		@current_selected_fighter = fighter
		fighter.select
	end

	def tell_click(event)
		pos = event.pos
		if pos[0] < 640
			game_coords = pos_to_coords(pos)
			fighter = @game.board[*game_coords]
			fighter = fighter.item if fighter
			select(fighter) if fighter and fighter.kind_of?(Fighter) and fighter.player.number == @turn
		else
			if i = is_over_menu?(event)
        if not @current_selected_fighter
          display("Select a fighter first")
          return
        end unless i == 3 # End turn
				case i
					when 0 then move
					when 1 then charge
					when 2 then card
          when 3 then end_turn
				end
			end
		end
	end

	def tell_move(event)
		if event.pos[0] > 640
			if i = is_over_menu?(event)
				highlight(i)
			else
				unhighlight
			end
		else
			unhighlight
		end
	end

	def is_over_menu?(event)
		y = event.pos[1]
		if y >= 30 and y < 60 then 0
		elsif y >= 60 and y < 90 then 1
		elsif y >= 90 and y < 120 then 2
    elsif y >= 120 and y < 150 then 3
		else nil
		end
	end

	def highlight(i)
		return if @mouse_over == i
		unhighlight
		@mouse_over = i		
		@actions_surface.fill(GAME_COLORS::MENU_BG_HIGHLIGHTED, Rect::new(0, i*30, 200, 30))
		action = Controls::Actions[i]
		text = Controls::Actions_font.render(action.upcase, true, GAME_COLORS::HIGHLIGHTED_TEXT)
		rect = text.make_rect
		rect.centerx = @menu_surface.width / 2
		rect.y = 30*i
		text.blit(@actions_surface, rect)
		@actions_surface.blit(@menu_surface, @ac_rect)
	end

	def unhighlight
		return unless @mouse_over
		@actions_surface.fill(GAME_COLORS::MENU_BG, Rect::new(0, @mouse_over*30, 200, 30))
		action = Controls::Actions[@mouse_over]
		text = Controls::Actions_font.render(action.upcase, true, GAME_COLORS::ACTIONS_TEXT)
		rect = text.make_rect
		rect.centerx = @menu_surface.width / 2
		rect.y = 30*@mouse_over
		text.blit(@actions_surface, rect)
		@actions_surface.blit(@menu_surface, @ac_rect)
		@mouse_over = nil
	end

	def move
		player = @game[@turn]
		if player.available_moves == 0
			display("You have no available moves")
      return
		end
    where = temporary_menu(Controls::Moves)
    @current_selected_fighter.move(where)
    player.available_moves -= 1
    display "Your #{@current_selected_fighter.char_name} will move #{Controls::Moves[where]}"
	end

  def charge
    player = @game[@turn]
    if player.available_charges == 0
      display("You have no available charges")
      return
    end
    @current_selected_fighter.charge
    player.available_charges -= 1
    display "Your #{@current_selected_fighter.char_name} will charge (+50 energy)"
  end

  def card
    fighter = @current_selected_fighter
    cards = @game[@turn].deck.cards[fighter.char_name.to_sym].select{|c| c.disponible > 0}
    choose = temporary_menu(cards)
    selected_card = cards[choose]
    @current_selected_fighter.card(selected_card)
    selected_card.disponible -= 1
    display "Your #{@current_selected_fighter.char_name} will use #{selected_card.name} card"
  end

  def end_turn
    @game.end_turn #Should be for player
  end

	def display_menu_for(fighter)
		puts fighter.char_name
	end

end

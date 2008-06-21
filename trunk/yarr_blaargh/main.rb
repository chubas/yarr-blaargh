require 'rubygems'
require 'rubygame'
include Rubygame

raise 'Images disabled' unless VERSIONS[:sdl_image] != nil
raise 'Font disabled' unless VERSIONS[:sdl_ttf] != nil
raise 'Sound disabled' unless VERSIONS[:sdl_mixer] != nil
Rubygame::TTF.setup

require 'helpers'
require 'events'
require 'controls'
require 'game'

def main
	Rubygame.init

	screen = Screen.new([840, 480])
	screen.title = "Zombies vs Pirates!"



	queue = EventQueue.new

	clock = Clock.new { |clock| clock.target_framerate = 20 }

	game = Game.new([:pirates, :zombies].reverse, 'board1.bd')
	$board = game.board

	controls = Controls.new(game)

	mouse_event_manager = MouseEventManager.new(controls)
	key_event_manager = KeyEventManager.new(controls)

	turn = 1																		#Player 1
	controls.turn_of(turn)

	loop do
		queue.each do |event|
			case event
				when QuitEvent
					return
				when MouseDownEvent
					controls.tell_click(event)
				when MouseMotionEvent
					controls.tell_move(event)
				when KeyDownEvent
					key_event_manager.tell(event)
			end
		end

		$board.draw(screen)
		$board.update
		controls.draw(screen)

		screen.update
	end

ensure
	Rubygame.quit
end

if $0 == __FILE__
  main
end

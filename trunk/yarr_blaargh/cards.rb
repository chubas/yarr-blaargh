require 'yaml'

#Fixes the coloring for windows
if RUBY_PLATFORM =~ /(win|w)32/
  class String
    %w{yellow red blue green underline bold}.each do |m|
        define_method(m){ self }
    end
  end
else
  require 'colorize'
end

CARD_DIR = File.join(File.dirname(__FILE__), 'cards')
RANGE_REPR_TEMPLATE = <<-TEMPLATE
     / \\ / \\ / \\     
    | %s | %s | %s |    
   / \\ / \\ / \\ / \\   
  | %s | %s | %s | %s |  
 / \\ / \\ / \\ / \\ / \\ 
| %s | %s | %s | %s | %s |
 \\ / \\ / \\ / \\ / \\ / 
  | %s | %s | %s | %s |  
   \\ / \\ / \\ / \\ /   
    | %s | %s | %s |    
     \\ / \\ / \\ /     
TEMPLATE

class Card

	#attr_accessor :displacement   # Pending: for attacks that carry a displacement
	attr_accessor :id, :name, :range, :damage, :spends, :affects, :disponible

	def initialize(card_id, d, player_number)
    @player_number = player_number
		@id = card_id
		@name = d['name']
		@range = d['range']
    @range_repr = d['range_repr']
		@damage = d['damage']
    @spends = d['spends']
		@affects = d['affects'] || 'enemies'
		@disponible = d['disponible'] || 2

    if player_number == 2
      @range.map! do |x, y|
        if y.even?
          [-x, y]
        else
          [-(x+1), y]
        end
      end
    end
	end

  def to_s
    [
      " --- " + @name.yellow + " ---",
      "Damage: " + @damage.to_s.red,
      (@spends > 0 ? "Spends: " : "Recovers: ") + @spends.to_s.red,
      "Affects: " + @affects.to_s,
      "Range: " + sub_range_repr,
      "Disponible: " + (@disponible > 0 ? @disponible.to_s.blue : @disponible.to_s.red.underline)
    ].join("\n")
  end

  def sub_range_repr
    a = Array.new(19){ ' ' }
    for i in @range_repr
      a[i] = (i == 9 ? 'O' : 'x')
    end
    a[9] = 'o' if a[9] != 'O' 
    str = "\n" + (RANGE_REPR_TEMPLATE % a).gsub('o', 'o'.blue).gsub('O', 'O'.red).gsub('x', 'x'.red) + "\n"
    str = str.split("\n").map{|line| line.reverse}.join("\n") if @player_number == 2
    str
  end

end

class Deck
	
	attr_accessor :cards

	def initialize(type, number)
		@cards = {}
		if type == :zombies
			@cards[:zombie] = []			
			YAML::load_file(File.join(CARD_DIR, 'zombie.cards')).each do |card_id, card_definition|
				@cards[:zombie] << Card.new(card_id, card_definition, number)
			end
			@cards[:ghoul] = []
			YAML::load_file(File.join(CARD_DIR, 'ghoul.cards')).each do|card_id, card_definition|
				@cards[:ghoul] << Card.new(card_id, card_definition, number)
			end
		else
			@cards[:pirate] = []			
			YAML::load_file(File.join(CARD_DIR, 'pirate.cards')).each do |card_id, card_definition|
				@cards[:pirate] << Card.new(card_id, card_definition, number)
			end
			@cards[:captain] = []
			YAML::load_file(File.join(CARD_DIR, 'captain.cards')).each do|card_id, card_definition|
				@cards[:captain] << Card.new(card_id, card_definition, number)
			end
		end
	end

end

require_relative 'lorentz_field'
require_relative 'occams_razor'
#require_relative 'quantum_bow'
#require_relative 'blade_of_recursion'

class WeaponHandler
  def initialize
    @weapons = {
      lorentz_field: LorentzField.new,
      occams_razor: OccamsRazor.new,
      #quantum_bow: QuantumBow.new,
      #blade_of_recursion: BladeOfRecursion.new
    }
  end

  def update(dt)
    @weapons.each_value { |weapon| weapon.update(dt) }

    selected_item = $bus.get(:selected_item)
    return unless @weapons.key?(selected_item)

    weapon = @weapons[selected_item]
    if $bus.get(:count, selected_item) > 0
      if Gosu.button_down?(Gosu::KB_SPACE)
        direction = $bus.get(:player_direction)
        weapon.attack(direction)
      elsif Gosu.button_down?(Gosu::MS_LEFT)
        player_x, player_y = $bus.get(:player_position)
        mouse_x, mouse_y = $bus.get(:mouse_position)
        direction = Math.atan2(mouse_y - player_y, mouse_x - player_x)
        weapon.attack(direction)
      end
    end
  end

  def draw
    @weapons.each_value(&:draw)
  end
end
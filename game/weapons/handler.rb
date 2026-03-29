require_relative 'lorentz_field'
#require_relative 'occams_razor'
#require_relative 'quantum_bow'
#require_relative 'blade_of_recursion'

class WeaponHandler
  def initialize
    @weapons = {
      lorentz_field: LorentzField.new,
      #occams_razor: OccamsRazor.new,
      #quantum_bow: QuantumBow.new,
      #blade_of_recursion: BladeOfRecursion.new
    }
  end

  def update(dt)
    @weapons.each_value { |weapon| weapon.update(dt) }

    selected_item = $bus.get(:selected_item)
    return unless @weapons.key?(selected_item)

    weapon = @weapons[selected_item]
    if $bus.get(:count, selected_item) > 0 && Gosu.button_down?(Gosu::KB_SPACE)
      weapon.attack
    end
  end

  def draw
    @weapons.each_value(&:draw)
  end
end
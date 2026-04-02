require_relative 'base'

class Komodo < Enemy
  load 'assets/images/komodo.png', 31, 48, 1.7

  def initialize(x, y)
    super(x, y, :komodo, 1000)

    $bus.on(:attack) do |attack_x, attack_y, range, damage|
      if Math.hypot(@x - attack_x, @y - attack_y) <= range
        take_damage(damage)
        next true
      end
      false
    end
  end
end
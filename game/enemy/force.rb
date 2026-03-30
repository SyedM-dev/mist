require_relative 'base'

class Force < Enemy
  load 'assets/images/force.png', 21, 32, 1.7

  def initialize(x, y)
    super(x, y, 100)

    $bus.on(:occams_razor_attack) do |attack_x, attack_y, range, damage|
      # Whoa, did'nt know ruby had hypot functions built in!
      if Math.hypot(@x - attack_x, @y - attack_y) <= range
        take_damage(damage)
      end
    end
  end
end
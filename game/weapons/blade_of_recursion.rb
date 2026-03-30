class BladeOfRecursion
  def initialize
    @damage = 1
    @range = 200
    @speed = 500
    @x = 0
    @y = 0
    @direction = nil
  end

  def attack(direction)
    @direction = direction
    @x, @y = $bus.get(:player_position)
  end

  def update(dt)
    return unless @direction

    @x += Math.cos(@direction) * @speed * dt
    @y += Math.sin(@direction) * @speed * dt

    $bus.get(:attack, @x, @y, @range, @damage)

    # If the blade has traveled its max range, reset it
    player_x, player_y = $bus.get(:player_position)
    if Math.hypot(@x - player_x, @y - player_y) > @range
      @direction = nil
    end
  end
end
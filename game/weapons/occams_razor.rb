class OccamsRazor
  BASE_TIME = 0.2 # seconds per attack

  def initialize
    @time = 0
    @active = false
    @damage = 20
    @range = 45 # how many pixels from player center to enemy center the attack hits, this is a melee weapon so it should be small
  end

  def attack(_direction)
    return if @active

    @active = true
    @time = BASE_TIME

    # Check for enemies in range and deal damage
    player_x, player_y = $bus.get(:player_position)
    $bus.emit(:attack, player_x, player_y, @range, @damage)
  end

  def update(dt)
    return unless @active

    @time -= dt
    if @time <= 0
      @active = false
      @time = 0
    end
  end

  def draw
    # Nothing for now, but player attack animation would go here
  end
end
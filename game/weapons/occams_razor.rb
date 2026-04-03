class OccamsRazor
  BASE_TIME = 0.2 # seconds per attack

  def initialize
    @time = 0
    @active = false
    @damage = 20
    @range = 45 # how many pixels from player center to enemy center the attack hits, this is a melee weapon so it should be small
  end

  def attack(direction)
    return if @active

    @active = true
    @time = BASE_TIME

    @direction = direction # radians
    @spread = Math::PI # 90° total arc

    # Check for enemies in range and deal damage
    player_x, player_y = $bus.get(:player_position)
    $bus.emit(:attack, player_x, player_y, @range, @damage)
  end

  def update(dt)
    return unless @active

    @time -= dt

    progress = @time / BASE_TIME
    @spread = (Math::PI) * progress

    if @time <= 0
      @active = false
      @time = 0
    end
  end

  def draw
    return unless @active

    px, py = $bus.get(:player_position)
    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]

    cx = px - cam_x
    cy = py - cam_y

    step = 0.1 # radians (~6°)

    angle_start = @direction - @spread
    angle_end   = @direction + @spread

    alpha = ((@time / BASE_TIME) * 255).to_i
    color = Gosu::Color.new(alpha, 255, 255, 255)

    (angle_start..angle_end).step(step) do |rad|
      x = cx + Math.cos(rad) * @range
      y = cy + Math.sin(rad) * @range

      Gosu.draw_rect(x, y, 4, 4, color, Float::INFINITY)
    end
  end
end
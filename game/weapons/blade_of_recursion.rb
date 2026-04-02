class BladeOfRecursion
  def initialize
    @damage = 1
    @range = 150
    @speed = 400
    @x = 0
    @y = 0
    @start_x = 0
    @start_y = 0
    @direction = nil

    # the knife is pointed top-right
    @sprite = Gosu::Image.new('assets/images/blade_of_recursion.png', retro: true)
  end

  def attack(direction)
    return if @direction
    @direction = direction
    @x, @y = $bus.get(:player_position)
    @start_x, @start_y = @x, @y
  end

  def update(dt)
    return unless @direction

    @x += Math.cos(@direction) * @speed * dt
    @y += Math.sin(@direction) * @speed * dt

    if Math.hypot(@x - @start_x, @y - @start_y) > @range
      @direction = nil
      @damage = 1
      return
    end

    collides = $bus.get_all(:collides?, [@x - 5, @y - 5, 10, 10])
    if collides.include?(:enemy)
      $bus.emit(:attack, @x, @y, 30, @damage)
      @direction = nil
      @damage *= 2
      if @damage > 512
        damage = 1
        $bus.emit(:consume, :blade_of_recursion, 1)
      end
    elsif collides.include?(:wall)
      @direction = nil
      @damage = 1
    end
  end

  def draw
    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]

    # Draw the blade if active
    if @direction
      # Convert radians to degrees
      angle_deg = @direction * 180 / Math::PI
      # Adjust for knife pointing top-right
      angle_deg += 45

      @sprite.draw_rot(
        @x - cam_x,  # x in world coords
        @y - cam_y,  # y in world coords
        1,           # z-order
        angle_deg,   # rotation
        0.5, 0.5,   # pivot center
        2, 2,
        Gosu::Color::WHITE
      )
    end

    # Draw memory bar as HUD in top-right of screen
    # this should be in the HUD layer but due to time constraints im putting it here, sorry
    bar_width  = 100
    bar_height = 10
    padding    = 10

    bar_x = SCREEN_SIZE[0] - bar_width - padding
    bar_y = padding

    # full red background
    Gosu.draw_rect(bar_x, bar_y, bar_width, bar_height, Gosu::Color::RED, Float::INFINITY)

    # green foreground representing current damage
    damage_ratio = Math.log2(@damage) / 9.0
    damage_width = bar_width * [damage_ratio, 1.0].min
    Gosu.draw_rect(bar_x, bar_y, damage_width, bar_height, Gosu::Color::GREEN, Float::INFINITY)
  end
end
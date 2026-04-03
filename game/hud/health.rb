class HealthBar
  attr_reader :health, :max_health

  def initialize(max_health)
    @max_health = max_health
    @health = max_health

    @heart_image = Gosu::Image.new("assets/images/heart.png", retro: true)

    $bus.on(:blast) do |x, y, radius, damage, safety|
      next if safety == :safe

      player_x, player_y = $bus.get(:player_position)

      dist = Math.hypot(player_x - x, player_y - y)
      if dist <= radius + 20
        take_damage(damage)
      end
    end
  end

  def take_damage(amount)
    @health -= amount
    if @health <= 0
      @health = 0
      $is_dead = true
      $bus.emit(:change_scene, GameOver)
    end
  end

  def heal(amount)
    @health += amount
    @health = @max_health if @health > @max_health
  end

  def draw
    # Draw the background of the health bar (red)
    Gosu.draw_rect(SCREEN_SIZE[0] - 100 - 10, 180, 100, 10, Gosu::Color::RED)

    # Draw the foreground of the health bar (green) based on current health
    health_width = (health.to_f / max_health) * 100
    Gosu.draw_rect(SCREEN_SIZE[0] - 100 - 10, 180, health_width, 10, Gosu::Color::GREEN)

    @heart_image.draw(SCREEN_SIZE[0] - 100 - 20, 173, 1, 1.5, 1.5)
  end
end
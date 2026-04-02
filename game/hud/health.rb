class HealthBar
  attr_reader :health, :max_health

  def initialize(max_health)
    @max_health = max_health
    @health = max_health

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
      $bus.emit(:change_scene, GameOver)
    end
  end

  def heal(amount)
    @health += amount
    @health = @max_health if @health > @max_health
  end

  def draw
    # Draw the background of the health bar (red)
    Gosu.draw_rect(30, 10, 100, 10, Gosu::Color::RED)

    # Draw the foreground of the health bar (green) based on current health
    health_width = (health.to_f / max_health) * 100
    Gosu.draw_rect(30, 10, health_width, 10, Gosu::Color::GREEN)
  end
end
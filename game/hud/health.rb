class HealthBar
  attr_reader :health, :max_health

  def initialize(max_health)
    @max_health = max_health
    @health = max_health
  end

  def take_damage(amount)
    @health -= amount
    @health = 0 if @health < 0
  end

  def heal(amount)
    @health += amount
    @health = @max_health if @health > @max_health
  end

  def draw(x, y)
    # Draw the background of the health bar (red)
    Gosu.draw_rect(x, y, 100, 10, Gosu::Color::RED)

    # Draw the foreground of the health bar (green) based on current health
    health_width = (health.to_f / max_health) * 100
    Gosu.draw_rect(x, y, health_width, 10, Gosu::Color::GREEN)
  end
end
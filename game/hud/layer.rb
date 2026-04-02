require_relative "inventory"
require_relative "health"
require_relative "logs"

class HUDLayer
  def initialize
    @hud_bg = Gosu::Image.new("assets/images/hud.png", retro: true)
    @hud_fg = Gosu::Image.new("assets/images/hud_fg.png", retro: true)
    @inventory = Inventory.new
    @health = HealthBar.new(100)
    @logs = GameLogger.new

    $bus.on(:enemy_attack) do |damage|
      @health.take_damage(damage)
    end
  end

  def update(dt)
    @logs.update(dt)
  end

  def draw
    @hud_bg.draw(0, 0, Float::INFINITY)

    @inventory.draw
    @health.draw
    @logs.draw

    @hud_fg.draw(0, 0, Float::INFINITY)
  end

  def button_down(id, pos)
    @inventory.button_down(id, pos)
  end
end
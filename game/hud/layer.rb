require_relative "inventory"

class HUDLayer
  def initialize
    @hud_bg = Gosu::Image.new("assets/images/hud.png", retro: true)
    @hud_fg = Gosu::Image.new("assets/images/hud_fg.png", retro: true)
    @inventory = Inventory.new

    $bus.on(:enemy_attack) do |damage|
      pp "Player takes #{damage} damage!"
    end
  end

  def draw
    @hud_bg.draw(0, 0, Float::INFINITY)

    @inventory.draw

    @hud_fg.draw(0, 0, Float::INFINITY)
  end

  def button_down(id, pos)
    @inventory.button_down(id, pos)
  end
end
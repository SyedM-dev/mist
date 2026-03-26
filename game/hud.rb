class HUD
  def initialize
    @inventory_bg = Gosu::Image.new("assets/images/inventory.png", retro: true)
  end

  def draw
    @inventory_bg.draw(0, 0, Float::INFINITY)
  end
end
require_relative "base"

class Chest < Prop
  def initialize(x, y)
    super(x, y)
    @frames_count = 1
    @spritesheet = Gosu::Image.load_tiles("assets/images/chest.png", 20, 20, retro: true)
  end

  def resources
    { wood: rand(0..64), metal: rand(0..16), science: rand(0..4) }
  end
end
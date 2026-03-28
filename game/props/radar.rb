require_relative "base"

class Radar < Prop
  def initialize(x, y)
    super(x, y)
    @frames_count = 4
    @spritesheet = Gosu::Image.load_tiles("assets/images/radar.png", 20, 20, retro: true)
  end

  def resources
    { wood: rand(0..2), metal: rand(0..8), science: rand(0..2) }
  end
end
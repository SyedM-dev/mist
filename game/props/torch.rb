require_relative "base"

class Torch < Prop
  def initialize(x, y)
    super(x, y)
    @frames_count = 4
    @spritesheet = Gosu::Image.load_tiles("assets/images/torch.png", 20, 20, retro: true)
  end

  def resources
    { wood: rand(0..8) }
  end
end
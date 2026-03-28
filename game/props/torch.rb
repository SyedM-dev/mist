require_relative "base"

class Torch < Prop
  setup_sprites("assets/images/torch.png", 4)

  def resources
    { wood: rand(0..8) }
  end
end
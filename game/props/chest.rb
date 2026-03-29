require_relative "base"

class Chest < Prop
  setup_sprites("assets/images/chest.png", 1)

  def resources
    { wood: rand(2..64), metal: rand(1..16), science: rand(0..4) }
  end
end
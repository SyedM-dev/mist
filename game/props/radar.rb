require_relative "base"

class Radar < Prop
  setup_sprites("assets/images/radar.png", 4)

  def resources
    { wood: rand(0..2), metal: rand(0..8), science: rand(0..2) }
  end
end
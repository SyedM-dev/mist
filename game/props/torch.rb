require_relative "base"

class Torch < Prop
  setup_sprites("assets/images/torch.png", 4)

  def resources
    { wood: rand(0..8) }
  end

  def update(dt)
    dead = super(dt)
    if dead
      $bus.emit(:torch_removed, @x, @y)
      pp "Emitted torch_removed for torch at #{@x}, #{@y}"
    end
    dead
  end
end
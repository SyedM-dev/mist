require_relative 'base'

class Landmine < Trap
  def initialize(x, y)
    super(x, y)
    @sprite = Gosu::Image.new("assets/images/landmine.png", retro: true)
  end

  def stepped_on(_)
    $bus.emit(:blast, @x, @y, 30, 30, :unsafe) # blast radius of 30 and damage of 30, and mark it as unsafe for the player
    true # to destroy the trap
  end
end
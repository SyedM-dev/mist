require_relative 'base'

class ShrodingersMine < Trap
  def initialize(x, y)
    super(x, y)
    @sprite = Gosu::Image.new("assets/images/shrodingers_mine.png", retro: true)
  end

  def stepped_on(entity)
    return false if entity == :character # shrodingers mine is safe for the player, so don't destroy it or cause a blast if the player steps on it
    if rand < 0.7 # 70% chance to be a landmine, 30% chance to be a dud
      $bus.emit(:blast, @x, @y, 50, 50, :safe) # blast radius of 50 and damage of 50, and always safe for the player
    else
      $bus.emit(:log, "You hear a click, but nothing happens. It was a dud!")
    end
    true # to destroy the trap
  end
end
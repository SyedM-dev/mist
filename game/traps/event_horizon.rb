require_relative 'base'

class EventHorizon < Trap
  def initialize(x, y)
    super(x, y)
    @sprite = Gosu::Image.new("assets/images/event_horizon.png", retro: true)
  end

  def stepped_on(entity)
    # this is not a weapon, so nothing
    # it is instead destroyed after after being stepped on by enemy
    $bus.emit(:stun, @x, @y)
    entity == :enemy
  end
end
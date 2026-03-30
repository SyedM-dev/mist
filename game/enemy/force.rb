require_relative 'base'

class Force < Enemy
  load 'assets/images/force.png', 21, 32, 1.7

  def initialize(x, y)
    super
    @w = 20
    @h = 20
  end
end
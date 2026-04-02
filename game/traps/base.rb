class Trap
  SIZE = [40, 40].freeze

  attr_reader :x, :y
  
  def initialize(x, y)
    @x = x
    @y = y
    @sprite = nil
  end

  def collides?(rect)
    return intersects?(collision_rect, rect)
  end

  def collision_rect
    [@x - SIZE[0] / 2, @y - SIZE[1] / 2, *SIZE]
  end

  def update(player)
    # the collision is checked by the player or enemy
  end

  def draw
    return unless @sprite

    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]
    @sprite.draw(@x - SIZE[0] / 2 - cam_x, @y - SIZE[1] / 2 - cam_y, 0, 2, 2)
  end
end
require_relative 'ai'

class Enemy
  attr_accessor :x, :y, :w, :h

  def initialize(x, y)
    @x = x
    @y = y
    @w = 25
    @h = 30

    @ai = EnemyAI.new(self, :chase)

    $bus.on(:collides?) do |rect|
      next collides?(rect) ? :enemy : nil
    end
  end

  def rect
    [@x - @w / 2, @y - @h / 2, @w, @h]
  end

  def collides?(rect)
    return true if intersects?(self.rect, rect)
    false
  end

  def update
    player_pos = $bus.get(:player_position)
    @ai.update(*player_pos) if player_pos
  end

  def draw
    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]

    screen_x = @x - cam_x
    screen_y = @y - cam_y

    Gosu.draw_rect(
      screen_x - @w / 2,
      screen_y - @h / 2,
      @w,
      @h,
      Gosu::Color::RED,
      screen_y - @h / 2
    )

    @ai.draw
  end
end
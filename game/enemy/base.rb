require_relative 'ai'

class Enemy
  attr_accessor :x, :y, :w, :h

  def self.load(path, w, h, s)
    # Once artwork is done need to load each animation here.
    # But as artwork takes time, for now just load a single image.
    @sprite = Gosu::Image.new(path, retro: true)
    @i_w = w
    @i_h = h
    @s = s
  end

  def self.sprite
    @sprite
  end

  def self.frame_size
    [@i_w, @i_h, @s]
  end

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

  def update(dt)
    player_pos = $bus.get(:player_position)
    @ai.update(*player_pos, dt) if player_pos
  end

  def draw
    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]

    screen_x = @x - cam_x
    screen_y = @y - cam_y


    self.class.sprite.draw(
      screen_x - self.class.frame_size[0],
      screen_y - self.class.frame_size[1],
      screen_y - self.class.frame_size[1],
      self.class.frame_size[2],
      self.class.frame_size[2]
    )

    Gosu.draw_rect(screen_x - @w / 2, screen_y - @h / 2, @w, @h, Gosu::Color.new(0x40FF0000), Float::INFINITY) if $bus.get(:settings, :debug)

    @ai.draw
  end
end
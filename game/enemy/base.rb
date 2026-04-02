require_relative 'ai'

class Enemy
  attr_accessor :x, :y, :w, :h, :lorentz

  def self.load(path, w, h, s)
    # Once artwork is done need to load each animation here.
    # But as artwork takes time, for now just load a single image.
    @sprite = Gosu::Image.new(path, retro: true)
    @i_w = w * s
    @i_h = h * s
    @s = s
  end

  def self.sprite
    @sprite
  end

  def self.frame_size
    [@i_w, @i_h, @s]
  end

  def initialize(x, y, health = 100)
    @x = x
    @y = y
    @w = 25
    @h = 30
    @health = health
    @stun = 0
    @last_lock = :none
    @lorentz = $bus.get(:lorentz_field?) || false

    $bus.on(:lorentz_field!) do |lorentz|
      @lorentz = lorentz
    end

    @ai = EnemyAI.new(self, :chase)

    $bus.on(:collides?) do |rect|
      next collides?(rect) ? :enemy : nil
    end

    $bus.on(:blast) do |x, y, radius, damage, _|
      dist = Math.hypot(@x - x, @y - y)
      if dist <= radius + 20
        take_damage(damage * 2)
      end
    end

    $bus.on(:stun)  do |x, y|
      dist = Math.hypot(@x - x, @y - y)
      if dist <= 100
        @stun = 60 * 1 # stun for 1 second
      end
    end
  end

  def take_damage(amount)
    @health -= amount
    if @health <= 0
      $bus.emit(:enemy_died, self)
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
    if @stun > 0
      @stun -= 1
      return
    end

    player_pos = $bus.get(:player_position)
    closest_event_horizon = $bus.get(:closest_event_horizon, @x, @y, 200)
    if closest_event_horizon
      @ai.update(*closest_event_horizon, dt, @last_lock != :event_horizon)
      @last_lock = :event_horizon
    else
      @ai.update(*player_pos, dt, @last_lock != :player) if player_pos
      @last_lock = :player
    end

    if $bus.get_all(:collides?, rect).include?(:trap)
      $bus.emit(:trap_stepped_on, rect, :enemy)
    end
  end

  def draw
    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]

    screen_x = @x - cam_x
    screen_y = @y - cam_y

    self.class.sprite.draw(
      screen_x - self.class.frame_size[0] / 2,
      screen_y - self.class.frame_size[1] / 2,
      screen_y - self.class.frame_size[1] / 2 + 10,
      self.class.frame_size[2],
      self.class.frame_size[2]
    )

    # Health bar

    health_width = (@w * @health / 100.0)
    Gosu.draw_rect(screen_x - @w / 2, screen_y - @h / 2 - 10, health_width, 5, Gosu::Color.new(0xFF00FF00), Float::INFINITY)

    if $bus.get(:settings, :debug)
      Gosu.draw_rect(screen_x - @w / 2, screen_y - @h / 2, @w, @h, Gosu::Color.new(0x40FF0000), Float::INFINITY)
    end

    @ai.draw
  end
end
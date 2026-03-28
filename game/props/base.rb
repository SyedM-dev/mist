class Prop
  DESTRUCTION_SPEED = 50.0
  SIZE = [25, 15]

  # The base class for all props in the game. Props are things that can be interacted with, but do not move (unlike characters).
  # They cannot be walked through, but can be interacted with (e.g. a chest can be opened, a torch can be lit, a radar can be used).
  # They are placed at the center of a tile, and their position is represented by the tile coordinate
  # A prop is one that is placed at the center of a tile (radar, torch & chest)
  attr_reader :x, :y

  def self.setup_sprites(path, frames)
    @frames_count = frames
    @spritesheet = Gosu::Image.load_tiles(path, 20, 20, retro: true)
  end

  def self.spritesheet
    @spritesheet
  end

  def self.frames_count
    @frames_count
  end

  def self.ghost
    @spritesheet&.first
  end

  def initialize(x, y)
    @x = x
    @y = y
    @health = 100
  end

  def collides?(rect)
    return true if intersects?(self.collision_rect, rect)
    false
  end

  def collision_rect
    [@x * 120 + 90 - SIZE[0] / 2, @y * 120 + 90 - SIZE[1], *SIZE]
  end

  def rect
    [@x * 120 + 90 - 20, @y * 120 + 90 - 20, 40, 40]
  end

  def resources
    {}
  end

  def update(dt)
    return unless Gosu.button_down?(Gosu::MS_LEFT) || Gosu.button_down?(Gosu::KB_X)

    player_x, player_y = $bus.get(:player_position) || [0, 0]

    tile_x, tile_y = [(player_x - 90) / 120, (player_y - 90) / 120].map(&:round)

    return unless tile_x == @x && tile_y == @y

    if Gosu.button_down?(Gosu::MS_LEFT)
      mouse_x, mouse_y = $bus.get(:mouse_pos)
      cam_x, cam_y = $bus.get(:camera_pos)
      world_mouse_x = mouse_x + cam_x
      world_mouse_y = mouse_y + cam_y
      return unless intersects?([world_mouse_x, world_mouse_y, 1, 1], self.rect)
    end

    @health -= DESTRUCTION_SPEED * dt
    if @health <= 0
      resources.each do |type, amount|
        $bus.emit(:obtain, type, amount)
      end
      return true
    end
    false
  end

  def draw
    return unless self.class.spritesheet

    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]
    screen_x = @x * 120 + 90 - cam_x
    screen_y = @y * 120 + 90 - cam_y

    elapsed = Gosu.milliseconds / 1000.0
    frame_index = ((elapsed * self.class.frames_count).floor) % self.class.frames_count

    self.class.spritesheet[frame_index].draw(screen_x - 20, screen_y - 20, screen_y, 2, 2)

    if @health < 100
      percent = 1.0 - @health / 100.0
      w, h = SIZE

      bar_width = w * percent
      bar_height = 3

      bar_x = screen_x - w / 2
      bar_y = screen_y + h + 5

      Gosu.draw_rect(bar_x, bar_y, bar_width, bar_height, Gosu::Color::RED, screen_y - 19)
    end

    return unless $bus.get(:settings, :debug)

    # collision box centered on same point
    Gosu.draw_rect(screen_x - SIZE[0] / 2, screen_y - SIZE[1], *SIZE, Gosu::Color.new(0x88ff0000), Float::INFINITY)
  end
end
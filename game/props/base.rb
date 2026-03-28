class Prop
  SIZE = [25, 15]

  # The base class for all props in the game. Props are things that can be interacted with, but do not move (unlike characters).
  # They cannot be walked through, but can be interacted with (e.g. a chest can be opened, a torch can be lit, a radar can be used).
  # They are placed at the center of a tile, and their position is represented by the tile coordinate
  # A prop is one that is placed at the center of a tile (radar, torch & chest)
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
    @frames_count = 0
    @spritesheet = nil
  end

  def collides?(rect)
    return true if intersects?(self.rect, rect)
    false
  end

  def rect
    [@x * 120 + 90 - SIZE[0] / 2, @y * 120 + 90 - SIZE[1], *SIZE]
  end

  def update
    # For now, placeables don't have any behavior
  end

  def draw
    return unless @spritesheet

    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]
    screen_x = @x * 120 + 90 - cam_x
    screen_y = @y * 120 + 90 - cam_y

    elapsed = Gosu.milliseconds / 1000.0
    frame_index = ((elapsed * @frames_count).floor) % @frames_count

    @spritesheet[frame_index].draw(screen_x - 20, screen_y - 20, screen_y, 2, 2)

    return unless DEBUG

    # collision box centered on same point
    Gosu.draw_rect(screen_x - SIZE[0] / 2, screen_y - SIZE[1], *SIZE, Gosu::Color.new(0x88ff0000), Float::INFINITY)
  end
end

class Radar < Prop
  def initialize(x, y)
    super(x, y)
    @frames_count = 4
    @spritesheet = Gosu::Image.load_tiles("assets/images/radar.png", 20, 20, retro: true)
  end
end

class Torch < Prop
  def initialize(x, y)
    super(x, y)
    @frames_count = 4
    @spritesheet = Gosu::Image.load_tiles("assets/images/torch.png", 20, 20, retro: true)
  end
end

class Chest < Prop
  def initialize(x, y)
    super(x, y)
    @wood = rand(0..64)
    @metal = rand(0..16)
    @science = rand(0..4)
    @frames_count = 1
    @spritesheet = Gosu::Image.load_tiles("assets/images/chest.png", 20, 20, retro: true)
  end
end
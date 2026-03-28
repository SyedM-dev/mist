class Placeable
  SIZE = [25, 15]

  # The base class for all placeables in the game. Placeables are things that can be interacted with, but do not move (unlike characters).
  # They cannot be walked through, but can be interacted with (e.g. a chest can be opened, a torch can be lit, a radar can be used).
  # They are placed at the center of a tile, and their position is represented by the tile coordinate
  # An object is one that is placed at the center of a tile (radar, torch & chest)
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
    @frames_count = 0
    @spritesheet = nil

    $bus.on(:object_at) do |x, y|
      next @x == x && @y == y ? self : nil
    end

    $bus.on(:collides?) do |rect|
      next collides?(rect) ? :object : nil
    end
  end

  def collides?(rect)
    return true if intersects?(self.rect, rect)
    false
  end

  def rect
    [@x * 120 + 90 - SIZE[0] / 2, @y * 120 + 90 - SIZE[1], SIZE[0], SIZE[1]]
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
    Gosu.draw_rect(screen_x - SIZE[0] / 2, screen_y - SIZE[1], SIZE[0], SIZE[1], Gosu::Color.new(0x88ff0000), Float::INFINITY)
  end
end

class Radar < Placeable
  def initialize(x, y)
    super(x, y)
    @frames_count = 4
    @spritesheet = Gosu::Image.load_tiles("assets/images/radar.png", 20, 20, retro: true)
  end
end

class Torch < Placeable
  def initialize(x, y)
    super(x, y)
    @frames_count = 4
    @spritesheet = Gosu::Image.load_tiles("assets/images/torch.png", 20, 20, retro: true)

    $bus.on(:torch_position) do
      next rect
    end
  end
end

class Chest < Placeable
  def initialize(x, y)
    super(x, y)
    @frames_count = 1
    @spritesheet = Gosu::Image.load_tiles("assets/images/chest.png", 20, 20, retro: true)
  end
end

class ObjectHandler
  attr_reader :objects

  def initialize
    start_room_coords = $bus.get(:start_room_coords)
    @objects = []

    #spawn_chests!
  end

  def spawn_chests!
    world_size = $bus.get(:maze_size) || [0, 0]

    cell_size = 6  # tweak this (bigger = more spread out)

    (0...world_size[0]).step(cell_size) do |cx|
      (0...world_size[1]).step(cell_size) do |cy|

        # Random position inside this cell
        x = cx + rand(cell_size)
        y = cy + rand(cell_size)

        next if x >= world_size[0] || y >= world_size[1]

        # Keep your spawn exclusion
        next if (x - 2).abs <= 1 && (y - 2).abs <= 1

        next if $bus.get(:room?, x, y)

        # Chance per cell instead of per tile
        if rand < 0.6
          @objects << Chest.new(x, y)
        end
      end
    end
  end

  def add(object)
    @objects << object
  end

  def update
    @objects.each(&:update)
  end

  def draw
    @objects.each(&:draw)
  end
end
require_relative "../utils/maze"

class Maze
  def initialize
    @maze = MazeData.new(80, 80)
    @spritesheet = Gosu::Image.load_tiles("assets/images/walls.png", 20, 40, retro: true)
    puts @spritesheet.size

    $bus.on(:maze_solve) do |x1, y1, x2, y2|
      next @maze.solve(x1, y1, x2, y2)
    end

    $bus.on(:collides?) do |rect|
      next collides?(rect) ? :wall : nil
    end
  end

  def collides?(rect)
    x1 = ((rect[0] - 10) / 60).floor
    y1 = ((rect[1] - 10) / 60).floor
    x2 = ((rect[0] + rect[2] + 10) / 60).floor
    y2 = ((rect[1] + rect[3] + 10) / 60).floor

    (x1..x2).each do |x|
      (y1..y2).each do |y|
        shapes = shapes_for(@maze.wall_type(x, y), x * 60, y * 60)
        shapes.each do |shape|
          return true if intersects?(shape, rect)
        end
      end
    end

    false
  end

  def shapes_for(mask, tx, ty)
    return [] if mask == 0

    half = 30
    band = 10

    shapes = []

    case mask & (W | E)
    when W | E
      shapes << [tx, ty + 30 - band / 2, 60, band]
    when E
      if (mask & (N | S)) == 0
        shapes << [tx, ty + 30 - band / 2, 60, band]
      else
        shapes << [tx + half, ty + 30 - band / 2, half, band]
      end
    when W
      if (mask & (N | S)) == 0
        shapes << [tx, ty + 30 - band / 2, 60, band]
      else
        shapes << [tx, ty + 30 - band / 2, half, band]
      end
    end

    band = 20

    case mask & (N | S)
    when (N | S)
      shapes << [tx + 30 - band / 2, ty, band, 60]
    when S
      shapes << [tx + 30 - band / 2, ty + half, band, half]
    when N
      shapes << [tx + 30 - band / 2, ty, band, half]
    end

    shapes
  end

  def draw
    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]
    tile_size = 60
    scale = 3
    screen_width, screen_height = SCREEN_SIZE

    # How many tiles fit on screen (+1 for partially visible tiles)
    tiles_x = (screen_width / tile_size) + 2
    tiles_y = (screen_height / tile_size) + 2

    # Which tile to start drawing (top-left corner of camera)
    start_x = (cam_x / tile_size).floor - 1
    start_y = (cam_y / tile_size).floor - 1

    (0...tiles_y).each do |j|
      (0...tiles_x).each do |i|
        gx = start_x + i
        gy = start_y + j

        next if gx < 0 || gy < 0 || gx >= @maze.width || gy >= @maze.height

        index = @maze.wall_type(gx, gy)
        next if index == 0

        # Pixel position on screen
        screen_x = gx * tile_size - cam_x
        screen_y = gy * tile_size - cam_y

        @spritesheet[index - 1].draw(screen_x, screen_y, screen_y, scale, scale)

        next unless DEBUG

        shapes = shapes_for(index, gx * tile_size, gy * tile_size)
        shapes.each do |shape|
          Gosu.draw_rect(shape[0] - cam_x, shape[1] - cam_y, shape[2], shape[3], 0x44ff0000, shape[1] - cam_y)
        end
      end
    end
  end
end
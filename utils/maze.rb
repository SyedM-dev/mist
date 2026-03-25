class MazeData
  def initialize(width, height)
    @width = width
    @height = height

    @grid = Array.new(height) { Array.new(width, 0) }

    @boss_rooms = []

    crate_rooms!
    carve_passages_from(0, 0)
    fix_room_entrances!

    return unless DEBUG

    print_debug
    $bus.on_retrievable(:boss_room_coords) do
      next @boss_rooms.first ? [@boss_rooms.first[0] * 2 + 1, @boss_rooms.first[1] * 2 + 1] : nil
    end
  end

  def width
    @width * 2 + 1
  end

  def height
    @height * 2 + 1
  end

  def wall_type(gx, gy)
    mask = 0
    
    return mask unless wall_at?(gx, gy)

    mask |= N if gy > 0          && wall_at?(gx,     gy - 1)
    mask |= S if gy < height - 1 && wall_at?(gx,     gy + 1)
    mask |= E if gx < width - 1  && wall_at?(gx + 1, gy    )
    mask |= W if gx > 0          && wall_at?(gx - 1, gy    )

    return mask
  end

  def wall_at?(gx, gy)
    return true if gx == 0 || gy == 0 || gx == width - 1 || gy == height - 1

    @boss_rooms.each do |rx, ry|
      display_x1 = rx * 2 + 1
      display_y1 = ry * 2 + 1
      display_x2 = display_x1 + (BOSS_ROOM_SIZE - 1) * 2
      display_y2 = display_y1 + (BOSS_ROOM_SIZE - 1) * 2
      return false if gx.between?(display_x1, display_x2) && gy.between?(display_y1, display_y2)
    end

    return false if gx.odd? && gy.odd?

    if gx.odd? && gy.even?
      cx = (gx - 1) / 2
      cy = (gy - 1) / 2
      return (@grid[cy][cx] & S) == 0
    end

    if gx.even? && gy.odd?
      cx = (gx - 1) / 2
      cy = (gy - 1) / 2
      return (@grid[cy][cx] & E) == 0
    end

    true
  end

  def print_debug
    wall_chars = {
      0   => " ",  # NONE
      1   => "╵",  # N
      2   => "╷",  # S
      3   => "│",  # NS
      4   => "╴",  # W
      5   => "┘",  # NW
      6   => "┐",  # WS
      7   => "┤",  # WNS
      8   => "╶",  # E
      9   => "└",  # NE
      10  => "┌",  # ES
      11  => "├",  # ENS
      12  => "─",  # EW
      13  => "┴",  # EWN
      14  => "┬",  # EWS
      15  => "┼"   # EWNS
    }
    (0...self.height).each do |y|
      (0...self.width).each do |x|
        print wall_chars[wall_type(x, y)]
      end
      puts
    end
  end

  private

  BOSS_ROOM_SIZE = 3
  BOSS_ROOM = 16
  N, S, W, E = 1, 2, 4, 8
  DX         = { E => 1, W => -1, N =>  0, S => 0 }
  DY         = { E => 0, W =>  0, N => -1, S => 1 }
  OPPOSITE   = { E => W, W =>  E, N =>  S, S => N }

  def room_free?(x, y)
    (y - 2...(y + BOSS_ROOM_SIZE + 2)).each do |j|
      (x - 2...(x + BOSS_ROOM_SIZE + 2)).each do |i|
        return false if @grid[j][i] & BOSS_ROOM != 0
      end
    end
    true
  end

  def fix_room_entrances!
    @boss_rooms.each do |x, y|
      @grid[y][x + 1] |= N
      @grid[y - 1][x + 1] |= S
    end
  end

  def crate_rooms!
    base = Math.sqrt(@width * @height / 200.0).round
    num_rooms = rand((base - 1)..(base))
    num_rooms = 1 if num_rooms < 1
    attempts = 0

    while @boss_rooms.size < num_rooms && attempts < 10
      attempts += 1

      x = rand(2..(@width - BOSS_ROOM_SIZE - 2))
      y = rand(2..(@height - BOSS_ROOM_SIZE - 2))

      next unless room_free?(x, y)

      (y...(y + BOSS_ROOM_SIZE)).each do |j|
        (x...(x + BOSS_ROOM_SIZE)).each do |i|
          cell = N | S | E | W
          cell |= BOSS_ROOM

          cell &= ~N if j == y
          cell &= ~S if j == y + BOSS_ROOM_SIZE - 1
          cell &= ~W if i == x
          cell &= ~E if i == x + BOSS_ROOM_SIZE - 1

          @grid[j][i] = cell
        end
      end

      @boss_rooms << [x, y]
    end
  end

  def carve_passages_from(cx, cy)
    directions = [N, S, E, W].shuffle

    directions.each do |direction|
      nx, ny = cx + DX[direction], cy + DY[direction]

      if ny.between?(0, @height - 1) && nx.between?(0, @width - 1) && @grid[ny][nx] == 0
        @grid[cy][cx] |= direction
        @grid[ny][nx] |= OPPOSITE[direction]
        carve_passages_from(nx, ny)
      end
    end
  end
end

if __FILE__ == $0

end